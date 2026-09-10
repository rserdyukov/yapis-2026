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
#   - вызывающий workflow обязан передавать его через env, а не подставлять
#     в тело `run:` (см. .github/workflows/ai-review.yml);
#   - здесь имя дополнительно валидируется, а всё, что уходит в GITHUB_OUTPUT
#     и дальше в пути файлов, приводится к безопасному подмножеству символов.
#
# Использование: detect-task.sh <branch-name> [repo-name]
# Пишет в $GITHUB_OUTPUT: student, task_num, task_dir, work_dir

set -euo pipefail

BRANCH="${1:-}"
REPO_NAME="${2:-}"

# Оставляем только заведомо безопасные символы. Это не отменяет передачу через
# env в workflow, а дополняет её на случай будущих правок вызывающего кода.
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
if [ ! -d ".github/review/tasks/${TASK_DIR}" ]; then
  TASK_DIR="default"
fi

# Автоопределение раскладки репозитория. В модели "репозиторий на студента"
# работа лежит в корне; каталог с именем студента ищем только ради
# совместимости со старым монорепо.
if [ "${STUDENT}" != "unknown" ] && [ -d "./${STUDENT}" ]; then
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
