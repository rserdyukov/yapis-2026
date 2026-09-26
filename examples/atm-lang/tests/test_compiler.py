"""Тесты компилятора fsmc.

    cd examples/atm-lang && python3 -m unittest discover -s tests -v

Node и wat2wasm необязательны: без них соответствующие тесты пропускаются
(SKIP — не успех; в CI оба установлены).
"""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

from helpers import (ATM, EXAMPLES, FRONTENDS, NEGATIVE, NODE, ROOT, SCENARIOS, WAT2WASM,
                     compile_source, expected_codes, run_node, run_reference)
from fsmc import parse
from fsmc.wasm import sleb, strip_custom_sections, uleb


class Frontends(unittest.TestCase):
    """ANTLR и Lark — два разных парсера одного языка. Они обязаны давать
    одинаковое AST и одинаковую диагностику, иначе один из них ошибается."""

    def test_same_ast_on_valid_programs(self):
        for path in EXAMPLES + NEGATIVE:
            src = path.read_text(encoding="utf-8")
            with self.subTest(path.name):
                a, da = parse(src, "antlr")
                b, db = parse(src, "lark")
                self.assertEqual(a is None, b is None, "один фронтенд принял, другой нет")
                if a is not None:
                    self.assertEqual(a, b)

    def test_same_diagnostics_codes(self):
        for path in EXAMPLES + NEGATIVE:
            src = path.read_text(encoding="utf-8")
            with self.subTest(path.name):
                a = compile_source(src, "antlr")
                b = compile_source(src, "lark")
                key = lambda r: [(d.code, d.line, d.col) for d in r.diagnostics]  # noqa: E731
                self.assertEqual(key(a), key(b))

    def test_same_wasm(self):
        src = ATM.read_text(encoding="utf-8")
        self.assertEqual(compile_source(src, "antlr").wasm, compile_source(src, "lark").wasm)

    def test_syntax_variants(self):
        # Конструкции, которых нет в atm.fsm, — разбор обоими фронтендами.
        src = '''machine M
          const A: int = 2 * (3 + 4) - -1
          const B: bool = not true or false and 1 < 2
          context { x: int = A % 5, s: string = "a\\"b\\\\c\\n" }
          events { e(v: int, w: string), f() }
          states S
          initial S
          terminal S
          action act(p: int) {
            if p > 0 { x = p } else if p == 0 { x = 0 } else { say "neg", p }
          }
          S -- e(v, _: string) [v != 0] ---> / act(v)
          S -- e(_, _) else -> / act(0)
          S -- f() ignore
        '''
        a, da = parse(src, "antlr")
        b, db = parse(src, "lark")
        self.assertFalse(da.items, [d.format() for d in da.items])
        self.assertFalse(db.items, [d.format() for d in db.items])
        self.assertEqual(a, b)
        self.assertEqual(a.fields[1].init.value, 'a"b\\c\n')


