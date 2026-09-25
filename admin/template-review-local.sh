#!/usr/bin/env bash
# Локальная проверка лабораторной работы — то же, что делает бот в Pull
# Request, но на вашей машине и без ограничений по количеству запусков.
#
# ЗАЧЕМ. Автоматическое ревью в PR запускается ограниченное число раз.
# Этот скрипт позволяет проверить работу сколько угодно раз ДО отправки PR
# и не тратить лимиты на очевидные недоработки.
#
# ИСПОЛЬЗОВАНИЕ
#
#   ./review-local.sh                 проверить текущую работу
#   ./review-local.sh --task 3        явно указать номер лабораторной
#   ./review-local.sh --model M       использовать свою модель
#   ./review-local.sh --prompt-only   только показать промпт, без запроса к модели
#   ./review-local.sh --update        обновить скачанные проверки курса
#   ./review-local.sh --help          справка
#
# КАК ЭТО РАБОТАЕТ
#
#   Сами проверки и промпты живут в публичном репозитории курса и
#   скачиваются в ~/.cache/yapis-review при первом запуске. Поэтому вы
#   всегда проверяетесь ровно тем, чем проверяет преподаватель, и вам не
#   нужно подтягивать обновления инфраструктуры в свой репозиторий.
#
# РЕЖИМЫ РАБОТЫ
#
#   Без ключа API — выполняются структурные проверки (наличие нужных файлов,
#   примеров с префиксом error-, запуск вашего compile.sh) и печатается
#   промпт, который получил бы ИИ-агент. Ключ не нужен, только git.
#
#   С ключом API — дополнительно запускается полноценное ИИ-ревью, как в PR.
#   Нужен opencode (https://opencode.ai/docs/) и ключ провайдера.
#
# ВЫБОР МОДЕЛИ
#
#   По умолчанию берётся модель курса. Локально можно использовать ЛЮБУЮ —
#   свою платную, бесплатную или локальную:
#
#       export ANTHROPIC_API_KEY=...
#       ./review-local.sh --model anthropic/claude-sonnet-4
#
#       # то же через переменную окружения (удобно занести в ~/.zshrc)
#       export REVIEW_MODEL=deepseek/deepseek-chat
#       export DEEPSEEK_API_KEY=...
#       ./review-local.sh
#
#       # локальная модель через Ollama — вообще без ключей и без интернета
#       ollama pull qwen2.5-coder
#       ./review-local.sh --model ollama/qwen2.5-coder
#
#   Выбор модели влияет только на ваш локальный запуск. В Pull Request
#   всегда используется модель курса.
#
# Скрипт ничего не отправляет на GitHub и не изменяет ваши файлы.
#
# ВНИМАНИЕ: структурная проверка ЗАПУСКАЕТ ваш compile.sh прямо на этой
# машине (в PR он выполняется в изолированном контейнере). Это ваш
# собственный код, но помните об этом, если копируете чужие примеры.

set -uo pipefail

# Репозиторий курса, откуда берутся проверки и промпты.
COURSE_REPO="${YAPIS_COURSE_REPO:-https://github.com/rserdyukov/yapis-2026.git}"
CACHE_DIR="${YAPIS_CACHE_DIR:-${HOME}/.cache/yapis-review}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"

WORK_DIR="."
TASK_NUM=""
PROMPT_ONLY=0
UPDATE_ONLY=0
MODEL_OVERRIDE=""

usage() {
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
}

while [ $# -gt 0 ]; do
  case "${1}" in
    --task)        TASK_NUM="${2:?Укажите номер работы, например --task 3}"; shift 2 ;;
    --dir)         WORK_DIR="${2:?Укажите директорию, например --dir .}"; shift 2 ;;
    --model)       MODEL_OVERRIDE="${2:?Укажите модель, например --model anthropic/claude-sonnet-4}"; shift 2 ;;
    --prompt-only) PROMPT_ONLY=1; shift ;;
    --update)      UPDATE_ONLY=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *)             echo "Неизвестный аргумент: ${1}" >&2; usage; exit 1 ;;
  esac
done

# --- Цветной вывод, если терминал поддерживает ---------------------------
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_BOLD=$'\033[1m'; C_OFF=$'\033[0m'
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_BOLD=""; C_OFF=""
fi

say()  { echo "${C_BOLD}$*${C_OFF}"; }
ok()   { echo "  ${C_GREEN}✓${C_OFF} $*"; }
warn() { echo "  ${C_YELLOW}!${C_OFF} $*"; }
err()  { echo "  ${C_RED}✗${C_OFF} $*"; }

