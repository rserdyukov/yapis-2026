#!/usr/bin/env bash
# Фактическая проверка грамматики ANTLR студента: сборка .g4 и прогон
# примеров через сгенерированный парсер — то же, что делает lab.antlr.org,
# только без картинки дерева разбора.
#
# ЗАЧЕМ. До этого check.sh для ЛР2 лишь считал строки и regex-правила в .g4.
# Модель при этом писала «грамматика полностью покрывает функционал», хотя
# грамматика не разбирала ни один из собственных примеров студента (реальный
# случай: yapis-2026-321702-rublevskaya#2 — все три примера падали на первой
# же строке). Сборка и прогон занимают ~2 с и дают модели факты вместо догадок.
#
# КАК РАБОТАЕТ
#   1. Находит все *.g4 (кроме каталогов сборки). Комбинированные грамматики
#      (`grammar X;`) собираются по одной; пары `lexer grammar XLexer;` +
#      `parser grammar XParser;` из одного каталога — вместе.
#   2. Генерирует Java-таргет во временный каталог. Всегда Java — независимо
#      от того, на чём студент пишет компилятор: Java-рантайм есть в образе,
#      а сама грамматика от таргета не зависит. Исключение — грамматики с
#      embedded-кодом (@header/@members/{...} на Python и т.п.): они не
#      скомпилируются javac, и это честно сообщается как ограничение
#      проверки, а не как ошибка студента.
#   3. Компилирует javac, стартовое правило — ПЕРВОЕ правило парсера в файле
#      (так же поступает lab.antlr.org, когда правило не указано).
#   4. Прогоняет каждый пример из examples/ через org.antlr.v4.gui.TestRig:
#      корректные примеры (без префикса error-) должны разбираться без
#      сообщений «line N:M ...»; error-примеры (если есть) — с ними.
#
# Результат печатается в stdout и попадает в промпт как ДАННЫЕ.
#
# Использование:
#   run_antlr_checks <work_dir> [timeout_seconds] [max_examples]
#
# Возвращает 0, если все грамматики собрались и все корректные примеры
# разобрались; 1 — иначе. Отсутствие Java/ANTLR в окружении — не вина
# студента: печатается предупреждение, возвращается 0.
#
# Переменные окружения:
#   ANTLR_JAR   путь к antlr-4.x-complete.jar (в образе задан Dockerfile;
#               локально ищется в типовых местах).

ANTLR_CHECK_MAX_EXAMPLES_DEFAULT=6
ANTLR_CHECK_TIMEOUT_DEFAULT=60
# Сколько строк вывода парсера показывать на один пример.
ANTLR_CHECK_MAX_OUTPUT_LINES=8

# --- Поиск инструментов ----------------------------------------------------

_antlr_find_jar() {
  if [ -n "${ANTLR_JAR:-}" ] && [ -f "${ANTLR_JAR}" ]; then
    echo "${ANTLR_JAR}"; return 0
  fi
  local c
  for c in /opt/antlr/antlr-*-complete.jar \
           /usr/local/lib/antlr-*-complete.jar \
           /opt/homebrew/Cellar/antlr/*/antlr-*-complete.jar \
           /usr/share/java/antlr4-*complete.jar \
           "${HOME}"/.m2/repository/org/antlr/antlr4/*/antlr4-*-complete.jar; do
    if [ -f "${c}" ]; then echo "${c}"; return 0; fi
  done
  return 1
}

# --- Разбор заголовка грамматики -------------------------------------------

# Печатает тип грамматики: combined | lexer | parser | unknown.
_antlr_grammar_kind() {
  local f="$1" head
  head="$(grep -vE '^\s*(//|\*|/\*)' "${f}" | grep -m1 -E '^\s*(lexer\s+grammar|parser\s+grammar|grammar)\s+[A-Za-z_][A-Za-z0-9_]*\s*;' || true)"
  case "${head}" in
    *"lexer grammar"*)  echo lexer ;;
    *"parser grammar"*) echo parser ;;
    *grammar*)          echo combined ;;
    *)                  echo unknown ;;
  esac
}

