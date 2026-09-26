"""Общее для тестов: пути, компиляция, запуск в Node."""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from fsmc import FRONTENDS, compile_source  # noqa: E402

EXAMPLES = sorted((ROOT / "examples").glob("*.fsm"))
SCENARIOS = sorted((ROOT / "scenarios").glob("*.events"))
NEGATIVE = sorted((ROOT / "tests" / "negative").glob("*.fsm"))
ATM = ROOT / "examples" / "atm.fsm"
NODE = shutil.which("node")
WAT2WASM = shutil.which("wat2wasm")


def expected_codes(path: Path) -> set[str]:
    m = re.search(r"^// expect:(.*)$", path.read_text(encoding="utf-8"), re.MULTILINE)
    if not m:
        raise AssertionError(f"{path.name}: нет строки // expect:")
    return set(m.group(1).split())


def run_node(wasm: bytes, scenario: Path) -> str:
    with tempfile.NamedTemporaryFile(suffix=".wasm", delete=False) as f:
        f.write(wasm)
        path = f.name
    try:
        out = subprocess.run([NODE, str(ROOT / "runtime" / "run.mjs"), path, str(scenario)],
                             capture_output=True, text=True, check=True, timeout=30)
        return out.stdout
    finally:
        Path(path).unlink()


def run_reference(scenario: Path) -> str:
    out = subprocess.run([sys.executable, str(ROOT / "reference" / "reference.py"),
                          str(scenario)], capture_output=True, text=True, check=True)
    return out.stdout


__all__ = ["ROOT", "EXAMPLES", "SCENARIOS", "NEGATIVE", "ATM", "NODE", "WAT2WASM",
           "FRONTENDS", "compile_source", "expected_codes", "run_node", "run_reference"]
