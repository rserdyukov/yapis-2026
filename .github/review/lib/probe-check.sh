#!/usr/bin/env bash
# Зонды устойчивости компилятора: программы, которые check.sh генерирует сам,
# не зная синтаксиса варианта студента.
#
# ЗАЧЕМ. Примеры в examples/ пишет студент, поэтому зелёный прогон
# доказывает только то, что анализатор справляется с ЭТИМИ программами.
# Слабая модель ревью (gemma 4) по коду дефектов не находит
# (rublevskaya#8: «Замечаний не найдено» при RecursionError и трассе на
# не-UTF-8 файле), а факты из вывода check.sh передаёт точно. Поэтому то,
# что можно проверить запуском, проверяем запуском.
#
# Каждый зонд строится либо без знания языка (пустой/бинарный/отсутствующий
# файл), либо механическим преобразованием примеров студента, которое
# сохраняет смысл программы в любом варианте курса:
#   - пустые строки в начале error-примера — номер строки в сообщении
#     должен сдвинуться ровно на столько же;
#   - целый литерал в корректном примере заменяется суммой из N единиц того
#     же типа — программа остаётся корректной, но выражение становится
#     глубоким (рекурсивный обход не должен падать);
#   - корректный пример, записанный дважды подряд, — подпрограммы и явно
#     объявленные переменные объявлены повторно с той же сигнатурой.
#
# Использование: source probe-check.sh; run_probe_checks <work_dir> <examples_dir> [timeout] [prefer_re] [skip]
#   prefer_re — шаблон имён error-примеров, которые брать для зонда сдвига
#   строк в первую очередь (на ЛР4 — семантические);
#   skip      — зонды, которые не запускать, через пробел: doubled (на ЛР3
#               повторные объявления ещё не проверяются — это ЛР4).
# Требует _looks_like_crash из compile-check.sh.
#
# Возвращает 0, если ни один зонд не дал замечания, иначе 1.

PROBE_SHIFT_LINES=5
PROBE_SUM_TERMS=300

# Первый номер строки из сообщения компилятора: «строка 12», «line 12»,
# «стр. 12», «[12:5]», «12:5:». Пусто, если номера нет. Время вида
# 00:00:01.23 («Time Elapsed» у dotnet build, логи gradle) — не позиция:
# вырезаем его до поиска, иначе «00:00» принимается за строку 0.
_probe_first_line_no() {
  printf '%s\n' "$1" | LC_ALL=C sed -E 's/[0-9]+:[0-9]+:[0-9]+([.,][0-9]+)?//g' | LC_ALL=C grep -oiE '(строк[аеиу]?|line|стр\.?)[^0-9[:alpha:]]{0,3}[0-9]+|(^|[^0-9.])[0-9]+:[0-9]+' \
    | head -n 1 | grep -oE '[0-9]+' | head -n 1
}

# Запуск compile.sh на зонде: печатает «rc<TAB>вывод».
_probe_run() {
  local work="$1" rel="$2" timeout_s="$3" out rc
  out="$( (cd "${work}" && timeout "${timeout_s}" bash compile.sh "${rel}" </dev/null) 2>&1 )"
  rc=$?
  printf '%s\t%s' "${rc}" "${out}"
}

# Короткая цитата вывода: первые 3 непустые строки и последняя строка
# (у трассы Python самое важное — последняя).
_probe_quote() {
  local out="$1" n
  n="$(printf '%s\n' "${out}" | grep -c .)"
  printf '%s\n' "${out}" | grep . | head -n 3 | cut -c1-200 | sed 's/^/      | /'
  if [ "${n}" -gt 3 ]; then
    echo "      | …"
    printf '%s\n' "${out}" | grep . | tail -n 1 | cut -c1-200 | sed 's/^/      | /'
  fi
}