class Negative(unittest.TestCase):
    """Каждый файл tests/negative/*.fsm объявляет ожидаемые коды в
    `// expect:`. Набор кодов должен совпасть ТОЧНО: лишняя ошибка — тоже
    регрессия (например, каскад из одной опечатки)."""

    def test_expected_codes(self):
        self.assertGreaterEqual(len(NEGATIVE), 10)
        for path in NEGATIVE:
            for fe in FRONTENDS:
                with self.subTest(file=path.name, frontend=fe):
                    r = compile_source(path.read_text(encoding="utf-8"), fe)
                    got = {d.code for d in r.diagnostics}
                    self.assertEqual(got, expected_codes(path),
                                     "\n".join(d.format(path.name) for d in r.diagnostics))

    def test_errors_block_codegen_warnings_do_not(self):
        for path in NEGATIVE:
            r = compile_source(path.read_text(encoding="utf-8"))
            with self.subTest(path.name):
                has_errors = any(c.startswith("E") for c in expected_codes(path))
                self.assertEqual(r.ok, not has_errors)
                self.assertEqual(bool(r.wasm), not has_errors)

    def test_naive_translation_is_rejected(self):
        # Главный тест карточки: баг, пропущенный Python, ловится до запуска.
        r = compile_source((ROOT / "tests/negative/neg_10_naive.fsm").read_text(encoding="utf-8"))
        messages = [d.message for d in r.diagnostics]
        self.assertTrue(any("'Dispencing'" in m and "'Dispensing'" in m for m in messages))
        self.assertTrue(any("'Dispensing' недостижимо" in m for m in messages))
        timeout_missing = [m for m in messages if m.startswith("в '") and "timeout" in m]
        self.assertEqual(len(timeout_missing), 6, "timeout не обработан ни в одном состоянии")

    def test_cli_exit_codes(self):
        env_py = [__import__("sys").executable, "-m", "fsmc"]
        ok = subprocess.run(env_py + [str(ATM), "--check"], cwd=ROOT, capture_output=True)
        self.assertEqual(ok.returncode, 0, ok.stderr)
        bad = subprocess.run(env_py + [str(ROOT / "tests/negative/neg_01_typo_state.fsm"),
                                       "--check"], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(bad.returncode, 1)
        self.assertIn("E101", bad.stderr)
        warn = subprocess.run(env_py + [str(ROOT / "tests/negative/neg_07_unhandled.fsm"),
                                        "--check", "--werror"], cwd=ROOT, capture_output=True)
        self.assertEqual(warn.returncode, 1)


class Examples(unittest.TestCase):
    def test_examples_compile_without_diagnostics(self):
        self.assertIn(ATM, EXAMPLES)
        for path in EXAMPLES:
            with self.subTest(path.name):
                r = compile_source(path.read_text(encoding="utf-8"))
                self.assertEqual([d.format(path.name) for d in r.diagnostics], [])
                self.assertTrue(r.wasm.startswith(b"\x00asm\x01\x00\x00\x00"))


@unittest.skipUnless(NODE, "node не найден")
class Scenarios(unittest.TestCase):
    """Дифференциальный тест: скомпилированный WASM против reference.py."""

    @classmethod
    def setUpClass(cls):
        cls.wasm = compile_source(ATM.read_text(encoding="utf-8")).wasm

    def test_matches_reference(self):
        self.assertGreaterEqual(len(SCENARIOS), 6)
        for scenario in SCENARIOS:
            with self.subTest(scenario.name):
                self.assertEqual(run_node(self.wasm, scenario), run_reference(scenario))

    def test_features_expected_output(self):
        # У каждого примера examples/X.fsm со сценарием X.events есть X.expected.
        for path in EXAMPLES:
            events = path.with_suffix(".events")
            if not events.exists():
                continue
            with self.subTest(path.name):
                wasm = compile_source(path.read_text(encoding="utf-8")).wasm
                self.assertEqual(run_node(wasm, events),
                                 path.with_suffix(".expected").read_text(encoding="utf-8"))

    def test_card_oracle(self):
        # Эталонный вывод из карточки, раздел 2, — буквально.
        expected = ("Введите PIN\nНеверный PIN. Осталось попыток: 2\n"
                    "Неверный PIN. Осталось попыток: 1\nЗдравствуйте! Выберите операцию\n"
                    "Недостаточно средств\nВыдано 3000 руб. Остаток 2000 руб.\n"
                    "Заберите карту\nГотов к работе\nИтоговое состояние: Idle\n")
        self.assertEqual(run_node(self.wasm, ROOT / "scenarios/01_success.events"), expected)


class Wasm(unittest.TestCase):
    def test_leb128(self):
        self.assertEqual(uleb(0), b"\x00")
        self.assertEqual(uleb(624485), b"\xe5\x8e\x26")
        self.assertEqual(sleb(-1), b"\x7f")
        self.assertEqual(sleb(-123456), b"\xc0\xbb\x78")
        self.assertEqual(sleb(64), b"\xc0\x00")
        self.assertEqual(sleb(-8), b"\x78")

    @unittest.skipUnless(WAT2WASM, "wat2wasm не найден")
    def test_encoder_matches_wat2wasm(self):
        # Наш кодировщик и wat2wasm, собирающий наш же WAT, дают одни байты.
        # Так проверяются сразу и WAT (он валиден), и двоичный кодировщик.
        for path in EXAMPLES:
            r = compile_source(path.read_text(encoding="utf-8"))
            with tempfile.TemporaryDirectory() as tmp, self.subTest(path.name):
                wat = Path(tmp) / "m.wat"
                wat.write_text(r.wat, encoding="utf-8")
                subprocess.run([WAT2WASM, str(wat), "-o", str(Path(tmp) / "m.wasm")], check=True)
                self.assertEqual(strip_custom_sections(r.wasm),
                                 (Path(tmp) / "m.wasm").read_bytes())


class Grammar(unittest.TestCase):
    def test_generated_parser_matches_grammar(self):
        # Без Java тест пропускается: сравнить не с чем.
        import shutil
        if not (shutil.which("java") or shutil.which("antlr")):
            self.skipTest("java не найдена")
        r = subprocess.run([__import__("sys").executable, "tools/gen_antlr.py", "--check"],
                           cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)


if __name__ == "__main__":
    unittest.main()
