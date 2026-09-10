#!/usr/bin/env bash
# Лёгкая структурная проверка для лабораторной работы №2: наличие файла
# грамматики ANTLR и базовые признаки того, что она непустая и прокомментирована.
#
# Сознательно НЕ запускает antlr4/java: у студентов разные версии окружения
# (Java/Maven, Python/venv и т.д.), и попытка собрать грамматику в CI для
# всех вариантов сразу сильно усложнила бы workflow и была бы хрупкой.
# Вместо этого — статический анализ текста .g4 файла.
#
# Использование: check.sh <work_dir>

set -uo pipefail

WORK_DIR="${1:?work_dir is required}"

# Портируемый аналог `mapfile` (совместим и с bash 3.2, например при
# локальном запуске скрипта на macOS, и с bash 5.x на CI-раннерах).
GRAMMAR_FILES=()
while IFS= read -r line; do
  GRAMMAR_FILES+=("${line}")
done < <(find "${WORK_DIR}" -name "*.g4" -not -path "*/target/*" -not -path "*/.venv/*" -not -path "*/node_modules/*")

if [ "${#GRAMMAR_FILES[@]}" -eq 0 ]; then
  echo "Файлы грамматики (*.g4) не найдены в ${WORK_DIR}."
  exit 1
fi

echo "Найдены файлы грамматики:"
printf '  %s\n' "${GRAMMAR_FILES[@]}"
echo

STATUS=0
for grammar in "${GRAMMAR_FILES[@]}"; do
  LINES="$(wc -l < "${grammar}" | tr -d ' ')"
  COMMENT_LINES="$(grep -cE '^\s*//' "${grammar}" || true)"
  PARSER_RULES="$(grep -cE '^[a-z][a-zA-Z0-9_]*\s*:' "${grammar}" || true)"
  LEXER_RULES="$(grep -cE '^[A-Z][A-Z0-9_]*\s*:' "${grammar}" || true)"

  echo "--- ${grammar} ---"
  echo "Строк: ${LINES}, строк-комментариев: ${COMMENT_LINES}"
  echo "Похоже на правил парсера: ${PARSER_RULES}, правил лексера: ${LEXER_RULES}"

  if [ "${LINES}" -lt 10 ]; then
    echo "ВНИМАНИЕ: файл грамматики подозрительно короткий (${LINES} строк)."
    STATUS=1
  fi
  if [ "${PARSER_RULES}" -eq 0 ]; then
    echo "ВНИМАНИЕ: не найдено ни одного похожего на правило парсера (строчные имена перед ':')."
    STATUS=1
  fi
  echo
done

exit "${STATUS}"
