#!/usr/bin/env bash
# Проверка для лабораторной работы №2: грамматика ANTLR.
#
#   1. Наличие файлов *.g4 и базовая статистика (строки, комментарии, число
#      правил лексера/парсера) — быстрые подсказки модели.
#   2. ФАКТИЧЕСКАЯ сборка каждой грамматики ANTLR (Java-таргет) и прогон
#      примеров из examples/ через сгенерированный парсер — аналог того, что
#      студент делает в lab.antlr.org: корректные примеры должны разбираться
#      без ошибок, error-примеры (если уже есть) — с ошибками.
#      См. lib/antlr-check.sh.
#
# Раньше сборка сознательно не выполнялась «из-за разнообразия окружений».
# Теперь check.sh запускается в едином контейнере (reviewer/Dockerfile) с
# JDK и antlr-4.13.2-complete.jar, а грамматика собирается в Java независимо
# от языка, на котором студент пишет компилятор. Локально у студента без
# Java прогон пропускается с предупреждением, статистика печатается всегда.
#
# Использование: check.sh <work_dir>

set -uo pipefail

WORK_DIR="${1:?work_dir is required}"
TIMEOUT_SECONDS=60

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/antlr-check.sh"

# Портируемый аналог `mapfile` (совместим и с bash 3.2, например при
# локальном запуске скрипта на macOS, и с bash 5.x на CI-раннерах).
GRAMMAR_FILES=()
while IFS= read -r line; do
  GRAMMAR_FILES+=("${line}")
done < <(find "${WORK_DIR}" -name "*.g4" -not -path "*/target/*" -not -path "*/build/*" \
  -not -path "*/.venv/*" -not -path "*/node_modules/*" -not -path "*/.antlr/*" -not -path "*/.git/*" | sort)

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
  COMMENT_LINES="$(grep -cE '^\s*(//|/\*|\*)' "${grammar}" || true)"
  PARSER_RULES="$(grep -cE '^[a-z][a-zA-Z0-9_]*\s*:' "${grammar}" || true)"
  LEXER_RULES="$(grep -cE '^(fragment\s+)?[A-Z][A-Z0-9_]*\s*:' "${grammar}" || true)"

  echo "--- ${grammar#"${WORK_DIR}"/} ---"
  echo "Строк: ${LINES}, строк-комментариев: ${COMMENT_LINES}"
  echo "Правил парсера (по началу строки): ${PARSER_RULES}, правил лексера: ${LEXER_RULES}"

  if [ "${LINES}" -lt 10 ]; then
    echo "ВНИМАНИЕ: файл грамматики подозрительно короткий (${LINES} строк)."
    STATUS=1
  fi
  if [ "${COMMENT_LINES}" -eq 0 ]; then
    echo "ЗАМЕЧАНИЕ: в грамматике нет ни одной строки-комментария (требование раздела 2 TASK.md — оформленная и прокомментированная грамматика)."
  fi
  echo
done

echo "== Сборка грамматики и прогон примеров (ANTLR) =="
run_antlr_checks "${WORK_DIR}" "${TIMEOUT_SECONDS}" 6 || STATUS=1

exit "${STATUS}"
