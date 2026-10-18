#!/usr/bin/env bash
# Стенд полноты ИИ-ревью: бот на реальных работах против ревью преподавателя.
#
# ЗАЧЕМ. eval-prompts.sh проверяет поведение бота на синтетических
# фикстурах. Этот стенд меряет главное: какую долю дефектов, найденных при
# ручном ревью (скил lab-review, досье ~/lab-reviews/_students/<repo>/),
# бот находит сам и сколько он пишет лишнего. Любую правку промпта, check.sh
# или конвейера проверяют по этим цифрам.
#
# ДАННЫЕ. Кейс — каталог ревью ~/lab-reviews/<repo>-pr<N>-<sha7>/ (meta.json,
# src/ с git, pr-diff.txt, generated.txt) и досье студента с
# findings.json (P — подтверждённые дефекты, когда открыты и исправлены)
# и dropped.json (X — отброшенные подозрения). Это работы студентов: в
# репозиторий курса стенд их не копирует, результаты — в tests/results/.
#
# КОНВЕЙЕР — как в reviewer/lib/review-pr.sh, шаги 4–7: check.sh в образе
# проверки без сети (run-check.sh), очистка конфигурации агента, промпт
# build-prompt.sh, opencode run с конфигурацией agent-config.sh. Отличие —
# прошлое ревью бота в промпт не передаётся: каждый кейс — первое ревью.
#
# ОЦЕНКА — recall/score.py: модель-судья сопоставляет замечания бота с P и X
# досье. Метрики: полнота по blocker+major и по всем P, существующим на этом
# коммите; доля замечаний, совпавших с X (заведомо ложные); «новые» —
# замечания, которых нет в досье (их стоит просмотреть: это либо ложные,
# либо пропуск ручного ревью).
#
# ИСПОЛЬЗОВАНИЕ
#   ./.github/review/tests/eval-recall.sh                все кейсы
#   ./.github/review/tests/eval-recall.sh kadikov        кейсы, где в имени есть подстрока
#   ./.github/review/tests/eval-recall.sh --list         список кейсов и ожидаемых P
#   ./.github/review/tests/eval-recall.sh --jobs 4       параллельно (по умолчанию 3)
#   ./.github/review/tests/eval-recall.sh --repeat 2     N прогонов каждого кейса
#   ./.github/review/tests/eval-recall.sh --no-judge     только прогон бота
#   ./.github/review/tests/eval-recall.sh --score <dir>  пересчитать готовый прогон
#   ./.github/review/tests/eval-recall.sh --label <имя>  имя прогона (по умолчанию дата)
#
# ПЕРЕМЕННЫЕ
#   EVAL_CASES_DIR       каталог ревью (по умолчанию ~/lab-reviews);
#   REVIEW_MODEL         модель бота (по умолчанию MODEL из config.env, а без
#                        OPENROUTER_API_KEY — litellm/claude-haiku-5-5);
#   EVAL_PROVIDER_JSON   блок provider для opencode (JSON-файл), если модель
#                        не из каталога; для litellm по умолчанию
#                        ~/lab-reviews/_eval/provider.json;
#   JUDGE_MODEL          модель-судья (по умолчанию claude-opus-5-5 через
#                        JUDGE_BASE_URL, OpenAI-совместимый API);
#   JUDGE_BASE_URL, JUDGE_API_KEY — по умолчанию LiteLLM и ключ из
#                        ~/.local/share/opencode/auth.json;
#   CHECK_RUNNER=direct  проверка без контейнера (быстрее, но не как у бота);
#   EVAL_TWO_STAGE=1     двухэтапное ревью: этап 1 — зонды модели (JSON,
#                        tasks/<N>/probes.md), их запуск run-model-probes.sh,
#                        этап 2 — ревью в той же сессии с результатами.
#
# Ответы модели недетерминированы: сравнивайте варианты на --repeat 2–3.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_DIR="$(cd "${TESTS_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${REVIEW_DIR}/../.." && pwd)"
CASES_DIR="${EVAL_CASES_DIR:-${HOME}/lab-reviews}"

