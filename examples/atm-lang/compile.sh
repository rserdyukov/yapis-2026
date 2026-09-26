#!/usr/bin/env bash
# Точка входа, как в лабораторных: ./compile.sh <файл.fsm> [сценарий.events]
#
#   ./compile.sh examples/atm.fsm                              # компиляция в build/
#   ./compile.sh examples/atm.fsm scenarios/01_success.events  # и запуск в Node
#   FSMC_FRONTEND=lark ./compile.sh examples/atm.fsm           # через Lark
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
if [ $# -lt 1 ]; then
  echo "использование: $0 <файл.fsm> [сценарий.events]" >&2
  exit 2
fi
python="${PYTHON:-python3}"
src="$1"
PYTHONPATH="${here}${PYTHONPATH:+:$PYTHONPATH}" \
  "$python" -m fsmc "$src" -o "${here}/build" --frontend "${FSMC_FRONTEND:-antlr}"

if [ $# -ge 2 ]; then
  wasm="${here}/build/$(basename "${src%.*}").wasm"
  node "${here}/runtime/run.mjs" "$wasm" "$2"
fi
