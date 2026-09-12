#!/usr/bin/env bash
# Выполняет ИИ-ревью одного PR студента и публикует результат комментарием.
#
# Шаги:
#   1. Клонирует репозиторий студента в рабочий каталог, переключается на
#      проверяемый коммит (head_sha).
#   2. Определяет номер лабораторной по имени ветки (lib/detect-task.sh).
#   3. Готовит diff base..head по рабочей директории студента.
#   4. Запускает структурную проверку check.sh в изолированном контейнере
#      (run-check.sh) — на КОПИИ репозитория, без сети и без секретов.
#   5. Очищает checkout от файлов, влияющих на поведение агента
#      (AGENTS.md, opencode.json, .opencode/ и т.п.) — они не относятся к
#      работе и могли быть добавлены ради prompt injection.
#   6. Собирает промпт (lib/build-prompt.sh) и запускает opencode в режиме
#      только-чтение, с минимальным окружением: в нём ТОЛЬКО ключ провайдера
#      модели, ни токена GitHub, ни прочих переменных раннера.
#   7. Проверяет ответ (не пустой, не справка CLI, не содержит секретов) и
#      публикует его в PR от имени GitHub App. При ошибке — публикует
#      сообщение о технической ошибке и завершается с кодом 1.
#
# Использование:
#   review-pr.sh <org> <repo> <pr> <head_sha> <base_sha> <branch> <student>
#
# Переменные окружения:
#   GH_TOKEN         токен для gh (installation token GitHub App): нужен для
#                    клонирования и публикации комментария. В окружение
#                    агента НЕ передаётся.
#   OPENROUTER_API_KEY  ключ модели. Единственный провайдер курса.
#   REVIEW_ROOT      каталог .github/review (по умолчанию ../../.github/review).
#   REVIEW_WORKDIR   где создавать рабочие каталоги (по умолчанию mktemp).
#   CHECK_IMAGE, CHECK_RUNNER — см. run-check.sh.
#   KEEP_WORKDIR=1   не удалять рабочий каталог (отладка).

set -uo pipefail

ORG="${1:?org}"; REPO="${2:?repo}"; PR="${3:?pr}"
HEAD_SHA="${4:?head_sha}"; BASE_SHA="${5:?base_sha}"
BRANCH="${6:?branch}"; STUDENT="${7:?student}"

REPO_FULL="${ORG}/${REPO}"
SHORT_SHA="${HEAD_SHA:0:7}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_ROOT="${REVIEW_ROOT:-$(cd "${SCRIPT_DIR}/../../.github/review" && pwd)}"

# shellcheck source=/dev/null
source "${REVIEW_ROOT}/config.env"
# shellcheck source=/dev/null
source "${REVIEW_ROOT}/messages.env"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

log() { echo "[${REPO}#${PR}] $*" >&2; }

WORK="${REVIEW_WORKDIR:-$(mktemp -d)}"
mkdir -p "${WORK}"
cleanup() {
  if [ "${KEEP_WORKDIR:-0}" != "1" ]; then rm -rf "${WORK}"; fi
}
trap cleanup EXIT

# Публикует сообщение о технической ошибке. SHA-маркер ставится и здесь:
# иначе следующий запуск повторит тот же сбой и так по кругу. Повторить
# ревью вручную: ./manage.sh review <repo>:<pr> --force.
fail_review() {
  log "ОШИБКА: $*"
  {
    echo "${MARKER_REVIEW}"
    echo "${MARKER_FAILED}"
    echo "${MARKER_SHA_PREFIX}${HEAD_SHA} -->"
    echo
    render_msg "${MSG_TECH_ERROR}"
    echo
  } > "${WORK}/failed-comment.md"
  gh pr comment "${PR}" --repo "${REPO_FULL}" --body-file "${WORK}/failed-comment.md" >/dev/null 2>&1 \
    || log "не удалось опубликовать сообщение об ошибке."
  exit 1
}

# --- 0. Ключ OpenRouter -----------------------------------------------------