JOBS=3; REPEAT=1; JUDGE=1; ONLY=""; LIST=0; SCORE_DIR=""; ONE=""; LABEL=""
while [ $# -gt 0 ]; do
  case "${1}" in
    --list)     LIST=1; shift ;;
    --jobs)     JOBS="${2:?}"; shift 2 ;;
    --repeat)   REPEAT="${2:?}"; shift 2 ;;
    --no-judge) JUDGE=0; shift ;;
    --score)    SCORE_DIR="${2:?}"; shift 2 ;;
    --label)    LABEL="${2:?}"; shift 2 ;;
    --one)      ONE="${2:?}"; shift 2 ;;   # внутренний: один кейс в OUT
    -h|--help)  sed -n '2,55p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)         echo "Неизвестный аргумент: ${1}" >&2; exit 1 ;;
    *)          ONLY="${1}"; shift ;;
  esac
done

SCORE_PY="${TESTS_DIR}/recall/score.py"
TWO_STAGE="${EVAL_TWO_STAGE:-0}"

if [ -n "${SCORE_DIR}" ]; then
  exec python3 "${SCORE_PY}" score "${SCORE_DIR}" --cases "${CASES_DIR}"
fi
if [ "${LIST}" -eq 1 ]; then
  exec python3 "${SCORE_PY}" list --cases "${CASES_DIR}" ${ONLY:+--only "${ONLY}"}
fi

# shellcheck source=/dev/null
source "${REVIEW_DIR}/config.env"
COURSE_MODEL="${MODEL}"
if [ -n "${REVIEW_MODEL:-}" ]; then
  MODEL="${REVIEW_MODEL}"
elif [ -z "${OPENROUTER_API_KEY:-}" ]; then
  MODEL="litellm/claude-haiku-5-5"
fi
# shellcheck source=/dev/null
source "${REVIEW_DIR}/lib/agent-config.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/reviewer/lib/common.sh"

PROVIDER="${MODEL%%/*}"
PROVIDER_JSON="${EVAL_PROVIDER_JSON:-}"
[ -z "${PROVIDER_JSON}" ] && [ "${PROVIDER}" = "litellm" ] && PROVIDER_JSON="${CASES_DIR}/_eval/provider.json"
if [ "${PROVIDER}" = "litellm" ] && [ -z "${LITELLM_API_KEY:-}" ]; then
  LITELLM_API_KEY="$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.local/share/opencode/auth.json")))["litellm"]["key"])' 2>/dev/null)"
  export LITELLM_API_KEY
fi

