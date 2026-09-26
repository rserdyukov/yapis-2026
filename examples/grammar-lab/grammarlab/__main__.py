"""python -m grammarlab check answer.txt [--level 1|2|3] [--reveal]

Код выхода: 0 — ошибок нет, 1 — есть ошибки в ответе, 2 — ответ не разобран.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from .answer import parse_answer
from .check import STEPS, check


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="grammarlab", description="Самопроверка задачи 3 (LL(1)).")
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("check", help="проверить ответ")
    c.add_argument("file", help="файл с ответом; '-' — stdin")
    c.add_argument("--level", type=int, choices=(1, 2, 3), default=3,
                   help="1 — только число ошибок по шагам, 2 — где, 3 — почему (по умолчанию)")
    c.add_argument("--reveal", action="store_true", help="показать эталон для ошибочных элементов")
    args = ap.parse_args(argv)

    text = sys.stdin.read() if args.file == "-" else Path(args.file).read_text(encoding="utf-8")
    report = check(parse_answer(text))

    for d in report.parse:
        print(d.format())
    if any(d.level == "error" for d in report.parse):
        return 2

    by_step = report.by_step()
    for step in report.checked:
        items = by_step.get(step, [])
        errors = [f for f in items if f.severity == "error"]
        warns = [f for f in items if f.severity != "error"]
        status = "ok" if not items else f"ошибок: {len(errors)}" + (f", замечаний: {len(warns)}" if warns else "")
        print(f"{STEPS[step]}: {status}")
        if args.level >= 2:
            for f in items:
                where = f" (строка {f.line})" if f.line else ""
                mark = "!" if f.severity == "error" else "~"
                print(f"  {mark} {f.summary}{where}")
                if args.level >= 3 and f.why:
                    for line in f.why.splitlines():
                        print(f"      {line}")
                if args.reveal and f.reveal:
                    print(f"      эталон: {f.reveal}")
    print(report.verdict)
    return 1 if any(f.severity == "error" for f in report.findings) else 0


if __name__ == "__main__":
    sys.exit(main())
