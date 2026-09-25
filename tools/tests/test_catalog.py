"""Schema-2 catalog regressions; every fixture mutation uses a temporary copy.

python3 -m unittest discover -s tools/tests -v
"""

from contextlib import redirect_stderr, redirect_stdout
from copy import deepcopy
from html.parser import HTMLParser
import importlib.util
import io
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

import markdown
import yaml


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
spec = importlib.util.spec_from_file_location("course_catalog", ROOT / "tools/build-catalog.py")
catalog = importlib.util.module_from_spec(spec)
# dataclasses resolves annotations through the module registry during import.
sys.modules[spec.name] = catalog
spec.loader.exec_module(catalog)


class Links(HTMLParser):
    def __init__(self, html):
        super().__init__()
        self.ids = []
        self.hrefs = []
        self.feed(html)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.append(attrs["id"])
        if tag == "a" and "href" in attrs:
            self.hrefs.append(attrs["href"])


class CatalogTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.data = self.root / "data"
        self.out = self.root / "pages"
        shutil.copytree(ROOT / "docs/languages/_data", self.data)

    def read_yaml(self, name):
        return yaml.safe_load((self.data / name).read_text(encoding="utf-8"))

    def write_mutation(self, name, value):
        self.assertNotEqual(self.read_yaml(name), value, f"no mutation: {name}")
        (self.data / name).write_text(
            yaml.safe_dump(value, allow_unicode=True, sort_keys=False), encoding="utf-8")

    def set_concept_policy(self, cid, **policy):
        onto = self.read_yaml("ontology.yaml")
        concept = next(c for cat in onto["categories"] for c in cat["concepts"] if c["id"] == cid)
        concept.update(policy)
        self.write_mutation("ontology.yaml", onto)

    def set_entries(self, cid, entries):
        raw = self.read_yaml("languages/rust.yaml")
        raw["concepts"][cid] = entries
        self.write_mutation("languages/rust.yaml", raw)

    def validate_rust(self):
        report = catalog.Report()
        onto = catalog.Ontology.load(self.data, report)
        lang = catalog.Language("rust", self.read_yaml("languages/rust.yaml"),
                                self.data / "languages/rust.yaml")
        try:
            catalog.validate_language(lang, onto, self.data, report)
        except catalog.CatalogError as error:
            report.error(str(error))
        return report.errors

    def build(self, expected=0, check=False):
        output = io.StringIO()
        with (redirect_stdout(output), redirect_stderr(output),
              patch.object(catalog, "DATA_DIR", self.data),
              patch.object(catalog, "_SECTION_CACHE", {})):
            result = catalog.run(self.data, self.out, check=check)
        self.assertEqual(result, expected, output.getvalue())
        self.assertNotIn("Traceback", output.getvalue())
        return output.getvalue()

    def test_disjoint_versions_share_cardinality_slot_at_exclusive_boundary(self):
        # Artificial policy: block syntax is not inherently mutually exclusive.
        self.set_concept_policy("syntax.blocks", max_values=1)
        self.set_entries("syntax.blocks", [
            {"value": "explicit", "until": "1.59"},
            {"value": "indentation", "since": "1.59"},
        ])
        self.assertEqual(self.validate_rust(), [])
        # Moving only the end date creates a real overlap.
        self.set_entries("syntax.blocks", [
            {"value": "explicit", "until": "1.98"},
            {"value": "indentation", "since": "1.59"},
        ])
        self.assertIn("rust.yaml: syntax.blocks: max_values=1, одновременно 2",
                      "\n".join(self.validate_rust()))

    def test_prose_and_explicit_default_layer_do_not_escape_same_context(self):
        self.set_concept_policy("syntax.blocks", max_values=1)
        self.set_entries("syntax.blocks", [
            {"value": "explicit", "applies_to": "First explanatory description"},
            {"value": "indentation", "layer": "language", "applies_to": "Different prose"},
        ])
        errors = self.validate_rust()
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("syntax.blocks: max_values=1, одновременно 2", errors[0])

    def test_repeated_evidence_for_one_value_does_not_exhaust_cardinality(self):
        self.set_concept_policy("syntax.blocks", max_values=1)
        self.set_entries("syntax.blocks", [
            {"value": "explicit", "note": "First source"},
            {"value": "explicit", "since": "1.59", "note": "Later evidence"},
        ])
        self.assertEqual(self.validate_rust(), [])

    def test_boolean_conflict_requires_no_explicit_cardinality_policy(self):
        self.set_entries("subprograms.overloading", [{"value": True}, {"value": False}])
        self.assertIn("max_values=1", "\n".join(self.validate_rust()))

    def test_default_profile_is_used_for_rendering_and_cardinality(self):
        raw = self.read_yaml("languages/rust.yaml")
        raw["default_profile"] = "locals"
        raw["concepts"]["subprograms.overloading"] = [
            {"value": True}, {"value": False, "profile": "locals"}]
        self.write_mutation("languages/rust.yaml", raw)
        self.assertIn("max_values=1", "\n".join(self.validate_rust()))
        onto = catalog.Ontology.load(self.data, catalog.Report())
        lang = catalog.Language("rust", raw, self.data / "languages/rust.yaml")
        label = catalog.value_label(onto, "subprograms.overloading", {"value": True}, lang)
        self.assertIn("profile: locals", label)

    def test_declared_profiles_separate_claims_but_same_profile_conflicts(self):
        self.set_concept_policy("typing.annotations", max_values=1)
        entries = [
            {"value": "optional", "profile": "locals", "note": "Fixture: local bindings"},
            {"value": "required", "profile": "signatures", "note": "Fixture: signatures"},
        ]
        self.set_entries("typing.annotations", entries)
        self.assertEqual(self.validate_rust(), [])
        entries[1]["profile"] = "locals"
        self.set_entries("typing.annotations", entries)
        self.assertIn("typing.annotations: max_values=1, одновременно 2",
                      "\n".join(self.validate_rust()))
        entries[1]["profile"] = "nonexistent-profile"
        self.set_entries("typing.annotations", entries)
        self.assertIn("profile='nonexistent-profile' не объявлен в profiles",
                      "\n".join(self.validate_rust()))

    def test_na_exempts_showcase_but_still_validates_remaining_metadata(self):
        self.set_concept_policy("syntax.blocks", showcase="required")
        raw = self.read_yaml("languages/rust.yaml")
        raw["examples"] = []
        entry = {"value": "n/a", "note": "Not applicable in this fixture"}
        raw["concepts"]["syntax.blocks"] = [entry]
        self.write_mutation("languages/rust.yaml", raw)
        self.assertEqual(self.validate_rust(), [])
        cases = [
            ({"note": " "}, "n/a допустим только с note"),
            ({"since": "nonexistent-version"}, "since='nonexistent-version' не найден в versions"),
            ({"until": "nonexistent-version"}, "until='nonexistent-version' не найден в versions"),
            ({"since": "1.98", "until": "1.59"}, "since должен предшествовать until"),
            ({"layer": "nonexistent-layer"}, "layer='nonexistent-layer'"),
            ({"profile": "nonexistent-profile"}, "profile='nonexistent-profile'"),
            ({"status": "nonexistent-status"}, "status='nonexistent-status'"),
            ({"sources": [{"url": "https://example.org", "retrieved": "2026-02-30"}]},
             "sources[].retrieved: ожидается дата YYYY-MM-DD"),
            ({"example": {"file": "showcase.rs", "section": "nonexistent-section"}},
             "example showcase.rs без секции nonexistent-section"),
        ]
        for changes, message in cases:
            with self.subTest(changes=changes):
                changed = deepcopy(raw)
                changed["concepts"]["syntax.blocks"][0].update(changes)
                self.write_mutation("languages/rust.yaml", changed)
                self.assertIn(message, "\n".join(self.validate_rust()))

    def test_legacy_aliases_and_canonical_links_resolve_after_markdown_rendering(self):
        self.build()
        rendered = {}
        for name in ("rust.md", "concepts.md", "lab-mapping.md"):
            source = (self.out / name).read_text(encoding="utf-8")
            html = markdown.markdown(source, extensions=[
                "attr_list", "tables", "fenced_code", "pymdownx.snippets",
            ], extension_configs={"pymdownx.snippets": {
                "base_path": [str(self.data)], "check_paths": True,
            }})
            self.assertNotIn("--8<--", html, name)
            rendered[name] = Links(html)
            self.assertEqual(len(rendered[name].ids), len(set(rendered[name].ids)), name)

        for name in ("rust.md", "concepts.md"):
            for anchor in ("bindings-assignment", "variants-3", "typing-conversions", "typing-strength"):
                self.assertIn(anchor, rendered[name].ids, name)
        rust_md = (self.out / "rust.md").read_text(encoding="utf-8")
        self.assertIn('--8<-- "examples/rust/showcase.rs:variants-3"', rust_md)
        self.assertIn("concepts.md#typing-conversions", rust_md)
        self.assertIn("concepts.md#bindings-assignment", rendered["lab-mapping.md"].hrefs)
        checked = 0
        for name, page in rendered.items():
            for href in page.hrefs:
                target, separator, anchor = href.partition("#")
                target = target or name
                if separator and target in rendered:
                    self.assertIn(anchor, rendered[target].ids, f"{name}: {href}")
                    checked += 1
        self.assertGreater(checked, 0)

    def test_broken_lab_mapping_reference_is_rejected_before_writing(self):
        raw = self.read_yaml("lab-mapping.yaml")
        item = raw["mappings"][0]
        self.assertNotIn("nonexistent.concept", item["concepts"])
        item["concepts"].append("nonexistent.concept")
        self.write_mutation("lab-mapping.yaml", raw)
        output = self.build(expected=1)
        self.assertIn(f"lab-mapping.{item['id']}: неизвестная концепция nonexistent.concept", output)
        self.assertFalse(self.out.exists())

    def test_guide_requires_definition_for_every_concept(self):
        raw = self.read_yaml("concept-guide.yaml")
        del raw["definitions"]["typing.inference"]
        self.write_mutation("concept-guide.yaml", raw)
        self.assertIn("нет определения typing.inference", self.build(expected=1))
        self.assertFalse(self.out.exists())

    def test_guide_rejects_bad_relation_targets_types_and_symmetric_duplicates(self):
        original = self.read_yaml("concept-guide.yaml")
        cases = [
            ({"from": "typing.inference", "to": "no.such.concept", "type": "related_to", "note": "Fixture"}, "неизвестный конец"),
            ({"from": "typing.inference", "to": "typing.checking", "type": "implies", "note": "Fixture"}, "неизвестный тип"),
            ({"from": "typing.inference", "to": "typing.inference", "type": "related_to", "note": "Fixture"}, "самим собой"),
            ({"from": "typing.checking", "to": "typing.inference", "type": "often_confused_with", "note": "Reverse duplicate"}, "повторная связь"),
        ]
        for edge, message in cases:
            with self.subTest(edge=edge):
                raw = deepcopy(original)
                raw["relations"].append(edge)
                self.write_mutation("concept-guide.yaml", raw)
                self.assertIn(message, self.build(expected=1))

    def test_guide_rejects_cycles_in_hierarchy_and_learning_order(self):
        original = self.read_yaml("concept-guide.yaml")
        for kind in ("specializes", "prerequisite"):
            with self.subTest(kind=kind):
                raw = deepcopy(original)
                raw["relations"] += [
                    {"from": "typing.checking", "to": "typing.annotations", "type": kind, "note": "Fixture"},
                    {"from": "typing.annotations", "to": "typing.checking", "type": kind, "note": "Fixture"},
                ]
                self.write_mutation("concept-guide.yaml", raw)
                self.assertIn(f"цикл {kind}", self.build(expected=1))

    def test_guide_renders_inverse_relations_and_all_cross_links(self):
        self.build()
        pages = {}
        for name in ("glossary.md", "questions.md", "concepts.md"):
            source = (self.out / name).read_text()
            pages[name] = Links(markdown.markdown(source, extensions=["attr_list", "tables"]))
            self.assertEqual(len(pages[name].ids), len(set(pages[name].ids)), name)
        for name, page in pages.items():
            for href in page.hrefs:
                target, sep, anchor = href.partition("#")
                target = target or name
                if sep and target in pages:
                    self.assertIn(anchor, pages[target].ids, href)
        glossary = (self.out / "glossary.md").read_text()
        self.assertIn("Частные случаи: [Выбор по значению switch/case]", glossary)
        self.assertIn("Помогает изучить: [Вывод статических типов]", glossary)
        self.assertEqual(len(self.read_yaml("concept-guide.yaml")["questions"]), 15)

    def test_guide_question_unknown_reference_is_rejected(self):
        raw = self.read_yaml("concept-guide.yaml")
        raw["questions"][0]["concepts"].append("unknown.concept")
        self.write_mutation("concept-guide.yaml", raw)
        self.assertIn("вопрос q01 ссылается на неизвестное понятие", self.build(expected=1))

    def test_malformed_types_produce_actionable_errors_before_rendering(self):
        original = self.read_yaml("languages/rust.yaml")
        cases = [
            ("versions", {"1.0": "not a list"}, "rust.yaml.versions: ожидается список"),
            ("profiles", ["safe"], "rust.yaml.profiles: ожидается объект со строковыми ключами"),
            ("concepts", ["syntax.blocks"], "rust.yaml.concepts: ожидается объект со строковыми ключами"),
            ("examples", "showcase.rs", "rust.yaml.examples: ожидается список"),
        ]
        for key, value, message in cases:
            with self.subTest(key=key):
                raw = deepcopy(original)
                raw[key] = value
                self.write_mutation("languages/rust.yaml", raw)
                self.assertIn(message, self.build(expected=1))
                self.assertFalse(self.out.exists())

    def test_boolean_concept_rejects_string_false(self):
        self.set_entries("subprograms.overloading", [{"value": "false"}])
        self.assertIn("subprograms.overloading: значение 'false' не входит в перечисление",
                      self.build(expected=1))

    def test_optional_showcase_can_be_absent_with_concepts_still_rendered(self):
        raw = self.read_yaml("languages/rust.yaml")
        self.assertTrue(any(e.get("role") == "showcase" for e in raw["examples"]))
        raw["examples"] = [e for e in raw["examples"] if e.get("role") != "showcase"]
        self.write_mutation("languages/rust.yaml", raw)
        self.build()
        page = (self.out / "rust.md").read_text(encoding="utf-8")
        self.assertIn("{ #syntax-blocks }", page)
        self.assertNotIn("{ #showcase }", page)
        self.assertNotIn("examples/rust/showcase.rs", page)
        self.build(check=True)

    def test_explicit_missing_snippet_is_rejected_even_when_showcase_is_optional(self):
        raw = self.read_yaml("languages/rust.yaml")
        raw["concepts"]["syntax.blocks"][0]["example"] = {
            "file": "showcase.rs", "section": "nonexistent-section",
        }
        self.write_mutation("languages/rust.yaml", raw)
        output = self.build(expected=1)
        self.assertIn("rust.yaml: syntax.blocks: example showcase.rs без секции nonexistent-section", output)
        self.assertFalse(self.out.exists())

    def test_missing_concept_is_unknown_not_false_or_na_in_matrix(self):
        raw = self.read_yaml("languages/rust.yaml")
        self.assertTrue(raw["concepts"].pop("subprograms.overloading"))
        self.write_mutation("languages/rust.yaml", raw)
        self.build()
        page = (self.out / "rust.md").read_text(encoding="utf-8")
        self.assertNotIn("{ #subprograms-overloading }", page)
        matrix = (self.out / "concepts.md").read_text(encoding="utf-8")
        self.assertNotIn("(rust.md#subprograms-overloading)", matrix)
        self.assertIn("(rust.md#syntax-blocks)", matrix)

    # --- порядок языков, полнота, люди и источники

    def test_languages_are_ordered_by_year_everywhere_including_nav(self):
        report = catalog.Report()
        langs = catalog.load_languages(self.data, report)
        years = [catalog.appeared_year(lang.raw) for lang in langs]
        self.assertNotIn(None, years, "у каждой карточки должен быть meta.appeared")
        self.assertEqual(years, sorted(years))
        self.build()
        index = (self.out / "index.md").read_text(encoding="utf-8")
        positions = [index.index(f"]({lang.id}.md)") for lang in langs]
        self.assertEqual(positions, sorted(positions))
        config = yaml.load((ROOT / "mkdocs.yml").read_text(encoding="utf-8"), Loader=yaml.BaseLoader)
        section = next(item["Каталог языков"] for item in config["nav"]
                       if isinstance(item, dict) and "Каталог языков" in item)
        nav = [next(iter(entry.values())) for entry in section if isinstance(entry, dict)]
        published = [f"languages/{lang.id}.md" for lang in langs if lang.raw.get("publish")]
        self.assertEqual(nav, published, "порядок nav в mkdocs.yml должен совпадать с каталогом")

    def test_completeness_is_computed_from_data(self):
        self.build()
        index = (self.out / "index.md").read_text(encoding="utf-8")
        self.assertRegex(index, r"\[Rust\]\(rust\.md\).*\| полная: \d+/\d+ понятий; пример, грамматика, оценка \|")
        self.assertRegex(index, r"\[C\]\(c\.md\).*\| сравнительная: \d+/\d+ понятий \|")
        raw = self.read_yaml("languages/rust.yaml")
        raw["examples"] = [e for e in raw["examples"] if e.get("role") != "showcase"]
        self.write_mutation("languages/rust.yaml", raw)
        self.build()
        page = (self.out / "rust.md").read_text(encoding="utf-8")
        self.assertRegex(page, r"\*Карточка сравнительная: \d+/\d+ понятий; грамматика, оценка\*")

    def test_people_and_sources_render_bidirectional_links(self):
        self.build()
        people = (self.out / "people.md").read_text(encoding="utf-8")
        sources = (self.out / "sources.md").read_text(encoding="utf-8")
        glossary = (self.out / "glossary.md").read_text(encoding="utf-8")
        haskell = (self.out / "haskell.md").read_text(encoding="utf-8")
        # человек → язык и источник; язык → человек и источник
        self.assertIn("{ #wadler }", people)
        self.assertIn("[Haskell](haskell.md)", people)
        self.assertIn("(sources.md#wadler-blott-1989)", people)
        self.assertIn("[Филип Уодлер](people.md#wadler)", haskell)
        self.assertIn("(sources.md#hopl-haskell)", haskell)
        # понятие → языки, примеры, лекции, люди, источники
        section = glossary.split("{ #abstraction-contracts }")[1].split("\n### ")[0]
        self.assertIn("**В языках:**", section)
        self.assertIn("(people.md#wadler)", section)
        self.assertIn("(sources.md#wadler-blott-1989)", section)
        assignment = glossary.split("{ #bindings-assignment }")[1].split("\n### ")[0]
        self.assertIn("../lectures/html/03-", assignment)
        mutation = glossary.split("{ #bindings-mutation }")[1].split("\n### ")[0]
        self.assertIn("../concepts/examples/index.md#oz", mutation)
        # источник → лекция и ЛР
        self.assertIn('<a id="antlr"></a>', sources)
        self.assertIn("../labs/index.md#lab-2", sources)
        rendered = {}
        for name in ("people.md", "sources.md", "glossary.md", "haskell.md"):
            html = markdown.markdown((self.out / name).read_text(encoding="utf-8"),
                                     extensions=["attr_list", "tables", "md_in_html"])
            rendered[name] = Links(html)
            self.assertEqual(len(rendered[name].ids), len(set(rendered[name].ids)), name)
        for name, page in rendered.items():
            for href in page.hrefs:
                target, sep, anchor = href.partition("#")
                target = target or name
                if sep and target in rendered:
                    self.assertIn(anchor, rendered[target].ids, f"{name}: {href}")

    def test_registry_rejects_unknown_references(self):
        original_people = self.read_yaml("people.yaml")
        original_sources = self.read_yaml("sources.yaml")
        cases = [
            ("people.yaml", lambda d: d["people"][0].update(languages=["cobol"]), "неизвестный язык cobol"),
            ("people.yaml", lambda d: d["people"][0].update(concepts=["no.such"]), "неизвестный понятие no.such"),
            ("people.yaml", lambda d: d["people"][0].update(lectures=["99"]), "неизвестный лекция 99"),
            ("people.yaml", lambda d: d["people"][0].update(lectures=[3]), "две цифры в кавычках"),
            ("people.yaml", lambda d: d["people"].append(deepcopy(d["people"][0])), "повторный или некорректный id"),
            ("sources.yaml", lambda d: d["sources"][0].update(people=["nobody"]), "неизвестный человек nobody"),
            ("sources.yaml", lambda d: d["sources"][0].update(kind="blog"), "kind='blog'"),
            ("sources.yaml", lambda d: d["sources"][0].update(labs=[7]), "номер ЛР от 1 до 5"),
            ("sources.yaml", lambda d: d["sources"][-1].pop("url"), "нужен url или doi"),
            ("sources.yaml", lambda d: d["sources"][0].pop("note"), "note: ожидается непустая строка"),
        ]
        for name, mutate, message in cases:
            with self.subTest(message=message):
                data = deepcopy(original_people if name == "people.yaml" else original_sources)
                mutate(data)
                self.write_mutation(name, data)
                self.assertIn(message, self.build(expected=1))
                (self.data / name).write_text(yaml.safe_dump(
                    original_people if name == "people.yaml" else original_sources,
                    allow_unicode=True, sort_keys=False), encoding="utf-8")

    def test_language_designer_must_be_linked_person(self):
        people = self.read_yaml("people.yaml")
        person = next(p for p in people["people"] if p["id"] == "graydon-hoare")
        person["languages"].remove("rust")
        self.write_mutation("people.yaml", people)
        self.assertIn("people.graydon-hoare: нет связи с языком rust", self.build(expected=1))
        raw = self.read_yaml("languages/rust.yaml")
        raw["meta"]["designers"].append("Nobody Known")
        self.write_mutation("languages/rust.yaml", raw)
        self.assertIn("автор 'Nobody Known' не описан в people.yaml", self.build(expected=1))


if __name__ == "__main__":
    unittest.main()
