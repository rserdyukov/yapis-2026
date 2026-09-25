#!/usr/bin/env python3
"""Run the six available semantic experiments in isolated temporary copies.

Missing toolchains are SKIP (or failure with --require-all). This runner does
not claim to execute the other nine examples documented on the site.
"""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "docs/concepts/examples/src"


def run(args, cwd, expected=None, stdin=None, rejects=()):
    result = subprocess.run(args, cwd=cwd, input=stdin, text=True,
                            capture_output=True, timeout=30)
    if rejects:
        diagnostic = result.stdout + result.stderr
        if result.returncode == 0 or not all(token in diagnostic for token in rejects):
            raise AssertionError(f"Expected rejection {rejects}: {args}\n{diagnostic}")
        return
    if result.returncode:
        raise AssertionError(f"Failed {args}: {result.returncode}\n{result.stdout}{result.stderr}")
    if expected is not None:
        # Icarus includes the source filename/time in its finish notification.
        actual = "\n".join(line for line in result.stdout.splitlines()
                           if "$finish called at" not in line)
        if actual != expected:
            raise AssertionError(f"{args}\nexpected: {expected!r}\nactual: {actual!r}")


def scheme(path):
    run(["guile", "--no-auto-compile", "--r7rs", "continuation.scm"], path, "11\n12\n13")
    run(["guile", "--no-auto-compile", "--r7rs", "hygiene.scm"], path, "(2 1)")


def icon(path):
    run(["icont", "-s", "-o", "search", "search.icn"], path)
    run(["./search"], path, "1\n9\nstored: fail\n1\n5\n9")


def sml(path):
    run(["poly", "--script", "opaque.sml"], path, "7")
    run(["poly", "--script", "transparent.sml"], path, "7")
    run(["poly", "--script", "reject.sml"], path, rejects=("A.t", "B.t", "Can't unify"))


def cobol(path):
    run(["cobc", "-x", "-free", "-o", "decimal", "decimal.cob"], path)
    run(["./decimal"], path, "012.3\n012.4\noverflow")


def verilog(path):
    run(["iverilog", "-g2012", "-s", "swap", "-o", "swap", "swap.v"], path)
    run(["vvp", "swap"], path,
        "active: a=1 b=2 x=2 y=2\nsettled: a=2 b=1 x=2 y=2")


def sql(path):
    run(["sqlite3", "-batch", "-noheader", ":memory:"], path,
        "1\n1\n2\n1\n2\nunknown", stdin=(path / "multiplicity.sql").read_text())


CASES = {
    "scheme": (scheme, ["guile"]),
    "icon": (icon, ["icont", "iconx"]),
    "sml": (sml, ["poly"]),
    "cobol": (cobol, ["cobc"]),
    "verilog": (verilog, ["iverilog", "vvp"]),
    "sql": (sql, ["sqlite3"]),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--require-all", action="store_true")
    args = parser.parse_args()
    passed = skipped = failed = 0
    with tempfile.TemporaryDirectory(prefix="yapis-examples-") as directory:
        root = Path(directory)
        for name, (check, commands) in CASES.items():
            missing = [cmd for cmd in commands if not shutil.which(cmd)]
            if missing:
                print(f"SKIP {name}: missing {', '.join(missing)}")
                skipped += 1
                continue
            path = root / name
            shutil.copytree(SOURCES / name, path)
            try:
                check(path)
            except (AssertionError, OSError, subprocess.TimeoutExpired) as error:
                failed += 1
                print(f"FAIL {name}: {error}")
            else:
                passed += 1
                print(f"PASS {name}")
    print(f"Passed: {passed}; skipped: {skipped}; failed: {failed}")
    return int(bool(failed or (args.require_all and skipped)))


if __name__ == "__main__":
    raise SystemExit(main())
