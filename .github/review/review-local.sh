#!/usr/bin/env bash
# Локальный запуск проверки лабораторной работы — то же самое, что делает бот
# в Pull Request, но на вашей машине и без ограничений по количеству запусков.
#
# ЗАЧЕМ. Автоматическое ревью в PR запускается ограниченное число раз
# (см. .github/review/config.env). Этот скрипт позволяет проверить работу
# сколько угодно раз ДО отправки PR и не тратить лимиты на очевидные
# недоработки.
#
# ИСПОЛЬЗОВАНИЕ
#
#   ./.github/review/review-local.sh                 проверить текущую работу
#   ./.github/review/review-local.sh --task 3        явно указать номер лабы
#   ./.github/review/review-local.sh --dir path/     проверить другую папку
#   ./.github/review/review-local.sh --model M       использовать свою модель
#   ./.github/review/review-local.sh --prompt-only   только показать промпт
#   ./.github/review/review-local.sh --help          справка
#
# РЕЖИМЫ РАБОТЫ
#
#   Без ключа API — выполняются структурные проверки (наличие нужных файлов,
#   примеров с префиксом error-, запуск build.sh/run.sh) и печатается промпт,
#   который получил бы ИИ-агент. Ключ не нужен, интернет не нужен.
#
#   С ключом API — дополнительно запускается полноценное ИИ-ревью, как в PR.
#   Нужен opencode (https://opencode.ai/docs/) и ключ провайдера.
#
# ВЫБОР МОДЕЛИ
#
#   По умолчанию берётся модель курса из config.env. Локально можно
#   использовать ЛЮБУЮ модель — свою платную, бесплатную или локальную:
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
#   Имя переменной с ключом определяется автоматически по имени провайдера
#   (openrouter -> OPENROUTER_API_KEY и т.д.). Полный список моделей:
#   https://models.dev, настройка провайдеров: https://opencode.ai/docs/providers
#
#   Выбор модели влияет только на ваш локальный запуск. В Pull Request
#   всегда используется модель курса, заданная преподавателем.
#
# Скрипт ничего не отправляет на GitHub и не изменяет ваши файлы.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

WORK_DIR="."
TASK_NUM=""
PROMPT_ONLY=0
MODEL_OVERRIDE=""

usage() {
  # Печатаем шапку целиком до первой строки кода. Жёсткий диапазон строк
  # использовать нельзя: он молча обрезает справку при правке комментариев.
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
}

while [ $# -gt 0 ]; do
  case "${1}" in
    --task)        TASK_NUM="${2:?Укажите номер работы, например --task 3}"; shift 2 ;;
    --dir)         WORK_DIR="${2:?Укажите директорию, например --dir .}"; shift 2 ;;
    --model)       MODEL_OVERRIDE="${2:?Укажите модель, например --model anthropic/claude-sonnet-4}"; shift 2 ;;
    --prompt-only) PROMPT_ONLY=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *)             echo "Неизвестный аргумент: ${1}" >&2; usage; exit 1 ;;
  esac
done

cd "${REPO_ROOT}"

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
command -v jq  >/dev/null 2>&1 || MISSING="${MISSING} jq"
command -v git >/dev/null 2>&1 || MISSING="${MISSING} git"
if [ -n "${MISSING}" ]; then
  err "Не установлены:${MISSING}"
  echo "     macOS:  brew install${MISSING}"
  echo "     Ubuntu: sudo apt install${MISSING}"
  exit 1
fi

# --- Определение номера лабораторной работы -------------------------------
# Если номер не задан явно, берём его из имени текущей ветки (task<N>) —
# ровно так же, как это делает бот в PR.
if [ -z "${TASK_NUM}" ]; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  TASK_NUM="$(printf '%s' "${BRANCH}" | grep -oE 'task[0-9]+' | grep -oE '[0-9]+' | head -1 || true)"
  if [ -n "${TASK_NUM}" ]; then
    say "Лабораторная работа №${TASK_NUM} (определена по имени ветки '${BRANCH}')"
  else
    warn "Не удалось определить номер работы по имени ветки '${BRANCH}'."
    echo "     Бот в PR тоже не сможет — назовите ветку 'task<номер>', например task3,"
    echo "     либо укажите вручную: $0 --task 3"
    TASK_NUM="0"
  fi
else
  say "Лабораторная работа №${TASK_NUM} (указана вручную)"
fi

TASK_DIR="task${TASK_NUM}"
[ -d "${SCRIPT_DIR}/tasks/${TASK_DIR}" ] || TASK_DIR="default"
echo "Набор проверок: ${TASK_DIR}"
echo "Проверяемая директория: ${WORK_DIR}"
echo

# --- Подготовка diff ------------------------------------------------------
# Бот анализирует изменения относительно main. Локально пытаемся сделать так
# же; если сравнить не с чем (нет main или это сам main) — не страшно,
# структурные проверки и чтение файлов работают в любом случае.
DIFF_FILE="$(mktemp)"
trap 'rm -f "${DIFF_FILE}"' EXIT

BASE_REF=""
for candidate in "origin/main" "main" "origin/master" "master"; do
  if git rev-parse --verify --quiet "${candidate}" >/dev/null 2>&1; then
    BASE_REF="${candidate}"; break
  fi
done

