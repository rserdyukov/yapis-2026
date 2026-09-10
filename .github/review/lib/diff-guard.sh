#!/usr/bin/env bash
# Защита от чрезмерно больших PR: если суммарное количество изменённых строк
# в рабочей директории студента превышает лимит — ИИ-ревью пропускается.
# Это вторая (после rate-limit.sh) линия защиты от перерасхода бесплатных
# лимитов токенов провайдера модели: одна лабораторная работа №5
# (полноценный компилятор) может содержать очень много кода, и прогонять
# через LLM весь такой diff целиком в одном запросе дорого и не нужно —
# такой PR разумнее смотреть преподавателю вручную.
#
# Использование: diff-guard.sh <base_sha> <head_sha> <work_dir>
# Требует переменную MAX_DIFF_LINES (см. .github/review/config.env).
# Пишет в $GITHUB_OUTPUT: allowed=true|false, reason=<текст>, changed_lines=<N>

set -euo pipefail

BASE_SHA="${1:?base_sha is required}"
HEAD_SHA="${2:?head_sha is required}"
WORK_DIR="${3:?work_dir is required}"

REVIEW_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."

# shellcheck source=/dev/null
source "${REVIEW_ROOT}/config.env"
# Тексты сообщений — см. .github/review/messages.env.
# shellcheck source=/dev/null
source "${REVIEW_ROOT}/messages.env"

# Подстановка ${VAR} в шаблон сообщения (см. пояснение в lib/rate-limit.sh).
render_msg() {
  local template="${1}"
  template="${template//\`/\\\`}"
  template="${template//\$(/\\\$(}"
  eval "printf '%s' \"${template}\""
}

output() {
  {
    echo "allowed=${1}"
    echo "reason=${2}"
    echo "changed_lines=${3}"
  } >> "${GITHUB_OUTPUT:-/dev/stdout}"
}

PATHSPEC="."
if [ "${WORK_DIR}" != "." ]; then
  PATHSPEC="${WORK_DIR}"
fi

# Сумма добавленных и удалённых строк (git diff --numstat: added, deleted, path).
CHANGED_LINES="$(git diff --numstat "${BASE_SHA}" "${HEAD_SHA}" -- "${PATHSPEC}" \
  | awk '{ if ($1 != "-") added+=$1; if ($2 != "-") removed+=$2 } END { print added+removed+0 }')"

echo "Изменённых строк в ${PATHSPEC}: ${CHANGED_LINES} (лимит: ${MAX_DIFF_LINES})" >&2

if [ "${CHANGED_LINES}" -gt "${MAX_DIFF_LINES}" ]; then
  output "false" "$(render_msg "${MSG_DIFF_TOO_BIG}")" "${CHANGED_LINES}"
  exit 0
fi

output "true" "ok" "${CHANGED_LINES}"
