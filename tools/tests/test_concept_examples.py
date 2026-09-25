"""Check that the documented experiments actually include existing source files."""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


class ConceptExampleTests(unittest.TestCase):
    def test_all_priority_languages_have_source_and_experiment(self):
        directory = ROOT / "docs/concepts/examples"
        page = (directory / "index.md").read_text()
        languages = {"scheme", "j", "icon", "oz", "mercury", "datalog", "sql",
                     "sml", "idris", "eiffel", "cobol", "pony", "lustre", "modelica", "verilog"}
        referenced = set()
        for path in re.findall(r'--8<-- "(src/[^"\n]+)"', page):
            self.assertTrue((directory / path).is_file(), path)
            referenced.add(Path(path).parts[1])
        self.assertEqual(referenced, languages)
        for language in languages:
            self.assertIn("{#" + language + "}", page)

    def test_download_links_exist(self):
        directory = ROOT / "docs/concepts/examples"
        page = (directory / "index.md").read_text()
        for path in re.findall(r'\]\((src/[^)]+)\)', page):
            self.assertTrue((directory / path).is_file(), path)
