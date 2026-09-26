"""Сборка файлов playground компилятора FSM (docs/playground/).

Хук MkDocs (site_hooks.on_post_build) кладёт в site/playground/:

* ``fsmc-bundle.zip`` — компилятор ``examples/atm-lang/fsmc`` и чистые
  Python-пакеты ``antlr4`` и ``lark`` из текущего окружения. Pyodide
  распаковывает архив в свою файловую систему, так что в браузере работает
  тот же код, что в CLI и тестах, а PyPI во время работы страницы не нужен;
* ``fsm-host.mjs`` — JS-хост, общий с ``runtime/run.mjs``;
* ``examples.json`` — примеры, сценарии и негативные тесты для меню.

Исходники для сборки уже в git, поэтому ничего из этого не коммитится.

    python3 tools/playground_bundle.py site/playground   # собрать вручную
"""

from __future__ import annotations

import importlib.metadata
import importlib.util
import json
import re
import shutil
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANG = ROOT / "examples" / "atm-lang"
# Версии обязаны совпадать с examples/atm-lang/requirements.txt: сборка
# с другой версией ANTLR runtime не прочтёт сгенерированный парсер.
PACKAGES = {"antlr4": "antlr4-python3-runtime", "lark": "lark"}


def pinned_versions() -> dict[str, str]:
    pins = {}
    for line in (LANG / "requirements.txt").read_text(encoding="utf-8").splitlines():
        m = re.match(r"^([A-Za-z0-9_.-]+)==(\S+)", line.strip())
        if m:
            pins[m.group(1)] = m.group(2)
    return pins


def _package_dir(module: str) -> Path:
    spec = importlib.util.find_spec(module)
    if spec is None or not spec.submodule_search_locations:
        raise RuntimeError(f"для playground нужен пакет {PACKAGES[module]}: "
                           "pip install -r docs/requirements.txt")
    return Path(next(iter(spec.submodule_search_locations)))


def _add_tree(zf: zipfile.ZipFile, src: Path, arcroot: str, suffixes: tuple[str, ...]) -> None:
    for path in sorted(src.rglob("*")):
        if "__pycache__" in path.parts or not path.is_file() or path.suffix not in suffixes:
            continue
        info = zipfile.ZipInfo(f"{arcroot}/{path.relative_to(src).as_posix()}",
                               date_time=(2026, 1, 1, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        zf.writestr(info, path.read_bytes())


def build_bundle(out: Path) -> None:
    pins = pinned_versions()
    for module, dist in PACKAGES.items():
        have = importlib.metadata.version(dist)
        if have != pins[dist]:
            raise RuntimeError(f"{dist}: установлена {have}, а компилятор рассчитан на "
                               f"{pins[dist]} (examples/atm-lang/requirements.txt)")
    # Архив детерминирован (фиксированные даты, сортировка): повторная
    # сборка даёт тот же файл, браузер не качает его заново без причины.
    with zipfile.ZipFile(out, "w") as zf:
        _add_tree(zf, LANG / "fsmc", "fsmc", (".py", ".lark"))
        for module in PACKAGES:
            _add_tree(zf, _package_dir(module), module, (".py", ".lark"))


def _title(source: str, fallback: str) -> str:
    for line in source.splitlines():
        line = line.strip()
        if line.startswith("//"):
            return line.lstrip("/ ").rstrip(".")
        if line:
            break
    return fallback


def build_examples() -> list[dict]:
    items = []
    atm_scenarios = {p.stem: p.read_text(encoding="utf-8")
                     for p in sorted((LANG / "scenarios").glob("*.events"))}
    for path in sorted((LANG / "examples").glob("*.fsm"), key=lambda p: p.name != "atm.fsm"):
        source = path.read_text(encoding="utf-8")
        scenarios = dict(atm_scenarios) if path.name == "atm.fsm" else {}
        own = path.with_suffix(".events")
        if own.exists():
            scenarios[own.stem] = own.read_text(encoding="utf-8")
        items.append({"id": path.stem, "group": "Примеры", "title": _title(source, path.stem),
                      "source": source, "scenarios": scenarios})
    for path in sorted((LANG / "tests" / "negative").glob("*.fsm")):
        source = path.read_text(encoding="utf-8")
        items.append({"id": path.stem, "group": "Негативные тесты",
                      "title": f"{path.stem}: {_title(source, path.stem)}",
                      "source": source, "scenarios": {}})
    return items


def build(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    build_bundle(out_dir / "fsmc-bundle.zip")
    shutil.copyfile(LANG / "runtime" / "fsm-host.mjs", out_dir / "fsm-host.mjs")
    (out_dir / "examples.json").write_text(
        json.dumps(build_examples(), ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    build(Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "site" / "playground")
