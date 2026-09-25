#!/usr/bin/env bash
# Примеры статьи «Zig: comptime вместо макросов».
# Запускаемые: cc (C11), clang++ (C++17), rustc. Zig и Common Lisp не установлены:
# для них скрипт только печатает команды, если компилятора нет.
set -u
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "== cc macros.c"
cc -std=c11 -o "$tmp/macros_c" macros.c && "$tmp/macros_c"

echo "== clang++ templates.cpp"
clang++ -std=c++17 -o "$tmp/templates" templates.cpp && "$tmp/templates"

echo "== clang++ template_error.cpp (ожидается ошибка компиляции)"
clang++ -std=c++17 -fsyntax-only template_error.cpp

echo "== rustc macros.rs"
rustc --edition 2021 -o "$tmp/macros_rs" macros.rs && "$tmp/macros_rs"

for f in generic comptime_eval reflection compile_error; do
  echo "== zig run $f.zig"
  if command -v zig >/dev/null 2>&1; then
    zig run "$f.zig"
  else
    echo "   zig не установлен; команда: zig run $f.zig   (код написан по Language Reference 0.16.0, не запускался)"
  fi
done

echo "== sbcl --script macros.lisp"
if command -v sbcl >/dev/null 2>&1; then
  sbcl --script macros.lisp
else
  echo "   sbcl не установлен; команда: sbcl --script macros.lisp"
fi
exit 0
