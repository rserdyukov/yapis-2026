#!/usr/bin/env bash
# Общие функции скриптов ревьюера. Подключается через source после
# config.env и messages.env.

# Подставляет ${VAR} в шаблон сообщения значениями текущего окружения.
# Используется envsubst-подобный приём через eval, но БЕЗОПАСНО: раскрываются
# только переменные, а подстановка команд экранируется — messages.env
# заполняет преподаватель, случайные обратные кавычки не должны выполняться.
render_msg() {
  local template="${1}"
  template="${template//\`/\\\`}"
  template="${template//\$(/\\\$(}"
  eval "printf '%b' \"${template}\""
}

# Убирает служебный мусор в начале ответа модели (правит файл на месте).
#   sanitize_review_text <файл>
#
# Gemma 4 через opencode в 7 из 9 прогонов eval-prompts.sh начинала ответ
# со служебных токенов, которые не являются частью ревью: строки «thought»,
# «judgment», «<|tool_call>», одиночные «}» и «{». Иногда «}» прилипает к
# первому слову ревью («}**Резюме:** …»). Само ревью после них корректно,
# поэтому такие строки срезаем, а не отклоняем ответ целиком.
#
# Режем только ПЕРВЫЕ строки, пока они подходят под шаблон; первая
# содержательная строка останавливает чистку. Так «thought» внутри ревью
# (например, цитата из кода студента) не пострадает.
sanitize_review_text() {
  local file="${1}" tmp
  tmp="$(mktemp)"
  LC_ALL=C awk '
    !started {
      line = $0
      # Целиком служебная строка -> пропускаем.
      if (line ~ /^[[:space:]]*$/ ||
          line ~ /^[[:space:]]*(thought|judgment|<\|tool_call>|<\|[a-z_]+\|?>|[{}]+)[[:space:]]*$/) next
      # Мусор прилип к началу содержательной строки -> отрезаем префикс.
      sub(/^[[:space:]]*(<\|[a-z_]+\|?>)+/, "", line)
      sub(/^[{}]+/, "", line)
      if (line ~ /^[[:space:]]*$/) next
      started = 1
      print line
      next
    }
    { print }
  ' "${file}" > "${tmp}" && mv "${tmp}" "${file}"
  rm -f "${tmp}"
}

# Проверяет, что текст ответа модели похож на готовое ревью, а не на брак.
#   validate_review_text <файл> -> 0 и пусто, либо 1 и причина в stdout
#
# Мотивация — реальный инцидент: бесплатная reasoning-модель вывела вместо
# ревью 50 КБ английских рассуждений «Let's check…», а в конце зациклилась
# на 18 тыс. плюсов и 19 тыс. девяток. Ни одна из существующих проверок
# (пустой файл, справка CLI, утечка ключа) этого не поймала, и брак ушёл
# студенту в PR. Пороги — в config.env (REVIEW_MAX_BYTES, REVIEW_MIN_CYR_PCT,
# REVIEW_MAX_REPEAT). Любую проверку можно отключить нулём.
validate_review_text() {
  local file="${1}"
  local max_bytes="${REVIEW_MAX_BYTES:-15000}"
  local min_cyr="${REVIEW_MIN_CYR_PCT:-60}"
  local max_repeat="${REVIEW_MAX_REPEAT:-200}"

  # 1. Размер. Ревью по формату футера — резюме + список замечаний; 15 КБ
  #    это уже очень много. Больше — почти наверняка рассуждения или цикл.
  local bytes; bytes="$(wc -c < "${file}" | tr -d ' ')"
  if [ "${max_bytes}" -gt 0 ] && [ "${bytes}" -gt "${max_bytes}" ]; then
    echo "ответ модели слишком длинный: ${bytes} байт (лимит ${max_bytes})"
    return 1
  fi

  # 2. Зацикливание: один и тот же байт N+ раз подряд. Легитимный текст
  #    так не выглядит (линейка «---» в markdown короче 200 символов).
  if [ "${max_repeat}" -gt 0 ] && LC_ALL=C grep -qE "(.)\1{${max_repeat},}" "${file}"; then
    echo "ответ модели содержит повтор одного символа >${max_repeat} раз подряд (зацикливание)"
    return 1
  fi

  # 3. Язык. Считаем кириллические и латинские буквы; в UTF-8 кириллица
  #    начинается с байтов 0xD0/0xD1 — по одному на символ, так что счёт
  #    байтов равен счёту букв. Код в обратных кавычках и пути файлов дают
  #    латиницу, поэтому порог мягкий; английские рассуждения дают ~10%.
  if [ "${min_cyr}" -gt 0 ]; then
    local cyr lat total
    cyr="$(LC_ALL=C tr -cd '\320\321' < "${file}" | wc -c | tr -d ' ')"
    lat="$(LC_ALL=C tr -cd 'A-Za-z' < "${file}" | wc -c | tr -d ' ')"
    total=$((cyr + lat))
    if [ "${total}" -gt 0 ] && [ $((cyr * 100 / total)) -lt "${min_cyr}" ]; then
      echo "ответ модели не на русском: кириллицы $((cyr * 100 / total))% (порог ${min_cyr}%)"
      return 1
    fi
  fi

  # 4. Ход рассуждений вместо ответа. Характерные зачины reasoning-моделей в
  #    первых строках. Проверяем только начало: цитата такой фразы в теле
  #    ревью (например, как замечание студенту) — не повод отклонять.
  if head -n 5 "${file}" | LC_ALL=C grep -qiE '^(we are given|we need to|let'"'"'s (check|start|look|begin)|first, let|okay, |<think>|thinking:)'; then
    echo "ответ модели начинается с хода рассуждений, а не с ревью"
    return 1
  fi

  return 0
}

# ISO-время 24 часа назад (GNU и BSD date).
since_24h() {
  date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -v-24H +%Y-%m-%dT%H:%M:%SZ
}

# Формирует комментарий-отказ (GitHub alert) и печатает его в stdout.
#   skip_comment <head_sha> <причина>
# Маркеры идут первыми: HTML-комментарии не отображаются, но по ним
# discover.sh отличает отказы от ревью и понимает, что SHA уже обработан.
skip_comment() {
  local head_sha="${1}" reason="${2}" line
  echo "${MARKER_REVIEW}"
  echo "${MARKER_SKIPPED}"
  echo "${MARKER_SHA_PREFIX}${head_sha} -->"
  echo
  echo "> [!${MSG_SKIPPED_ALERT_TYPE:-WARNING}]"
  echo "> **${MSG_SKIPPED_HEADER}**"
  echo ">"
  # Причина может быть многострочной; каждую строку префиксуем '>', иначе
  # alert оборвётся на первой строке без префикса.
  while IFS= read -r line; do
    if [ -z "${line}" ]; then echo ">"; else echo "> ${line}"; fi
  done <<< "${reason}"
}

# Публикует комментарий-отказ в PR (если не DRY_RUN).
#   post_skip <owner/repo> <pr> <head_sha> <причина>
post_skip() {
  local repo_full="${1}" pr="${2}" head_sha="${3}" reason="${4}"
  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] ${repo_full}#${pr}: отказ — ${reason}" >&2
    return 0
  fi
  local body
  body="$(mktemp)"
  skip_comment "${head_sha}" "${reason}" > "${body}"
  if ! gh pr comment "${pr}" --repo "${repo_full}" --body-file "${body}" >/dev/null 2>&1; then
    echo "${repo_full}#${pr}: не удалось опубликовать комментарий-отказ." >&2
  fi
  rm -f "${body}"
}
