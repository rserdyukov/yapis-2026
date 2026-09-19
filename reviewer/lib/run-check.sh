#!/usr/bin/env bash
# Запускает структурную проверку tasks/<task_dir>/check.sh для работы
# студента в ИЗОЛИРОВАННОМ контейнере и сохраняет её вывод в файл.
#
# ДВЕ ФАЗЫ.
#
#   Фаза 1 — зависимости (СЕТЬ ЕСТЬ, секретов нет). Выполняется
#   .github/review/lib/install-deps.sh: pip/maven/gradle/npm/dotnet по
#   манифестам в работе студента, либо его собственный install-deps.sh.
#   Всё скачанное ложится в <work>/.deps/ внутри рабочей копии. В этом
#   контейнере нечему утечь: ни ключа модели, ни токена GitHub — только
#   копия репозитория студента. Риск — злоупотребление сетью раннера —
#   ограничен таймаутом, памятью, CPU и pids.
#
#   Фаза 2 — проверка (СЕТИ НЕТ). check.sh -> compile.sh студента на той
#   же рабочей копии, с переменными окружения, указывающими на .deps/
#   (PYTHONPATH, MAVEN_OPTS, GRADLE_USER_HOME, NUGET_PACKAGES...). Это
#   недоверенный код; ревьюер работает в раннере, где рядом ключ модели и
#   токен GitHub App, поэтому здесь:
#     - сеть отключена (--network none): ни утечки секретов, ни майнинга;
#     - монтируется только КОПИЯ репозитория и копия каталога проверок;
#     - ограничены память, CPU, число процессов и время;
#     - корневая ФС read-only, запись — только в рабочую копию и tmpfs /tmp;
#     - все capabilities сброшены, повышение привилегий запрещено.
#
# Раньше фазы 1 не было, и compile.sh, пытавшийся скачать ANTLR-jar или
# поставить pip-пакет, падал «из-за отсутствия сети» — это выглядело как
# ошибка студента, хотя локально у него всё работало.
#
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
#   out_file          куда записать вывод (фаза 1 + фаза 2).
#
# Код возврата: код check.sh (0 — проверки пройдены), 124 — таймаут,
# 125 — контейнер не удалось запустить, 0 с пометкой в out_file — если
# check.sh для task_dir отсутствует. Ошибки фазы 1 в код возврата НЕ
# входят: они видны в отчёте, а фаза 2 всё равно выполняется.
#
# Переменные окружения:
#   CHECK_IMAGE            образ (по умолчанию ghcr.io/<owner>/yapis-check:latest,
#                          owner берётся из GITHUB_REPOSITORY_OWNER);
#   CHECK_TIMEOUT_SECONDS, CHECK_MEMORY_LIMIT, CHECK_CPU_LIMIT — из config.env;
#   DEPS_TIMEOUT_SECONDS   таймаут фазы 1 (из config.env, по умолчанию 300);
#   DEPS_PHASE             "1" (по умолчанию) или "0" — пропустить фазу 1;
#   REVIEW_ROOT            каталог .github/review (по умолчанию — ../../.github/review).
#   CHECK_RUNNER           "docker" (по умолчанию) или "direct" — запустить без
#                          контейнера (ТОЛЬКО для тестов и локального
#                          прогона у студента, где код его собственный).
#                          В direct-режиме фаза 1 тоже выполняется — прямо
#                          на машине, в <work>/.deps/.
#   CHECK_SANDBOX_DIR      где создавать sandbox (по умолчанию рядом с
#                          student_repo_dir; на macOS с Docker Desktop
#                          укажите каталог внутри $HOME).

set -uo pipefail

TASK_DIR="${1:?task_dir is required}"
STUDENT_REPO_DIR="${2:?student_repo_dir is required}"
WORK_DIR="${3:?work_dir is required}"
OUT_FILE="${4:?out_file is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_ROOT="${REVIEW_ROOT:-$(cd "${SCRIPT_DIR}/../../.github/review" && pwd)}"

CHECK_TIMEOUT_SECONDS="${CHECK_TIMEOUT_SECONDS:-300}"
DEPS_TIMEOUT_SECONDS="${DEPS_TIMEOUT_SECONDS:-300}"
CHECK_MEMORY_LIMIT="${CHECK_MEMORY_LIMIT:-1g}"
CHECK_CPU_LIMIT="${CHECK_CPU_LIMIT:-1.0}"
CHECK_RUNNER="${CHECK_RUNNER:-docker}"
DEPS_PHASE="${DEPS_PHASE:-1}"
CHECK_IMAGE="${CHECK_IMAGE:-ghcr.io/${GITHUB_REPOSITORY_OWNER:-local}/yapis-check:latest}"

CHECK_SCRIPT="${REVIEW_ROOT}/tasks/${TASK_DIR}/check.sh"
DEPS_SCRIPT="${REVIEW_ROOT}/lib/install-deps.sh"

if [ ! -f "${CHECK_SCRIPT}" ]; then
  echo "Для набора ${TASK_DIR} скрипт структурной проверки не настроен." > "${OUT_FILE}"
  exit 0
fi

# Зависимости нужны только там, где исполняется код студента (compile.sh).
# Для ЛР1-2 фаза не нужна: check.sh там ничего не запускает, а сборка
# грамматики идёт инструментами образа.
case "${TASK_DIR}" in
  task1|task2|default) DEPS_PHASE=0 ;;
esac

# Печатает заголовок секции в отчёт.
section() { printf '\n== %s ==\n' "$1"; }

