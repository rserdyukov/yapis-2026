#!/usr/bin/env bash
# Примеры статьи «Go: сознательная бедность языка».
# Запускаемые: python3, rustc. Go не установлен: для Go-примеров скрипт
# только печатает команды, если компилятора нет.
set -u
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "== python3 sum.py"
python3 sum.py

echo "== rustc sum.rs"
rustc --edition 2021 -o "$tmp/sum_rs" sum.rs && "$tmp/sum_rs"

echo "== python3 rich.py"
python3 rich.py

for f in sum loops embed concurrency generics; do
  echo "== go run $f.go"
  if command -v go >/dev/null 2>&1; then
    go run "$f.go"
  else
    echo "   go не установлен; команда: go run $f.go   (код написан по спецификации go1.27, не запускался)"
  fi
done
exit 0
