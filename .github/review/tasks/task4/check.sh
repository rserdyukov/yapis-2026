#!/usr/bin/env bash
# Структурная проверка для лабораторной работы №4:
#   1. наличие примеров с ошибками (префикс error-);
#   2. наличие compile.sh в корне (обязателен с ЛР3, см. TASK.md);
#   3. фактический прогон примеров через compile.sh;
#   4. зонды устойчивости (lib/probe-check.sh): программы, построенные
#      автоматически без знания синтаксиса варианта.
#
# Важно: у каждого студента своё окружение (Java/Maven, Python/venv и т.д.),
# поэтому запуск выполняется "по возможности" — падение не считается фатальной
# ошибкой всего workflow, а фиксируется в отчёте для ИИ-ревью.
#
# Использование: check.sh <work_dir>

set -uo pipefail

WORK_DIR="${1:?work_dir is required}"
TIMEOUT_SECONDS=120
# Лимит error-примеров выше, чем в ЛР3: в examples/ лежат и ошибки ЛР3
# (лексические/синтаксические), и новые семантические.
MAX_EXAMPLES=12
# Имена error-файлов из ЛР3 — запускаются после семантических, чтобы не
# вытеснять их за лимит.
LEGACY_ERROR_RE='lex|synt|pars|token'

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/compile-check.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/layout-check.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/probe-check.sh"

EXAMPLES_DIR=""
for candidate in "examples" "example" "samples"; do
  if [ -d "${WORK_DIR}/${candidate}" ]; then
    EXAMPLES_DIR="${WORK_DIR}/${candidate}"
    break
  fi
done

if [ -z "${EXAMPLES_DIR}" ]; then
  echo "Директория с примерами не найдена в ${WORK_DIR}."
  exit 1
fi

# Портируемый аналог `mapfile` (совместим и с bash 3.2 при локальном запуске
# на macOS, и с bash 5.x на CI-раннерах).
ERROR_EXAMPLES=()
while IFS= read -r line; do
  ERROR_EXAMPLES+=("${line}")
done < <(find "${EXAMPLES_DIR}" -type f -iname "error-*" 2>/dev/null | sort -u)

ALL_EXAMPLES=()
while IFS= read -r line; do
  ALL_EXAMPLES+=("${line}")
done < <(find "${EXAMPLES_DIR}" -type f 2>/dev/null | sort -u)

echo "Всего файлов-примеров: ${#ALL_EXAMPLES[@]}"
echo "Из них с префиксом error-: ${#ERROR_EXAMPLES[@]}"
if [ "${#ERROR_EXAMPLES[@]}" -gt 0 ]; then
  printf '  %s\n' "${ERROR_EXAMPLES[@]}"
fi
echo

STATUS=0
if [ "${#ERROR_EXAMPLES[@]}" -eq 0 ]; then
  echo "ВНИМАНИЕ: не найдено ни одного файла-примера с префиксом error-."
  echo "По требованиям ЛР4 нужны примеры с СЕМАНТИЧЕСКИМИ ошибками (см. TASK.md)."
  echo
  STATUS=1
fi

echo "== Раскладка репозитория =="
check_layout "${WORK_DIR}" || STATUS=1
echo

echo "== Проверка компилятора через compile.sh =="
run_compile_checks "${WORK_DIR}" "${TIMEOUT_SECONDS}" "${MAX_EXAMPLES}" "${EXAMPLES_DIR}" "${LEGACY_ERROR_RE}" || STATUS=1
echo

echo "== Зонды устойчивости =="
run_probe_checks "${WORK_DIR}" "${EXAMPLES_DIR}" 60 'sem' || STATUS=1

exit "${STATUS}"
