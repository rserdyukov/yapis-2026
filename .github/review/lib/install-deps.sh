#!/usr/bin/env bash
# Фаза установки зависимостей работы студента — ЕДИНСТВЕННЫЙ шаг проверки,
# где есть сеть. Выполняется в контейнере без секретов (см.
# reviewer/lib/run-check.sh, фаза 1) ПЕРЕД запуском check.sh/compile.sh,
# которые идут уже без сети.
#
# ЗАЧЕМ. Начиная с ЛР3 компилятор — это реальный проект со зависимостями:
# ANTLR-jar, antlr4-python3-runtime, Maven/Gradle-артефакты, npm/NuGet-
# пакеты. Образ yapis-check содержит типовой набор, но не всё. Раньше
# compile.sh, который пытался скачать зависимость, падал в контейнере без
# сети, и это выглядело как ошибка студента (реальный случай:
# yapis-2026-321702-semenido#3 — скачивание antlr-4.13.2-complete.jar).
#
# ПОЧЕМУ ДВЕ ФАЗЫ, А НЕ ОДНА С СЕТЬЮ. В фазе с сетью в контейнере нет ничего
# ценного: ни ключа модели, ни токена GitHub, только копия публичного (для
# студента) репозитория. Утечь нечему. Единственный риск — злоупотребление
# сетью раннера (майнинг, DDoS) — ограничен таймаутом, памятью и CPU.
# А вот compile.sh — недоверенный код, который позже будет читать агент с
# ключом; ему сеть по-прежнему не даём.
#
# ЧТО УСТАНАВЛИВАЕТСЯ. По манифестам, найденным в корне работы (и на один
# уровень ниже — compiler/, src/ и т.п.). Всё складывается в /work/.deps/
# (внутри рабочей копии, которая монтируется и во вторую фазу):
#
#   install-deps.sh           — собственный скрипт студента (приоритет:
#                               если он есть, стандартные шаги НЕ выполняются;
#                               студент отвечает за всё сам)
#   requirements*.txt         — pip install --target .deps/python
#   pyproject.toml            — pip install . --target (если есть [project])
#   pom.xml                   — mvn -o dependency:go-offline в .deps/m2
#   build.gradle(.kts)        — gradle dependencies с GRADLE_USER_HOME=.deps/gradle
#   package.json              — npm ci / npm install (node_modules рядом)
#   *.csproj / *.sln          — dotnet restore с NUGET_PACKAGES=.deps/nuget
#   Cargo.toml                — cargo fetch с CARGO_HOME=.deps/cargo
#   go.mod                    — go mod download с GOMODCACHE=.deps/go
#   antlr jar по URL antlr.org — если compile.sh упоминает antlr-*-complete.jar
#                               и файла нет, кладём копию из образа
#                               ($ANTLR_JAR) по ожидаемому пути
#
# Во второй фазе те же переменные окружения (PYTHONPATH, MAVEN_OPTS,
# GRADLE_USER_HOME, NUGET_PACKAGES, CARGO_HOME, GOMODCACHE) выставляются
# снова — см. deps_env() ниже, её вызывает run-check.sh.
#
# Использование:
#   install-deps.sh <work_dir>       — выполнить установку, отчёт в stdout
#   source install-deps.sh; deps_env <work_dir>  — напечатать VAR=value для фазы 2
#
# Код возврата: 0 — всё установлено или устанавливать нечего; 1 — какой-то
# шаг упал (это попадает в отчёт для модели как замечание к описанию
# зависимостей, но фаза 2 всё равно запускается).

DEPS_DIRNAME=".deps"
DEPS_STEP_TIMEOUT="${DEPS_STEP_TIMEOUT:-240}"

