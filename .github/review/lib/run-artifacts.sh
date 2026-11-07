#!/usr/bin/env bash
# Исполнение целевого кода ЛР5: компилирует корректные примеры через
# compile.sh, запускает получившийся артефакт и сверяет вывод с ожидаемым,
# если студент его положил рядом.
#
# ЗАЧЕМ. До 03.11 проверка только искала артефакты (find), но не запускала
# их. Модель видела, что программы не исполнялись, и писала замечания
# «подтвердите вывод в отчёте» (strunets#12, pereverzev#10, rublevskaya#10:
# 5 ложных из 12), а дефекты сгенерированного кода (pereverzev P1 — `==`
# для attribute, pikta P4 — `%` над inf) не видела вовсе.
#
# Как найти артефакт. Форматы и каталоги у студентов разные (out/, build/<имя>/,
# рядом с примером), поэтому берём файлы, появившиеся после запуска
# compile.sh, и выбираем запускаемый по приоритету: исполняемый файл без
# расширения (clang) → .jar → Main.class или класс с main → .pyc → .ll (lli)
# → .dll с runtimeconfig (dotnet). .wat/.wasm и прочее не запускаем —
# пишем «не запускался проверкой».
#
# Ожидаемый вывод: <имя>.expected или <имя>.out рядом с примером, в
# tests/ или в examples/ (поиск по имени без расширения). Вход: <имя>.in
# там же, иначе пустой stdin.
#
# Использование: source run-artifacts.sh; run_artifact_checks <work_dir> <examples_dir> [max] [timeout_s]

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/compile-check.sh"

ARTIFACT_RUN_TIMEOUT="${ARTIFACT_RUN_TIMEOUT:-10}"

# Файлы, появившиеся в work_dir новее маркера (без служебных каталогов).
_art_new_files() {
  local work="$1" marker="$2"
  (cd "${work}" && find . \
      \( -path './.git' -o -path './.deps' -o -path './.review' -o -path './node_modules' \
         -o -path './.venv' -o -name '__pycache__' \) -prune -o \
      -type f -newer "${marker}" -print 2>/dev/null) | sed 's#^\./##' | sort
}

# Печатает «<вид>\t<путь>» самого подходящего для запуска артефакта.
_art_pick() {
  local work="$1" files="$2" f
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    case "${f##*/}" in *.*) continue ;; esac
    [ -x "${work}/${f}" ] && { printf 'native\t%s\n' "${f}"; return 0; }
  done <<< "${files}"
  f="$(printf '%s\n' "${files}" | grep -E '\.jar$' | head -n 1)"
  [ -n "${f}" ] && { printf 'jar\t%s\n' "${f}"; return 0; }
  f="$(printf '%s\n' "${files}" | grep -E '(^|/)Main\.class$' | head -n 1)"
  if [ -z "${f}" ] && command -v javap >/dev/null 2>&1; then
    local c
    while IFS= read -r c; do
      (cd "$(dirname "${work}/${c}")" && javap -cp . "$(basename "${c}" .class)" 2>/dev/null) \
        | grep -q 'public static void main(java.lang.String' && { f="${c}"; break; }
    done < <(printf '%s\n' "${files}" | grep -E '\.class$' | grep -v '\$' | head -n 20)
  fi
  [ -n "${f}" ] && { printf 'class\t%s\n' "${f}"; return 0; }
  f="$(printf '%s\n' "${files}" | grep -E '\.pyc$' | head -n 1)"
  [ -n "${f}" ] && { printf 'pyc\t%s\n' "${f}"; return 0; }
  f="$(printf '%s\n' "${files}" | grep -E '\.ll$' | head -n 1)"
  [ -n "${f}" ] && { printf 'll\t%s\n' "${f}"; return 0; }
  f="$(printf '%s\n' "${files}" | grep -E '\.dll$' | while IFS= read -r d; do
        [ -f "${work}/${d%.dll}.runtimeconfig.json" ] && { echo "${d}"; break; }; done)"
  [ -n "${f}" ] && { printf 'dotnet\t%s\n' "${f}"; return 0; }
  return 1
}

