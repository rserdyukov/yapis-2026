#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
python3 compiler/mini.py "${1:?нужен файл с программой}"