# Переменные окружения для фазы 2 (и для самой установки), чтобы тулчейны
# находили скачанное в .deps/. Печатает строки VAR=value.
deps_env() {
  local work="${1:?work_dir}"
  local d="${work}/${DEPS_DIRNAME}"
  echo "PYTHONPATH=${d}/python${PYTHONPATH:+:${PYTHONPATH}}"
  echo "PIP_TARGET=${d}/python"
  echo "MAVEN_OPTS=-Dmaven.repo.local=${d}/m2${MAVEN_OPTS:+ ${MAVEN_OPTS}}"
  echo "GRADLE_USER_HOME=${d}/gradle"
  echo "NUGET_PACKAGES=${d}/nuget"
  echo "DOTNET_CLI_HOME=${d}/dotnet"
  echo "CARGO_HOME=${d}/cargo"
  echo "GOMODCACHE=${d}/go"
  echo "GOPATH=${d}/gopath"
  echo "npm_config_cache=${d}/npm"
}

_deps_run() {
  # _deps_run <описание> <cwd> <команда...>
  local desc="$1" cwd="$2"; shift 2
  local out rc
  echo "--- ${desc}"
  echo "    $ $*"
  out="$( (cd "${cwd}" && timeout "${DEPS_STEP_TIMEOUT}" "$@") 2>&1 )"
  rc=$?
  if [ -n "${out}" ]; then
    printf '%s\n' "${out}" | tail -n 12 | cut -c1-200 | sed 's/^/    /'
  fi
  if [ "${rc}" -eq 124 ]; then
    echo "    РЕЗУЛЬТАТ: таймаут ${DEPS_STEP_TIMEOUT}с."
    return 1
  elif [ "${rc}" -ne 0 ]; then
    echo "    РЕЗУЛЬТАТ: код ${rc}."
    return 1
  fi
  echo "    РЕЗУЛЬТАТ: успешно."
  return 0
}

# Ищет манифест в корне и на один уровень ниже (без служебных каталогов).
_deps_find() {
  local work="$1"; shift
  find "${work}" -maxdepth 2 -type f \( "$@" \) \
    -not -path "*/${DEPS_DIRNAME}/*" -not -path '*/node_modules/*' \
    -not -path '*/.git/*' -not -path '*/target/*' -not -path '*/build/*' \
    -not -path '*/.venv/*' 2>/dev/null | sort
}

