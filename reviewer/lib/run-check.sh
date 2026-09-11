#!/usr/bin/env bash
# Запускает структурную проверку tasks/<task_dir>/check.sh для работы
# студента в ИЗОЛИРОВАННОМ контейнере и сохраняет её вывод в файл.
#
# ЗАЧЕМ КОНТЕЙНЕР. check.sh для лаб 3-5 вызывает compile.sh студента — это
# недоверенный код, а ревьюер работает в раннере преподавателя, где рядом
# лежат ключ модели и токен GitHub App. Поэтому:
#   - сеть отключена (--network none): ни утечки секретов, ни майнинга;
#   - в контейнер монтируется только КОПИЯ репозитория студента и копия
#     каталога проверок; ничего из $HOME, /tmp раннера и т.п.;
#   - ограничены память, CPU, число процессов и время;
#   - корневая ФС контейнера read-only, запись — только в рабочую копию
#     и tmpfs /tmp;
#   - все capabilities сброшены, повышение привилегий запрещено.
# Побочные файлы, которые compile.sh создаст в рабочей копии (например,
# AGENTS.md или .opencode/), в контейнере и останутся — агент потом читает
# ДРУГУЮ, чистую копию репозитория (см. review-pr.sh).
#
# Использование:
#   run-check.sh <task_dir> <student_repo_dir> <work_dir> <out_file>
#
#   task_dir          имя набора проверок (task3, default, ...);
#   student_repo_dir  checkout репозитория студента (будет СКОПИРОВАН);
#   work_dir          рабочая директория внутри репозитория ('.' обычно);
#   out_file          куда записать вывод check.sh.
#
# Код возврата: код check.sh (0 — проверки пройдены), 124 — таймаут,
# 125 — контейнер не удалось запустить, 0 с пометкой в out_file — если
# check.sh для task_dir отсутствует.
#
# Переменные окружения:
#   CHECK_IMAGE            образ (по умолчанию ghcr.io/<owner>/yapis-check:latest,
#                          owner берётся из GITHUB_REPOSITORY_OWNER);
#   CHECK_TIMEOUT_SECONDS, CHECK_MEMORY_LIMIT, CHECK_CPU_LIMIT — из config.env;
#   REVIEW_ROOT            каталог .github/review (по умолчанию — ../../.github/review).
#   CHECK_RUNNER           "docker" (по умолчанию) или "direct" — запустить без
#                          контейнера (ТОЛЬКО для тестов и локального
#                          прогона у студента, где код его собственный).

set -uo pipefail

TASK_DIR="${1:?task_dir is required}"
STUDENT_REPO_DIR="${2:?student_repo_dir is required}"
WORK_DIR="${3:?work_dir is required}"
OUT_FILE="${4:?out_file is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_ROOT="${REVIEW_ROOT:-$(cd "${SCRIPT_DIR}/../../.github/review" && pwd)}"

CHECK_TIMEOUT_SECONDS="${CHECK_TIMEOUT_SECONDS:-300}"
CHECK_MEMORY_LIMIT="${CHECK_MEMORY_LIMIT:-1g}"
CHECK_CPU_LIMIT="${CHECK_CPU_LIMIT:-1.0}"
CHECK_RUNNER="${CHECK_RUNNER:-docker}"
CHECK_IMAGE="${CHECK_IMAGE:-ghcr.io/${GITHUB_REPOSITORY_OWNER:-local}/yapis-check:latest}"

CHECK_SCRIPT="${REVIEW_ROOT}/tasks/${TASK_DIR}/check.sh"

if [ ! -f "${CHECK_SCRIPT}" ]; then
  echo "Для набора ${TASK_DIR} скрипт структурной проверки не настроен." > "${OUT_FILE}"
  exit 0
fi

# --- Прямой запуск (без изоляции) ------------------------------------------
if [ "${CHECK_RUNNER}" = "direct" ]; then
  (
    cd "${STUDENT_REPO_DIR}" \
      && timeout "${CHECK_TIMEOUT_SECONDS}" bash "${CHECK_SCRIPT}" "${WORK_DIR}"
  ) > "${OUT_FILE}" 2>&1
  exit $?
fi

# --- Запуск в контейнере ---------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
  echo "docker не найден — структурная проверка не выполнена." > "${OUT_FILE}"
  exit 125