# --- Прямой запуск (без изоляции) ------------------------------------------
if [ "${CHECK_RUNNER}" = "direct" ]; then
  : > "${OUT_FILE}"
  if [ "${DEPS_PHASE}" = "1" ]; then
    {
      section "Фаза 1: зависимости"
      (
        cd "${STUDENT_REPO_DIR}" \
          && timeout "${DEPS_TIMEOUT_SECONDS}" bash "${DEPS_SCRIPT}" "${WORK_DIR}"
      )
      section "Фаза 2: проверка"
    } >> "${OUT_FILE}" 2>&1
  fi
  (
    cd "${STUDENT_REPO_DIR}" || exit 1
    # Окружение фазы 2 — пути к .deps/.
    if [ "${DEPS_PHASE}" = "1" ]; then
      # shellcheck source=/dev/null
      source "${DEPS_SCRIPT}"
      while IFS= read -r line; do export "${line?}"; done < <(deps_env "$(cd "${WORK_DIR}" && pwd)")
    fi
    timeout "${CHECK_TIMEOUT_SECONDS}" bash "${CHECK_SCRIPT}" "${WORK_DIR}"
  ) >> "${OUT_FILE}" 2>&1
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

# Общие флаги обеих фаз. uid 1000 — непривилегированный пользователь образа
# (см. Dockerfile). --init: корректно убивать дерево процессов по таймауту.
# --pids-limit: защита от fork-бомбы. Таймаут снаружи (timeout) дублирует
# внутренний на случай, если compile.sh перехватывает сигналы.
DOCKER_COMMON=(
  --rm --init
  --read-only
  --tmpfs /tmp:rw,exec,nosuid,size=512m
  --memory "${CHECK_MEMORY_LIMIT}" --memory-swap "${CHECK_MEMORY_LIMIT}"
  --cpus "${CHECK_CPU_LIMIT}"
  --pids-limit 256
  --cap-drop ALL
  --security-opt no-new-privileges
  --user 1000:1000
  -e HOME=/tmp
  -v "${SANDBOX}/repo:/work:rw"
  -v "${SANDBOX}/review:/review:ro"
  -w /work
)

: > "${OUT_FILE}"

# --- Фаза 1: зависимости (сеть есть, секретов нет) --------------------------
if [ "${DEPS_PHASE}" = "1" ]; then
  section "Фаза 1: зависимости" >> "${OUT_FILE}"
  DEPS_CONTAINER="yapis-deps-$$-$(date +%s)"
  # Сеть по умолчанию (bridge). Секретов в окружении нет: передаются только
  # таймаут и HOME. Образ тот же — все тулчейны уже на месте.
  timeout --kill-after=10 "$((DEPS_TIMEOUT_SECONDS + 30))" \
    docker run "${DOCKER_COMMON[@]}" \
      --name "${DEPS_CONTAINER}" \
      -e DEPS_STEP_TIMEOUT="$((DEPS_TIMEOUT_SECONDS - 30))" \
      "${CHECK_IMAGE}" \
      bash -c 'timeout "$1" bash /review/lib/install-deps.sh "$2"' _ "${DEPS_TIMEOUT_SECONDS}" "${WORK_DIR}" \
    >> "${OUT_FILE}" 2>&1
  DEPS_RC=$?
  docker rm -f "${DEPS_CONTAINER}" >/dev/null 2>&1 || true
  case "${DEPS_RC}" in
    0) ;;
    124|137) echo "РЕЗУЛЬТАТ ФАЗЫ 1: установка зависимостей прервана по таймауту (${DEPS_TIMEOUT_SECONDS}с) или по памяти." >> "${OUT_FILE}" ;;
    125|126|127)
      echo "ОШИБКА ИНФРАСТРУКТУРЫ: контейнер фазы зависимостей не запустился (код ${DEPS_RC}, образ ${CHECK_IMAGE})." >> "${OUT_FILE}"
      exit 125 ;;
    *) echo "РЕЗУЛЬТАТ ФАЗЫ 1: код ${DEPS_RC} — часть зависимостей не установлена, см. выше." >> "${OUT_FILE}" ;;
  esac
  # Установщики могли создать файлы от uid 1000 — фаза 2 работает от того же
  # uid, но на всякий случай выравниваем права.
  chmod -R a+rwX "${SANDBOX}/repo" 2>/dev/null || true
  section "Фаза 2: проверка (без сети)" >> "${OUT_FILE}"
fi

# --- Фаза 2: проверка (без сети) --------------------------------------------
CONTAINER_NAME="yapis-check-$$-$(date +%s)"
# Переменные окружения, указывающие на .deps/ внутри /work.
DEPS_ENV_ARGS=()
if [ "${DEPS_PHASE}" = "1" ]; then
  # shellcheck source=/dev/null
  source "${DEPS_SCRIPT}"
  # Внутри контейнера рабочая копия смонтирована в /work; WORK_DIR — путь
  # внутри неё.
  while IFS= read -r line; do
    DEPS_ENV_ARGS+=(-e "${line}")
  done < <(deps_env "/work/${WORK_DIR#./}")
fi

timeout --kill-after=10 "$((CHECK_TIMEOUT_SECONDS + 30))" \
  docker run "${DOCKER_COMMON[@]}" \
    --name "${CONTAINER_NAME}" \
    --network none \
    -e CHECK_TIMEOUT_SECONDS="${CHECK_TIMEOUT_SECONDS}" \
    "${DEPS_ENV_ARGS[@]}" \
    "${CHECK_IMAGE}" \
    bash -c 'timeout "${CHECK_TIMEOUT_SECONDS}" bash "/review/tasks/$1/check.sh" "$2"' _ "${TASK_DIR}" "${WORK_DIR}" \
  >> "${OUT_FILE}" 2>&1
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
