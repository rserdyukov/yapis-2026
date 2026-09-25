"""Структура сайта после ревью: перенесённые страницы и стабильные якоря.

python3 -m unittest discover -s tools/tests -v
"""

from pathlib import Path
import re
import sys
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from publication import metadata  # noqa: E402


class SiteStructureTests(unittest.TestCase):
    def test_labs_page_contains_variants_and_stable_anchors(self):
        page = (ROOT / "docs/labs/index.md").read_text(encoding="utf-8")
        for anchor in ("posledovatelnost", "otchet", "trebovaniya", "varianty",
                       "svoystva", "yazyki", "celevoy-kod", "raspredelenie"):
            self.assertIn("{ #" + anchor + " }", page)
        for n in range(1, 6):
            self.assertIn(f'<a id="lab-{n}"></a>', page)
        self.assertEqual(len(re.findall(r"^\| \d+ \| \d+ \|", page, re.MULTILINE)), 30)
        # Таблица вариантов — только на сайте; TASK.md студента ссылается на неё.
        task = (ROOT / "admin/template-TASK.md").read_text(encoding="utf-8")
        self.assertNotIn("Таблица распределения", task)
        self.assertIn("labs/#varianty", task)

    def test_moved_pages_redirect_and_leave_search(self):
        for path, target in (("docs/labs/variants.md", "../#varianty"),
                             ("docs/materials/index.md", "../languages/sources/")):
            meta = metadata(ROOT / path)
            self.assertTrue(meta["publish"], path)
            self.assertEqual(meta["redirect"], target, path)
            self.assertTrue(meta["search"]["exclude"], path)
        template = (ROOT / "overrides/main.html").read_text(encoding="utf-8")
        self.assertIn("page.meta.redirect", template)
        self.assertIn("location.hash", template)

    def test_no_links_to_moved_pages(self):
        # Ссылки Markdown и абсолютные адреса сайта; упоминания в комментариях не в счёт.
        pattern = re.compile(r"\]\((?:\.\./)*(?:labs/)?variants\.md|\]\((?:\.\./)*materials/"
                             r"|yapis-2026/labs/variants/|yapis-2026/materials/")
        offenders = []
        for path in [*ROOT.glob("docs/**/*.md"), ROOT / "tools/build-docs.py",
                     ROOT / "tools/build-catalog.py", *ROOT.glob("admin/*.md")]:
            if "_design" in path.parts or path.name in ("variants.md",) and path.parent.name == "labs":
                continue
            if path == ROOT / "docs/materials/index.md":
                continue
            if pattern.search(path.read_text(encoding="utf-8")):
                offenders.append(str(path.relative_to(ROOT)))
        self.assertEqual(offenders, [])

    def test_course_topics_link_every_published_lecture(self):
        course = (ROOT / "docs/course/index.md").read_text(encoding="utf-8")
        topics = course.split("{ #tema-")[1:]
        self.assertEqual(len(topics), 5)
        for n, topic in enumerate(topics, start=1):
            self.assertIn(f"../tests/index.md#tema-{n}", topic)
            # тема ссылается либо на свои задачи, либо на пустой раздел практики
            self.assertRegex(topic, rf"\.\./practice/(index\.md#tema-{n}|task\d\.md)")
        for deck in (ROOT / "docs/lectures/slides").glob("[0-9][0-9]-*.md"):
            if metadata(deck).get("publish"):
                self.assertIn(f"../lectures/html/{deck.stem}.html", course, deck.name)
        for section in ("practice", "tests"):
            page = (ROOT / f"docs/{section}/index.md").read_text(encoding="utf-8")
            for n in range(1, 6):
                self.assertIn("{ #tema-" + str(n) + " }", page)

    def test_practice_tasks_are_complete_and_self_contained(self):
        practice = ROOT / "docs/practice"
        index = (practice / "index.md").read_text(encoding="utf-8")
        course = (ROOT / "docs/course/index.md").read_text(encoding="utf-8")
        used = set()
        for n in range(1, 6):
            page = (practice / f"task{n}.md").read_text(encoding="utf-8")
            self.assertTrue(metadata(practice / f"task{n}.md")["publish"])
            self.assertIn(f"(task{n}.md)", index)
            self.assertIn(f"../practice/task{n}.md", course)
            for anchor in ("teoriya", "uslovie", "varianty", "primer"):
                self.assertIn("{ #" + anchor + " }", page, f"task{n}: {anchor}")
            # 30 вариантов в таблице раздела «Варианты»
            variants = page.split("{ #varianty }")[1].split("\n## ")[0]
            self.assertEqual(len(re.findall(r"^\| (\d+) \|", variants, re.MULTILINE)), 30, f"task{n}")
            # артефакты конвертации из Google Docs
            self.assertNotRegex(page, r"[\x00-\x08]")
            self.assertNotIn("docs.google.com", page)
            for image in re.findall(r"\]\((img/[^)]+)\)", page):
                self.assertTrue((practice / image).is_file(), image)
                used.add(image.split("/", 1)[1])
        # в каталоге нет неиспользуемых картинок
        self.assertEqual(used, {p.name for p in (practice / "img").iterdir()})

    def test_garden_articles_are_linked_and_self_contained(self):
        garden = ROOT / "docs/garden"
        index = (garden / "index.md").read_text(encoding="utf-8")
        nav = (ROOT / "mkdocs.yml").read_text(encoding="utf-8")
        onto = yaml.safe_load((ROOT / "docs/languages/_data/ontology.yaml").read_text(encoding="utf-8"))
        concepts = {c["id"] for cat in onto["categories"] for c in cat["concepts"]}
        langs = {p.stem for p in (ROOT / "docs/languages/_data/languages").glob("*.yaml")}
        articles = [p for p in garden.glob("*.md") if metadata(p).get("publish") and p.name != "index.md"]
        self.assertGreaterEqual(len(articles), 11)
        for path in articles:
            meta = metadata(path)
            text = path.read_text(encoding="utf-8")
            with self.subTest(article=path.name):
                self.assertIn(f"({path.name})", index)
                self.assertIn(f"garden/{path.name}", nav)
                self.assertTrue(meta.get("title") and meta.get("languages") and meta.get("concepts"))
                self.assertLessEqual(set(meta["languages"]), langs)
                self.assertLessEqual(set(meta["concepts"]), concepts)
                self.assertIn("## Источники", text)
                # у каждого включённого файла есть исходник, у папки — run.sh
                for ref in re.findall(r'--8<-- "(src/[^":]+)(?::[a-z][-_0-9a-z]*)?"', text):
                    self.assertTrue((garden / ref).is_file(), ref)
                slug = path.stem
                self.assertTrue((garden / "src" / slug / "run.sh").is_file(), slug)
                # каждый пример помечен: запущен или выведен из документации
                self.assertRegex(text, r"\*\*(Проверено|Не запускалось):\*\*")


if __name__ == "__main__":
    unittest.main()
