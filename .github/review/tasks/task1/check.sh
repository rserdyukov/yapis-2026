#!/usr/bin/env bash
# Лёгкая структурная проверка для лабораторной работы №1:
# наличие директории с примерами и минимум трёх файлов в ней.
#
# Использование: check.sh <work_dir>
# Ничего не собирает и не запускает — только проверяет наличие файлов,
# поэтому безопасен и быстр для любого варианта задания.

set -uo pipefail

WORK_DIR="${1:?work_dir is required}"

EXAMPLES_DIR=""
for candidate in "examples" "example" "samples"; do
  if [ -d "${WORK_DIR}/${candidate}" ]; then
    EXAMPLES_DIR="${WORK_DIR}/${candidate}"
    break
  fi
done

if [ -z "${EXAMPLES_DIR}" ]; then
  echo "Директория с примерами не найдена (ожидались examples/, example/ или samples/ внутри ${WORK_DIR})."
  exit 1
fi

FILE_COUNT="$(find "${EXAMPLES_DIR}" -maxdepth 2 -type f | wc -l | tr -d ' ')"

echo "Директория с примерами: ${EXAMPLES_DIR}"
echo "Найдено файлов: ${FILE_COUNT}"
find "${EXAMPLES_DIR}" -maxdepth 2 -type f -print

if [ "${FILE_COUNT}" -lt 3 ]; then
  echo "ВНИМАНИЕ: ожидалось минимум 3 файла-примера, найдено ${FILE_COUNT}."
  exit 1
fi

exit 0
