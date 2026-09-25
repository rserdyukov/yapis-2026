#!/usr/bin/env bash
# Запуск примеров статьи «Smalltalk: всё есть сообщение».
set -u
cd "$(dirname "$0")"

run() {
  echo "== $*"
  "$@"
  echo
}

run python3 if_as_message.py
run python3 proxy.py
run node proxy.js
run python3 binary_ltr.py

echo "== Smalltalk-примеры (Boolean.st, expressions.st, LoggingProxy.st) не запускались:"
echo "   Smalltalk не установлен. Выражения из expressions.st выполняются в Pharo"
echo "   (Playground -> Print it) или из командной строки, например:"
echo "     ./pharo Pharo.image eval \"3 + 4 * 2\"     # ожидается 14"
echo "     ./pharo Pharo.image eval \"3 class class class\"   # ожидается Metaclass"
echo "   Методы из Boolean.st уже есть в образе (True, False); LoggingProxy.st"
echo "   вводится через System Browser по одному методу."