# Курс работает с одним провайдером — OpenRouter (см. MODEL в config.env).
# Раньше провайдер и имя переменной с ключом вычислялись из MODEL, чтобы
# поддержать любой из 200+ провайдеров opencode. На практике это не
# понадобилось: ключ один, и лишний слой только усложнял отладку.
# Если когда-нибудь понадобится другой провайдер — менять нужно здесь,
# в config.env и в set-secret.
KEY_VALUE="${OPENROUTER_API_KEY:-}"
if [ -z "${KEY_VALUE}" ]; then
  fail_review "не задан секрет OPENROUTER_API_KEY. Добавьте его: ./manage.sh set-secret OPENROUTER_API_KEY"
fi

case "${MODEL}" in
  openrouter/*) ;;
  *)
    fail_review "MODEL в config.env должен начинаться с openrouter/ (сейчас: ${MODEL})."
    ;;
esac

if ! command -v opencode >/dev/null 2>&1; then
  fail_review "opencode не установлен в раннере."
fi

# --- 1. Клонирование --------------------------------------------------------

STUDENT_DIR="${WORK}/student"
log "клонирую ${REPO_FULL}..."
# gh repo clone подставляет учётные данные через свой credential helper на
# время команды и не сохраняет токен в .git/config.
if ! gh repo clone "${REPO_FULL}" "${STUDENT_DIR}" -- --quiet --no-checkout 2>"${WORK}/clone.err"; then
  fail_review "не удалось клонировать: $(head -3 "${WORK}/clone.err")"
fi

# Коммит мог исчезнуть после force-push, пока ревьюер стоял в очереди. Тогда
# это не ошибка: следующий запуск найдёт новый head. Комментарий не ставим.
if ! git -C "${STUDENT_DIR}" cat-file -e "${HEAD_SHA}^{commit}" 2>/dev/null; then
  # Для не-advertised SHA пробуем явный fetch (GitHub его разрешает для
  # коммитов, достижимых из веток/PR).
  git -C "${STUDENT_DIR}" fetch -q origin "${HEAD_SHA}" 2>/dev/null || true
fi
if ! git -C "${STUDENT_DIR}" cat-file -e "${HEAD_SHA}^{commit}" 2>/dev/null; then
  log "коммит ${SHORT_SHA} недоступен (ветка перезаписана?), ревью отложено."
  exit 0
fi
if ! git -C "${STUDENT_DIR}" cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
  git -C "${STUDENT_DIR}" fetch -q origin "${BASE_SHA}" 2>/dev/null || true
fi

git -C "${STUDENT_DIR}" checkout -q --detach "${HEAD_SHA}" || fail_review "не удалось переключиться на ${SHORT_SHA}."

# --- 2. Лабораторная работа -------------------------------------------------

DETECT_OUT="${WORK}/detect.out"
GITHUB_OUTPUT="${DETECT_OUT}" bash "${REVIEW_ROOT}/lib/detect-task.sh" "${BRANCH}" "${REPO}" "${STUDENT_DIR}" 2>/dev/null \
  || fail_review "detect-task.sh завершился с ошибкой."
TASK_NUM="$(sed -n 's/^task_num=//p' "${DETECT_OUT}" | tail -1)"
TASK_DIR="$(sed -n 's/^task_dir=//p' "${DETECT_OUT}" | tail -1)"
WORK_DIR="$(sed -n 's/^work_dir=//p' "${DETECT_OUT}" | tail -1)"
WORK_DIR="${WORK_DIR:-.}"
log "лабораторная №${TASK_NUM}, набор ${TASK_DIR}, work_dir=${WORK_DIR}"

# --- 3. Diff ----------------------------------------------------------------

DIFF_FILE="${WORK}/pr-diff.txt"
DIFF_BASE="${BASE_SHA}"
if MB="$(git -C "${STUDENT_DIR}" merge-base "${BASE_SHA}" "${HEAD_SHA}" 2>/dev/null)"; then
  DIFF_BASE="${MB}"
fi
{
  echo "### Список изменённых файлов"
  echo
  git -C "${STUDENT_DIR}" diff --stat "${DIFF_BASE}" "${HEAD_SHA}" -- "${WORK_DIR}"
  echo
  echo "### Полный diff"
  echo
  git -C "${STUDENT_DIR}" diff "${DIFF_BASE}" "${HEAD_SHA}" -- "${WORK_DIR}"
} > "${DIFF_FILE}" 2>/dev/null
log "diff: $(wc -l < "${DIFF_FILE}" | tr -d ' ') строк"

# --- 4. Структурная проверка в контейнере -----------------------------------

CHECK_FILE="${WORK}/check.out"
log "структурная проверка (${CHECK_RUNNER:-docker})..."
bash "${SCRIPT_DIR}/run-check.sh" "${TASK_DIR}" "${STUDENT_DIR}" "${WORK_DIR}" "${CHECK_FILE}"
CHECK_EXIT=$?
log "check.sh завершился с кодом ${CHECK_EXIT}"
if [ "${CHECK_EXIT}" -eq 125 ]; then
  fail_review "контейнер структурной проверки не запустился: $(tail -2 "${CHECK_FILE}")"
fi

# --- 5. Очистка checkout от конфигурации агента -----------------------------

# opencode читает конфигурацию из корня проекта (opencode.json, .opencode/,
# AGENTS.md) — там могут быть плагины, MCP-серверы, инструкции. Всё это
# исполняемый или управляющий код, который студент не должен передавать
# агенту. Файлы удаляются только из рабочей копии ревьюера.
(
  # `cd ... || exit` обязателен: ниже идут rm -rf по относительным путям, и
  # при неудачном переходе они отработали бы в каталоге вызова.
  cd "${STUDENT_DIR}" || exit 1
  rm -rf AGENTS.md CLAUDE.md opencode.json opencode.jsonc .opencode .claude .cursor .env .env.* 2>/dev/null
  find . -path ./.git -prune -o \( -type d \( -name .opencode -o -name .claude \) \) -print0 2>/dev/null \
    | xargs -0 rm -rf 2>/dev/null
  find . -path ./.git -prune -o \( -type f \( -name AGENTS.md -o -name CLAUDE.md -o -name opencode.json -o -name opencode.jsonc \) \) -print0 2>/dev/null \
    | xargs -0 rm -f 2>/dev/null
  true
)
# Полный diff кладём внутрь копии, чтобы агент мог дочитать его инструментом
# read (за пределы рабочего каталога ему выходить запрещено).
mkdir -p "${STUDENT_DIR}/.review"
cp "${DIFF_FILE}" "${STUDENT_DIR}/.review/pr-diff.txt"

# --- 6. Промпт --------------------------------------------------------------

# Промпт передаётся аргументом командной строки, а у Linux есть предел на
# длину одного аргумента (~128 КБ). Уменьшаем долю diff в промпте, пока не
# уложимся с запасом.
PROMPT_FILE="${WORK}/prompt.md"
MAX_PROMPT_BYTES=100000
DIFF_LINES_IN_PROMPT=1200
while :; do
  MAX_DIFF_LINES_IN_PROMPT="${DIFF_LINES_IN_PROMPT}" DIFF_FILE_HINT=".review/pr-diff.txt" \
    bash "${REVIEW_ROOT}/lib/build-prompt.sh" \
      "${TASK_DIR}" "${WORK_DIR}" "${STUDENT}" "${TASK_NUM}" \
      "${DIFF_FILE}" "${CHECK_FILE}" "${CHECK_EXIT}" > "${PROMPT_FILE}" \
    || fail_review "не удалось собрать промпт."
  PROMPT_BYTES="$(wc -c < "${PROMPT_FILE}" | tr -d ' ')"
  if [ "${PROMPT_BYTES}" -le "${MAX_PROMPT_BYTES}" ] || [ "${DIFF_LINES_IN_PROMPT}" -le 100 ]; then
    break
  fi
  DIFF_LINES_IN_PROMPT=$((DIFF_LINES_IN_PROMPT / 2))
done
log "промпт: ${PROMPT_BYTES} байт (diff в промпте: до ${DIFF_LINES_IN_PROMPT} строк)"

# --- 7. Запуск агента --------------------------------------------------------

# Конфигурация агента передаётся inline (OPENCODE_CONFIG_CONTENT) — она имеет
# приоритет над любым opencode.json в проекте. Все разрешения, кроме
# чтения/поиска, запрещены ЯВНО и по именам: "*" перекрывается ключами из
# конфигурации проекта, отдельные ключи — нет.
AGENT_HOME="${WORK}/agent-home"
mkdir -p "${AGENT_HOME}"
AGENT_CONFIG="$(jq -cn --arg model "${MODEL}" '{
  "$schema": "https://opencode.ai/config.json",
  model: $model,
  share: "disabled",
  autoupdate: false,
  snapshot: false,
  plugin: [],
  instructions: [],
  permission: {
    "*": "deny",
    read: "allow",
    glob: "allow",
    grep: "allow",
    list: "allow",
    bash: "deny",
    edit: "deny",
    write: "deny",
    patch: "deny",
    task: "deny",
    skill: "deny",
    lsp: "deny",
    question: "deny",
    webfetch: "deny",
    websearch: "deny",
    todowrite: "deny",
    external_directory: "deny",
    doom_loop: "deny"
  }
}')"

RESULT_FILE="${WORK}/result.md"
AGENT_ERR="${WORK}/agent.err"
log "запуск модели ${MODEL}..."

# Минимальное окружение: PATH, HOME (пустой временный), ключ провайдера и
# флаги opencode. GH_TOKEN и прочее сюда НЕ попадают.
AGENT_ENV=(
  "PATH=${PATH}"
  "HOME=${AGENT_HOME}"
  "TMPDIR=${AGENT_HOME}"
  "LANG=C.UTF-8"
  "OPENCODE_CONFIG_CONTENT=${AGENT_CONFIG}"
  "OPENCODE_DISABLE_CLAUDE_CODE=true"
  "OPENCODE_DISABLE_AUTOUPDATE=true"
  "OPENCODE_DISABLE_DEFAULT_PLUGINS=true"
  "OPENROUTER_API_KEY=${KEY_VALUE}"
)

(
  cd "${STUDENT_DIR}" \
    && timeout 600 env -i "${AGENT_ENV[@]}" \
         opencode run --auto --pure --format default "$(cat "${PROMPT_FILE}")" \
         > "${RESULT_FILE}" 2> "${AGENT_ERR}"
)
AGENT_RC=$?

if [ "${AGENT_RC}" -ne 0 ]; then
  fail_review "opencode завершился с кодом ${AGENT_RC}: $(tail -3 "${AGENT_ERR}" | tr '\n' ' ')"
fi
if [ ! -s "${RESULT_FILE}" ]; then
  fail_review "пустой результат ревью."
fi
# opencode при некорректных флагах печатает справку и выходит с кодом 0.
if grep -qE '^opencode run \[message' "${RESULT_FILE}"; then
  fail_review "opencode напечатал справку вместо ревью — проверьте флаги CLI."
fi
# Защита от утечки: если в ответе оказался ключ модели или токен — не
# публикуем ни при каких обстоятельствах.
if [ -n "${KEY_VALUE}" ] && grep -qF -- "${KEY_VALUE}" "${RESULT_FILE}"; then
  fail_review "в ответе модели обнаружен ключ провайдера — публикация отменена."
fi
if [ -n "${GH_TOKEN:-}" ] && grep -qF -- "${GH_TOKEN}" "${RESULT_FILE}"; then
  fail_review "в ответе модели обнаружен токен GitHub — публикация отменена."
fi

# --- 8. Публикация ------------------------------------------------------------

COMMENT_FILE="${WORK}/review-comment.md"
{
  echo "${MARKER_REVIEW}"
  echo "${MARKER_SHA_PREFIX}${HEAD_SHA} -->"
  render_msg "${MSG_REVIEW_HEADER}"
  echo
  echo
  echo "${MSG_REVIEW_DISCLAIMER}"
  echo
  cat "${RESULT_FILE}"
} > "${COMMENT_FILE}"

if ! gh pr comment "${PR}" --repo "${REPO_FULL}" --body-file "${COMMENT_FILE}" >/dev/null 2>"${WORK}/comment.err"; then
  fail_review "не удалось опубликовать комментарий: $(head -2 "${WORK}/comment.err")"
fi

log "ревью опубликовано ($(wc -c < "${RESULT_FILE}" | tr -d ' ') байт)."
