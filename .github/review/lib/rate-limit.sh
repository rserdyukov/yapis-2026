#!/usr/bin/env bash
# Защита от избыточного количества запусков ИИ-ревью.
#
# Состояние не хранится отдельно: лимит на PR считается по фактически
# опубликованным комментариям бота (маркер <!-- ai-review-marker -->), а
# дневной лимит — по истории запусков workflow (gh run list). Считать лимит
# на PR именно по комментариям важно: иначе отказы по cooldown и отменённые
# через concurrency запуски съедали бы бюджет ревью, и студент мог получить
# "лимит исчерпан", не увидев ни одного ревью.
#
# Проверяются три независимых лимита (см. .github/review/config.env):
#   1. MAX_REVIEWS_PER_PR   — не более N опубликованных ревью на один PR.
#   2. MAX_REVIEWS_PER_DAY  — не более N запусков ревью в сутки на репозиторий
#                             (защита от превышения дневных лимитов free tier
#                             провайдера модели и расхода минут Actions).
#   3. COOLDOWN_MINUTES     — не чаще одного запуска за N минут на один и тот
#                             же PR (защита от серии быстрых push подряд).
#
# Использование: rate-limit.sh <pr_number> <workflow_filename>
# Требует переменную окружения GH_TOKEN (в workflow — secrets.GITHUB_TOKEN).
# Пишет в $GITHUB_OUTPUT: allowed=true|false, reason=<текст причины отказа>

set -euo pipefail

PR_NUMBER="${1:?PR number is required}"
WORKFLOW_FILE="${2:?workflow filename is required}"

REVIEW_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."

# shellcheck source=/dev/null
source "${REVIEW_ROOT}/config.env"
# Тексты сообщений вынесены отдельно, чтобы их можно было править без
# изменения логики (см. .github/review/messages.env).
# shellcheck source=/dev/null
source "${REVIEW_ROOT}/messages.env"

REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is not set}"

# Подставляет ${VAR} в шаблон сообщения значениями текущего окружения.
# Используется envsubst-подобный приём через eval, но БЕЗОПАСНО: раскрываются
# только переменные, а подстановка команд экранируется — messages.env
# заполняет преподаватель, случайные обратные кавычки не должны выполняться.
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
  } >> "${GITHUB_OUTPUT:-/dev/stdout}"
}

deny() {
  echo "Ревью отклонено: ${1}" >&2
  output "false" "${1}"
  exit 0
}

# --- 1. Дневной лимит на репозиторий (по истории запусков workflow) ---
SINCE="$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-24H +%Y-%m-%dT%H:%M:%SZ)"

# Ошибку получения истории НЕ глушим в пустой список: раньше `|| echo '[]'`
# маскировал отсутствие права actions:read у GITHUB_TOKEN, и оба лимита
# (дневной и cooldown) молча не работали. Теперь это явно видно в логе.
if ! RUNS_JSON="$(gh run list \
  --repo "${REPO}" \
  --workflow "${WORKFLOW_FILE}" \
  --limit 200 \
  --json databaseId,createdAt,headBranch,conclusion,status 2>&1)"; then
  echo "ВНИМАНИЕ: не удалось получить историю запусков workflow." >&2
  echo "${RUNS_JSON}" | head -3 >&2
  echo "Проверьте, что в workflow задано право 'actions: read'." >&2
  echo "Дневной лимит и cooldown в этом запуске не проверяются." >&2
  RUNS_JSON='[]'
fi

# Дополнительная защита: если вернулся не массив (например, текст ошибки),
# дальше jq выдал бы мусор вместо чисел.
if ! echo "${RUNS_JSON}" | jq -e 'type == "array"' >/dev/null 2>&1; then
  echo "ВНИМАНИЕ: история запусков вернулась в неожидаемом формате." >&2
  RUNS_JSON='[]'
fi

