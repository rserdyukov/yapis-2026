"""Командная строка компилятора.

    python3 -m fsmc examples/atm.fsm                  # → build/atm.wat, build/atm.wasm
    python3 -m fsmc examples/atm.fsm --frontend lark  # тот же результат через Lark
    python3 -m fsmc examples/atm.fsm --emit mermaid   # диаграмма в stdout
    python3 -m fsmc examples/atm.fsm --check          # только анализ, без кода

Код возврата: 0 — успех (предупреждения допустимы), 1 — есть ошибки,
2 — неверные аргументы. С --werror предупреждения считаются ошибками.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from . import FRONTENDS, compile_source


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="fsmc", description="Компилятор языка FSM в WebAssembly")
    ap.add_argument("source", type=Path)
    ap.add_argument("-o", "--out-dir", type=Path, default=Path("build"))
    ap.add_argument("--frontend", choices=FRONTENDS, default="antlr",
                    help="чем разбирать исходник (по умолчанию antlr)")
    ap.add_argument("--emit", choices=("files", "wat", "mermaid", "meta", "json"),
                    default="files", help="что вывести: файлы в out-dir или текст в stdout")
    ap.add_argument("--check", action="store_true", help="только анализ, без генерации")
    ap.add_argument("--werror", action="store_true", help="предупреждения — тоже ошибки")
    args = ap.parse_args(argv)

    try:
        source = args.source.read_text(encoding="utf-8")
    except OSError as e:
        print(f"fsmc: {e}", file=sys.stderr)
        return 2
    r = compile_source(source, args.frontend)

    if args.emit == "json":
        print(json.dumps({"ok": r.ok, "diagnostics": [d.to_dict() for d in r.diagnostics]},
                         ensure_ascii=False, indent=2))
        return 0 if r.ok else 1

    for d in r.diagnostics:
        print(d.format(str(args.source)), file=sys.stderr)
    failed = not r.ok or (args.werror and r.diagnostics)
    if failed:
        errors = sum(d.level == "error" for d in r.diagnostics)
        print(f"fsmc: компиляция не удалась (ошибок: {errors}, "
              f"предупреждений: {len(r.diagnostics) - errors})", file=sys.stderr)
        return 1
    if args.check:
        return 0
    if args.emit == "wat":
        sys.stdout.write(r.wat)
    elif args.emit == "mermaid":
        sys.stdout.write(r.mermaid)
    elif args.emit == "meta":
        print(json.dumps(r.meta, ensure_ascii=False, indent=2))
    else:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        stem = args.out_dir / args.source.stem
        stem.with_suffix(".wat").write_text(r.wat, encoding="utf-8")
        stem.with_suffix(".wasm").write_bytes(r.wasm)
        stem.with_suffix(".mmd").write_text(r.mermaid, encoding="utf-8")
        print(f"{stem}.wat, {stem}.wasm ({len(r.wasm)} байт), {stem}.mmd")
    return 0


if __name__ == "__main__":
    sys.exit(main())