# Имя грамматики из заголовка.
_antlr_grammar_name() {
  grep -vE '^\s*(//|\*|/\*)' "$1" \
    | grep -m1 -oE '(lexer\s+|parser\s+)?grammar\s+[A-Za-z_][A-Za-z0-9_]*' \
    | awk '{ print $NF }'
}

# Первое правило парсера: строка, начинающаяся со строчной буквы и
# продолжающаяся `:` (возможно, через перевод строки). Комментарии и
# `fragment`/лексерные правила (с заглавной) не подходят.
_antlr_first_parser_rule() {
  local f="$1"
  # Убираем блочные и строчные комментарии (perl: BSD sed на macOS не знает
  # \+ и не работает с многострочными шаблонами), затем ищем первое
  # `<начало строки>имя<пробелы/переводы>:`. Строчные буквы в начале —
  # признак правила парсера (лексерные — с заглавной); `options`, `import`,
  # `tokens`, `channels`, `mode` и `fragment` исключаем явно.
  perl -0777 -pe 's{/\*.*?\*/}{}gs; s{//[^\n]*}{}g' "${f}" \
    | grep -oE '^[[:space:]]*[a-z][A-Za-z0-9_]*[[:space:]]*(:|$)' \
    | grep -oE '[a-z][A-Za-z0-9_]*' \
    | grep -vE '^(options|import|tokens|channels|mode|fragment|grammar|lexer|parser|returns|locals|throws|catch|finally)$' \
    | head -n 1
}

# Есть ли в грамматике embedded-код, специфичный для не-Java таргета.
# Признаки: @header/@members с python/import/def/self, либо
# options { language = Python/JavaScript/CSharp... }.
_antlr_has_foreign_actions() {
  local f="$1"
  grep -qiE 'language\s*=\s*(Python|JavaScript|TypeScript|CSharp|Go|Cpp|Swift|Dart|PHP)' "${f}" && return 0
  if grep -qE '@(header|members|lexer::header|lexer::members|parser::header|parser::members)' "${f}"; then
    grep -qE '^\s*(import\s+\w+|from\s+\w+\s+import|def\s+\w+\(|self\.|using\s+System|const\s+\w+\s*=|require\()' "${f}" && return 0
  fi
  return 1
}

# --- Прогон одного примера --------------------------------------------------

# Печатает отчёт по примеру, возвращает 0 при ожидаемом поведении.
_antlr_run_example() {
  local classdir="$1" jar="$2" grammar="$3" rule="$4" example="$5" expect="$6" timeout_s="$7" rel="$8"
  local out rc errors

  out="$(cd "${classdir}" && timeout "${timeout_s}" \
    java -cp "${jar}:." org.antlr.v4.gui.TestRig "${grammar}" "${rule}" "${example}" 2>&1)"
  rc=$?

  # TestRig печатает ошибки в формате `line N:M message`; сам процесс при
  # синтаксических ошибках всё равно завершается кодом 0, поэтому считаем
  # именно строки с ошибками.
  errors="$(printf '%s\n' "${out}" | grep -cE '^line [0-9]+:[0-9]+ ' || true)"

  echo "--- ${rel}"
  if [ "${rc}" -eq 124 ]; then
    echo "    РЕЗУЛЬТАТ: таймаут ${timeout_s}с — разбор не завершился (возможна левая рекурсия без базы или бесконечный цикл в лексере)."
    return 1
  fi

  if [ -n "${out}" ]; then
    printf '%s\n' "${out}" | head -n "${ANTLR_CHECK_MAX_OUTPUT_LINES}" | cut -c1-300 | sed 's/^/    /'
    if [ "$(printf '%s\n' "${out}" | wc -l)" -gt "${ANTLR_CHECK_MAX_OUTPUT_LINES}" ]; then
      echo "    (вывод обрезан)"
    fi
  fi

  if [ "${expect}" = "ok" ]; then
    if [ "${errors}" -eq 0 ] && [ "${rc}" -eq 0 ]; then
      echo "    РЕЗУЛЬТАТ: разобран без ошибок, как и ожидается."
      return 0
    fi
    echo "    РЕЗУЛЬТАТ: ${errors} сообщений об ошибках — корректный пример НЕ разбирается грамматикой."
    return 1
  fi

  # expect = error
  if [ "${errors}" -gt 0 ]; then
    echo "    РЕЗУЛЬТАТ: ${errors} сообщений об ошибках — ошибка обнаружена, как и ожидается."
    return 0
  fi
  echo "    РЕЗУЛЬТАТ: разобран БЕЗ ошибок — пример с ошибкой грамматика принимает как корректный."
  return 1
}