# --- Проверка окружения ---------------------------------------------------
MISSING=""
command -v git >/dev/null 2>&1 || MISSING="${MISSING} git"
if [ -n "${MISSING}" ]; then
  err "Не установлены:${MISSING}"
  echo "     macOS:  brew install${MISSING}"
  echo "     Ubuntu: sudo apt install${MISSING}"
  exit 1
fi

# --- Загрузка/обновление проверок курса -----------------------------------
sync_course() {
  if [ -d "${CACHE_DIR}/.git" ]; then
    git -C "${CACHE_DIR}" fetch -q --depth 1 origin HEAD 2>/dev/null \
      && git -C "${CACHE_DIR}" reset -q --hard FETCH_HEAD 2>/dev/null
    return $?
  fi
  mkdir -p "$(dirname "${CACHE_DIR}")"
  git clone -q --depth 1 "${COURSE_REPO}" "${CACHE_DIR}" 2>/dev/null
}

if [ "${UPDATE_ONLY}" -eq 1 ]; then
  say "Обновляю проверки курса из ${COURSE_REPO}"
  if sync_course; then ok "Готово: ${CACHE_DIR}"; else err "Не удалось обновить."; exit 1; fi
  exit 0
fi

if [ ! -d "${CACHE_DIR}/.github/review" ]; then
  say "Первый запуск: скачиваю проверки курса в ${CACHE_DIR}"
  if ! sync_course; then
    err "Не удалось скачать ${COURSE_REPO}."
    echo "     Проверьте доступ в интернет. Проверки можно получить и вручную:"
    echo "       git clone --depth 1 ${COURSE_REPO} ${CACHE_DIR}"
    exit 1
  fi
  echo
else
  # Тихое обновление раз в сутки, чтобы студент не проверялся устаревшими
  # правилами. Неудача не фатальна — работаем тем, что уже скачано.
  STAMP="${CACHE_DIR}/.last-sync"
  if [ ! -f "${STAMP}" ] || [ -n "$(find "${STAMP}" -mtime +1 2>/dev/null)" ]; then
    sync_course >/dev/null 2>&1 && touch "${STAMP}" 2>/dev/null || true
  fi
fi

REVIEW_ROOT="${CACHE_DIR}/.github/review"
REVIEWER_LIB="${CACHE_DIR}/reviewer/lib"

if [ ! -f "${REVIEW_ROOT}/lib/build-prompt.sh" ]; then
  err "В ${CACHE_DIR} нет ожидаемых файлов проверок."
  echo "     Попробуйте: rm -rf ${CACHE_DIR} && $0 --update"
  exit 1
fi

cd "${REPO_ROOT}" || { err "Не удалось перейти в ${REPO_ROOT}"; exit 1; }

# --- Определение номера лабораторной работы -------------------------------
if [ -z "${TASK_NUM}" ]; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  TASK_NUM="$(printf '%s' "${BRANCH}" | grep -oE 'task[0-9]+' | grep -oE '[0-9]+' | head -1 || true)"
  if [ -n "${TASK_NUM}" ]; then
    say "Лабораторная работа №${TASK_NUM} (определена по имени ветки '${BRANCH}')"
  else
    warn "Не удалось определить номер работы по имени ветки '${BRANCH}'."
    echo "     Бот тоже не сможет — назовите ветку 'task<номер>', например task3,"
    echo "     либо укажите вручную: $0 --task 3"
    TASK_NUM="0"
  fi
else
  say "Лабораторная работа №${TASK_NUM} (указана вручную)"
fi

TASK_DIR="task${TASK_NUM}"
[ -d "${REVIEW_ROOT}/tasks/${TASK_DIR}" ] || TASK_DIR="default"
echo "Набор проверок: ${TASK_DIR}"
echo "Проверяемая директория: ${WORK_DIR}"
echo

# --- Подготовка diff ------------------------------------------------------
DIFF_FILE="$(mktemp)"
PROMPT_FILE="$(mktemp)"
CHECK_FILE="$(mktemp)"
trap 'rm -f "${DIFF_FILE}" "${PROMPT_FILE}" "${CHECK_FILE}"' EXIT

# shellcheck source=/dev/null
source "${REVIEW_ROOT}/config.env"
# shellcheck source=/dev/null
source "${REVIEW_ROOT}/lib/generated-files.sh"

BASE_REF=""
for candidate in "origin/main" "main" "origin/master" "master"; do
  if git rev-parse --verify --quiet "${candidate}" >/dev/null 2>&1; then
    BASE_REF="${candidate}"; break
  fi
done

GENERATED_FILE="$(mktemp)"
NUMSTAT_FILE="$(mktemp)"
trap 'rm -f "${DIFF_FILE}" "${PROMPT_FILE}" "${CHECK_FILE}" "${GENERATED_FILE}" "${NUMSTAT_FILE}"' EXIT

