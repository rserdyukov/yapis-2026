#!/usr/bin/env bash
# Общая проверка компилятора студента через его скрипт compile.sh.
#
# По требованиям практикума (TASK.md, лабораторная 3 и далее) в корне
# репозитория должен лежать compile.sh, принимающий файл с текстом программы:
#
#     ./compile.sh examples/1.txt
#
# Скрипт прогоняет через compile.sh все примеры из examples/ и сверяет
# фактическое поведение с ожидаемым:
#   - корректный пример (без префикса error-) должен компилироваться, то есть
#     завершаться с кодом 0;
#   - пример с префиксом error- должен завершаться НЕнулевым кодом и печатать
#     осмысленное сообщение об ошибке.
#
# Результат печатается в stdout и попадает в промпт ИИ-ревью как ДАННЫЕ —
# модель перепроверяет выводы по коду, а не доверяет им слепо.
#
# Используется из tasks/task3..task5/check.sh, чтобы не дублировать логику.
#
# Использование:
#   run_compile_checks <work_dir> [timeout_seconds] [max_examples] [examples_dir] [demote_re]
#
# demote_re — регулярное выражение (grep -E, без учёта регистра) по имени
# error-файла: такие примеры идут в прогон последними. На ЛР4 это
# лексические/синтаксические примеры из ЛР3: при сортировке по алфавиту
# error-lex-*/error-syntax-* шли раньше error-sem-* и вытесняли семантические
# за лимит (rublevskaya#8: прогнано 4 из 7).
#
# Не попавшие в прогон файлы перечисляются в выводе, а в конце печатаются
# точные счётчики — модель должна брать числа отсюда, а не из README.
#
# Возвращает 0, если поведение всех примеров ожидаемое, иначе 1.
# Отсутствие compile.sh — это нарушение требования, возвращает 1.

# Максимум примеров каждого вида. Ограничение бережёт минуты GitHub Actions:
# у некоторых студентов в examples/ десятки файлов.
COMPILE_CHECK_MAX_EXAMPLES_DEFAULT=6

# Ищет compile.sh в корне работы студента.
# Проверяем наличие файла, а не бит исполнения: скрипт мог быть закоммичен
# без +x (например, разработка велась на Windows), но `bash compile.sh`
# всё равно отработает.
find_compile_script() {
  local work_dir="$1"
  if [ -f "${work_dir}/compile.sh" ]; then
    echo "compile.sh"
    return 0
  fi
  return 1
}

# Похож ли вывод на аварийное завершение компилятора, а не на диагностику.
# Проверяются типовые сигнатуры: Python Traceback, Java/C# stack trace,
# Node ошибки модулей, отсутствие интерпретатора/команды.
_looks_like_crash() {
  printf '%s\n' "$1" | grep -qE \
    '^Traceback \(most recent call last\)|ModuleNotFoundError|ImportError: |No module named|Exception in thread "main"|^\s+at [A-Za-z_$][A-Za-z0-9_.$<>]*\(.*\)$|Unhandled exception\.|^Error: Cannot find module|command not found|No such file or directory: .*(python|java|node|dotnet)|not recognized as an internal or external command|Could not find or load main class|Error: Could not find or load|MSBUILD : error|error CS[0-9]+:|error: package .* does not exist'
}

# Запускает compile.sh на одном примере и печатает результат.
# Возвращает 0, если поведение совпало с ожидаемым.
_run_one_example() {
  local work_dir="$1" script="$2" example="$3" expect="$4" timeout_s="$5"
  local rel out rc

  # Путь относительно рабочей директории: compile.sh почти всегда написан
  # в расчёте на запуск из корня репозитория студента.
  rel="${example#"${work_dir}"/}"

  out="$( (cd "${work_dir}" && timeout "${timeout_s}" bash compile.sh "${rel}") 2>&1 )"
  rc=$?

  echo "--- ./compile.sh ${rel}"
  echo "${out}" | head -n 25
  if [ "$(printf '%s\n' "${out}" | wc -l)" -gt 25 ]; then
    echo "    (вывод обрезан)"
  fi

  if [ "${rc}" -eq 124 ]; then
    echo "    РЕЗУЛЬТАТ: таймаут ${timeout_s}с — компиляция не завершилась."
    return 1
  fi

  # Падение самого компилятора — не «обнаруженная ошибка в примере».
  # Трасса интерпретатора/JVM/.NET, отсутствующий модуль, «command not
  # found» — признаки того, что до анализа программы дело не дошло.
  # Без этого error-пример, на котором компилятор упал с Traceback,
  # засчитывался бы как успешно обнаруженная ошибка.
  if [ "${rc}" -ne 0 ] && _looks_like_crash "${out}"; then
    echo "    РЕЗУЛЬТАТ: код ${rc}, но это ПАДЕНИЕ компилятора (трасса исключения / отсутствующая"
    echo "    зависимость / не найден интерпретатор), а не сообщение об ошибке в программе."
    return 1
  fi

  if [ "${expect}" = "ok" ]; then
    if [ "${rc}" -eq 0 ]; then
      echo "    РЕЗУЛЬТАТ: код 0 — корректный пример скомпилирован, как и ожидается."
      return 0
    fi
    echo "    РЕЗУЛЬТАТ: код ${rc} — корректный пример НЕ скомпилировался."
    return 1
  fi

  # expect = error
  if [ "${rc}" -ne 0 ]; then
    echo "    РЕЗУЛЬТАТ: код ${rc} — ошибка обнаружена, как и ожидается."
    if [ -z "${out}" ]; then
      echo "    ЗАМЕЧАНИЕ: сообщение об ошибке пустое — студент должен выводить"
      echo "    осмысленный текст с указанием строки/столбца."
      return 1
    fi
    return 0
  fi
  echo "    РЕЗУЛЬТАТ: код 0 — пример с ошибкой скомпилировался БЕЗ ошибки."
  return 1
}

