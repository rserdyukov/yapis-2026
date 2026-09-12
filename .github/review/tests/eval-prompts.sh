#!/usr/bin/env bash
# Стенд отладки промптов: прогоняет ИИ-ревью на наборе эталонных работ и
# проверяет, что бот нашёл то, что должен, и не сказал того, чего нельзя.
#
# ЗАЧЕМ. Правка промпта в tasks/*/prompt.md или common-footer.md может
# незаметно ухудшить ревью: бот перестанет замечать нарушения, начнёт
# выдавать вердикт или поддастся prompt injection. Этот скрипт делает
# такой регресс видимым.
#
# ИСПОЛЬЗОВАНИЕ
#   ./.github/review/tests/eval-prompts.sh                 все фикстуры
#   ./.github/review/tests/eval-prompts.sh broken-task3    одна фикстура
#   ./.github/review/tests/eval-prompts.sh --list          список фикстур
#   ./.github/review/tests/eval-prompts.sh --dry-run       без вызова модели
#   ./.github/review/tests/eval-prompts.sh --keep          сохранить ответы
#   ./.github/review/tests/eval-prompts.sh --repeat 3      N прогонов подряд
#
# ТРЕБУЕТСЯ
#   - opencode (https://opencode.ai/docs/)
#   - ключ провайдера из config.env, например OPENROUTER_API_KEY
#
# ВНИМАНИЕ: каждый прогон расходует квоту API. Полный набор — по одному
# запросу на фикстуру. Для проверки самой сборки промпта без обращения
# к модели используйте --dry-run (бесплатно).
#
# КАК ДОБАВИТЬ СВОЮ ФИКСТУРУ
#   1. mkdir -p tests/fixtures/<имя>/work
#   2. Положите в work/ файлы работы (README.md, examples/, compiler/ ...).
#   3. Создайте tests/fixtures/<имя>/expect.env — см. примеры рядом.
#   4. Запустите: ./eval-prompts.sh <имя>
#
# Ответы модели недетерминированы. Один провал не всегда означает регресс —
# используйте --repeat, чтобы отличить случайность от систематики.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_DIR="$(cd "${TESTS_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${REVIEW_DIR}/../.." && pwd)"
FIXTURES_DIR="${TESTS_DIR}/fixtures"

DRY_RUN=0
KEEP=0
REPEAT=1
ONLY=""