OVERSIZE=0
if [ -n "${BASE_REF}" ] && [ "$(git rev-parse HEAD)" != "$(git rev-parse "${BASE_REF}")" ]; then
  MERGE_BASE="$(git merge-base "${BASE_REF}" HEAD 2>/dev/null || echo "${BASE_REF}")"
  # Тот же diff, что увидит бот: --numstat вместо --stat (гистограммы «++++»
  # провоцируют модели на зацикливание), сгенерированные файлы ANTLR и
  # артефакты сборки исключены и перечислены отдельно.
  git diff --numstat "${MERGE_BASE}" HEAD -- "${WORK_DIR}" > "${NUMSTAT_FILE}" 2>/dev/null
  generated_paths_from_numstat < "${NUMSTAT_FILE}" > "${GENERATED_FILE}"
  build_review_diff "${REPO_ROOT}" "${MERGE_BASE}" HEAD "${WORK_DIR}" "${NUMSTAT_FILE}" "${DIFF_FILE}"

  CHANGED="$(filter_generated_numstat < "${NUMSTAT_FILE}" | sum_numstat_lines)"
  GENERATED_COUNT="$(wc -l < "${GENERATED_FILE}" | tr -d ' ')"

  echo "Изменено строк относительно ${BASE_REF}: ${CHANGED} (лимит полного ревью в PR: ${MAX_DIFF_LINES})"
  if [ "${GENERATED_COUNT}" -gt 0 ]; then
    warn "В изменениях ${GENERATED_COUNT} сгенерированных файлов (вывод ANTLR, артефакты сборки) — они не считаются"
    echo "     в лимите и не показываются модели, но бот отметит их коммит как замечание:"
    sed 's/^/       /' "${GENERATED_FILE}" | head -n 10
  fi
  if [ "${CHANGED}" -gt "${MAX_DIFF_LINES}" ]; then
    OVERSIZE=1
    warn "Изменений больше лимита: в PR бот проведёт СОКРАЩЁННОЕ ревью — запустит compile.sh"
    echo "     и проверит структуру, но анализ кода оставит преподавателю. Локально режим тот же."
  fi
  echo
else
  warn "Не с чем сравнить (нет ветки main или вы на ней) — diff в промпт не попадёт."
  echo "     В реальном PR diff будет, поэтому ревью может отличаться."
  echo
fi

# --- Структурные проверки -------------------------------------------------
say "1. Структурные проверки"
echo

# Локально проверки запускаются напрямую: это ваш собственный код на вашей
# машине. В PR тот же check.sh выполняется в контейнере без сети.
CHECK_RUNNER=direct REVIEW_ROOT="${REVIEW_ROOT}" \
  bash "${REVIEWER_LIB}/run-check.sh" "${TASK_DIR}" "${REPO_ROOT}" "${WORK_DIR}" "${CHECK_FILE}"
CHECK_EXIT=$?

sed 's/^/  /' "${CHECK_FILE}"
echo
if [ "${CHECK_EXIT}" -eq 0 ]; then
  ok "Структурные проверки пройдены."
else
  warn "Структурные проверки нашли замечания (код ${CHECK_EXIT}) — см. выше."
fi
echo

# --- Сборка промпта -------------------------------------------------------
STUDENT="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo student)")"

if ! GENERATED_FILES_LIST="${GENERATED_FILE}" OVERSIZE_MODE="${OVERSIZE}" DIFF_FILE_HINT=".review/pr-diff.txt" \
     MAX_DIFF_LINES_IN_PROMPT="$([ "${OVERSIZE}" -eq 1 ] && echo 0 || echo "${MAX_DIFF_LINES_IN_PROMPT:-6000}")" \
     bash "${REVIEW_ROOT}/lib/build-prompt.sh" \
      "${TASK_DIR}" "${WORK_DIR}" "${STUDENT}" "${TASK_NUM}" \
      "${DIFF_FILE}" "${CHECK_FILE}" "${CHECK_EXIT}" \
      > "${PROMPT_FILE}" 2>/tmp/build-prompt.err; then
  err "Не удалось собрать промпт:"
  sed 's/^/     /' /tmp/build-prompt.err
  exit 1
fi

if [ "${PROMPT_ONLY}" -eq 1 ]; then
  say "Промпт, который получил бы ИИ-агент:"
  echo
  cat "${PROMPT_FILE}"
  exit 0
fi

# --- Запуск ИИ-ревью ------------------------------------------------------
say "2. ИИ-ревью"
echo

if [ -n "${MODEL_OVERRIDE}" ]; then
  MODEL="${MODEL_OVERRIDE}"
elif [ -n "${REVIEW_MODEL:-}" ]; then
  MODEL="${REVIEW_MODEL}"
fi