install_deps() {
  local work="${1:?work_dir}"
  work="$(cd "${work}" && pwd)"
  local d="${work}/${DEPS_DIRNAME}"
  mkdir -p "${d}"
  local failed=0 did=0 f

  # Окружение для установки — то же, что будет во второй фазе.
  local line
  while IFS= read -r line; do
    export "${line?}"
  done < <(deps_env "${work}")

  echo "Фаза установки зависимостей (с сетью, без секретов). Кэши: ${DEPS_DIRNAME}/"
  echo

  # 0. Собственный скрипт студента — полностью заменяет стандартные шаги.
  if [ -f "${work}/install-deps.sh" ]; then
    did=1
    _deps_run "install-deps.sh студента" "${work}" bash install-deps.sh || failed=1
    echo
    echo "Итог: выполнен собственный install-deps.sh$([ "${failed}" -eq 0 ] && echo ' (успешно)' || echo ' (С ОШИБКОЙ)')."
    return "${failed}"
  fi

  # 1. Python.
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    did=1
    _deps_run "pip: $(realpath --relative-to="${work}" "${f}")" "$(dirname "${f}")" \
      pip3 install --quiet --disable-pip-version-check --no-cache-dir \
        --target "${d}/python" -r "${f}" || failed=1
  done < <(_deps_find "${work}" -name 'requirements*.txt')

  # 2. Maven.
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    did=1
    _deps_run "maven: $(realpath --relative-to="${work}" "${f}")" "$(dirname "${f}")" \
      mvn -q -B -Dmaven.repo.local="${d}/m2" dependency:go-offline || failed=1
  done < <(_deps_find "${work}" -name 'pom.xml')

  # 3. Gradle (wrapper предпочтительнее — версия из проекта).
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    did=1
    local gdir; gdir="$(dirname "${f}")"
    if [ -x "${gdir}/gradlew" ]; then
      _deps_run "gradle: $(realpath --relative-to="${work}" "${f}")" "${gdir}" \
        ./gradlew -q --no-daemon dependencies || failed=1
    elif command -v gradle >/dev/null 2>&1; then
      _deps_run "gradle: $(realpath --relative-to="${work}" "${f}")" "${gdir}" \
        gradle -q --no-daemon dependencies || failed=1
    else
      echo "--- gradle: $(realpath --relative-to="${work}" "${f}")"
      echo "    gradle не установлен в образе и нет gradlew — добавьте wrapper в репозиторий."
      failed=1
    fi
  done < <(_deps_find "${work}" \( -name 'build.gradle' -o -name 'build.gradle.kts' \))

  # 4. npm.
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    did=1
    local ndir; ndir="$(dirname "${f}")"
    if [ -f "${ndir}/package-lock.json" ]; then
      _deps_run "npm ci: $(realpath --relative-to="${work}" "${f}")" "${ndir}" npm ci --silent --no-audit --no-fund || failed=1
    else
      _deps_run "npm install: $(realpath --relative-to="${work}" "${f}")" "${ndir}" npm install --silent --no-audit --no-fund || failed=1
    fi
  done < <(_deps_find "${work}" -name 'package.json')

  # 5. .NET.
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    did=1
    _deps_run "dotnet restore: $(realpath --relative-to="${work}" "${f}")" "$(dirname "${f}")" \
      dotnet restore --verbosity quiet "${f}" || failed=1
  done < <(_deps_find "${work}" \( -name '*.csproj' -o -name '*.fsproj' -o -name '*.sln' \))

  # 6. Rust / Go — если тулчейн есть в образе.
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    did=1
    if command -v cargo >/dev/null 2>&1; then
      _deps_run "cargo fetch: $(realpath --relative-to="${work}" "${f}")" "$(dirname "${f}")" cargo fetch --quiet || failed=1
    else
      echo "--- cargo: $(realpath --relative-to="${work}" "${f}")"; echo "    cargo не установлен в образе."; failed=1
    fi
  done < <(_deps_find "${work}" -name 'Cargo.toml')
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    did=1
    if command -v go >/dev/null 2>&1; then
      _deps_run "go mod download: $(realpath --relative-to="${work}" "${f}")" "$(dirname "${f}")" go mod download || failed=1
    else
      echo "--- go: $(realpath --relative-to="${work}" "${f}")"; echo "    go не установлен в образе."; failed=1
    fi
  done < <(_deps_find "${work}" -name 'go.mod')

  # 7. ANTLR-jar по пути из compile.sh. Скачивать не нужно — та же версия
  # уже в образе; копируем, чтобы скрипт студента нашёл её там, где ждёт.
  if [ -f "${work}/compile.sh" ] && [ -n "${ANTLR_JAR:-}" ] && [ -f "${ANTLR_JAR}" ]; then
    local jar_rel
    while IFS= read -r jar_rel; do
      [ -n "${jar_rel}" ] || continue
      case "${jar_rel}" in /*|~*|\$*) continue ;; esac
      if [ ! -f "${work}/${jar_rel}" ]; then
        did=1
        echo "--- antlr jar: compile.sh ожидает ${jar_rel}"
        mkdir -p "$(dirname "${work}/${jar_rel}")"
        if cp "${ANTLR_JAR}" "${work}/${jar_rel}"; then
          echo "    Положена копия $(basename "${ANTLR_JAR}") из образа (скачивание не требуется)."
        else
          echo "    Не удалось скопировать jar."; failed=1
        fi
      fi
    done < <(grep -oE '[A-Za-z0-9_./-]*antlr-?[0-9.]*-complete\.jar' "${work}/compile.sh" | sort -u)
  fi

  echo
  if [ "${did}" -eq 0 ]; then
    echo "Итог: манифестов зависимостей не найдено — используется только то, что есть в образе."
    return 0
  fi
  if [ "${failed}" -ne 0 ]; then
    echo "Итог: часть шагов установки завершилась с ошибкой (см. выше). compile.sh будет запущен как есть."
    return 1
  fi
  echo "Итог: зависимости установлены."
  return 0
}

# При прямом запуске — выполнить установку.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  set -uo pipefail
  install_deps "${1:?work_dir is required}"
fi
