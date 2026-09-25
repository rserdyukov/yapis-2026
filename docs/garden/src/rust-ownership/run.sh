#!/usr/bin/env bash
# Запуск примеров статьи «Rust: владение и заимствование».
# Запускать из этой папки: bash run.sh
set -u
cd "$(dirname "$0")"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

echo "### Ожидаемые ошибки компиляции"
for f in move_error borrow_conflict dangling no_lifetime; do
  echo "=== $f.rs (rustc должен отказать)"
  rustc --edition 2024 -o "$OUT/$f" "$f.rs" 2>&1 && echo "НЕОЖИДАННО: скомпилировалось"
done

echo
echo "### Корректные программы"
for f in mut_ref lifetimes drop_order rc_refcell; do
  echo "=== $f.rs"
  rustc --edition 2024 -o "$OUT/$f" "$f.rs" && "$OUT/$f" 2>&1
  echo "(код выхода: $?)"
done

echo
echo "### C: use-after-free (поведение не определено, вывод может отличаться)"
if command -v clang >/dev/null 2>&1; then
  clang --analyze -o /dev/null use_after_free.c 2>&1
  clang -Wall -o "$OUT/uaf" use_after_free.c && "$OUT/uaf" | od -c | head -n 3
else
  echo "clang не найден: clang -Wall use_after_free.c && ./a.out"
fi

echo
echo "### C++: unique_ptr и std::move"
if command -v clang++ >/dev/null 2>&1; then
  clang++ -std=c++17 -Wall -o "$OUT/up" unique_ptr.cpp && "$OUT/up"
else
  echo "clang++ не найден: clang++ -std=c++17 unique_ptr.cpp && ./a.out"
fi