# Провайдер — первая часть имени модели: openrouter/nvidia/... -> openrouter.
PROVIDER="${MODEL%%/*}"

# Имя переменной с ключом. Общее правило opencode: <ПРОВАЙДЕР>_API_KEY.
# Исключения перечислены явно; локальные провайдеры ключа не требуют.
# Полный список: https://models.dev
case "${PROVIDER}" in
  ollama|lmstudio|llama.cpp) REQUIRED_KEY="" ;;
  google)                    REQUIRED_KEY="GEMINI_API_KEY" ;;
  *)                         REQUIRED_KEY="$(printf '%s' "${PROVIDER}" \
                                | tr '[:lower:]-' '[:upper:]_')_API_KEY" ;;
esac

if ! command -v opencode >/dev/null 2>&1; then
  warn "opencode не установлен — ИИ-ревью пропущено."
  echo "     Структурные проверки выше уже показали основные недочёты."
  echo "     Чтобы запускать полноценное ревью локально:"
  echo "       curl -fsSL https://opencode.ai/install | bash"
  echo "     Посмотреть промпт целиком: $0 --prompt-only"
  exit 0
fi

if [ -n "${REQUIRED_KEY}" ] && [ -z "${!REQUIRED_KEY:-}" ]; then
  warn "Не задан ${REQUIRED_KEY} — ИИ-ревью пропущено."
  echo "     Структурные проверки выше уже показали основные недочёты."
  echo
  echo "     Чтобы запускать полноценное ревью локально:"
  echo "       export ${REQUIRED_KEY}=<ваш ключ>"
  if [ "${PROVIDER}" = "openrouter" ]; then
    echo "       Ключ: https://openrouter.ai/keys"
  else
    echo "       Где взять ключ: https://models.dev (раздел ${PROVIDER})"
  fi
  echo
  echo "     Можно использовать любую другую модель — свою или локальную:"
  echo "       REVIEW_MODEL=anthropic/claude-sonnet-4 $0"
  echo "       REVIEW_MODEL=ollama/qwen2.5-coder $0        # локально, без ключа"
  echo "     Список моделей: https://models.dev"
  exit 0
fi

echo "Модель: ${MODEL}"
echo "Запуск... (обычно 2-6 минут: модель читает файлы работы инструментами)"
echo

SANDBOX="$(mktemp -d)"
trap 'rm -f "${DIFF_FILE}" "${PROMPT_FILE}" "${CHECK_FILE}" "${GENERATED_FILE}" "${NUMSTAT_FILE}"; rm -rf "${SANDBOX}"' EXIT

# Полный diff кладём в рабочую копию, как делает бот: промпт ссылается на
# него как на .review/pr-diff.txt, который агент может дочитать.
mkdir -p "${REPO_ROOT}/.review"
cp "${DIFF_FILE}" "${REPO_ROOT}/.review/pr-diff.txt"
trap 'rm -f "${DIFF_FILE}" "${PROMPT_FILE}" "${CHECK_FILE}" "${GENERATED_FILE}" "${NUMSTAT_FILE}"; rm -rf "${SANDBOX}" "${REPO_ROOT}/.review"' EXIT

# Агент работает в режиме только для чтения — как и в PR.
AGENT_CONFIG="$(cat <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "${MODEL}",
  "small_model": "${MODEL}",
  "share": "disabled",
  "permission": {
    "*": "deny",
    "read": "allow",
    "glob": "allow",
    "grep": "allow",
    "list": "allow",
    "bash": "deny",
    "edit": "deny",
    "write": "deny"
  }
}
EOF
)"

# Промпт — через stdin, как в боте: аргумент командной строки ограничен
# ~128 КБ, а промпт с большим diff может быть длиннее.
RESULT_FILE="${SANDBOX}/result.md"
if ! (cd "${REPO_ROOT}" && OPENCODE_CONFIG_CONTENT="${AGENT_CONFIG}" \
        OPENCODE_DISABLE_CLAUDE_CODE=true \
        opencode run --auto --format default \
        < "${PROMPT_FILE}" > "${RESULT_FILE}" 2>"${SANDBOX}/err.log"); then
  err "ИИ-ревью не удалось выполнить:"
  tail -5 "${SANDBOX}/err.log" | sed 's/^/     /'
  exit 1
fi

if [ ! -s "${RESULT_FILE}" ]; then
  err "Пустой ответ модели. Попробуйте ещё раз или смените модель через --model."
  exit 1
fi

echo "────────────────────────────────────────────────────────────"
cat "${RESULT_FILE}"
echo "────────────────────────────────────────────────────────────"
echo
say "Это предварительная проверка. Итоговое решение принимает преподаватель."
echo "Замечания могут быть неточными — оценивайте их критически."
