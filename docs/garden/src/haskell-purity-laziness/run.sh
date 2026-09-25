#!/usr/bin/env bash
# Запуск примеров статьи «Haskell: чистота и ленивость».
# Запускать из этой папки: bash run.sh
set -u
cd "$(dirname "$0")"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

echo "### Haskell (нужен GHC)"
for f in Pure Infinite Undefined SpaceLeak; do
  echo "=== $f.hs"
  if command -v runghc >/dev/null 2>&1; then
    runghc "$f.hs" 2>&1
    echo "(код выхода: $?)"
  else
    echo "GHC не найден. Команда: runghc $f.hs"
    echo "  (для SpaceLeak.hs сравните память: ghc -O0 -rtsopts SpaceLeak.hs && ./SpaceLeak +RTS -s)"
  fi
done

echo
echo "### Python: строгие аргументы и генераторы"
python3 lazy_gen.py

echo
echo "### JavaScript: строгие аргументы, генераторы и thunk"
node lazy_gen.js

echo
echo "### Rust: ленивые адаптеры итераторов"
rustc --edition 2024 -o "$OUT/lazy_iter" lazy_iter.rs 2>&1 && "$OUT/lazy_iter"
