#!/usr/bin/env python3
"""Сгенерировать Python-парсер из grammar/Fsm.g4.

Результат (fsmc/frontend_antlr/generated/) закоммичен: для запуска
компилятора, тестов и playground Java не нужна. Скрипт запускают только
после правки грамматики.

    python3 tools/gen_antlr.py          # перегенерировать
    python3 tools/gen_antlr.py --check  # убедиться, что закоммиченное актуально

Где взять ANTLR (версия обязана совпадать с antlr4-python3-runtime==4.13.2):
  * переменная ANTLR_JAR с путём к antlr-4.13.2-complete.jar;
  * или команда `antlr` / `antlr4` в PATH (brew install antlr);
  * иначе jar скачивается в ~/.cache/fsmc/ (нужна Java 11+).
"""

from __future__ import annotations

import argparse
import filecmp
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

VERSION = "4.13.2"
JAR_URL = f"https://www.antlr.org/download/antlr-{VERSION}-complete.jar"
ROOT = Path(__file__).resolve().parents[1]
GRAMMAR = ROOT / "grammar" / "Fsm.g4"
OUT = ROOT / "fsmc" / "frontend_antlr" / "generated"
# Служебные файлы ANTLR, которые парсеру не нужны.
SKIP = {".interp", ".tokens"}


def antlr_command() -> list[str]:
    jar = os.environ.get("ANTLR_JAR")
    if jar:
        return ["java", "-jar", jar]
    for name in ("antlr", "antlr4"):
        if shutil.which(name):
            return [name]
    cache = Path.home() / ".cache" / "fsmc" / f"antlr-{VERSION}-complete.jar"
    if not cache.exists():
        cache.parent.mkdir(parents=True, exist_ok=True)
        print(f"скачиваю {JAR_URL}", file=sys.stderr)
        urllib.request.urlretrieve(JAR_URL, cache)
    return ["java", "-jar", str(cache)]


def generate(out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    # Запуск из каталога грамматики: иначе ANTLR впишет в шапку
    # сгенерированных файлов абсолютный путь с машины автора.
    subprocess.run(antlr_command() + ["-Dlanguage=Python3", "-visitor", "-no-listener",
                                      "-o", str(out), "-Xexact-output-dir", GRAMMAR.name],
                   check=True, cwd=GRAMMAR.parent)
    for p in out.iterdir():
        if p.suffix in SKIP:
            p.unlink()
    (out / "__init__.py").write_text(
        f'"""Сгенерировано ANTLR {VERSION} из grammar/Fsm.g4 — не править руками.\n\n'
        'Перегенерировать: python3 tools/gen_antlr.py\n"""\n', encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    if not args.check:
        generate(OUT)
        print(f"готово: {OUT.relative_to(ROOT)}")
        return 0
    with tempfile.TemporaryDirectory() as tmp:
        fresh = Path(tmp)
        generate(fresh)
        names = sorted(p.name for p in fresh.iterdir())
        stale = [n for n in names if not (OUT / n).exists()
                 or not filecmp.cmp(fresh / n, OUT / n, shallow=False)]
        extra = sorted({p.name for p in OUT.glob("*.py")} - set(names))
    if stale or extra:
        print("сгенерированный парсер устарел: " + ", ".join(stale + extra), file=sys.stderr)
        print("запустите python3 tools/gen_antlr.py", file=sys.stderr)
        return 1
    print("сгенерированный парсер актуален")
    return 0


if __name__ == "__main__":
    sys.exit(main())
