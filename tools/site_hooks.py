"""Фильтрация до навигации/поиска; оформление страницы без боковых колонок."""

from pathlib import Path
from copy import deepcopy
import sys

from mkdocs.exceptions import PluginError

sys.path.insert(0, str(Path(__file__).resolve().parent))
from publication import published  # noqa: E402


def on_files(files, config):
    docs = Path(config.docs_dir)
    try:
        for file in list(files):
            uri = file.src_uri
            if file.is_documentation_page() and not published(Path(file.abs_src_path)):
                files.remove(file)
            elif uri.startswith("lectures/html/") and uri.endswith(".html"):
                source = docs / "lectures/slides" / (Path(uri).stem + ".md")
                if not published(source):
                    files.remove(file)
    except (ValueError, OSError) as error:
        raise PluginError(str(error)) from error

    available = {f.src_uri for f in files}

    def prune(items):
        result = []
        for item in items:
            if isinstance(item, str):
                if item in available:
                    result.append(item)
            else:
                for label, target in item.items():
                    if isinstance(target, list):
                        children = prune(target)
                        if children:
                            result.append({label: children})
                    elif target in available:
                        result.append({label: target})
        return result

    # Не теряем исходное дерево при повторной сборке с тем же config.
    config.nav = prune(config._course_navigation)
    return files


def on_config(config):
    # on_config вызывается перед КАЖДОЙ сборкой, даже с тем же объектом.
    # Новый load_config (правка mkdocs.yml) получает новый снимок.
    if not hasattr(config, "_course_navigation"):
        config._course_navigation = deepcopy(config.nav or [])
    return config


def on_page_content(html, page, config, files):
    """Штатный TOC MkDocs внутри статьи, без JS и отдельной колонки."""
    if page.meta.get("layout") == "landing":
        return html
    headings = page.toc.items
    if len(headings) == 1 and headings[0].level == 1:
        headings = headings[0].children
    if len(headings) < 2:
        return html
    from html import escape

    def links(items):
        return "<ul>" + "".join(
            f'<li><a href="#{escape(item.id, quote=True)}">{escape(item.title)}</a>'
            + (links(item.children) if item.children else "") + "</li>"
            for item in items
        ) + "</ul>"

    toc = ('<details class="course-toc"><summary>На этой странице</summary>'
           + links(headings) + "</details>")
    end = html.find("</h1>")
    return html[:end + 5] + toc + html[end + 5:] if end >= 0 else toc + html
