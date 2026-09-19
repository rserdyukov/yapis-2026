#!/usr/bin/env bash
# Структурная проверка для лабораторной работы №5:
#   1. наличие директории отчёта doc/ с непустым содержимым;
#   2. наличие compile.sh в корне (обязателен с ЛР3, см. TASK.md);
#   3. фактический прогон примеров через compile.sh — на этом этапе он должен
#      не только находить ошибки, но и генерировать запускаемый файл.
#
# Использование: check.sh <work_dir>

set -uo pipefail

WORK_DIR="${1:?work_dir is required}"
TIMEOUT_SECONDS=180

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/compile-check.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/layout-check.sh"

STATUS=0

DOC_DIR=""
for candidate in "doc" "docs"; do
  if [ -d "${WORK_DIR}/${candidate}" ]; then
    DOC_DIR="${WORK_DIR}/${candidate}"
    break
  fi
done

if [ -z "${DOC_DIR}" ]; then
  echo "ВНИМАНИЕ: директория отчёта (doc/ или docs/) не найдена в ${WORK_DIR}."
  STATUS=1
else
  DOC_FILE_COUNT="$(find "${DOC_DIR}" -type f | wc -l | tr -d ' ')"
  echo "Директория отчёта: ${DOC_DIR}, файлов внутри: ${DOC_FILE_COUNT}"
  if [ "${DOC_FILE_COUNT}" -eq 0 ]; then
    echo "ВНИМАНИЕ: директория отчёта пуста."
    STATUS=1
  fi
fi
echo

EXAMPLES_DIR=""
for candidate in "examples" "example" "samples"; do
  if [ -d "${WORK_DIR}/${candidate}" ]; then
    EXAMPLES_DIR="${WORK_DIR}/${candidate}"
    break
  fi
done

echo "== Раскладка репозитория =="
check_layout "${WORK_DIR}" || STATUS=1
echo

echo "== Проверка компилятора через compile.sh =="
run_compile_checks "${WORK_DIR}" "${TIMEOUT_SECONDS}" 6 "${EXAMPLES_DIR}" || STATUS=1
echo

# На ЛР5 compile.sh должен породить артефакт целевого кода. Ищем файлы,
# появившиеся в рабочей директории, — это подсказка для ИИ-ревью, а не
# строгий критерий: формат артефакта зависит от варианта (JVM/CIL/LLVM/WAT).
echo "== Артефакты после компиляции =="
ARTIFACTS="$(find "${WORK_DIR}" -maxdepth 3 -type f \
  \( -name '*.class' -o -name '*.jar' -o -name '*.exe' -o -name '*.ll' \
     -o -name '*.wat' -o -name '*.wasm' -o -name '*.il' -o -name '*.pyc' \
     -o -name '*.j' -o -name '*.bc' \) \
  -not -path '*/target/*' -not -path '*/.venv/*' 2>/dev/null | head -n 15)"

if [ -n "${ARTIFACTS}" ]; then
  echo "Найдены файлы целевого кода:"
  printf '  %s\n' ${ARTIFACTS}
else
  echo "Файлы целевого кода не найдены. Это может означать, что compile.sh"
  echo "не генерирует запускаемый файл, либо артефакты складываются в"
  echo "нестандартное место или игнорируются git. Проверьте по коду и отчёту."
fi

exit "${STATUS}"