# Команда запуска артефакта (печатает строку для показа; сам запуск — _art_exec).
_art_cmd() {
  local kind="$1" f="$2"
  case "${kind}" in
    native) echo "./${f}" ;;
    jar)    echo "java -jar ${f}" ;;
    class)  echo "java -cp $(dirname "${f}") $(basename "${f}" .class)" ;;
    pyc)    echo "python3 ${f}" ;;
    ll)     echo "lli ${f}" ;;
    dotnet) echo "dotnet ${f}" ;;
  esac
}

_art_exec() {
  local work="$1" kind="$2" f="$3" input="$4" t="$5"
  (
    cd "${work}" || exit 125
    case "${kind}" in
      native) timeout "${t}" "./${f}" ;;
      jar)    timeout "${t}" java -jar "${f}" ;;
      class)  timeout "${t}" java -cp "$(dirname "${f}")" "$(basename "${f}" .class)" ;;
      pyc)    timeout "${t}" python3 "${f}" ;;
      ll)     if command -v lli >/dev/null 2>&1; then timeout "${t}" lli "${f}"
              else echo "ОКРУЖЕНИЕ: lli не найден"; exit 125; fi ;;
      dotnet) timeout "${t}" dotnet "${f}" ;;
    esac
  ) < "${input}"
}

# Ожидаемый вывод и вход для примера: печатает «<expected>\t<input>».
_art_expected_for() {
  local work="$1" example="$2" base dir e="" i="" cand
  base="$(basename "${example}")"; base="${base%.*}"
  dir="$(dirname "${example}")"
  for cand in "${dir}/${base}.expected" "${dir}/${base}.out"; do
    [ -f "${cand}" ] && { e="${cand}"; break; }
  done
  if [ -z "${e}" ]; then
    e="$(cd "${work}" && find tests test examples -maxdepth 3 -type f \
          \( -name "${base}.expected" -o -name "${base}.out" \) 2>/dev/null | head -n 1)"
    [ -n "${e}" ] && e="${work}/${e}"
  fi
  if [ -n "${e}" ] && [ -f "${e%.*}.in" ]; then i="${e%.*}.in"
  elif [ -f "${dir}/${base}.in" ]; then i="${dir}/${base}.in"; fi
  printf '%s\t%s\n' "${e}" "${i}"
}