# Считаем только запуски, которые могли реально обратиться к API модели.
# Исключаем:
#   - служебную ветку синхронизации инфраструктуры (PR преподавателя от
#     ./manage.sh sync-workflow): в них ревью всегда отменяется
#     integrity-check, но раньше они съедали дневной лимит студента —
#     обнаружено на живом тесте, где 3 из 6 запусков были служебными;
#   - отменённые запуски (concurrency отменяет предыдущий при быстрых push),
#     они тоже до модели не доходят.
RUNS_TODAY_COUNT="$(echo "${RUNS_JSON}" | jq --arg since "${SINCE}" '
  [ .[]
    | select(.createdAt >= $since)
    | select(.headBranch != "ci/sync-review-tooling")
    | select(.conclusion != "cancelled")
  ] | length' 2>/dev/null || echo 0)"
case "${RUNS_TODAY_COUNT}" in
  ''|*[!0-9]*) RUNS_TODAY_COUNT=0 ;;
esac

if [ "${RUNS_TODAY_COUNT}" -ge "${MAX_REVIEWS_PER_DAY}" ]; then
  deny "$(render_msg "${MSG_LIMIT_DAILY}")"
fi

# --- 2. Лимит на PR: считаем опубликованные комментарии бота ---
# В бюджет попадают только реально выполненные ревью. Отказы несут отдельный
# маркер MARKER_SKIPPED и по нему исключаются. Раньше они отсеивались по
# фразе "Автоматическое ИИ-ревью пропущено" — из-за этого правка текста
# сообщения незаметно ломала подсчёт лимита.
COMMENTS_JSON="$(gh pr view "${PR_NUMBER}" --repo "${REPO}" --json comments \
  --jq '[.comments[] | {author: .author.login, body: .body}]' 2>/dev/null || echo '[]')"

PUBLISHED_REVIEWS="$(echo "${COMMENTS_JSON}" \
  | jq --arg marker "${MARKER_REVIEW}" --arg skipped "${MARKER_SKIPPED}" '
  [ .[]
    | select(.body | contains($marker))
    | select(.body | contains($skipped) | not)
  ] | length' 2>/dev/null || echo 0)"

# Если API комментариев недоступен или вернул неожидаемую структуру, jq даёт
# пустую строку — сравнение ниже упало бы с ошибкой при `set -e`.
case "${PUBLISHED_REVIEWS}" in
  ''|*[!0-9]*) PUBLISHED_REVIEWS=0 ;;
esac

if [ "${PUBLISHED_REVIEWS}" -ge "${MAX_REVIEWS_PER_PR}" ]; then
  deny "$(render_msg "${MSG_LIMIT_PER_PR}")"
fi

# --- 3. Cooldown по этому же PR (по истории запусков ветки) ---
BRANCH="$(gh pr view "${PR_NUMBER}" --repo "${REPO}" --json headRefName --jq '.headRefName')"

# Текущий запуск уже присутствует в списке, поэтому исключаем его по id.
CURRENT_RUN_ID="${GITHUB_RUN_ID:-0}"

LAST_RUN_TIME="$(echo "${RUNS_JSON}" | jq -r \
  --arg branch "${BRANCH}" \
  --argjson current "${CURRENT_RUN_ID}" '
  [ .[]
    | select(.headBranch == $branch)
    | select(.databaseId != $current)
  ] | map(.createdAt) | sort | last // empty')"

if [ -n "${LAST_RUN_TIME}" ]; then
  LAST_RUN_EPOCH="$(date -u -d "${LAST_RUN_TIME}" +%s 2>/dev/null \
    || date -u -jf '%Y-%m-%dT%H:%M:%SZ' "${LAST_RUN_TIME}" +%s)"
  NOW_EPOCH="$(date -u +%s)"
  DIFF_MINUTES=$(( (NOW_EPOCH - LAST_RUN_EPOCH) / 60 ))

  if [ "${DIFF_MINUTES}" -lt "${COOLDOWN_MINUTES}" ]; then
    WAIT=$(( COOLDOWN_MINUTES - DIFF_MINUTES ))
    deny "$(render_msg "${MSG_LIMIT_COOLDOWN}")"
  fi
fi

echo "Лимиты не превышены: запусков за сутки ${RUNS_TODAY_COUNT}/${MAX_REVIEWS_PER_DAY}, опубликованных ревью по PR ${PUBLISHED_REVIEWS}/${MAX_REVIEWS_PER_PR}." >&2
output "true" "ok"
