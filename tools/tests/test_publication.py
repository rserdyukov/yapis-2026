"""Регрессии публикации: проверяем артефакты, а не только значения флага.

python3 -m unittest discover -s tools/tests -v
Все изменения тестовых данных изолированы TemporaryDirectory.
"""

import importlib.util
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import yaml

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from publication import load_publication_yaml, metadata, page_frontmatter, published


def load_slides():
    spec = importlib.util.spec_from_file_location("course_slides", ROOT / "tools/build-slides.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def test_only_explicit_boolean_true_publishes(self):
        for header, expected in [("publish: true", True), ("publish: false", False), ("title: Draft", False)]:
            with self.subTest(header=header):
                path = self.write("page.md", f"---\n{header}\n---\n# Title\n---\npublish: true\n")
                self.assertEqual(published(path), expected)
        self.assertFalse(published(self.write("page.md", "# No front matter\n")))
        for header in ['publish: "true"', "publish: 1", "publish: null", "- publish", "publish: [true]"]:
            with self.subTest(header=header), self.assertRaises(ValueError):
                published(self.write("page.md", f"---\n{header}\n---\n"))
        with self.assertRaises(ValueError):
            published(self.write("page.md", "---\npublish: true\n"))

    def test_ambiguous_publish_is_rejected_and_delimiter_spaces_are_allowed(self):
        path = self.write("page.md", "--- \t\npublish: true\n--- \n# Done\n")
        self.assertTrue(published(path))
        for text in ["publish: false\npublish: true", "publish: true\npublish: false"]:
            with self.subTest(text=text), self.assertRaises(ValueError):
                load_publication_yaml(text, "card.yaml")
            with self.subTest(text=text), self.assertRaises(ValueError):
                published(self.write("page.md", f"---\n{text}\n---\n"))

    def test_generated_page_preserves_editor_metadata(self):
        path = self.write("page.md", "---\npublish: false\ntitle: Мой заголовок\n---\nOld body")
        path.write_text(page_frontmatter(path) + "New body", encoding="utf-8")
        self.assertEqual(metadata(path), {"publish": False, "title": "Мой заголовок"})

    def test_mkdocs_excludes_drafts_stale_slides_search_and_sitemap(self):
        self.write("mkdocs.yml", yaml.safe_dump({
            "site_name": "Fixture", "site_url": "https://example.org/course/",
            "strict": True, "hooks": [str(ROOT / "tools/site_hooks.py")],
            "nav": [{"Home": "index.md"}, {"Hidden": "draft.md"}],
        }))
        self.write("docs/index.md", "---\npublish: true\n---\n# Visible\n")
        self.write("docs/draft.md", "---\npublish: false\n---\n# DRAFT_CANARY\n")
        self.write("docs/unmarked.md", "# UNMARKED_CANARY\n")
        self.write("docs/lectures/slides/hidden.md", "---\npublish: false\n---\n# HIDDEN_DECK\n")
        self.write("docs/lectures/html/hidden.html", "STALE_SLIDE_CANARY")
        self.write("docs/lectures/html/deleted.html", "DELETED_SLIDE_CANARY")
        page = self.write("docs/formerly-public.md", "---\npublish: true\n---\n# REVOKED_CANARY\n")

        def build():
            result = subprocess.run([sys.executable, "-m", "mkdocs", "build"], cwd=self.root, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        build()
        self.assertTrue((self.root / "site/formerly-public/index.html").exists())
        page.write_text("---\npublish: false\n---\n# REVOKED_CANARY\n", encoding="utf-8")
        build()
        for target in ["draft/index.html", "unmarked/index.html", "formerly-public/index.html",
                       "lectures/html/hidden.html", "lectures/html/deleted.html"]:
            self.assertFalse((self.root / "site" / target).exists(), target)
        for name in ["search/search_index.json", "sitemap.xml", "index.html"]:
            content = (self.root / "site" / name).read_text()
            for marker in ["DRAFT_CANARY", "UNMARKED_CANARY", "REVOKED_CANARY", "HIDDEN_DECK", "draft.md"]:
                self.assertNotIn(marker, content, name)
        # Опубликованная ссылка на черновик должна давать ошибку, а не тихий 404.
        self.write("docs/index.md", "---\npublish: true\n---\n# Visible\n[Draft](draft.md)\n")
        result = subprocess.run([sys.executable, "-m", "mkdocs", "build"], cwd=self.root, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("draft.md", result.stderr)

    def test_rebuild_restores_navigation_when_page_is_published(self):
        # mkdocs serve выполняет несколько сборок с тем же config/hooks.
        from mkdocs.commands.build import build
        from mkdocs.config import load_config

        self.write("mkdocs.yml", yaml.safe_dump({
            "site_name": "Fixture", "strict": True,
            "hooks": [str(ROOT / "tools/site_hooks.py")],
            "nav": [{"Home": "index.md"}, {"Released": "released.md"}],
        }))
        self.write("docs/index.md", "---\npublish: true\n---\n# Visible\n")
        page = self.write("docs/released.md", "---\npublish: false\n---\n# Released\n")
        config = load_config(config_file=str(self.root / "mkdocs.yml"))
        build(config)
        self.assertEqual(config.nav, [{"Home": "index.md"}])
        page.write_text("---\npublish: true\n---\n# Released\n")
        build(config)
        self.assertEqual(config.nav, [{"Home": "index.md"}, {"Released": "released.md"}])
        self.assertTrue((self.root / "site/released/index.html").exists())

    def test_slides_filter_actual_marp_input_and_remove_old_html(self):
        slides = load_slides()
        slides.ROOT = self.root
        slides.SLIDES = self.root / "docs/lectures/slides"
        slides.HTML_OUT = self.root / "docs/lectures/html"
        slides.INDEX = self.root / "docs/lectures/index.md"
        slides.THEME = self.root / "theme.css"
        public = self.write("docs/lectures/slides/01-public.md", "---\npublish: true\n---\n# Visible\n")
        self.write("docs/lectures/slides/02-draft.md", "---\npublish: false\n---\n# Secret\n")
        self.write("docs/lectures/html/02-draft.html", "stale")
        self.write("docs/lectures/html/removed.html", "stale")

        def fake_marp(args, **kwargs):
            inputs = self.root / args[args.index("--input-dir") + 1]
            self.assertEqual([p.name for p in inputs.glob("*.md")], ["01-public.md"])
            (slides.HTML_OUT / "01-public.html").write_text("<!doctype html><html><head></head><body>Visible</body></html>")
            return subprocess.CompletedProcess(args, 0)

        with patch.object(slides, "marp_command", return_value=["npx"]), patch.object(slides.subprocess, "run", side_effect=fake_marp):
            self.assertEqual(slides.build_html(True), 0)
        self.assertEqual([p.name for p in slides.HTML_OUT.iterdir()], ["01-public.html"])
        self.assertNotIn("Secret", slides.index_content())
        public.write_text("---\npublish: false\n---\n# Visible\n")
        self.assertEqual(slides.build_html(), 0)
        self.assertEqual(list(slides.HTML_OUT.iterdir()), [])
        self.assertEqual(slides.decks(), [])

    def test_catalog_draft_leaves_no_links_in_public_matrix(self):
        data = self.root / "data"
        shutil.copytree(ROOT / "docs/languages/_data", data)
        path = data / "languages/python.yaml"
        content = yaml.safe_load(path.read_text())
        content["publish"] = False
        path.write_text(yaml.safe_dump(content, allow_unicode=True))
        out = self.root / "pages"
        result = subprocess.run([sys.executable, str(ROOT / "tools/build-catalog.py"), "--data", str(data), "--out", str(out)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(published(out / "python.md"))
        self.assertTrue(published(out / "java.md"))
        for name in ["index.md", "concepts.md"]:
            self.assertNotIn("(python.md", (out / name).read_text())


if __name__ == "__main__":
    unittest.main()
