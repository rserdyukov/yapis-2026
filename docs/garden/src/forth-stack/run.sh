#!/usr/bin/env bash
# Примеры статьи «Forth: стек вместо синтаксиса». Запуск: bash run.sh (из этой папки).
set -u
cd "$(dirname "$0")"

echo "### miniforth.py — учебное подмножество Forth ($(python3 --version))"
for f in arith stack square factorial immediate untyped; do
  echo "--- $f.fs"
  python3 miniforth.py "$f.fs"
done

echo
echo "### Стековые машины-цели компилятора"
echo "--- CPython: dis"
python3 dis_expr.py
if command -v javac >/dev/null && command -v javap >/dev/null; then
  echo "--- JVM: javap -c"
  tmp=$(mktemp -d)
  javac -d "$tmp" Expr.java && java -cp "$tmp" Expr \
    && javap -c -cp "$tmp" Expr | sed -n '/static int f/,/ireturn/p'
  rm -rf "$tmp"
else
  echo "(javac/javap не найдены — пропущено)"
fi

echo
echo "### Нужен настоящий Forth (miniforth.py эти слова не поддерживает)"
for f in loop does; do
  if command -v gforth >/dev/null; then
    echo "--- gforth $f.fs"
    gforth "$f.fs" -e bye
  else
    echo "--- не запускалось: gforth $f.fs -e bye"
  fi
done
