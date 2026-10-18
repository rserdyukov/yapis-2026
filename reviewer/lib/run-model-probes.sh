#!/usr/bin/env bash
# Запускает зонды модели (этап 1 ИИ-ревью) через compile.sh студента в
# изоляции — с теми же ограничениями, что фаза 2 run-check.sh: без сети,
# read-only корень, лимиты памяти, CPU, pids и времени.
#
# Использование:
#   run-model-probes.sh <prepared_dir> <work_dir> <probes.json> <out_file>
#
#   prepared_dir  рабочая копия ПОСЛЕ check.sh (CHECK_KEEP_DIR в run-check.sh):
#                 парсер уже сгенерирован, зависимости в .deps/;
#   work_dir      рабочая директория внутри неё;
#   probes.json   ответ модели этапа 1 (недоверенные данные);
#   out_file      отчёт для промпта этапа 2.
#
# Переменные: CHECK_RUNNER, CHECK_IMAGE, CHECK_MEMORY_LIMIT, CHECK_CPU_LIMIT
# (как в run-check.sh); MODEL_PROBES_BUDGET — общий лимит секунд (180).
#
# Код выхода: 0 — отчёт записан; 125 — контейнер не запустился.

set -uo pipefail

PREPARED="${1:?prepared_dir}"; WORK_DIR="${2:?work_dir}"; PROBES="${3:?probes.json}"; OUT_FILE="${4:?out_file}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_ROOT="${REVIEW_ROOT:-$(cd "${SCRIPT_DIR}/../../.github/review" && pwd)}"
CHECK_RUNNER="${CHECK_RUNNER:-docker}"
CHECK_IMAGE="${CHECK_IMAGE:-ghcr.io/${GITHUB_REPOSITORY_OWNER:-local}/yapis-check:latest}"
CHECK_MEMORY_LIMIT="${CHECK_MEMORY_LIMIT:-1g}"
CHECK_CPU_LIMIT="${CHECK_CPU_LIMIT:-1.0}"
BUDGET="${MODEL_PROBES_BUDGET:-180}"
case "${BUDGET}" in ''|*[!0-9]*) BUDGET=180 ;; esac

if [ ! -d "${PREPARED}/${WORK_DIR}" ]; then
  echo "Зонды модели не запускались: нет подготовленной рабочей копии." > "${OUT_FILE}"
  exit 0
fi
mkdir -p "${PREPARED}/${WORK_DIR}/.review"
cp "${PROBES}" "${PREPARED}/${WORK_DIR}/.review/model-probes.json" 2>/dev/null \
  || echo '{}' > "${PREPARED}/${WORK_DIR}/.review/model-probes.json"

if [ "${CHECK_RUNNER}" = "direct" ]; then
  (
    cd "${PREPARED}" || exit 1
    if [ -f "${REVIEW_ROOT}/lib/install-deps.sh" ]; then
      # shellcheck source=/dev/null
      source "${REVIEW_ROOT}/lib/install-deps.sh"
      while IFS= read -r line; do export "${line?}"; done < <(deps_env "$(cd "${WORK_DIR}" && pwd)")
    fi
    timeout "$((BUDGET + 30))" python3 -B "${REVIEW_ROOT}/lib/model-probes.py" "${WORK_DIR}" --budget "${BUDGET}"
  ) > "${OUT_FILE}" 2>&1
  exit 0
fi

command -v docker >/dev/null 2>&1 || { echo "docker не найден — зонды модели не запускались." > "${OUT_FILE}"; exit 125; }

REVIEW_COPY="$(mktemp -d "$(cd "$(dirname "${PREPARED}")" && pwd)/probes-review.XXXXXX")"
trap 'rm -rf "${REVIEW_COPY}"' EXIT
cp -R "${REVIEW_ROOT}/lib" "${REVIEW_COPY}/lib"
chmod -R a+rX "${REVIEW_COPY}"
chmod -R a+rwX "${PREPARED}" 2>/dev/null || true

DEPS_ENV_ARGS=()
# shellcheck source=/dev/null
source "${REVIEW_ROOT}/lib/install-deps.sh"
while IFS= read -r line; do DEPS_ENV_ARGS+=(-e "${line}"); done < <(deps_env "/work/${WORK_DIR#./}")

NAME="yapis-probes-$$-$(date +%s)"
timeout --kill-after=10 "$((BUDGET + 60))" \
  docker run --rm --init --read-only \
    --tmpfs /tmp:rw,exec,nosuid,size=512m \
    --memory "${CHECK_MEMORY_LIMIT}" --memory-swap "${CHECK_MEMORY_LIMIT}" \
    --cpus "${CHECK_CPU_LIMIT}" --pids-limit 256 \
    --cap-drop ALL --security-opt no-new-privileges --user 1000:1000 \
    --network none -e HOME=/tmp \
    ${DEPS_ENV_ARGS[@]+"${DEPS_ENV_ARGS[@]}"} \
    -v "$(cd "${PREPARED}" && pwd):/work:rw" -v "${REVIEW_COPY}:/review:ro" -w /work \
    --name "${NAME}" "${CHECK_IMAGE}" \
    python3 -B /review/lib/model-probes.py "${WORK_DIR}" --budget "${BUDGET}" \
  > "${OUT_FILE}" 2>&1
RC=$?
docker rm -f "${NAME}" >/dev/null 2>&1 || true
case "${RC}" in
  0) ;;
  124|137) echo "Зонды модели прерваны по таймауту или памяти — результаты выше неполные." >> "${OUT_FILE}" ;;
  125|126|127) echo "ОШИБКА ИНФРАСТРУКТУРЫ: контейнер зондов не запустился (код ${RC})." >> "${OUT_FILE}"; exit 125 ;;
esac
exit 0