fi

# Каталог sandbox создаётся РЯДОМ с репозиторием студента, а не в $TMPDIR.
# На macOS Docker Desktop по умолчанию не пробрасывает /var/folders (куда
# указывает mktemp), и том монтируется пустым — проверка тогда падает с
# "No such file or directory" вместо осмысленного результата. Рядом с
# рабочим каталогом путь заведомо доступен и на раннере, и локально.
SANDBOX_PARENT="${CHECK_SANDBOX_DIR:-$(cd "$(dirname "${STUDENT_REPO_DIR}")" && pwd)}"
SANDBOX="$(mktemp -d "${SANDBOX_PARENT}/check-sandbox.XXXXXX")"
trap 'rm -rf "${SANDBOX}"' EXIT

# Копия репозитория студента: контейнер может писать в неё что угодно, на
# оригинал (который потом читает агент) это не повлияет. .git не копируем —
# compile.sh он не нужен, а hooks оттуда исполняться не должны.
mkdir -p "${SANDBOX}/repo" "${SANDBOX}/review"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --exclude '.git' "${STUDENT_REPO_DIR}/" "${SANDBOX}/repo/"
else
  (cd "${STUDENT_REPO_DIR}" && tar --exclude='.git' -cf - .) | (cd "${SANDBOX}/repo" && tar -xf -)
fi
# Копия проверок: только tasks/ и lib/ — без config.env, messages.env и
# остального, что студенту видеть не обязательно.
cp -R "${REVIEW_ROOT}/tasks" "${SANDBOX}/review/tasks"
cp -R "${REVIEW_ROOT}/lib"   "${SANDBOX}/review/lib"
chmod -R a+rwX "${SANDBOX}/repo"
chmod -R a+rX  "${SANDBOX}/review"

# uid 1000 — непривилегированный пользователь образа (см. Dockerfile).
# --init: корректно убивать дерево процессов по таймауту.
# --pids-limit: защита от fork-бомбы.
# Таймаут снаружи (timeout) дублирует внутренний на случай, если compile.sh
# перехватывает сигналы; docker kill добивает контейнер.
CONTAINER_NAME="yapis-check-$$-$(date +%s)"
timeout --kill-after=10 "$((CHECK_TIMEOUT_SECONDS + 30))" \
  docker run --rm --init \
    --name "${CONTAINER_NAME}" \
    --network none \
    --read-only \
    --tmpfs /tmp:rw,exec,nosuid,size=256m \
    --memory "${CHECK_MEMORY_LIMIT}" --memory-swap "${CHECK_MEMORY_LIMIT}" \
    --cpus "${CHECK_CPU_LIMIT}" \
    --pids-limit 256 \
    --cap-drop ALL \
    --security-opt no-new-privileges \
    --user 1000:1000 \
    -e HOME=/tmp \
    -e CHECK_TIMEOUT_SECONDS="${CHECK_TIMEOUT_SECONDS}" \
    -v "${SANDBOX}/repo:/work:rw" \
    -v "${SANDBOX}/review:/review:ro" \
    -w /work \
    "${CHECK_IMAGE}" \
    bash -c 'timeout "${CHECK_TIMEOUT_SECONDS}" bash "/review/tasks/$1/check.sh" "$2"' _ "${TASK_DIR}" "${WORK_DIR}" \
  > "${OUT_FILE}" 2>&1
RC=$?

# Если внешний таймаут сработал раньше docker'а, контейнер мог остаться.
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

if [ "${RC}" -eq 124 ] || [ "${RC}" -eq 137 ]; then
  {
    echo
    echo "РЕЗУЛЬТАТ: проверка прервана по таймауту (${CHECK_TIMEOUT_SECONDS}с) или по лимиту памяти (${CHECK_MEMORY_LIMIT})."
  } >> "${OUT_FILE}"
  exit 124
fi

if [ "${RC}" -eq 125 ] || [ "${RC}" -eq 126 ] || [ "${RC}" -eq 127 ]; then
  {
    echo
    echo "ОШИБКА ИНФРАСТРУКТУРЫ: контейнер проверки не запустился (код ${RC}, образ ${CHECK_IMAGE})."
  } >> "${OUT_FILE}"
  exit 125
fi

exit "${RC}"