# Основная функция. Печатает отчёт и возвращает 0/1.
run_compile_checks() {
  local work_dir="${1:?work_dir is required}"
  local timeout_s="${2:-120}"
  local max_examples="${3:-${COMPILE_CHECK_MAX_EXAMPLES_DEFAULT}}"
  local examples_dir="${4:-}"
  local demote_re="${5:-}"

  local script
  if ! script="$(find_compile_script "${work_dir}")"; then
    echo "ВНИМАНИЕ: в корне репозитория не найден compile.sh."
    echo "По требованиям практикума (TASK.md) он обязателен начиная с"
    echo "лабораторной работы 3 и должен запускаться как:"
    echo "    ./compile.sh <файл с примером>"
    echo "Фактическая проверка компилятора не выполнена."
    return 1
  fi

  if [ -z "${examples_dir}" ] || [ ! -d "${examples_dir}" ]; then
    echo "Найден ${script}, но директория с примерами отсутствует — запуск пропущен."
    return 1
  fi

  local all_err all_ok
  all_ok="$(find "${examples_dir}" -type f -not -iname "error-*" -not -iname "*.md" 2>/dev/null | sort)"
  all_err="$(find "${examples_dir}" -type f -iname "error-*" 2>/dev/null | sort)"
  if [ -n "${demote_re}" ] && [ -n "${all_err}" ]; then
    all_err="$(
      printf '%s\n' "${all_err}" | while IFS= read -r line; do
        if ! basename "${line}" | grep -qiE "${demote_re}"; then printf '%s\n' "${line}"; fi
      done
      printf '%s\n' "${all_err}" | while IFS= read -r line; do
        if basename "${line}" | grep -qiE "${demote_re}"; then printf '%s\n' "${line}"; fi
      done
    )"
  fi

  local ok_examples=() err_examples=() ok_skipped=() err_skipped=() line
  while IFS= read -r line; do
    [ -z "${line}" ] && continue
    if [ "${#err_examples[@]}" -lt "${max_examples}" ]; then err_examples+=("${line}"); else err_skipped+=("${line}"); fi
  done <<< "${all_err}"

  while IFS= read -r line; do
    [ -z "${line}" ] && continue
    if [ "${#ok_examples[@]}" -lt "${max_examples}" ]; then ok_examples+=("${line}"); else ok_skipped+=("${line}"); fi
  done <<< "${all_ok}"

  echo "Найден ${work_dir}/${script}. Прогоняю примеры (таймаут ${timeout_s}с на файл, не более ${max_examples} каждого вида)."
  [ -n "${demote_re}" ] && echo "Error-примеры с именем по шаблону «${demote_re}» (ошибки прошлых лабораторных) запускаются последними."
  echo

  local ok_failed=0 err_failed=0 example

  if [ "${#ok_examples[@]}" -gt 0 ]; then
    echo "== Корректные примеры (ожидается успешная компиляция) =="
    for example in "${ok_examples[@]}"; do
      _run_one_example "${work_dir}" "${script}" "${example}" "ok" "${timeout_s}" || ok_failed=$((ok_failed + 1))
    done
    echo
  else
    echo "Корректных примеров не найдено."
    echo
  fi

  if [ "${#err_examples[@]}" -gt 0 ]; then
    echo "== Примеры с ошибками (ожидается сообщение об ошибке) =="
    for example in "${err_examples[@]}"; do
      _run_one_example "${work_dir}" "${script}" "${example}" "error" "${timeout_s}" || err_failed=$((err_failed + 1))
    done
    echo
  else
    echo "Примеров с префиксом error- не найдено."
    echo
  fi

  if [ "$(( ${#ok_skipped[@]} + ${#err_skipped[@]} ))" -gt 0 ]; then
    echo "== НЕ запускались (лимит ${max_examples} на вид) =="
    echo "Поведение этих файлов неизвестно: не пиши о них «отработал» и не включай их в числа прогона."
    for example in ${ok_skipped[@]+"${ok_skipped[@]}"} ${err_skipped[@]+"${err_skipped[@]}"}; do
      echo "  ${example#"${work_dir}"/}"
    done
    echo
  fi

  echo "Счётчики (копируй в таблицу проверок как есть):"
  echo "  корректные: запущено ${#ok_examples[@]}, ожидаемо $(( ${#ok_examples[@]} - ok_failed )), не запускалось ${#ok_skipped[@]}"
  echo "  error-*: запущено ${#err_examples[@]}, ожидаемо $(( ${#err_examples[@]} - err_failed )), не запускалось ${#err_skipped[@]}"

  local failed=$((ok_failed + err_failed))
  if [ "${failed}" -gt 0 ]; then
    echo "Итог: расхождений с ожидаемым поведением — ${failed}."
    return 1
  fi

  echo "Итог: все проверенные примеры отработали ожидаемо."
  return 0
}
