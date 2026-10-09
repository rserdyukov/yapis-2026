"""Тесты labgen: разбор вывода анализатора и прогоны на фикстуре Mini.

Фикстура fixtures/mini — маленький язык с эталонным анализатором; дефекты
включаются переменной LABGEN_MOCK_DEFECTS (см. fixtures/mini/compiler/mini.py).

Запуск: python3 -B -m unittest discover -s .github/review/tests/labgen -v
Прогоны с ANTLR пропускаются, если нет java или ANTLR_JAR.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
LIB = HERE.parent.parent / "lib"
MINI = HERE / "fixtures" / "mini"
sys.path.insert(0, str(LIB))

from labgen.judge import classify, error_lines, error_positions, judge  # noqa: E402
from labgen.lexing import find_grammar, find_jar, read_props, start_rule  # noqa: E402
from labgen.mutate import Mutant  # noqa: E402

JAR = find_jar(None)
HAVE_JAVA = shutil.which("java") is not None


def mutant(expect="error", mode="sem", op="undeclared-var", line=3, exit=1, output=""):
    m = Mutant("t001", op, mode, expect, "high", "1.txt", line, "", "", lines=[line])
    m.exit, m.output = exit, output
    judge(m)
    return m


class OutputParsing(unittest.TestCase):
    def test_error_lines_skip_ok_and_summary(self):
        out = "Синтаксический анализ: OK\nСемантическая ошибка: строка 4: x\nНайдено ошибок: 1\n"
        self.assertEqual(error_lines(out), ["Семантическая ошибка: строка 4: x"])

    def test_positions_formats(self):
        self.assertEqual(error_positions("Ошибка: строка 7: x"), [7])
        self.assertEqual(error_positions("error at line 12"), [12])
        self.assertEqual(error_positions("<file>:5:3: error: bad"), [5])
        self.assertEqual(error_positions("Ошибка (9, 2): bad"), [9])

    def test_classify(self):
        self.assertEqual(classify("Синтаксическая ошибка: строка 1"), "syn")
        self.assertEqual(classify("line 1:4 mismatched input ')' error"), "syn")
        self.assertEqual(classify("Лексическая ошибка: строка 2"), "lex")
        self.assertEqual(classify("Ошибка: строка 2: тип"), "sem")
        self.assertEqual(classify("Traceback (most recent call last):\n  File x"), "crash")
        self.assertEqual(classify("OK"), "?")


class Verdicts(unittest.TestCase):
    def test_ok_on_right_line(self):
        self.assertEqual(mutant(output="Семантическая ошибка: строка 3: x").verdict, "ok")

    def test_missed(self):
        self.assertEqual(mutant(exit=0, output="OK").verdict, "missed")

    def test_exit_code_zero_with_message(self):
        self.assertEqual(mutant(exit=0, output="Семантическая ошибка: строка 3: x").verdict, "exit-code")

    def test_sem_mutant_with_syntax_error_is_invalid(self):
        self.assertEqual(mutant(output="Синтаксическая ошибка: строка 3").verdict, "invalid")

    def test_elsewhere(self):
        self.assertEqual(mutant(output="Семантическая ошибка: строка 9: x").verdict, "elsewhere")

    def test_control_rejected_is_false_positive(self):
        self.assertEqual(mutant(expect="pass", output="Семантическая ошибка: строка 1").verdict,
                         "false-positive")

    def test_cascade(self):
        out = "Семантическая ошибка: строка 3: a\nСемантическая ошибка: строка 5: b"
        self.assertEqual(mutant(expect="one-error", op="cascade", output=out).verdict, "cascade")

    def test_timeout(self):
        self.assertEqual(mutant(exit=124, output="TIMEOUT 30s").verdict, "timeout")

    def test_crash_beats_everything(self):
        out = "Traceback (most recent call last):\nAttributeError: x"
        self.assertEqual(mutant(expect="no-crash", op="deep-expr", output=out).verdict, "crash")

    def test_syn_reported_as_semantic(self):
        m = mutant(mode="syn", op="drop-rparen", output="Семантическая ошибка: строка 3")
        self.assertEqual(m.verdict, "wrong-kind")


class Discovery(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def test_read_props(self):
        props = read_props(MINI / "README.md")
        self.assertEqual(props, {"conversion": "explicit", "declaration": "explicit", "overload": "no"})

    def test_split_grammar_parser_first(self):
        (self.tmp / "L.g4").write_text("lexer grammar L;\nID : [a-z]+ ;\n")
        (self.tmp / "P.g4").write_text("parser grammar P;\noptions { tokenVocab=L; }\nprog : ID+ ;\n")
        (self.tmp / "compile.sh").write_text("")
        self.assertEqual([p.name for p in find_grammar(self.tmp)], ["P.g4", "L.g4"])

    def test_generated_dirs_ignored(self):
        (self.tmp / "gen").mkdir()
        (self.tmp / "gen" / "Big.g4").write_text("grammar Big;\n" + "x : 'a' ;\n" * 50)
        (self.tmp / "My.g4").write_text("grammar My;\nprog : 'a' ;\n")
        self.assertEqual([p.name for p in find_grammar(self.tmp)], ["My.g4"])

    def test_start_rule(self):
        self.assertEqual(start_rule(MINI / "compiler" / "Mini.g4"), "program")


def run_labgen(*args, defects="", jar=True):
    out = Path(tempfile.mkdtemp())
    env = dict(os.environ, LABGEN_MOCK_DEFECTS=defects)
    if not jar:
        args = (*args, "--no-antlr")
    r = subprocess.run([sys.executable, "-B", str(LIB / "labgen"), str(MINI), "--out", str(out), *args],
                       capture_output=True, text=True, env=env, timeout=600)
    report = json.loads((out / "report.json").read_text()) if (out / "report.json").is_file() else None
    shutil.rmtree(out)
    return r, report


def verdicts(report, op=None):
    return {m["verdict"] for m in report["mutants"] if op is None or m["op"] == op}


@unittest.skipUnless(JAR and HAVE_JAVA, "нужны java и ANTLR_JAR")
class MiniEndToEnd(unittest.TestCase):
    """Эталонный анализатор: все ожидания выполнены; каждый дефект ловится."""

    def test_clean_all_ok(self):
        r, rep = run_labgen("--mode", "all")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual(rep["meta"]["lexer"], "ANTLR")
        self.assertEqual(verdicts(rep), {"ok"})
        ops = {m["op"] for m in rep["mutants"]}
        # cascade строится только для неявного объявления (`x = …`): в Mini его нет.
        expected = {"undeclared-var", "unknown-func", "arg-count", "string-arith", "string-cond",
                    "missing-return", "dup-func", "dup-param", "local-leak", "void-value",
                    "implicit-cast", "deep-expr", "ctl-rename-var", "ctl-rename-func",
                    "drop-rparen", "bad-char", "unclosed-string", "drop-delim"}
        self.assertEqual(expected - ops, set(), "мутации, которые фикстура больше не порождает")

    def test_error_examples_are_not_seeds(self):
        _, rep = run_labgen()
        self.assertEqual(sorted(rep["meta"]["seeds"]), ["1.txt", "2.txt"])

    def test_missing_return_check(self):
        r, rep = run_labgen(defects="no-return-check")
        self.assertEqual(r.returncode, 1)
        self.assertEqual(verdicts(rep, "missing-return"), {"missed"})

    def test_arg_count_check(self):
        _, rep = run_labgen(defects="no-arg-count")
        self.assertEqual(verdicts(rep, "arg-count"), {"missed"})

    def test_crash_detected(self):
        _, rep = run_labgen(defects="crash-dup-func")
        self.assertEqual(verdicts(rep, "dup-func"), {"crash"})

    def test_false_positive_on_controls(self):
        _, rep = run_labgen(defects="reject-fresh")
        self.assertIn("false-positive", verdicts(rep, "ctl-rename-var"))

    def test_no_run_writes_mutants_only(self):
        r, rep = run_labgen("--no-run")
        self.assertEqual(r.returncode, 0)
        self.assertTrue(rep["mutants"])
        self.assertEqual(verdicts(rep), {""})


class MiniFallbackLexer(unittest.TestCase):
    def test_runs_without_antlr(self):
        r, rep = run_labgen("--mode", "all", jar=False)
        self.assertIn(r.returncode, (0, 1), r.stderr)
        self.assertEqual(rep["meta"]["lexer"], "запасной")
        self.assertTrue(rep["mutants"])


if __name__ == "__main__":
    unittest.main()
