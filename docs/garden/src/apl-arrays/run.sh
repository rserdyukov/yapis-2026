#!/usr/bin/env bash
# Примеры статьи «APL: нотация как инструмент мышления». Запуск: bash run.sh (из этой папки).
set -u
cd "$(dirname "$0")"

echo "### miniapl.py — учебная модель подмножества APL ($(python3 --version))"
for f in order arrays outer; do
  echo "--- $f.apl"
  python3 miniapl.py "$f.apl"
done

echo "--- parse_demo.py: деревья разбора"
PYTHONDONTWRITEBYTECODE=1 python3 parse_demo.py

echo "--- primes.py: то же на циклах Python"
python3 primes.py

echo
echo "### Нужен NumPy"
if python3 -c "import numpy" 2>/dev/null; then
  python3 numpy_equiv.py
else
  echo "--- не запускалось (нет numpy): python3 numpy_equiv.py"
fi

echo
echo "### Нужен настоящий APL (Dyalog APL): miniapl.py это не поддерживает"
for f in trains scope; do
  echo "--- не запускалось: вставить $f.apl в сессию Dyalog APL"
done
