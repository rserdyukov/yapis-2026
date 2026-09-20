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
import tempfile
from pathlib import Path

from publication import page_frontmatter, published

ROOT = Path(__file__).resolve().parent.parent
SLIDES = ROOT / "docs" / "lectures" / "slides"
HTML_OUT = ROOT / "docs" / "lectures" / "html"
THEME = ROOT / "docs" / "lectures" / "theme" / "custom_academic.css"
INDEX = ROOT / "docs" / "lectures" / "index.md"

MARP_IMAGE = "marpteam/marp-cli:v4.2.3"

GENERATED_NOTICE = (
    "<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-slides.py\n"
    "     Текст меняйте в docs/lectures/slides/. Метаданные индекса сохраняются. -->"
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
        if not published(f):
            continue
        m = re.match(r"^(\d+)-", f.name)
        num = m.group(1) if m else ""
        out.append((num, deck_title(f), f))
    return out


def index_content() -> str:
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
    return page_frontmatter(INDEX) + "\n".join(lines)


def build_index() -> None:
    INDEX.write_text(index_content(), encoding="utf-8")
    print(f"  индекс:  docs/lectures/index.md ({len(decks())} колод)")


def marp_command(prefer_npx: bool = False) -> list[str] | None:
    """Команда запуска marp-cli: Docker, иначе npx, иначе None.

    На CI выгоднее npx: Node на раннере уже есть, а образ надо тянуть.
    Локально наоборот — Docker не требует установленного Node.
    """
    if prefer_npx and shutil.which("npx"):
        return ["npx", "--yes", "@marp-team/marp-cli@4.2.3"]
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
        return ["npx", "--yes", "@marp-team/marp-cli@4.2.3"]
    return None


def add_course_navigation(path: Path) -> None:
    """Standalone Marp не использует шаблон MkDocs: добавляем выход в курс.

    Относительный URL сохраняет префикс GitHub Pages (/yapis-2026/).
    Прямая ссылка работает и без истории браузера; печать её не показывает.
    """
    html = path.read_text(encoding="utf-8")
    style = """<style id="course-slide-navigation-style">
#course-back-link {
  position: fixed; top: max(12px, env(safe-area-inset-top));
  left: max(12px, env(safe-area-inset-left)); z-index: 2147483647;
  display: inline-flex; align-items: center; min-height: 44px;
  box-sizing: border-box; padding: 8px 16px; border-radius: 24px;
  border: 1px solid #d1cfc5; background: #faf9f5; color: #903e28;
  font: 500 15px/1.4 system-ui, sans-serif; text-decoration: none;
  box-shadow: 0 2px 10px #0002;
}
#course-back-link:hover { background: #f0eee6; }
#course-back-link:focus-visible { outline: 3px solid #ad4e32; outline-offset: 3px; }
@media print { #course-back-link { display: none; } }
</style>"""
    link = '<a id="course-back-link" href="../" aria-label="Вернуться к списку лекций" aria-keyshortcuts="Escape" title="К списку лекций (Esc)">← К лекциям · Esc</a>'
    script = """<script>
// Capture: Esc возвращает в курс раньше обработчиков клавиш презентации.
window.addEventListener('keydown', function (event) {
  if (event.key !== 'Escape') return;
  event.preventDefault();
  event.stopImmediatePropagation();
  window.location.assign(document.getElementById('course-back-link').href);
}, true);
</script>"""
    if "</head>" not in html or not re.search(r"<body\b[^>]*>", html):
        raise ValueError(f"{path}: Marp не создал полный HTML-документ")
    html = html.replace("</head>", style + "</head>", 1)
    html = re.sub(r"(<body\b[^>]*>)", lambda m: m[1] + link + script, html, count=1)
    path.write_text(html, encoding="utf-8")


def build_html(prefer_npx: bool = False) -> int:
    selected = decks()
    # Каталог содержит только производные файлы. Удаляем и отозванные,
    # и переименованные колоды; повторная сборка не публикует старый HTML.
    if HTML_OUT.exists():
        shutil.rmtree(HTML_OUT)
    HTML_OUT.mkdir(parents=True, exist_ok=True)
    if not selected:
        return 0
    cmd = marp_command(prefer_npx)
    if cmd is None:
        print(
            "Не найден ни Docker, ни npx — HTML слайдов не собран.\n"
            "Индекс обновлён; для сборки слайдов поставьте Docker.",
            file=sys.stderr,
        )
        return 1

    using_docker = cmd[0] == "docker"

    # Внутри контейнера репозиторий смонтирован в /home/marp/app,
    # поэтому пути передаём относительные — они валидны в обоих режимах.
    rel_out = HTML_OUT.relative_to(ROOT)
    rel_theme = THEME.relative_to(ROOT)

    print(f"  marp:    {'docker' if using_docker else 'npx'} -> {rel_out}/")
    # Marp принимает --output-каталог только вместе с --input-dir.
    # Временный вход содержит исключительно опубликованные исходники.
    # Под ROOT, чтобы этот же путь был доступен Docker через bind mount.
    with tempfile.TemporaryDirectory(prefix=".marp-input-", dir=ROOT) as directory:
        source_dir = Path(directory)
        for _, _, path in selected:
            shutil.copy2(path, source_dir / path.name)
        args = cmd + [
            "--html", "--theme", str(rel_theme),
            "--input-dir", str(source_dir.relative_to(ROOT)),
            "--output", str(rel_out),
        ]
        proc = subprocess.run(args, cwd=ROOT, check=False)
    if proc.returncode != 0:
        print("marp-cli завершился с ошибкой", file=sys.stderr)
        return proc.returncode

    built = sorted(HTML_OUT.glob("*.html"))
    for path in built:
        add_course_navigation(path)
    print(f"  собрано: {len(built)} HTML")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true", help="проверить индекс без записи и сборки HTML",
    )
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

    if args.check:
        if not INDEX.exists() or INDEX.read_text(encoding="utf-8") != index_content():
            print("Индекс лекций устарел: python3 tools/build-slides.py --index-only", file=sys.stderr)
            return 1
        return 0
    build_index()
    if args.index_only:
        return 0
    return build_html(prefer_npx=args.npx or bool(os.environ.get("CI")))


if __name__ == "__main__":
    sys.exit(main())
