#!/usr/bin/env bash
# Распознавание СГЕНЕРИРОВАННЫХ файлов в работе студента.
#
# ЗАЧЕМ. Начиная с ЛР3 студенты на Python/JS/C# коммитят вывод ANTLR:
# <Grammar>Lexer.py, <Grammar>Parser.py и т.п. Один такой парсер — это
# 4000+ строк, из них одна строка — сериализованный ATN на десятки килобайт.
# Если считать эти файлы обычным кодом, то:
#   - PR превышает MAX_DIFF_LINES и ревью пропускается целиком, хотя
#     собственно рукописного кода там на 500-1000 строк (реальный случай:
#     yapis-2026-321702-semenido#3 — 5439 строк, из них 4352 сгенерированы);
#   - в промпт вместо кода студента попадают тысячи строк таблиц переходов.
#
# Поэтому размер PR (discover.sh) и diff для промпта (review-pr.sh)
# считаются БЕЗ этих файлов, а список отфильтрованных файлов передаётся
# модели отдельной строкой: коммитить сгенерированное — само по себе
# замечание (в репозитории должен лежать .g4 и команда генерации, а не
# результат).
#
# Использование (source, затем):
#   is_generated_path <путь>      — код 0, если путь похож на сгенерированный
#   filter_generated_numstat      — stdin: строки `git diff --numstat`
#                                   (added<TAB>deleted<TAB>path);
#                                   stdout: только НЕсгенерированные
#   list_generated_numstat        — stdin: то же; stdout: только сгенерированные
#
# Критерий — только по пути, содержимое не читается: это должно одинаково
# работать и на GitHub API (где есть лишь список файлов), и локально.

# Каталоги сборки и зависимостей — всё внутри них считается сгенерированным.
GENERATED_DIR_RE='(^|/)(target|build|out|bin|obj|dist|node_modules|__pycache__|\.venv|venv|\.gradle|\.idea|\.vs|gen|generated|antlr-gen|\.antlr)(/|$)'

# Файлы, которые порождает ANTLR (все таргеты) и типовые артефакты сборки.
#   <Name>Lexer.<ext> / <Name>Parser.<ext> / <Name>Listener / <Name>Visitor /
#   <Name>BaseListener / <Name>BaseVisitor — стандартные имена ANTLR;
#   *.interp, *.tokens — служебные файлы ANTLR;
#   *.pyc, *.class, *.jar, *.dll, *.exe, *.o, *.wasm — бинарные артефакты;
#   package-lock.json, yarn.lock, poetry.lock — lock-файлы зависимостей.
GENERATED_FILE_RE='(^|/)([A-Za-z0-9_]+(Lexer|Parser|Listener|Visitor|BaseListener|BaseVisitor)\.(py|js|ts|cs|java|go|cpp|h|hpp|swift|dart|php|kt)|[A-Za-z0-9_]+\.(interp|tokens|pyc|class|jar|dll|exe|o|obj|wasm)|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|Pipfile\.lock)$'

is_generated_path() {
  local p="${1:-}"
  [ -n "${p}" ] || return 1
  if printf '%s' "${p}" | grep -qE "${GENERATED_DIR_RE}"; then
    return 0
  fi
  if printf '%s' "${p}" | grep -qE "${GENERATED_FILE_RE}"; then
    return 0
  fi
  return 1
}

# Вход — numstat (added<TAB>deleted<TAB>path), бинарные файлы приходят как
# "-<TAB>-<TAB>path" и тоже проходят через фильтр.
filter_generated_numstat() {
  local a d p
  while IFS=$'\t' read -r a d p; do
    [ -n "${p}" ] || continue
    if ! is_generated_path "${p}"; then
      printf '%s\t%s\t%s\n' "${a}" "${d}" "${p}"
    fi
  done
}

list_generated_numstat() {
  local a d p
  while IFS=$'\t' read -r a d p; do
    [ -n "${p}" ] || continue
    if is_generated_path "${p}"; then
      printf '%s\t%s\t%s\n' "${a}" "${d}" "${p}"
    fi
  done
}

# Суммирует added+deleted по numstat со stdin; "-" (бинарные) считаются 0.
sum_numstat_lines() {
  awk -F'\t' '{ if ($1 != "-") a += $1; if ($2 != "-") d += $2 } END { print a + d + 0 }'
}

# Печатает список сгенерированных путей из numstat, по одному в строке,
# без счётчиков — для передачи в build-prompt.sh.
generated_paths_from_numstat() {
  list_generated_numstat | awk -F'\t' '{ print $3 }'
}

# Человекочитаемый список файлов из numstat со stdin: «  +12 -3  path».
# Бинарные файлы (numstat даёт "-") помечаются словом, а не «+- --».
format_numstat() {
  awk -F'\t' '{
    if ($1 == "-") printf "  (бинарный)  %s\n", $3
    else           printf "  +%s -%s  %s\n", $1, $2, $3
  }'
}

# Готовит файл diff для промпта: список изменённых файлов (без
# сгенерированных), список сгенерированных отдельно и сам diff без них.
#   build_review_diff <repo_dir> <base> <head> <work_dir> <numstat_file> <out_file>
# numstat_file должен быть уже заполнен `git diff --numstat base head -- work_dir`.
build_review_diff() {
  local repo_dir="$1" base="$2" head="$3" work_dir="$4" numstat="$5" out="$6"
  local gen_count exclude=() p
  gen_count="$(list_generated_numstat < "${numstat}" | wc -l | tr -d ' ')"
  # Исключение через pathspec ':(exclude,top)…' — git diff не умеет
  # --pathspec-from-file. Сгенерированных файлов единицы; ограничиваем 200,
  # чтобы заведомо уложиться в argv.
  while IFS= read -r p; do
    [ -n "${p}" ] && exclude+=(":(exclude,top)${p}")
  done < <(generated_paths_from_numstat < "${numstat}" | head -n 200)
  {
    echo "### Список изменённых файлов (добавлено/удалено строк)"
    echo
    filter_generated_numstat < "${numstat}" | format_numstat
    if [ "${gen_count}" -gt 0 ]; then
      echo
      echo "### Сгенерированные файлы (исключены из diff, ${gen_count} шт.)"
      echo
      list_generated_numstat < "${numstat}" | format_numstat
    fi
    echo
    echo "### Полный diff (без сгенерированных файлов)"
    echo
    # ${exclude[@]+…}: при пустом массиве (нет сгенерированных файлов — частый
    # случай) bash < 4.4 под `set -u` считает "${exclude[@]}" unbound variable
    # и завершает весь скрипт; а ошибку не видно из-за 2>/dev/null ниже.
    # Это /bin/bash 3.2 на macOS, т. е. локальный review-local.sh.
    git -C "${repo_dir}" diff "${base}" "${head}" -- "${work_dir}" ${exclude[@]+"${exclude[@]}"}
  } > "${out}" 2>/dev/null
}