# --- один кейс ---------------------------------------------------------------
# OUT/<кейс>/{check.out,prompt.md,events.jsonl,review.md,run.json}
run_case() {
  local case_dir="${1}" out="${2}"
  local name; name="$(basename "${case_dir}")"
  mkdir -p "${out}"
  local meta="${case_dir}/meta.json"
  local head task work_dir repo
  head="$(jq -r .head "${meta}")"; task="$(jq -r .task "${meta}")"
  work_dir="$(jq -r '.work_dir // "."' "${meta}")"; repo="$(jq -r .repo "${meta}")"
  local task_dir="task${task}"
  [ -d "${REVIEW_DIR}/tasks/${task_dir}" ] || task_dir="default"

  local tmp; tmp="$(mktemp -d "${CASES_DIR}/_eval/tmp/${name}.XXXXXX")"
  local student="${tmp}/student"
  mkdir -p "${student}"
  git -C "${case_dir}/src" archive "${head}" | tar -x -C "${student}" \
    || { echo "{\"error\":\"git archive\"}" > "${out}/run.json"; rm -rf "${tmp}"; return 1; }

  # check.sh зависит только от коммита и кода проверок — кэшируем по ним.
  local check_hash
  # Зонды модели (probes.md, model-probes.py) на check.sh не влияют.
  check_hash="$( (cd "${REVIEW_DIR}" && find tasks lib -type f ! -name '*.pyc' ! -name probes.md ! -name model-probes.py -print0 \
                  | sort -z | xargs -0 cat; \
                  cat "${REPO_ROOT}/reviewer/lib/run-check.sh"; echo "${CHECK_RUNNER:-docker}") | shasum | cut -c1-12)"
  local cache="${CASES_DIR}/_eval/check-cache/${head:0:12}-${check_hash}"
  local t0="${SECONDS}"
  # Прогоны r1..rN одного кейса идут параллельно: проверку делает первый,
  # остальные ждут его (mkdir атомарен).
  mkdir -p "$(dirname "${cache}")"
  until mkdir "${cache}.lock" 2>/dev/null; do sleep 2; done
  if [ ! -f "${cache}/check.out" ]; then
    mkdir -p "${cache}"
    local ck="${tmp}/check-copy"; mkdir -p "${ck}"
    (cd "${student}" && tar -cf - .) | (cd "${ck}" && tar -xf -)
    CHECK_TIMEOUT_SECONDS="${CHECK_TIMEOUT_SECONDS:-300}" DEPS_TIMEOUT_SECONDS="${DEPS_TIMEOUT_SECONDS:-300}" \
    CHECK_MEMORY_LIMIT="${CHECK_MEMORY_LIMIT:-1g}" CHECK_CPU_LIMIT="${CHECK_CPU_LIMIT:-1.0}" \
    CHECK_IMAGE="${CHECK_IMAGE:-ghcr.io/rserdyukov/yapis-check:latest}" CHECK_KEEP_DIR="${cache}/work" \
      bash "${REPO_ROOT}/reviewer/lib/run-check.sh" "${task_dir}" "${ck}" "${work_dir}" "${cache}/check.out.part"
    # direct-режим проверяет прямо в копии — она и есть подготовленная.
    [ -d "${cache}/work" ] || mv "${ck}" "${cache}/work"
    echo $? > "${cache}/check.exit"
    mv "${cache}/check.out.part" "${cache}/check.out"
  fi
  rmdir "${cache}.lock"
  cp "${cache}/check.out" "${out}/check.out"
  local check_exit; check_exit="$(cat "${cache}/check.exit")"
  local check_s=$((SECONDS - t0))

  (
    cd "${student}" || exit 1
    rm -rf AGENTS.md CLAUDE.md opencode.json opencode.jsonc .opencode .claude .cursor .env .env.* 2>/dev/null
    find . \( -type d \( -name .opencode -o -name .claude \) \) -prune -exec rm -rf {} + 2>/dev/null
    find . -type f \( -name AGENTS.md -o -name CLAUDE.md -o -name opencode.json -o -name opencode.jsonc \) -delete 2>/dev/null
    true
  )
  mkdir -p "${student}/.review"
  cp "${case_dir}/pr-diff.txt" "${student}/.review/pr-diff.txt"

  local diff_lines="${MAX_DIFF_LINES_IN_PROMPT:-6000}"
  while :; do
    MAX_DIFF_LINES_IN_PROMPT="${diff_lines}" DIFF_FILE_HINT=".review/pr-diff.txt" \
    GENERATED_FILES_LIST="${case_dir}/generated.txt" OVERSIZE_MODE=0 \
      bash "${REVIEW_DIR}/lib/build-prompt.sh" "${task_dir}" "${work_dir}" "${repo#*/}" "${task}" \
        "${case_dir}/pr-diff.txt" "${out}/check.out" "${check_exit}" > "${out}/prompt.md" 2>"${out}/prompt.err" \
      || { echo '{"error":"build-prompt"}' > "${out}/run.json"; rm -rf "${tmp}"; return 1; }
    [ "$(wc -c < "${out}/prompt.md")" -le "${MAX_PROMPT_BYTES:-400000}" ] || [ "${diff_lines}" -le 200 ] && break
    diff_lines=$((diff_lines / 2))
  done

  local cfg
  cfg="$(MODEL_DECLARE="$([ "${MODEL}" = "${COURSE_MODEL}" ] && echo "${MODEL_DECLARE:-0}" || echo 0)" agent_config_json "${MODEL}")"
  if [ -n "${PROVIDER_JSON}" ]; then
    cfg="$(printf '%s' "${cfg}" | jq -c --slurpfile p "${PROVIDER_JSON}" '.provider = $p[0]')"
  fi
  local flags=() f
  while IFS= read -r f; do flags+=("${f}"); done < <(agent_run_flags "${MODEL}" json)

  local home="${tmp}/home"; mkdir -p "${home}"
  local -a aenv=(env -i PATH="${PATH}" HOME="${home}" TMPDIR="${home}" LANG=C.UTF-8
           XDG_CACHE_HOME="${CASES_DIR}/_eval/cache"
           OPENCODE_CONFIG_CONTENT="${cfg}" OPENCODE_DISABLE_CLAUDE_CODE=true
           OPENCODE_DISABLE_AUTOUPDATE=true OPENCODE_DISABLE_DEFAULT_PLUGINS=true
           OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}" LITELLM_API_KEY="${LITELLM_API_KEY:-}")
  t0="${SECONDS}"
  local rc probes_s=0
  if [ "${TWO_STAGE}" -eq 1 ] && [ -f "${REVIEW_DIR}/tasks/${task_dir}/probes.md" ]; then
    # Этап 1: тот же промпт + задание на зонды. Ответ — JSON.
    { cat "${out}/prompt.md"; echo; cat "${REVIEW_DIR}/tasks/${task_dir}/probes.md"; } > "${out}/prompt1.md"
    ( cd "${student}" && timeout "${AGENT_TIMEOUT_SECONDS:-900}" "${aenv[@]}" \
        opencode run "${flags[@]}" < "${out}/prompt1.md" > "${out}/events1.jsonl" 2> "${out}/agent1.err" )
    extract_final_answer "${out}/events1.jsonl" "${out}/probes.json"
    local session; session="$(jq -R 'fromjson? // empty' "${out}/events1.jsonl" 2>/dev/null | jq -rs '[.[] | .sessionID? // empty][0] // ""')"
    # Зонды — в рабочей копии после check.sh (парсер сгенерирован, .deps/ на месте).
    local t1="${SECONDS}" prep="${tmp}/prepared"
    until mkdir "${cache}.lock" 2>/dev/null; do sleep 2; done
    rm -rf "${prep}"; mkdir -p "${prep}"
    (cd "${cache}/work" && tar -cf - .) | (cd "${prep}" && tar -xf -)
    rmdir "${cache}.lock"
    CHECK_IMAGE="${CHECK_IMAGE:-ghcr.io/rserdyukov/yapis-check:latest}" \
      bash "${REPO_ROOT}/reviewer/lib/run-model-probes.sh" "${prep}" "${work_dir}" "${out}/probes.json" "${out}/probes.out"
    probes_s=$((SECONDS - t1))
    # Этап 2: продолжение той же сессии — код уже прочитан, в кэше.
    python3 - "${REVIEW_DIR}/model-probes-result.md" "${out}/probes.out" > "${out}/prompt2.md" <<'PY'
import sys
t = open(sys.argv[1], encoding="utf-8").read()
r = open(sys.argv[2], encoding="utf-8", errors="replace").read()
lines = r.splitlines()[:300]
print(t.replace("{{MODEL_PROBES}}", "\n".join(lines).replace("<<<", "‹‹‹").replace(">>>", "›››")))
PY
    ( cd "${student}" && timeout "${AGENT_TIMEOUT_SECONDS:-900}" "${aenv[@]}" \
        opencode run "${flags[@]}" ${session:+-s "${session}"} < "${out}/prompt2.md" > "${out}/events.jsonl" 2> "${out}/agent.err" )
    rc=$?
    cat "${out}/events1.jsonl" "${out}/events.jsonl" > "${out}/events-all.jsonl"
  else
    ( cd "${student}" && timeout "${AGENT_TIMEOUT_SECONDS:-900}" "${aenv[@]}" \
        opencode run "${flags[@]}" < "${out}/prompt.md" > "${out}/events.jsonl" 2> "${out}/agent.err" )
    rc=$?
    cp "${out}/events.jsonl" "${out}/events-all.jsonl"
  fi
  local agent_s=$((SECONDS - t0 - probes_s))
  extract_final_answer "${out}/events.jsonl" "${out}/review.md"
  [ -s "${out}/review.md" ] && sanitize_review_text "${out}/review.md"
  local verr=""
  if [ -s "${out}/review.md" ]; then
    verr="$(validate_review_text "${out}/review.md")" || true
  else
    verr="пустой ответ"
  fi
  jq -n --arg case "${name}" --arg model "${MODEL}" --argjson rc "${rc}" --arg verr "${verr}" \
        --argjson check_s "${check_s}" --argjson agent_s "${agent_s}" --arg check_exit "${check_exit}" \
        --argjson probes_s "${probes_s}" --argjson two_stage "${TWO_STAGE}" \
        --arg summary "$(summarize_agent_events "${out}/events-all.jsonl")" \
        --argjson prompt_bytes "$(wc -c < "${out}/prompt.md" | tr -d ' ')" \
        --argjson tokens "$(jq -R 'fromjson? // empty' "${out}/events-all.jsonl" 2>/dev/null | jq -s '[.[] | select(.type=="step_finish") | .part.tokens] |
            {input: (map(.input // 0) | add // 0), output: (map(.output // 0) | add // 0),
             cache_read: (map(.cache.read // 0) | add // 0), cache_write: (map(.cache.write // 0) | add // 0), steps: length}' 2>/dev/null || echo '{}')" \
    '{case:$case, model:$model, two_stage:$two_stage, rc:$rc, invalid:$verr, check_exit:$check_exit, check_s:$check_s,
      agent_s:$agent_s, probes_s:$probes_s,
      prompt_bytes:$prompt_bytes, tokens:$tokens, summary:$summary}' > "${out}/run.json"
  rm -rf "${tmp}"
  echo "  ${name}: агент ${agent_s} с, код ${rc}${verr:+, брак: ${verr}}" >&2
}

if [ -n "${ONE}" ]; then
  # --one <кейс>:<каталог результата>
  run_case "${CASES_DIR}/${ONE%%:*}" "${ONE#*:}"
  exit $?
fi

# --- все кейсы ---------------------------------------------------------------
command -v opencode >/dev/null || { echo "нужен opencode" >&2; exit 1; }
command -v jq >/dev/null || { echo "нужен jq" >&2; exit 1; }
if [ "${PROVIDER}" = "openrouter" ] && [ -z "${OPENROUTER_API_KEY:-}" ]; then
  echo "Не задан OPENROUTER_API_KEY для ${MODEL}" >&2; exit 1
fi

CASES=()
while IFS= read -r c; do CASES+=("${c}"); done < <(python3 "${SCORE_PY}" list --cases "${CASES_DIR}" --names ${ONLY:+--only "${ONLY}"})
[ "${#CASES[@]}" -gt 0 ] || { echo "Кейсы не найдены в ${CASES_DIR}" >&2; exit 1; }

mkdir -p "${CASES_DIR}/_eval/tmp"
# Блокировки, оставшиеся от прерванного прогона.
rm -rf "${CASES_DIR}/_eval/check-cache/"*.lock 2>/dev/null
RUN_DIR="${EVAL_OUT_DIR:-${TESTS_DIR}/results/recall}/${LABEL:-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "${RUN_DIR}"
{
  echo "model=${MODEL}"
  echo "course_commit=$(git -C "${REPO_ROOT}" rev-parse --short HEAD)"
  echo "dirty=$(git -C "${REPO_ROOT}" status --porcelain -- .github/review reviewer | wc -l | tr -d ' ')"
  echo "repeat=${REPEAT}"
  echo "two_stage=${TWO_STAGE}"
  echo "date=$(date -u +%FT%TZ)"
} > "${RUN_DIR}/run.env"

echo "Стенд полноты: ${#CASES[@]} кейсов × ${REPEAT}, модель ${MODEL}, параллельно ${JOBS}"
echo "Результат: ${RUN_DIR}"
for c in "${CASES[@]}"; do
  r=1
  while [ "${r}" -le "${REPEAT}" ]; do
    echo "${c}:${RUN_DIR}/${c}/r${r}"
    r=$((r + 1))
  done
done | xargs -P "${JOBS}" -I{} bash "${BASH_SOURCE[0]}" --one {}

[ "${JUDGE}" -eq 1 ] || exit 0
python3 "${SCORE_PY}" score "${RUN_DIR}" --cases "${CASES_DIR}"