# --- Сборка одной грамматики ------------------------------------------------

# Аргументы: <jar> <outdir> <файлы .g4...>
# Печатает отчёт; в stdout последней строкой — "OK <ParserGrammarName> <rule>"
# либо "FAIL" / "SKIP <причина>".
_antlr_build() {
  local jar="$1" outdir="$2"; shift 2
  local files=("$@") f out rc
  local parser_name="" rule="" kind name

  for f in "${files[@]}"; do
    if _antlr_has_foreign_actions "${f}"; then
      echo "    Грамматика содержит встроенный код (@header/@members/options language) для не-Java таргета."
      echo "    Сборка в Java невозможна — проверка на примерах ПРОПУЩЕНА. Это ограничение проверки, а не ошибка студента;"
      echo "    но по требованиям курса грамматика должна быть переносимой: код лучше выносить из .g4 в отдельные классы."
      echo "SKIP foreign-actions"
      return 0
    fi
  done

  # TestRig принимает БАЗОВОЕ имя грамматики и сам добавляет Lexer/Parser:
  # для `grammar X;` это X, для пары `lexer grammar XLexer; parser grammar
  # XParser;` — тоже X. Если студент назвал файлы иначе (MyLex + MyPar),
  # TestRig их не свяжет — сообщаем об этом ниже, а не падаем с ClassCast.
  local lexer_name=""
  for f in "${files[@]}"; do
    kind="$(_antlr_grammar_kind "${f}")"
    name="$(_antlr_grammar_name "${f}")"
    case "${kind}" in
      combined) parser_name="${name}"; rule="$(_antlr_first_parser_rule "${f}")" ;;
      parser)   parser_name="${name%Parser}"; rule="$(_antlr_first_parser_rule "${f}")" ;;
      lexer)    lexer_name="${name%Lexer}" ;;
    esac
  done
  if [ -n "${lexer_name}" ] && [ -n "${parser_name}" ] && [ "${lexer_name}" != "${parser_name}" ]; then
    echo "    Имена лексера (${lexer_name}Lexer) и парсера (${parser_name}Parser) не согласованы:"
    echo "    ANTLR TestRig (и lab.antlr.org) ожидают пару <Имя>Lexer / <Имя>Parser. Прогон примеров пропущен."
    echo "SKIP name-mismatch"
    return 0
  fi

  if [ -z "${parser_name}" ]; then
    echo "    Не найдено правил парсера (только lexer grammar?) — прогон примеров невозможен."
    echo "SKIP no-parser"
    return 0
  fi
  if [ -z "${rule}" ]; then
    echo "    Не удалось определить стартовое правило (первое правило парсера) — прогон примеров невозможен."
    echo "FAIL"
    return 1
  fi

  mkdir -p "${outdir}"
  # -Xexact-output-dir: класть файлы прямо в outdir, а не воспроизводить путь.
  # Файлы копируем в outdir: ANTLR ищет tokenVocab рядом с грамматикой.
  cp "${files[@]}" "${outdir}/"
  local basenames=() b
  for f in "${files[@]}"; do basenames+=("$(basename "${f}")"); done

  out="$(cd "${outdir}" && timeout 120 java -jar "${jar}" -o . -Xexact-output-dir -no-listener -no-visitor "${basenames[@]}" 2>&1)"
  rc=$?
  if [ -n "${out}" ]; then
    echo "    Вывод antlr4:"
    printf '%s\n' "${out}" | head -n 20 | cut -c1-300 | sed 's/^/      /'
  fi
  if [ "${rc}" -ne 0 ]; then
    echo "    РЕЗУЛЬТАТ: antlr4 завершился с кодом ${rc} — грамматика НЕ собирается."
    echo "FAIL"
    return 1
  fi
  # Предупреждения ANTLR (warning(…)) не ломают сборку, но это замечания.
  if printf '%s\n' "${out}" | grep -qE '^(warning|error)\('; then
    echo "    ЗАМЕЧАНИЕ: antlr4 выдал предупреждения — см. выше."
  fi

  out="$(cd "${outdir}" && timeout 120 javac -cp "${jar}" ./*.java 2>&1)"
  rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "    Вывод javac:"
    printf '%s\n' "${out}" | head -n 15 | cut -c1-300 | sed 's/^/      /'
    echo "    РЕЗУЛЬТАТ: сгенерированный парсер не компилируется (код ${rc}). Обычно это встроенный код в .g4, не совместимый с Java-таргетом."
    echo "SKIP javac-failed"
    return 0
  fi

  for b in "${basenames[@]}"; do
    [ -f "${outdir}/${b}" ] && [ "${b}" != "${parser_name}Parser.java" ] && rm -f "${outdir}/${b}"
  done

  echo "    Сборка: успешно. Стартовое правило: ${rule}"
  echo "OK ${parser_name} ${rule}"
  return 0
}

