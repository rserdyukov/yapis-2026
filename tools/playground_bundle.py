"""Сборка Python-бандлов для страниц сайта, которые работают в Pyodide.

Playground компилятора FSM (docs/playground/). Хук MkDocs
(site_hooks.on_post_build) кладёт в site/playground/:

* ``fsmc-bundle.zip`` — компилятор ``examples/switchyard/fsmc`` (git submodule
  rserdyukov/yapis-example-switchyard) и чистые
  Python-пакеты ``antlr4`` и ``lark`` из текущего окружения. Pyodide
  распаковывает архив в свою файловую систему, так что в браузере работает
  тот же код, что в CLI и тестах, а PyPI во время работы страницы не нужен;
* ``fsm-host.mjs`` — JS-хост, общий с ``runtime/run.mjs``;
* ``examples.json`` — примеры, сценарии и негативные тесты для меню.

Самопроверка задачи 3 (docs/practice/task3-check/): в
site/practice/task3-check/ кладутся ``grammarlab-bundle.zip`` (пакет
``examples/grammar-lab/grammarlab`` и ``lark``) и ``examples.json`` —
эталонные ответы из ``tests/fixtures``.

Исходники для сборки уже в git, поэтому ничего из этого не коммитится.

    python3 tools/playground_bundle.py site/playground   # собрать вручную
    python3 tools/playground_bundle.py --grammarlab site/practice/task3-check
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
LANG = ROOT / "examples" / "switchyard"  # git submodule
GRAMMARLAB = ROOT / "examples" / "grammar-lab"
# Версии обязаны совпадать с examples/switchyard/requirements.txt: сборка
# с другой версией ANTLR runtime не прочтёт сгенерированный парсер.
PACKAGES = {"antlr4": "antlr4-python3-runtime", "lark": "lark"}


def pinned_versions(project: Path = LANG) -> dict[str, str]:
    pins = {}
    for line in (project / "requirements.txt").read_text(encoding="utf-8").splitlines():
        m = re.match(r"^([A-Za-z0-9_.-]+)==(\S+)", line.strip())
        if m:
            pins[m.group(1)] = m.group(2)
    return pins


def _package_dir(module: str) -> Path:
    spec = importlib.util.find_spec(module)
    if spec is None or not spec.submodule_search_locations:
        raise RuntimeError(f"для сборки сайта нужен пакет {PACKAGES[module]}: "
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


def bundle(out: Path, project: Path, package: str, modules: tuple[str, ...]) -> None:
    """Zip: пакет проекта и чистые Python-зависимости из текущего окружения.

    Версии зависимостей сверяются с requirements.txt проекта.
    """
    pins = pinned_versions(project)
    for module in modules:
        dist = PACKAGES[module]
        have = importlib.metadata.version(dist)
        if dist not in pins:
            raise RuntimeError(f"{dist}: нет пина в {project.relative_to(ROOT)}/requirements.txt")
        if have != pins[dist]:
            raise RuntimeError(f"{dist}: установлена {have}, а {project.name} рассчитан на "
                               f"{pins[dist]} ({project.relative_to(ROOT)}/requirements.txt)")
    # Архив детерминирован (фиксированные даты, сортировка): повторная
    # сборка даёт тот же файл, браузер не качает его заново без причины.
    with zipfile.ZipFile(out, "w") as zf:
        _add_tree(zf, project / package, package, (".py", ".lark"))
        for module in modules:
            _add_tree(zf, _package_dir(module), module, (".py", ".lark"))


def build_bundle(out: Path) -> None:
    bundle(out, LANG, "fsmc", ("antlr4", "lark"))


def _title(source: str, fallback: str) -> str:
    for line in source.splitlines():
        line = line.strip()
        if line.startswith("//"):
            return line.lstrip("/ ").rstrip(".")
        if line:
            break
    return fallback


def _kind(source: str) -> str:
    """Первое значимое слово файла: machine, module или system."""
    return re.sub(r"//[^\n]*", "", source).split(None, 1)[0]


def build_examples() -> list[dict]:
    """Примеры для меню. Модули (module) отдельными пунктами не показываются:
    они уходят в ``files`` программы из того же каталога, чтобы её import
    находил их в браузере так же, как в CLI."""
    items = []
    atm_scenarios = {p.stem: p.read_text(encoding="utf-8")
                     for p in sorted((LANG / "scenarios").glob("*.events"))}
    root = LANG / "examples"
    paths = sorted(root.rglob("*.fsm"),
                   key=lambda p: (p.name != "atm.fsm", p.name != "features.fsm",
                                  p.relative_to(root).as_posix()))
    for path in paths:
        source = path.read_text(encoding="utf-8")
        if _kind(source) == "module":
            continue
        scenarios = dict(atm_scenarios) if path.name == "atm.fsm" else {}
        own = path.with_suffix(".events")
        if own.exists():
            scenarios[own.stem] = own.read_text(encoding="utf-8")
        files = {p.name: p.read_text(encoding="utf-8") for p in sorted(path.parent.glob("*.fsm"))
                 if p != path and _kind(p.read_text(encoding="utf-8")) == "module"}
        items.append({"id": path.stem, "group": "Примеры", "title": _title(source, path.stem),
                      "source": source, "scenarios": scenarios, "files": files})
    for path in sorted((LANG / "tests" / "negative").glob("*.fsm")):
        source = path.read_text(encoding="utf-8")
        items.append({"id": path.stem, "group": "Негативные тесты",
                      "title": f"{path.stem}: {_title(source, path.stem)}",
                      "source": source, "scenarios": {}, "files": {}})
    return items


def build(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    build_bundle(out_dir / "fsmc-bundle.zip")
    shutil.copyfile(LANG / "runtime" / "fsm-host.mjs", out_dir / "fsm-host.mjs")
    (out_dir / "examples.json").write_text(
        json.dumps(build_examples(), ensure_ascii=False, indent=1), encoding="utf-8")


def grammarlab_examples() -> list[dict]:
    """Эталонные ответы из tests/fixtures — примеры в меню страницы.
    Заголовок — первая строка-комментарий файла."""
    items = []
    for path in sorted((GRAMMARLAB / "tests" / "fixtures").glob("*.txt")):
        source = path.read_text(encoding="utf-8")
        title = source.splitlines()[0].lstrip("# ").split(":")[0] if source.startswith("#") else path.stem
        items.append({"id": path.stem, "title": title, "source": source})
    return items


def build_grammarlab(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    bundle(out_dir / "grammarlab-bundle.zip", GRAMMARLAB, "grammarlab", ("lark",))
    (out_dir / "examples.json").write_text(
        json.dumps(grammarlab_examples(), ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["--grammarlab"]:
        build_grammarlab(Path(args[1]) if len(args) > 1 else ROOT / "site" / "practice" / "task3-check")
    else:
        build(Path(args[0]) if args else ROOT / "site" / "playground")