# awk-программа: маскирует строковые литералы "…" и '…' и комментарии
# (//, #, --) пробелами той же длины, чтобы позиции совпадали с исходной строкой.
_PROBE_AWK_MASK='
function mask(s,   out, i, c, q) {
  out = ""; q = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (q != "") { out = out " "; if (c == q) q = ""; continue }
    if (c == "\"" || c == "\047") { q = c; out = out " "; continue }
    if (substr(s, i, 2) == "//" || substr(s, i, 2) == "--" || c == "#") {
      while (i <= length(s)) { out = out " "; i++ }
      break
    }
    out = out c
  }
  return out
}
function find_lit(m) {
  return match(m, /(=|\(|,)[[:space:]]*-?[0-9]+(\.[0-9]+)?([^A-Za-z0-9_.]|$)/)
}'

# Номер первой строки с числовым литералом после «=», «(» или «,».
_probe_literal_line() {
  LC_ALL=C awk "${_PROBE_AWK_MASK}"'
    /^[[:space:]]*(==|!=)/ { next }
    { m = mask($0); if (find_lit(m)) { print NR; exit } }
  ' "$1"
}

# Печатает файл, в строке ln которого литерал заменён на (L + 0 + … + 0).
_probe_deepen() {
  LC_ALL=C awk -v ln="$2" -v n="$3" "${_PROBE_AWK_MASK}"'
    NR == ln {
      m = mask($0)
      if (find_lit(m)) {
        # Внутри совпадения «=  12.5)» ищем само число.
        seg = substr(m, RSTART, RLENGTH); base = RSTART
        match(seg, /-?[0-9]+(\.[0-9]+)?/)
        start = base + RSTART - 1; len = RLENGTH
        lit = substr($0, start, len)
        zero = (lit ~ /\./) ? "0.0" : "0"
        e = "(" lit; for (k = 1; k < n; k++) e = e " + " zero; e = e ")"
        $0 = substr($0, 1, start - 1) e substr($0, start + len)
      }
    }
    { print }
  ' "$1"
}

run_probe_checks() {
  local work="${1:?work_dir}" examples_dir="${2:?examples_dir}" timeout_s="${3:-60}" prefer_re="${4:-}" skip=" ${5:-} "
  work="$(cd "${work}" && pwd)"
  [ -f "${work}/compile.sh" ] || { echo "compile.sh не найден — зонды не запускались."; return 0; }

  # .review/ исключён из проверки раскладки и из diff; чистим за собой.
  local pdir_rel=".review/probes" pdir="${work}/.review/probes"
  rm -rf "${pdir}"; mkdir -p "${pdir}"

  local total=0 remarks=0 res rc out
  _probe_remark() { remarks=$((remarks + 1)); echo "    РЕЗУЛЬТАТ: ЗАМЕЧАНИЕ — $1"; }
  _probe_ok() { echo "    РЕЗУЛЬТАТ: ожидаемо — $1"; }

  echo "Зонды строятся автоматически и не зависят от синтаксиса варианта. Замечание по зонду — факт запуска, а не догадка; причину ищи в коде."
  echo

  # 1. Несуществующий файл.
  total=$((total + 1))
  echo "--- зонд «нет файла»: ./compile.sh ${pdir_rel}/no-such-file.txt"
  res="$(_probe_run "${work}" "${pdir_rel}/no-such-file.txt" "${timeout_s}")"; rc="${res%%$'\t'*}"; out="${res#*$'\t'}"
  _probe_quote "${out}"
  if [ "${rc}" -eq 124 ]; then _probe_remark "таймаут"
  elif [ "${rc}" -eq 0 ]; then _probe_remark "код 0 для несуществующего файла"
  elif _looks_like_crash "${out}"; then _probe_remark "код ${rc}, но вместо сообщения трасса исключения"
  else _probe_ok "код ${rc}, сообщение без трассы"; fi

  # 2. Пустой файл: код любой, но без трассы.
  total=$((total + 1))
  : > "${pdir}/empty.txt"
  echo "--- зонд «пустой файл»: ./compile.sh ${pdir_rel}/empty.txt"
  res="$(_probe_run "${work}" "${pdir_rel}/empty.txt" "${timeout_s}")"; rc="${res%%$'\t'*}"; out="${res#*$'\t'}"
  _probe_quote "${out}"
  if [ "${rc}" -eq 124 ]; then _probe_remark "таймаут"
  elif [ "${rc}" -ne 0 ] && _looks_like_crash "${out}"; then _probe_remark "код ${rc}, трасса исключения на пустом файле"
  else _probe_ok "код ${rc} (пустая программа может быть и корректной, и ошибкой — смотри README)"; fi

  # 3. Не UTF-8.
  total=$((total + 1))
  printf '\377\376\200\201 \000\001 garbage\n' > "${pdir}/not-utf8.txt"
  echo "--- зонд «файл не в UTF-8 / бинарный»: ./compile.sh ${pdir_rel}/not-utf8.txt"
  res="$(_probe_run "${work}" "${pdir_rel}/not-utf8.txt" "${timeout_s}")"; rc="${res%%$'\t'*}"; out="${res#*$'\t'}"
  _probe_quote "${out}"
  if [ "${rc}" -eq 124 ]; then _probe_remark "таймаут"
  elif [ "${rc}" -eq 0 ]; then _probe_remark "код 0 для бинарного мусора"
  elif _looks_like_crash "${out}" || printf '%s' "${out}" | grep -qE 'UnicodeDecodeError|MalformedInputException|DecoderFallbackException'; then
    _probe_remark "код ${rc}, но вместо сообщения об ошибке — трасса исключения (ошибка декодирования не перехвачена)"
  else _probe_ok "код ${rc}, сообщение без трассы"; fi

  # 4. Глубокое выражение: числовой литерал L в корректном примере
  # заменяется на (L + 0 + 0 + … ) — значение и тип те же (для 1.5 — нули
  # вида 0.0). Берём литерал сразу после «=», «(» или «,» — там стоит
  # выражение почти в любой грамматике; строки и комментарии пропускаем.
  local ok_rel="" deep_src="" deep_line="" f_ok
  while IFS= read -r f_ok; do
    [ -z "${f_ok}" ] && continue
    deep_line="$(_probe_literal_line "${f_ok}")"
    if [ -n "${deep_line}" ]; then deep_src="${f_ok}"; break; fi
  done < <(find "${examples_dir}" -type f -not -iname 'error-*' -not -iname '*.md' 2>/dev/null | sort)
  total=$((total + 1))
  if [ -z "${deep_src}" ]; then
    echo "--- зонд «глубокое выражение»: ни в одном корректном примере не найден числовой литерал после «=», «(» или «,» — зонд пропущен."
  else
    ok_rel="${deep_src#"${work}"/}"
    _probe_deepen "${deep_src}" "${deep_line}" "${PROBE_SUM_TERMS}" > "${pdir}/deep-sum.txt"
    echo "--- зонд «глубокое выражение»: ${ok_rel}, строка ${deep_line}: литерал L заменён на (L + 0 + … + 0) из ${PROBE_SUM_TERMS} слагаемых"
    printf '      исходная:  %s\n' "$(sed -n "${deep_line}p" "${deep_src}" | cut -c1-120)"
    res="$(_probe_run "${work}" "${pdir_rel}/deep-sum.txt" "${timeout_s}")"; rc="${res%%$'\t'*}"; out="${res#*$'\t'}"
    _probe_quote "${out}"
    if [ "${rc}" -eq 124 ]; then _probe_remark "таймаут на выражении из ${PROBE_SUM_TERMS} слагаемых"
    elif printf '%s' "${out}" | grep -qE 'RecursionError|StackOverflowError|StackOverflowException|Maximum call stack|stack overflow'; then
      _probe_remark "переполнение стека рекурсии на выражении из ${PROBE_SUM_TERMS} слагаемых"
    elif [ "${rc}" -ne 0 ] && _looks_like_crash "${out}"; then _probe_remark "код ${rc}, трасса исключения"
    elif [ "${rc}" -eq 0 ]; then _probe_ok "код 0"
    else echo "    РЕЗУЛЬТАТ: код ${rc} с сообщением — программа отвергнута. Если литерал стоял там, где выражение недопустимо по правилам языка (константа, размер, граница диапазона), это не дефект; иначе — ложное срабатывание."; fi
  fi

  local ok_example="${deep_src}"
  [ -z "${ok_example}" ] && ok_example="$(find "${examples_dir}" -type f -not -iname 'error-*' -not -iname '*.md' 2>/dev/null | sort | head -n 1)"
  if [ -n "${ok_example}" ] && [ "${skip#* doubled }" = "${skip}" ]; then
    ok_rel="${ok_example#"${work}"/}"
    # 5. Корректный пример дважды подряд.
    total=$((total + 1))
    { cat "${ok_example}"; echo; cat "${ok_example}"; } > "${pdir}/doubled.txt"
    echo "--- зонд «пример дважды»: ${ok_rel}, записанный два раза подряд"
    res="$(_probe_run "${work}" "${pdir_rel}/doubled.txt" "${timeout_s}")"; rc="${res%%$'\t'*}"; out="${res#*$'\t'}"
    _probe_quote "${out}"
    if [ "${rc}" -eq 124 ]; then _probe_remark "таймаут"
    elif [ "${rc}" -ne 0 ] && _looks_like_crash "${out}"; then _probe_remark "код ${rc}, трасса исключения"
    elif [ "${rc}" -eq 0 ]; then
      echo "    РЕЗУЛЬТАТ: код 0. Если в ${ok_rel} объявлены подпрограммы (или переменные при явном объявлении), повторное объявление с той же сигнатурой НЕ обнаружено — проверь по примеру и коду; если объявлений нет — это норма."
    else _probe_ok "код ${rc} — повторные объявления обнаружены (сверь текст сообщения)"; fi
  fi

  # 6. Сдвиг номеров строк: до 3 error-примеров с пустыми строками в начале.
  local err_list f
  err_list="$(find "${examples_dir}" -type f -iname 'error-*' 2>/dev/null | sort)"
  if [ -n "${prefer_re}" ] && [ -n "${err_list}" ]; then
    err_list="$( { printf '%s\n' "${err_list}" | while IFS= read -r f; do basename "${f}" | grep -qiE "${prefer_re}" && printf '%s\n' "${f}"; done
                   printf '%s\n' "${err_list}" | while IFS= read -r f; do basename "${f}" | grep -qiE "${prefer_re}" || printf '%s\n' "${f}"; done; } )"
  fi
  local shifted=0 orig_res orig_rc orig_out l0 l1 rel
  while IFS= read -r f; do
    [ -z "${f}" ] && continue
    [ "${shifted}" -ge 3 ] && break
    rel="${f#"${work}"/}"
    orig_res="$(_probe_run "${work}" "${rel}" "${timeout_s}")"; orig_rc="${orig_res%%$'\t'*}"; orig_out="${orig_res#*$'\t'}"
    [ "${orig_rc}" -eq 0 ] && continue
    _looks_like_crash "${orig_out}" && continue
    l0="$(_probe_first_line_no "${orig_out}")"
    shifted=$((shifted + 1)); total=$((total + 1))
    { for _ in $(seq "${PROBE_SHIFT_LINES}"); do echo; done; cat "${f}"; } > "${pdir}/shift-$(basename "${f}")"
    echo "--- зонд «сдвиг строк»: ${rel} с ${PROBE_SHIFT_LINES} пустыми строками в начале"
    res="$(_probe_run "${work}" "${pdir_rel}/shift-$(basename "${f}")" "${timeout_s}")"; rc="${res%%$'\t'*}"; out="${res#*$'\t'}"
    _probe_quote "${out}"
    if [ -z "${l0}" ]; then _probe_remark "в сообщении об ошибке для ${rel} не найден номер строки"; continue; fi
    l1="$(_probe_first_line_no "${out}")"
    if [ "${rc}" -eq 0 ]; then _probe_remark "после добавления пустых строк ошибка перестала обнаруживаться (код 0)"
    elif [ "${l1:-}" = "$((l0 + PROBE_SHIFT_LINES))" ]; then _probe_ok "строка ${l0} → ${l1}"
    else _probe_remark "номер строки ${l0} → ${l1:-нет}, ожидалось $((l0 + PROBE_SHIFT_LINES)): сообщение указывает не на строку исходного файла"; fi
  done <<< "${err_list}"

  rm -rf "${pdir}"
  rmdir "${work}/.review" 2>/dev/null || true

  echo
  echo "Счётчики зондов (копируй в таблицу проверок как есть): запущено ${total}, замечаний ${remarks}"
  [ "${remarks}" -eq 0 ]
}
