#!/usr/bin/env bash
# Проверка раскладки репозитория по GUIDE.md («Структура репозитория»):
#
#   compiler/   — исходный код компилятора (грамматика, лексер, парсер,
#                 семантика, генерация);
#   examples/   — примеры программ;
#   doc/        — отчёт;
#   compile.sh  — в корне.
#
# ЗАЧЕМ. Модель по промпту «в compiler/ или аналогичной директории»
# пропускала analyzer.py в корне репозитория (semenido#3). Расположение —
# факт, который дешевле проверить скриптом и отдать модели готовым.
#
# Использование: source layout-check.sh; check_layout <work_dir>
# Печатает отчёт; возвращает 0, если исходники лежат в compiler/, иначе 1.

# Расширения исходников компилятора. Не включаем .sh (compile.sh в корне —
# норма), .md (документы), .txt (примеры), конфиги сборки (pom.xml,
# package.json, requirements.txt — их место в корне тоже нормально).
LAYOUT_SOURCE_EXT_RE='\.(py|java|kt|kts|scala|cs|fs|js|mjs|ts|go|rs|c|cc|cpp|h|hpp|swift|dart|php|rb|hs|ml|g4)$'

check_layout() {
  local work="${1:?work_dir}"
  work="$(cd "${work}" && pwd)"
  local status=0

  echo "Раскладка (GUIDE.md, раздел «Структура репозитория»): compiler/ — код, examples/ — примеры, doc/ — отчёт, compile.sh — в корне."

  if [ -d "${work}/compiler" ]; then
    echo "  compiler/: есть, файлов исходников — $(find "${work}/compiler" -type f | grep -cE "${LAYOUT_SOURCE_EXT_RE}")."
  else
    echo "  compiler/: НЕТ. Исходный код компилятора должен лежать в compiler/."
    status=1
  fi

  # Исходники вне compiler/: ищем в корне и в каталогах, не являющихся
  # служебными. Сгенерированные/зависимости/тесты не считаем.
  local stray
  stray="$(cd "${work}" && find . -type f \
      -not -path './compiler/*' -not -path './.git/*' -not -path './.deps/*' \
      -not -path './.github/*' -not -path './.review/*' \
      -not -path './examples/*' -not -path './doc/*' -not -path './docs/*' \
      -not -path './node_modules/*' -not -path './.venv/*' -not -path './venv/*' \
      -not -path './target/*' -not -path './build/*' -not -path './out/*' \
      -not -path './bin/*' -not -path './obj/*' -not -path './__pycache__/*' \
      -not -path './tools/*' -not -path './tests/*' -not -path './test/*' \
      2>/dev/null | grep -E "${LAYOUT_SOURCE_EXT_RE}" | sed 's#^\./##' | sort | head -n 20)"

  if [ -n "${stray}" ]; then
    echo "  ЗАМЕЧАНИЕ: исходники компилятора ВНЕ compiler/ (по GUIDE.md им место в compiler/):"
    printf '%s\n' "${stray}" | sed 's/^/    /'
    status=1
  else
    echo "  Исходников вне compiler/ не найдено."
  fi

  if [ -f "${work}/compile.sh" ]; then
    echo "  compile.sh: в корне, как требуется."
  else
    # Отсутствие compile.sh уже проверяет compile-check.sh; здесь — только
    # случай «лежит, но не там».
    local misplaced
    misplaced="$(cd "${work}" && find . -maxdepth 3 -name 'compile.sh' -not -path './.git/*' -not -path './.deps/*' 2>/dev/null | sed 's#^\./##' | head -n 3)"
    if [ -n "${misplaced}" ]; then
      echo "  ЗАМЕЧАНИЕ: compile.sh найден не в корне: ${misplaced//$'\n'/, }. По GUIDE.md он должен быть в корне репозитория."
      status=1
    fi
  fi

  return "${status}"
}