while [ $# -gt 0 ]; do
  case "${1}" in
    --list)
      echo "Доступные фикстуры:"
      for d in "${FIXTURES_DIR}"/*/; do
        [ -f "${d}/expect.env" ] || continue
        # shellcheck source=/dev/null
        ( source "${d}/expect.env"; printf '  %-20s %s\n' "$(basename "${d}")" "${DESCRIPTION:-}" )
      done
      exit 0 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --keep)    KEEP=1; shift ;;
    --repeat)  REPEAT="${2:?Укажите число повторов}"; shift 2 ;;
    -h|--help) sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        echo "Неизвестный аргумент: ${1}" >&2; exit 1 ;;
    *)         ONLY="${1}"; shift ;;
  esac
done

if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'; C_OFF=$'\033[0m'
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_DIM=""; C_BOLD=""; C_OFF=""
fi

OUT_DIR="${TESTS_DIR}/results"
mkdir -p "${OUT_DIR}"

TMP_ROOT="$(mktemp -d)"
cleanup() { [ "${KEEP}" -eq 1 ] || rm -rf "${TMP_ROOT}"; }
trap cleanup EXIT

# shellcheck source=/dev/null
source "${REVIEW_DIR}/config.env"

# Курс работает с одним провайдером — OpenRouter (см. MODEL в config.env),
# поэтому ключ ровно один. Для локальных экспериментов модель можно
# переопределить переменной REVIEW_MODEL: тогда имя ключа выводится по
# общему правилу opencode (<ПРОВАЙДЕР>_API_KEY).
MODEL="${REVIEW_MODEL:-${MODEL}}"
PROVIDER="${MODEL%%/*}"
case "${PROVIDER}" in
  ollama|lmstudio|llama.cpp) REQUIRED_KEY="" ;;
  google)                    REQUIRED_KEY="GEMINI_API_KEY" ;;
  *)                         REQUIRED_KEY="$(printf '%s' "${PROVIDER}" \
                               | tr '[:lower:]-' '[:upper:]_')_API_KEY" ;;
esac

if [ "${DRY_RUN}" -eq 0 ]; then
  if ! command -v opencode >/dev/null 2>&1; then
    echo "${C_RED}opencode не установлен.${C_OFF}" >&2
    echo "  curl -fsSL https://opencode.ai/install | bash" >&2
    echo "  либо запустите с --dry-run (только сборка промпта)" >&2
    exit 1
  fi
  if [ -n "${REQUIRED_KEY}" ] && [ -z "${!REQUIRED_KEY:-}" ]; then
    echo "${C_RED}Не задан ${REQUIRED_KEY} для модели ${MODEL}.${C_OFF}" >&2
    echo "  export ${REQUIRED_KEY}=<ключ>" >&2
    echo "  либо запустите с --dry-run" >&2
    exit 1
  fi
fi

echo "${C_BOLD}Отладка промптов${C_OFF}"
echo "Модель: ${MODEL}"
[ "${DRY_RUN}" -eq 1 ] && echo "${C_YELLOW}Режим --dry-run: модель не вызывается${C_OFF}"
[ "${REPEAT}" -gt 1 ] && echo "Повторов на фикстуру: ${REPEAT}"
echo

TOTAL=0; OK=0; BAD=0
REPORT=""

# grep_any <текст> <шаблон1|шаблон2> — есть ли хоть одно совпадение
grep_any() {
  printf '%s' "${1}" | grep -qiE "${2}"
}

run_fixture() {
  local fx="${1}" attempt="${2}"
  local dir="${FIXTURES_DIR}/${fx}"
  local work="${dir}/work"

  # shellcheck source=/dev/null
  source "${dir}/expect.env"

  local task_dir="task${TASK_NUM}"
  [ -d "${REVIEW_DIR}/tasks/${task_dir}" ] || task_dir="default"

  # Diff подставляем синтетический: фикстура не в git, а промпт ожидает diff.
  local diff_file="${TMP_ROOT}/${fx}.diff"
  {
    echo "### Список изменённых файлов"
    echo
    ( cd "${work}" && find . -type f | sed 's/^\.\///' | sed 's/^/ + /' )
    echo
    echo "### Полный diff"
    echo
    ( cd "${work}" && for f in $(find . -type f | sort); do
        echo "diff --git a/${f#./} b/${f#./}"
        echo "+++ b/${f#./}"
        sed 's/^/+/' "${f}"
      done )
  } > "${diff_file}"

  local prompt_file="${TMP_ROOT}/${fx}.prompt.md"
  if ! ( cd "${REPO_ROOT}" && bash "${REVIEW_DIR}/lib/build-prompt.sh" \
           "${task_dir}" "${work}" "${fx}" "${TASK_NUM}" "${diff_file}" \
           > "${prompt_file}" 2>"${TMP_ROOT}/${fx}.err" ); then
    echo "  ${C_RED}✗ промпт не собрался${C_OFF}"
    sed 's/^/      /' "${TMP_ROOT}/${fx}.err"
    return 1
  fi

  local psize; psize="$(wc -c < "${prompt_file}" | tr -d ' ')"
  echo "  ${C_DIM}промпт: ${psize} байт${C_OFF}"

  if [ "${DRY_RUN}" -eq 1 ]; then
    # Проверяем только то, что можно без модели.
    local prompt_text; prompt_text="$(cat "${prompt_file}")"
    local issues=""
    grep -q '{{' "${prompt_file}" && issues="${issues} нераскрытые-плейсхолдеры"
    grep_any "${prompt_text}" "Границы доверия" || issues="${issues} нет-защиты-от-инъекций"
    grep_any "${prompt_text}" "BEGIN_UNTRUSTED_DIFF" || issues="${issues} diff-не-помечен"
    if [ -z "${issues}" ]; then
      echo "  ${C_GREEN}✓ промпт корректен${C_OFF}"; return 0
    fi
    echo "  ${C_RED}✗ проблемы промпта:${issues}${C_OFF}"; return 1
  fi

  # --- Запуск модели в песочнице (агент только читает) ---
  local sandbox="${TMP_ROOT}/sandbox-${fx}-${attempt}"
  mkdir -p "${sandbox}"
  cat > "${sandbox}/opencode.json" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "${MODEL}",
  "share": "disabled",
  "permission": { "*": "deny", "read": "allow", "glob": "allow", "grep": "allow" }
}
EOF

  local result="${OUT_DIR}/${fx}$([ "${REPEAT}" -gt 1 ] && echo "-${attempt}").md"
  if ! ( cd "${work}" && OPENCODE_CONFIG="${sandbox}/opencode.json" \
           OPENCODE_DISABLE_CLAUDE_CODE=true \
           opencode run --auto --format default "$(cat "${prompt_file}")" \
           > "${result}" 2>"${sandbox}/err.log" ); then
    echo "  ${C_RED}✗ ошибка вызова модели${C_OFF}"
    tail -3 "${sandbox}/err.log" | sed 's/^/      /'
    return 1
  fi

  if [ ! -s "${result}" ]; then
    echo "  ${C_RED}✗ пустой ответ модели${C_OFF}"; return 1
  fi

  # --- Проверка ожиданий ---
  local text; text="$(cat "${result}")"
  local len; len="$(printf '%s' "${text}" | wc -c | tr -d ' ')"
  local problems=""

  if [ -n "${EXPECT_PRESENT:-}" ]; then
    grep_any "${text}" "${EXPECT_PRESENT}" \
      || problems="${problems}    - не упомянуто обязательное: ${EXPECT_PRESENT}"$'\n'
  fi

  if [ -n "${EXPECT_ANY_OF:-}" ]; then
    grep_any "${text}" "${EXPECT_ANY_OF}" \
      || problems="${problems}    - не найдено ни одного из: ${EXPECT_ANY_OF}"$'\n'
  fi

  if [ -n "${EXPECT_ABSENT:-}" ]; then
    local hit
    hit="$(printf '%s' "${text}" | grep -ioE "${EXPECT_ABSENT}" | head -1 || true)"
    [ -z "${hit}" ] \
      || problems="${problems}    - присутствует запрещённое: «${hit}»"$'\n'
  fi

  if [ -n "${MAX_LENGTH_CHARS:-}" ] && [ "${len}" -gt "${MAX_LENGTH_CHARS}" ]; then
    problems="${problems}    - ответ слишком длинный: ${len} > ${MAX_LENGTH_CHARS}"$'\n'
  fi

  echo "  ${C_DIM}ответ: ${len} байт -> ${result}${C_OFF}"

  if [ -z "${problems}" ]; then
    echo "  ${C_GREEN}✓ ожидания выполнены${C_OFF}"
    return 0
  fi
  echo "  ${C_RED}✗ ожидания нарушены:${C_OFF}"
  printf '%s' "${problems}"
  return 1
}

for dir in "${FIXTURES_DIR}"/*/; do
  fx="$(basename "${dir}")"
  [ -f "${dir}/expect.env" ] || continue
  [ -n "${ONLY}" ] && [ "${ONLY}" != "${fx}" ] && continue

  # shellcheck source=/dev/null
  ( source "${dir}/expect.env"; echo "${C_BOLD}${fx}${C_OFF} — ${DESCRIPTION:-}" )

  attempt=1
  fx_ok=0; fx_bad=0
  while [ "${attempt}" -le "${REPEAT}" ]; do
    [ "${REPEAT}" -gt 1 ] && echo "  ${C_DIM}прогон ${attempt}/${REPEAT}${C_OFF}"
    if run_fixture "${fx}" "${attempt}"; then
      fx_ok=$((fx_ok + 1)); OK=$((OK + 1))
    else
      fx_bad=$((fx_bad + 1)); BAD=$((BAD + 1))
    fi
    TOTAL=$((TOTAL + 1))
    attempt=$((attempt + 1))
  done

  if [ "${REPEAT}" -gt 1 ]; then
    echo "  итог: ${fx_ok}/${REPEAT} успешно"
    [ "${fx_bad}" -gt 0 ] && [ "${fx_ok}" -gt 0 ] \
      && echo "  ${C_YELLOW}нестабильный результат — промпт стоит уточнить${C_OFF}"
  fi
  REPORT="${REPORT}${fx}: ${fx_ok}/${REPEAT}"$'\n'
  echo
done

echo "${C_BOLD}────────────────────────────────${C_OFF}"
if [ "${TOTAL}" -eq 0 ]; then
  echo "${C_YELLOW}Фикстуры не найдены.${C_OFF} Проверьте ${FIXTURES_DIR}"
  exit 1
fi

echo "Успешно: ${OK}/${TOTAL}"
[ "${DRY_RUN}" -eq 0 ] && echo "Ответы модели: ${OUT_DIR}/"

if [ "${BAD}" -gt 0 ]; then
  echo
  echo "${C_YELLOW}Ответы модели недетерминированы: единичный провал может быть"
  echo "случайностью. Повторите с --repeat 3, чтобы отличить её от регресса.${C_OFF}"
  exit 1
fi
exit 0
