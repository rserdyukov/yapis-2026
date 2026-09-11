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