if [ -n "${BASE_REF}" ] && [ "$(git rev-parse HEAD)" != "$(git rev-parse "${BASE_REF}")" ]; then
  {
    echo "### Список изменённых файлов"
    echo
    git diff --stat "${BASE_REF}...HEAD" -- "${WORK_DIR}" 2>/dev/null
    echo
    echo "### Полный diff"
    echo
    git diff "${BASE_REF}...HEAD" -- "${WORK_DIR}" 2>/dev/null
  } > "${DIFF_FILE}"

  CHANGED="$(git diff --numstat "${BASE_REF}...HEAD" -- "${WORK_DIR}" 2>/dev/null \
    | awk '{ if ($1 != "-") a+=$1; if ($2 != "-") d+=$2 } END { print a+d+0 }')"

  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/config.env"
  echo "Изменено строк относительно ${BASE_REF}: ${CHANGED} (лимит в PR: ${MAX_DIFF_LINES})"
  if [ "${CHANGED}" -gt "${MAX_DIFF_LINES}" ]; then
    warn "Такой PR бот пропустит: изменений больше лимита — ревью будет делать преподаватель."
  fi
  echo
else
  warn "Не с чем сравнить (нет ветки main или вы на ней) — diff в промпт не попадёт."
  echo "     В реальном PR diff будет, поэтому ревью может отличаться."
  echo
fi

# --- Сборка промпта -------------------------------------------------------
say "1. Структурные проверки и сборка промпта"
echo

PROMPT_FILE="$(mktemp)"
trap 'rm -f "${DIFF_FILE}" "${PROMPT_FILE}"' EXIT

STUDENT="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo student)")"

if ! bash "${SCRIPT_DIR}/lib/build-prompt.sh" \
      "${TASK_DIR}" "${WORK_DIR}" "${STUDENT}" "${TASK_NUM}" "${DIFF_FILE}" \
      > "${PROMPT_FILE}" 2>/tmp/build-prompt.err; then
  err "Не удалось собрать промпт:"
  sed 's/^/     /' /tmp/build-prompt.err
  exit 1
fi

# Показываем студенту результат структурных проверок — самая полезная часть.
sed -n '/## Результаты автоматических проверок/,/^## /p' "${PROMPT_FILE}" \
  | sed '$d' | sed 's/^/  /'

if [ "${PROMPT_ONLY}" -eq 1 ]; then
  echo
  say "Промпт, который получил бы ИИ-агент:"
  echo
  cat "${PROMPT_FILE}"
  exit 0
fi

# --- Запуск ИИ-ревью ------------------------------------------------------
echo
say "2. ИИ-ревью"
echo

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/config.env"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/provider.sh"

# Студент может использовать ЛЮБУЮ модель, а не только ту, что настроена
# для курса: достаточно задать REVIEW_MODEL или указать --model.
# Это его локальный запуск и его ключ — на проверку в PR не влияет.
if [ -n "${MODEL_OVERRIDE}" ]; then
  MODEL="${MODEL_OVERRIDE}"
  MODEL_SOURCE="аргумент --model"
elif [ -n "${REVIEW_MODEL:-}" ]; then
  MODEL="${REVIEW_MODEL}"
  MODEL_SOURCE="переменная REVIEW_MODEL"
else
  MODEL_SOURCE="config.env (модель курса)"
fi

PROVIDER="$(provider_for "${MODEL}")"
REQUIRED_KEY="$(key_var_for "${PROVIDER}")"

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
  echo "       Ключ: $(key_url_for "${PROVIDER}")"
  echo
  echo "     Можно использовать любую другую модель — свою или локальную:"
  echo "       REVIEW_MODEL=anthropic/claude-sonnet-4 $0"
  echo "       REVIEW_MODEL=ollama/qwen2.5-coder $0        # локально, без ключа"
  echo "     Список моделей: https://models.dev"
  exit 0
fi

echo "Модель: ${MODEL}"
echo "Запуск... (обычно 1-2 минуты)"
echo

# Агент работает в режиме только для чтения — как и в PR.
SANDBOX="$(mktemp -d)"
trap 'rm -f "${DIFF_FILE}" "${PROMPT_FILE}"; rm -rf "${SANDBOX}"' EXIT

cat > "${SANDBOX}/opencode.json" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "${MODEL}",
  "share": "disabled",
  "permission": {
    "*": "deny",
    "read": "allow",
    "glob": "allow",
    "grep": "allow"
  }
}
EOF

RESULT_FILE="${SANDBOX}/result.md"
if ! (cd "${REPO_ROOT}" && OPENCODE_CONFIG="${SANDBOX}/opencode.json" \
        OPENCODE_DISABLE_CLAUDE_CODE=true \
        opencode run --auto --format default "$(cat "${PROMPT_FILE}")" \
        > "${RESULT_FILE}" 2>"${SANDBOX}/err.log"); then
  err "ИИ-ревью не удалось выполнить:"
  tail -5 "${SANDBOX}/err.log" | sed 's/^/     /'
  exit 1
fi

if [ ! -s "${RESULT_FILE}" ]; then
  err "Пустой ответ модели. Попробуйте ещё раз или смените модель в config.env."
  exit 1
fi

echo "────────────────────────────────────────────────────────────"
cat "${RESULT_FILE}"
echo "────────────────────────────────────────────────────────────"
echo
say "Это предварительная проверка. Итоговое решение принимает преподаватель."
echo "Замечания могут быть неточными — оценивайте их критически."
