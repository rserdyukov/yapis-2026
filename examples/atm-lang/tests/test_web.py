"""Мост для playground (fsmc/web.py) — тот же код, что исполняет Pyodide."""

from __future__ import annotations

import base64
import json
import unittest

from helpers import ATM, NEGATIVE, ROOT, compile_source
from fsmc.web import compile_json


class Web(unittest.TestCase):
    def test_ok_program(self):
        for fe in ("antlr", "lark"):
            with self.subTest(fe):
                r = json.loads(compile_json(ATM.read_text(encoding="utf-8"), fe))
                self.assertTrue(r["ok"])
                self.assertEqual(r["frontend"], fe)
                wasm = base64.b64decode(r["wasm"])
                self.assertEqual(wasm, compile_source(ATM.read_text(encoding="utf-8"), fe).wasm)
                self.assertEqual(r["meta"]["initial"], "Idle")
                self.assertEqual(r["stats"]["wasm_bytes"], len(wasm))
                self.assertIn("stateDiagram-v2", r["mermaid"])
                self.assertTrue(r["ast"].startswith("Program"))

    def test_errors_have_no_code(self):
        for path in NEGATIVE:
            r = json.loads(compile_json(path.read_text(encoding="utf-8")))
            with self.subTest(path.name):
                if not r["ok"]:
                    self.assertEqual(r["wasm"], "")
                    self.assertEqual(r["wat"], "")
                self.assertTrue(all({"level", "code", "message", "line", "col"} <= d.keys()
                                    for d in r["diagnostics"]))

    def test_syntax_error_has_no_ast(self):
        r = json.loads(compile_json((ROOT / "tests/negative/neg_13_syntax.fsm")
                                    .read_text(encoding="utf-8"), "lark"))
        self.assertFalse(r["ok"])
        self.assertEqual(r["ast"], "")
        self.assertEqual(r["mermaid"], "")


if __name__ == "__main__":
    unittest.main()
