#!/usr/bin/env bash
# Определяет студента, номер лабораторной работы и рабочую директорию
# по имени ветки PR.
#
# Ожидаемый формат имени ветки — task<номер> (модель "один репозиторий на
# студента", см. GUIDE.md). Идентификатором студента служит имя
# репозитория. Формат <фамилия>/task<номер> из старой модели "монорепо" тоже
# распознаётся, чтобы ревью не падало на ветках, названных по привычке.
#
# БЕЗОПАСНОСТЬ: имя ветки — недоверенные данные. Git разрешает в нём `$`, `(`,
# `)` и другие символы, значимые для shell, поэтому:
#   - вызывающий код обязан передавать его аргументом/через env, а не
#     подставлять в тело команды;
#   - здесь имя дополнительно валидируется, а всё, что уходит в вывод и дальше
#     в пути файлов, приводится к безопасному подмножеству символов.
#
# Использование: detect-task.sh <branch-name> [repo-name] [repo-root]
#   repo-root — корень checkout репозитория студента (по умолчанию .);
#               нужен для автоопределения раскладки "монорепо".
# Пишет в $GITHUB_OUTPUT (или stdout): student, task_num, task_dir, work_dir.
# Набор промптов tasks/<task_dir> ищется рядом с этим скриптом.

set -euo pipefail

BRANCH="${1:-}"
REPO_NAME="${2:-}"
REPO_ROOT="${3:-.}"

REVIEW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Оставляем только заведомо безопасные символы. Это не отменяет передачу через
# env в вызывающем коде, а дополняет её на случай будущих правок.
sanitize() {
  printf '%s' "${1}" | tr -cd 'A-Za-z0-9._/-'
}

BRANCH="$(sanitize "${BRANCH}")"
REPO_NAME="$(sanitize "${REPO_NAME}")"

# Защита от путей вида ../ и от абсолютных путей в work_dir.
case "${BRANCH}" in
  *..*) BRANCH="" ;;
esac

if [[ "${BRANCH}" == */* ]]; then
  # Формат <фамилия>/task<номер> (старая модель "монорепо").
  STUDENT="${BRANCH%%/*}"
else
  # Формат task<номер> — идентификатором служит имя репозитория.
  STUDENT="${REPO_NAME}"
fi

TASK_NUM="$(printf '%s' "${BRANCH}" | grep -oE 'task[0-9]+' | grep -oE '[0-9]+' | head -1 || true)"

if [ -z "${STUDENT}" ]; then
  STUDENT="unknown"
fi

if [ -z "${TASK_NUM}" ]; then
  TASK_DIR="default"
  TASK_NUM="0"
else
  # Отсекаем ведущие нули и заведомо бессмысленные номера, чтобы task_dir
  # оставался предсказуемым именем каталога.
  TASK_NUM="$((10#${TASK_NUM}))"
  TASK_DIR="task${TASK_NUM}"
fi

# Если для номера задания нет отдельного набора промпта/скриптов — fallback.
if [ ! -d "${REVIEW_ROOT}/tasks/${TASK_DIR}" ]; then
  TASK_DIR="default"
fi

# Автоопределение раскладки репозитория. В модели "репозиторий на студента"
# работа лежит в корне; каталог с именем студента ищем только ради
# совместимости со старым монорепо.
if [ "${STUDENT}" != "unknown" ] && [ -d "${REPO_ROOT}/${STUDENT}" ]; then
  WORK_DIR="${STUDENT}"
else
  WORK_DIR="."
fi

{
  echo "student=${STUDENT}"
  echo "task_num=${TASK_NUM}"
  echo "task_dir=${TASK_DIR}"
  echo "work_dir=${WORK_DIR}"
} >> "${GITHUB_OUTPUT:-/dev/stdout}"

echo "Определено: student=${STUDENT}, task_num=${TASK_NUM}, task_dir=${TASK_DIR}, work_dir=${WORK_DIR}" >&2
