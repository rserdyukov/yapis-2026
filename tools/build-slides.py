#!/usr/bin/env python3
"""Сборка лекционных слайдов Marp и страницы-индекса лекций.

Исходники колод — docs/lectures/slides/*.md (обычный Marp-markdown).
Скрипт делает две вещи:

  1. Генерирует docs/lectures/index.md — оглавление лекций со ссылками
     на собранные слайды. Заголовок берётся из первого `# ` колоды,
     номер — из имени файла.

  2. Запускает marp-cli и складывает HTML в docs/lectures/html/.
     marp-cli берётся из Docker-образа, чтобы не заводить в репозитории
     Node и node_modules. Если Docker недоступен, используется npx.

Собранный HTML в git не коммитится (см. .gitignore) — его строит CI
перед mkdocs build.

Запуск:
    python3 tools/build-slides.py             # индекс + HTML
    python3 tools/build-slides.py --index-only  # только индекс (без Docker)
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SLIDES = ROOT / "docs" / "lectures" / "slides"
HTML_OUT = ROOT / "docs" / "lectures" / "html"
THEME = ROOT / "docs" / "lectures" / "theme" / "custom_academic.css"
INDEX = ROOT / "docs" / "lectures" / "index.md"

MARP_IMAGE = "marpteam/marp-cli:v4.2.3"

GENERATED_NOTICE = (
    "<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-slides.py\n"
    "     Правки вносите в исходники колод docs/lectures/slides/. -->"
)


def deck_title(path: Path) -> str:
    """Заголовок колоды — первый `# ` в файле."""
    for line in path.read_text(encoding="utf-8").split("\n"):
        if line.startswith("# "):
            return line[2:].strip()
    return path.stem


def decks() -> list[tuple[str, str, Path]]:
    """Список колод: (номер, заголовок, путь), отсортированный по номеру."""
    out = []
    for f in sorted(SLIDES.glob("*.md")):
        m = re.match(r"^(\d+)-", f.name)
        num = m.group(1) if m else ""
        out.append((num, deck_title(f), f))
    return out


def build_index() -> None:
    lines = [
        GENERATED_NOTICE,
        "",
        "# Лекции",
        "",
        "Слайды открываются в браузере. Листать — стрелками или пробелом.",
        "",
        "| № | Тема |",
        "|:---:|---|",
    ]
    for num, title, f in decks():
        lines.append(f"| {num} | [{title}](html/{f.stem}.html) |")
    lines += [
        "",
        "Исходники колод лежат в репозитории курса: "
        "[`docs/lectures/slides/`]"
        "(https://github.com/rserdyukov/yapis-2026/tree/main/docs/lectures/slides).",
        "",
    ]
    INDEX.write_text("\n".join(lines), encoding="utf-8")
    print(f"  индекс:  docs/lectures/index.md ({len(decks())} колод)")


def marp_command(prefer_npx: bool = False) -> list[str] | None:
    """Команда запуска marp-cli: Docker, иначе npx, иначе None.

    На CI выгоднее npx: Node на раннере уже есть, а образ надо тянуть.
    Локально наоборот — Docker не требует установленного Node.
    """
    if prefer_npx and shutil.which("npx"):
        return ["npx", "--yes", "@marp-team/marp-cli@4"]
    if shutil.which("docker"):
        probe = subprocess.run(
            ["docker", "info"], capture_output=True, text=True, check=False
        )
        if probe.returncode == 0:
            return [
                "docker", "run", "--rm", "--init",
                "-v", f"{ROOT}:/home/marp/app",
                "-e", "MARP_USER=root:root",
                MARP_IMAGE,
            ]
    if shutil.which("npx"):
        return ["npx", "--yes", "@marp-team/marp-cli@4"]
    return None


def build_html(prefer_npx: bool = False) -> int:
    cmd = marp_command(prefer_npx)
    if cmd is None:
        print(
            "Не найден ни Docker, ни npx — HTML слайдов не собран.\n"
            "Индекс обновлён; для сборки слайдов поставьте Docker.",
            file=sys.stderr,
        )
        return 1

    HTML_OUT.mkdir(parents=True, exist_ok=True)
    using_docker = cmd[0] == "docker"

    # Внутри контейнера репозиторий смонтирован в /home/marp/app,
    # поэтому пути передаём относительные — они валидны в обоих режимах.
    rel_slides = SLIDES.relative_to(ROOT)
    rel_out = HTML_OUT.relative_to(ROOT)
    rel_theme = THEME.relative_to(ROOT)

    args = cmd + [
        "--html",                      # нужен для <video> в колоде про C++/Python
        "--theme", str(rel_theme),
        "--input-dir", str(rel_slides),
        "--output", str(rel_out),
    ]
    print(f"  marp:    {'docker' if using_docker else 'npx'} -> {rel_out}/")
    proc = subprocess.run(args, cwd=ROOT, check=False)
    if proc.returncode != 0:
        print("marp-cli завершился с ошибкой", file=sys.stderr)
        return proc.returncode

    built = sorted(HTML_OUT.glob("*.html"))
    print(f"  собрано: {len(built)} HTML")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--index-only",
        action="store_true",
        help="только пересобрать оглавление, не запускать marp-cli",
    )
    parser.add_argument(
        "--npx",
        action="store_true",
        help="запускать marp-cli через npx, а не Docker (так делает CI)",
    )
    args = parser.parse_args()

    if not SLIDES.is_dir():
        print(f"нет каталога {SLIDES}", file=sys.stderr)
        return 1

    build_index()
    if args.index_only:
        return 0
    return build_html(prefer_npx=args.npx or bool(os.environ.get("CI")))


if __name__ == "__main__":
    sys.exit(main())
