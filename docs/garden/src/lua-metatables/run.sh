#!/usr/bin/env bash
# Запускает все примеры статьи «Lua: метатаблицы, язык как конструктор».
# Нужны: lua (5.4 или новее), node, python3.
set -u
cd "$(dirname "$0")"

for f in class vector proxy memo close dispatch; do
  echo "== lua $f.lua"
  lua "$f.lua"
done

echo "== node compare.js"
node compare.js

echo "== python3 compare.py"
python3 compare.py