# --- Главная функция -------------------------------------------------------

run_antlr_checks() {
  local work_dir="${1:?work_dir is required}"
  local timeout_s="${2:-${ANTLR_CHECK_TIMEOUT_DEFAULT}}"
  local max_examples="${3:-${ANTLR_CHECK_MAX_EXAMPLES_DEFAULT}}"

  # Прогон идёт из временного каталога с .class-файлами, поэтому пути к
  # примерам и грамматикам должны быть абсолютными (check.sh получает '.').
  if [ -d "${work_dir}" ]; then
    work_dir="$(cd "${work_dir}" && pwd)"
  fi

  local jar
  if ! command -v java >/dev/null 2>&1; then
    echo "Java не найдена — сборка грамматики и прогон примеров не выполнены (ограничение окружения, не работы)."
    return 0
  fi
  if ! jar="$(_antlr_find_jar)"; then
    echo "antlr-*-complete.jar не найден — сборка грамматики и прогон примеров не выполнены (ограничение окружения, не работы)."
    return 0
  fi

  local grammars=() line
  while IFS= read -r line; do
    [ -n "${line}" ] && grammars+=("${line}")
  done < <(find "${work_dir}" -name '*.g4' \
      -not -path '*/target/*' -not -path '*/build/*' -not -path '*/.venv/*' \
      -not -path '*/node_modules/*' -not -path '*/.antlr/*' -not -path '*/.git/*' 2>/dev/null | sort)

  if [ "${#grammars[@]}" -eq 0 ]; then
    echo "Файлы грамматики (*.g4) не найдены — сборка не выполнена."
    return 1
  fi

  local examples_dir="" candidate
  for candidate in examples example samples; do
    if [ -d "${work_dir}/${candidate}" ]; then examples_dir="${work_dir}/${candidate}"; break; fi
  done

  local ok_examples=() err_examples=()
  if [ -n "${examples_dir}" ]; then
    while IFS= read -r line; do
      [ -n "${line}" ] && err_examples+=("${line}")
    done < <(find "${examples_dir}" -type f -iname 'error-*' 2>/dev/null | sort | head -n "${max_examples}")
    while IFS= read -r line; do
      [ -n "${line}" ] && ok_examples+=("${line}")
    done < <(find "${examples_dir}" -type f -not -iname 'error-*' -not -iname '*.md' -not -iname '.*' 2>/dev/null | sort | head -n "${max_examples}")
  fi

  echo "ANTLR: $(java -jar "${jar}" 2>&1 | head -n 1 | grep -oE 'Version [0-9.]+' || echo 'версия неизвестна'). Стартовое правило — первое правило парсера в файле (как в lab.antlr.org без указания правила)."
  echo

  # Группировка: комбинированные — по одной; lexer+parser из одного каталога — вместе.
  # Простая схема: для каждого каталога с .g4 собираем все parser/combined
  # грамматики, к parser-грамматике добавляем все lexer-грамматики того же каталога.
  local tmp_root
  tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/antlr-check.XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp_root}'" RETURN

  local failed=0 built=0 g kind dir lexers=() group=() name outdir status parser rule example rel n=0

  for g in "${grammars[@]}"; do
    kind="$(_antlr_grammar_kind "${g}")"
    [ "${kind}" = "lexer" ] && lexers+=("${g}")
  done

  for g in "${grammars[@]}"; do
    kind="$(_antlr_grammar_kind "${g}")"
    name="$(_antlr_grammar_name "${g}")"
    rel="${g#"${work_dir}"/}"
    case "${kind}" in
      lexer)
        # Отдельный лексер: собирается в паре со своим парсером, здесь пропускаем.
        continue ;;
      unknown)
        echo "== ${rel} =="
        echo "    Не распознан заголовок grammar/lexer grammar/parser grammar — файл пропущен."
        echo
        failed=$((failed + 1))
        continue ;;
    esac

    group=("${g}")
    if [ "${kind}" = "parser" ]; then
      dir="$(dirname "${g}")"
      local lx
      for lx in "${lexers[@]}"; do
        [ "$(dirname "${lx}")" = "${dir}" ] && group+=("${lx}")
      done
      if [ "${#group[@]}" -eq 1 ]; then
        echo "== ${rel} (${name}) =="
        echo "    parser grammar без lexer grammar в том же каталоге — сборка невозможна."
        echo
        failed=$((failed + 1))
        continue
      fi
    fi

    n=$((n + 1))
    outdir="${tmp_root}/g${n}"
    echo "== ${rel} (${name}) =="
    status="$(_antlr_build "${jar}" "${outdir}" "${group[@]}")"
    printf '%s\n' "${status}" | sed '$d'
    status="$(printf '%s\n' "${status}" | tail -n 1)"

    case "${status}" in
      FAIL*) failed=$((failed + 1)); echo; continue ;;
      SKIP*) echo; continue ;;
      OK*)   built=$((built + 1)) ;;
    esac
    parser="$(printf '%s' "${status}" | awk '{ print $2 }')"
    rule="$(printf '%s' "${status}" | awk '{ print $3 }')"

    if [ -z "${examples_dir}" ]; then
      echo "    Директория с примерами не найдена — прогон пропущен."
      echo
      continue
    fi

    if [ "${#ok_examples[@]}" -gt 0 ]; then
      echo "  -- Корректные примеры (ожидается разбор без ошибок) --"
      for example in "${ok_examples[@]}"; do
        _antlr_run_example "${outdir}" "${jar}" "${parser}" "${rule}" "${example}" ok "${timeout_s}" "${example#"${work_dir}"/}" \
          || failed=$((failed + 1))
      done
    else
      echo "  Корректных примеров не найдено."
    fi
    if [ "${#err_examples[@]}" -gt 0 ]; then
      echo "  -- Примеры с ошибками (ожидаются сообщения об ошибках) --"
      for example in "${err_examples[@]}"; do
        _antlr_run_example "${outdir}" "${jar}" "${parser}" "${rule}" "${example}" error "${timeout_s}" "${example#"${work_dir}"/}" \
          || failed=$((failed + 1))
      done
    fi
    echo
  done

  if [ "${failed}" -gt 0 ]; then
    echo "Итог: собрано грамматик — ${built}, расхождений с ожидаемым поведением — ${failed}."
    return 1
  fi
  if [ "${built}" -eq 0 ]; then
    echo "Итог: ни одна грамматика не была собрана и проверена на примерах (см. причины выше)."
    return 0
  fi
  echo "Итог: собрано грамматик — ${built}, все проверенные примеры разобраны ожидаемо."
  return 0
}