run_artifact_checks() {
  local work="${1:?work_dir}" examples="${2:-}" max="${3:-6}" t="${4:-${ARTIFACT_RUN_TIMEOUT}}"
  work="$(cd "${work}" && pwd)"
  local ran=0 matched=0 diffs=0 noexp=0 notrun=0 remarks=0 start="${SECONDS}"
  if [ -z "${examples}" ] || [ ! -f "${work}/compile.sh" ]; then
    echo "Исполнение не проводилось: нет examples/ или compile.sh."
    echo "Счётчики исполнения (копируй в таблицу проверок как есть): запущено 0, совпало 0, расхождений 0, без ожидаемого вывода 0, не запускалось 0"
    return 0
  fi
  local tmp="${work}/.review/artifacts"
  mkdir -p "${tmp}"
  local -a list=()
  local ex
  while IFS= read -r ex; do list+=("${ex}"); done < <(find "${examples}" -maxdepth 1 -type f \
      -not -name 'error-*' -not -name '*.expected' -not -name '*.out' -not -name '*.in' \
      -not -name '*.md' -not -name '.*' 2>/dev/null | sort)
  local n=0
  for ex in ${list[@]+"${list[@]}"}; do
    n=$((n + 1))
    local rel="${ex#"${work}"/}"
    if [ "${n}" -gt "${max}" ]; then notrun=$((notrun + 1)); continue; fi
    # Общий таймаут check.sh — CHECK_TIMEOUT_SECONDS; исполнение идёт
    # последним и не должно его съесть.
    if [ $((SECONDS - start)) -ge "${ARTIFACT_BUDGET_SECONDS:-90}" ]; then
      echo "--- ${rel}: не запускался — исчерпан бюджет времени исполнения (${ARTIFACT_BUDGET_SECONDS:-90} с)."
      notrun=$((notrun + 1)); continue
    fi
    local marker="${tmp}/marker" files picked kind f out rc exp inp pair
    : > "${marker}"
    # mtime маркера должна быть строго раньше файлов compile.sh.
    sleep 1
    if ! (cd "${work}" && timeout 180 bash compile.sh "${rel}") > "${tmp}/compile.out" 2>&1; then
      echo "--- ${rel}: compile.sh завершился с ошибкой — исполнять нечего (см. прогон выше)."
      notrun=$((notrun + 1)); continue
    fi
    files="$(_art_new_files "${work}" "${marker}")"
    if ! picked="$(_art_pick "${work}" "${files}")"; then
      echo "--- ${rel}: запускаемый артефакт не найден среди новых файлов ($(printf '%s\n' "${files}" | grep -c . ) шт.: $(printf '%s\n' "${files}" | head -n 5 | tr '\n' ' ')) — не запускался проверкой."
      notrun=$((notrun + 1)); continue
    fi
    kind="${picked%%$'\t'*}"; f="${picked#*$'\t'}"
    pair="$(_art_expected_for "${work}" "${ex}")"
    exp="${pair%%$'\t'*}"; inp="${pair#*$'\t'}"
    [ -n "${inp}" ] || inp=/dev/null
    echo "--- ${rel}: $(_art_cmd "${kind}" "${f}")$([ "${inp}" != /dev/null ] && echo " < ${inp#"${work}"/}")"
    out="$(_art_exec "${work}" "${kind}" "${f}" "${inp}" "${t}" 2>&1)"; rc=$?
    ran=$((ran + 1))
    printf '%s\n' "${out}" | head -n 15 | sed 's/^/    | /'
    [ "$(printf '%s\n' "${out}" | wc -l)" -gt 15 ] && echo "    | … (показано 15 строк)"
    if [ "${rc}" -eq 124 ]; then
      echo "    РЕЗУЛЬТАТ: ЗАМЕЧАНИЕ — исполнение не завершилось за ${t} с (stdin: ${inp#"${work}"/})."
      remarks=$((remarks + 1))
    elif _looks_like_crash "${out}"; then
      echo "    РЕЗУЛЬТАТ: код ${rc}, трасса исключения при исполнении сгенерированного кода — проверь, не ошибка ли это генерации."
      remarks=$((remarks + 1))
    fi
    if [ -n "${exp}" ]; then
      if diff -q <(printf '%s\n' "${out}" | sed 's/[[:space:]]*$//') <(sed 's/[[:space:]]*$//' "${exp}") >/dev/null 2>&1; then
        echo "    совпадает с ${exp#"${work}"/}"; matched=$((matched + 1))
      else
        echo "    РАСХОЖДЕНИЕ с ${exp#"${work}"/} (код ${rc}; формат файла мог включать код выхода — сверь сам):"
        diff <(sed 's/[[:space:]]*$//' "${exp}") <(printf '%s\n' "${out}" | sed 's/[[:space:]]*$//') | head -n 10 | sed 's/^/      /'
        diffs=$((diffs + 1))
      fi
    else
      echo "    код ${rc}; ожидаемого вывода (${ex##*/} → .expected/.out) нет — сверь вывод с программой сам."
      noexp=$((noexp + 1))
    fi
  done
  rm -rf "${tmp}"
  rmdir "${work}/.review" 2>/dev/null || true
  echo "Счётчики исполнения (копируй в таблицу проверок как есть): запущено ${ran}, совпало ${matched}, расхождений ${diffs}, без ожидаемого вывода ${noexp}, не запускалось ${notrun}$([ "${remarks}" -gt 0 ] && echo ", трасс/таймаутов ${remarks}")"
  return 0
}
