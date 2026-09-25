#!/usr/bin/env bash
# Запускает все примеры статьи «JavaScript: цена обратной совместимости».
# Нужен node (проверено на 22.x). Файлы .cjs — нестрогий CommonJS-скрипт,
# .mjs — модуль ES (всегда строгий).
set -u
cd "$(dirname "$0")"

for f in equality.cjs asi.cjs scope.cjs this.cjs strict.cjs module.mjs legacy.cjs tailcall.cjs; do
  echo "== node $f"
  node "$f"
done
