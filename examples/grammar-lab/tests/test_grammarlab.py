"""Тесты grammar-lab. Номера T-N — сценарии из kickoff-документа
docs/_design/2026-09-26-task3-selfcheck-kickoff.md, раздел 11."""

from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from grammarlab.answer import parse_answer  # noqa: E402
from grammarlab.check import check  # noqa: E402
from grammarlab.grammar import (END, EPS, Grammar, accepts, build_table, compute_sets,  # noqa: E402
                                conflicts, first_witness, follow_witness, is_derivation, simulate)
from grammarlab.grid import apply_grid, grid_model  # noqa: E402
from grammarlab.web import apply_grid_json, check_json, grid_json  # noqa: E402

FIX = ROOT / "tests" / "fixtures"


def fixture(name: str) -> str:
    return (FIX / f"{name}.txt").read_text(encoding="utf-8")


def notes(text: str) -> list[tuple[str, str]]:
    return [(f.note, f.key) for f in check(parse_answer(text)).findings]


def replace_line(text: str, startswith: str, contains: str, old: str, new: str) -> str:
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if line.strip().startswith(startswith) and contains in line:
            lines[i] = line.replace(old, new)
            return "\n".join(lines)
    raise AssertionError(f"нет строки {startswith!r} … {contains!r}")


V8 = Grammar.from_dict("P", {
    "P": [["H", "G"]], "G": [["B", "G"], []], "H": [["h", "N"]],
    "N": [["t", "i", "N"], []], "B": [["b", "M", ";"]], "M": [[",", "b", "M"], []],
})


class Core(unittest.TestCase):
    def test_sets_match_task3_example(self):
        # FIRST/FOLLOW из task3.md:135-142 (они верны)
        s = compute_sets(V8)
        self.assertEqual(s.first, {"P": {"h"}, "G": {"b", EPS}, "H": {"h"}, "N": {"t", EPS},
                                   "B": {"b"}, "M": {",", EPS}})
        self.assertEqual(s.follow, {"P": {END}, "G": {END}, "H": {"b", END}, "N": {"b", END},
                                    "B": {"b", END}, "M": {";"}})
        self.assertEqual(conflicts(build_table(V8, s)), [])

    def test_every_witness_is_a_valid_derivation(self):
        # T-6: каждый вывод-свидетель — цепочка применений правил
        for g in (V8, parse_answer(fixture("v18-ok")).grammar, parse_answer(fixture("v12-ok")).grammar):
            s = compute_sets(g)
            for a in g.nonterminals:
                for t in s.follow[a]:
                    forms = follow_witness(g, s, a, t)
                    self.assertIsNotNone(forms, (a, t))
                    self.assertTrue(is_derivation(g, forms), (a, t, forms))
                    last = forms[-1]
                    self.assertTrue(any((t == END and k == len(last) - 1) or
                                        (k + 1 < len(last) and last[k + 1] == t)
                                        for k, x in enumerate(last) if x == a), (a, t, last))
                for t in s.first[a]:
                    forms = first_witness(g, s, a, t)
                    self.assertTrue(is_derivation(g, forms), (a, t))
                    self.assertEqual(forms[-1][:1] if t != EPS else forms[-1], [t] if t != EPS else [])

    def test_wrong_example_trace_fails_on_M_t(self):
        # T-5/T-27: в task3.md:171-175 трасса hbtib,b;$ неверна — ошибка на M[M, t]
        steps = simulate(V8, build_table(V8, compute_sets(V8)), "h b t i b , b ;".split())
        self.assertEqual(steps[-1].action, "error")
        self.assertEqual((steps[-1].stack[0], steps[-1].rest[0]), ("M", "t"))

    def test_earley(self):
        self.assertTrue(accepts(V8, "h t i b , b ;".split()))
        self.assertTrue(accepts(V8, ["h"]))
        self.assertFalse(accepts(V8, "h b t".split()))
        amb = Grammar.from_dict("E", {"E": [["E", "+", "E"], ["i"]]})
        self.assertTrue(accepts(amb, "i + i + i".split()))

    def test_left_recursion_and_productivity(self):
        g = Grammar.from_dict("E", {"E": [["E", "+", "T"], ["T"]], "T": [["i"]], "Z": [["Z", "x"]]})
        self.assertEqual(g.left_recursive(), {"E", "Z"})
        self.assertNotIn("Z", g.productive())
        self.assertNotIn("Z", g.reachable())


class Fixtures(unittest.TestCase):
    def test_reference_answers_have_no_errors(self):
        # T-5, T-10: эталонные ответы проходят без замечаний
        for name in ("v08-ok", "v12-ok", "v18-ok"):
            ans = parse_answer(fixture(name))
            self.assertTrue(ans.ok, [d.format() for d in ans.diagnostics])
            rep = check(ans)
            self.assertEqual(rep.findings, [], name)
            ok_prefix = "Алгоритм применён верно; конфликт" if name == "v18-ok" else "Ошибок нет"
            self.assertTrue(rep.verdict.startswith(ok_prefix), rep.verdict)

    def test_v18_has_declared_else_conflict(self):
        ans = parse_answer(fixture("v18-ok"))
        g = ans.grammar
        self.assertEqual(conflicts(build_table(g, compute_sets(g))), [("X", "else")])
        self.assertEqual(ans.conflict_choices[("X", "else")], ("X", ("else", "O")))


class Parsing(unittest.TestCase):
    def test_interpretation(self):
        # T-1: N -> t i N — три символа, ';' — терминал
        g = parse_answer(fixture("v08-ok")).grammar
        self.assertIn(("N", ("t", "i", "N")), g.rules)
        self.assertIn(("B", ("b", "M", ";")), g.rules)
        self.assertEqual(g.start, "P")

    def test_glued_symbols_warning(self):
        # T-2
        ans = parse_answer("grammar:\n  N -> tiN | eps\n")
        self.assertTrue(ans.ok)
        self.assertEqual([d.code for d in ans.diagnostics], ["W101"])
        self.assertIn("t i N", ans.diagnostics[0].message)
        self.assertIn(("N", ("tiN",)), ans.grammar.rules)

    def test_syntax_errors_are_localized_in_russian(self):
        # T-3
        cases = {
            "grammar:\n  S -> 'a\n": ("S001", 2),
            "grammar:\n  B -> b M ;\n": ("S007", 2),
            "grammar:\n  S -> a | | b\n": ("S002", 2),
            "grammar:\n  S -> a\nfolow:\n": ("S004", 3),
            "first:\n  P = { h }\n": ("S006", 0),
            "grammar:\n  S -> a\ngrammar:\n  S -> b\n": ("S005", 3),
            "grammar:\n  S -> a\n  M[S, a] = S -> a\n": ("S003", 3),
        }
        for text, (code, line) in cases.items():
            ans = parse_answer(text)
            self.assertFalse(ans.ok, text)
            d = next(d for d in ans.diagnostics if d.level == "error")
            self.assertEqual((d.code, d.line), (code, line), (text, d.format()))
            self.assertNotIn("__ANON", d.message)

    def test_section_names_are_not_symbols(self):
        # T-4: заголовок follow: после first: — секция, а не символ
        ans = parse_answer("grammar:\n  S -> a\nfirst:\n  S = { a }\nfollow:\n  S = { $ }\n")
        self.assertTrue(ans.ok)
        self.assertEqual(ans.follow, {"S": {END}})

    def test_nonterminal_may_be_named_like_keyword(self):
        ans = parse_answer("grammar:\n  M -> first M | eps\n  first -> x\n")
        self.assertTrue(ans.ok, [d.format() for d in ans.diagnostics])
        self.assertEqual(ans.grammar.nonterminals, ["M", "first"])


class Mutants(unittest.TestCase):
    base = fixture("v08-ok")

    def test_missing_follow_element(self):
        # T-6: в FOLLOW(N) пропущен b → вывод-свидетель
        text = self.base.replace("N = { b, $ }", "N = { $ }", 1)
        rep = check(parse_answer(text))
        [f] = rep.findings
        self.assertEqual((f.note, f.key), ("follow-wrong", "FOLLOW(N)"))
        self.assertIn("не хватает b", f.summary)
        self.assertIn("P ⇒ H G ⇒ H B G ⇒ H b M ';' G ⇒ h N b M ';' G", f.why)
        self.assertEqual(f.reveal, "FOLLOW(N) = { b, $ }")

    def test_extra_first_element(self):
        # T-7: лишний элемент объясняется правилами, без вывода
        text = self.base.replace("M = { ',', eps }", "M = { ',', ';', eps }")
        [f] = check(parse_answer(text)).findings
        self.assertEqual(f.note, "first-wrong")
        self.assertIn("лишние ';'", f.summary)
        self.assertNotIn("⇒", f.why)

    def test_extra_cell_counterexample(self):
        # T-8: лишнее M -> eps в M[M, t] → строка, где трассы расходятся
        text = self.base.replace("M[M, ';'] = M -> eps", "M[M, ';'] = M -> eps\n  M[M, t] = M -> eps")
        [f] = check(parse_answer(text)).findings
        self.assertEqual((f.note, f.key), ("cell-wrong", "M[M, t]"))
        self.assertIn("Пример: на входе «h b t»", f.why)
        self.assertEqual(f.reveal, "M[M, t] = пусто")

    def test_trace_row(self):
        # T-9: первая неверная строка трассы
        text = replace_line(self.base, "N G $", "b t i b", "N -> eps", "N -> t i N")
        [f] = check(parse_answer(text)).findings
        self.assertEqual(f.note, "trace-row-wrong")
        self.assertIn("строка 4", f.key)
        self.assertIn("N -> eps", f.reveal)

    def test_undeclared_else_conflict(self):
        # T-10 (негатив): конфликт висячего else не объявлен
        text = fixture("v18-ok").split("conflicts:")[0] + "\n"
        got = notes(text)
        self.assertIn(("conflict-undeclared", "M[X, else]"), got)
        self.assertIn(("choice-missing", "M[X, else]"), got)

    def test_untransformed_ambiguous_grammar(self):
        # T-11: вариант 1 без преобразования — итог не «ошибок нет»
        rep = check(parse_answer("grammar:\n  E -> E '+' E | E '*' E | '(' E ')' | i\n"))
        kinds = {f.note for f in rep.findings}
        self.assertIn("left-recursion", kinds)
        self.assertIn("conflict-undeclared", kinds)
        self.assertFalse(rep.verdict.startswith("Ошибок нет"))

    def test_trace_count(self):
        # T-28: 1 правильная + 2 неправильные
        text = self.base.split('trace "h b t i b')[0]
        self.assertIn(("trace-count", "примеры"), notes(text))

    def test_missing_cell_and_set_line(self):
        text = self.base.replace("  M[N, $] = N -> eps\n", "").replace("  H = { h }\n", "", 1)
        got = notes(text)
        self.assertIn(("cell-wrong", "M[N, $]"), got)
        self.assertIn(("first-missing-line", "FIRST(H)"), got)


class ReviewRegressions(unittest.TestCase):
    """Дефекты, найденные ревью (см. историю коммита)."""

    def test_left_recursive_table_is_fast(self):
        # Таблица неустранённой левой рекурсии зацикливала simulate и перебор контрпримеров.
        import time
        text = ("grammar:\n  E -> E '+' T | T\n  T -> T '*' F | F\n  F -> '(' E ')' | i\n"
                "table:\n  M[E, i] = E -> T\n  M[E, '('] = E -> T\n  M[T, i] = T -> F\n"
                "  M[F, i] = F -> i\n\ntrace \"i + i\":\n  E $ | i '+' i $ | E -> T\n")
        t0 = time.monotonic()
        rep = check(parse_answer(text))
        self.assertLess(time.monotonic() - t0, 3)
        self.assertIn("left-recursion", {f.note for f in rep.findings})

    def test_unreachable_cell_is_fast(self):
        import time
        text = fixture("v18-ok").replace("M[X, $] = X -> eps", "M[X, $] = X -> eps\n  M[Q, o] = X -> eps")
        t0 = time.monotonic()
        rep = check(parse_answer(text))
        self.assertLess(time.monotonic() - t0, 2)
        self.assertIn(("cell-wrong", "M[Q, o]"), [(f.note, f.key) for f in rep.findings])

    def test_witness_must_be_ambiguous(self):
        text = fixture("v18-ok").replace("M[X, else]: if i then if i then o else o",
                                         "M[X, else]: if i then o else o")
        self.assertIn(("witness-not-ambiguous", "M[X, else]"), notes(text))

    def test_declared_non_else_conflict_is_not_clean(self):
        text = ("grammar:\n  S -> a b | a c\nconflicts:\n  M[S, a]: a b\n"
                "  choose M[S, a] = S -> a b\n")
        rep = check(parse_answer(text))
        self.assertFalse(rep.verdict.startswith("Ошибок нет"), rep.verdict)

    def test_choice_must_be_in_cell(self):
        text = fixture("v18-ok").replace("choose M[X, else] = X -> else O", "choose M[X, else] = X -> else O O")
        self.assertIn(("choice-not-in-cell", "M[X, else]"), notes(text))

    def test_wrong_match_symbol(self):
        text = replace_line(fixture("v08-ok"), "h N G $", "h t i t i", "match h", "match t")
        self.assertIn("trace-row-wrong", {n for n, _ in notes(text)})

    def test_names_starting_with_keywords(self):
        ans = parse_answer("grammar:\n  S -> chooser errors\n  chooser -> b\n  errors -> accepted\n"
                           "  accepted -> matcher\n  matcher -> c\n")
        self.assertTrue(ans.ok, [d.format() for d in ans.diagnostics])
        self.assertEqual(ans.grammar.nonterminals, ["S", "chooser", "errors", "accepted", "matcher"])

    def test_empty_grammar_section(self):
        ans = parse_answer("grammar:\n")
        self.assertEqual([d.code for d in ans.diagnostics], ["S006"])

    def test_reserved_symbols(self):
        for text in ("grammar:\n  S -> 'ε' S | b\n", "grammar:\n  S -> a eps\n", "grammar:\n  S -> '$'\n"):
            self.assertEqual([d.code for d in parse_answer(text).diagnostics], ["S008"], text)

    def test_bom_and_nbsp(self):
        self.assertTrue(parse_answer("\ufeffgrammar:\n  S\u00a0-> a\n").ok)

    def test_dollar_in_trace_header(self):
        ans = parse_answer("grammar:\n  S -> a\ntrace \"a $\":\n  S $ | a $ | S -> a\n")
        self.assertEqual(ans.traces[0].word, ["a"])
        self.assertIn("W103", [d.code for d in ans.diagnostics])


class Grid(unittest.TestCase):
    """T-22: табличный редактор — то же самое, что ручной ввод DSL."""

    def test_roundtrip_on_fixtures(self):
        for name in ("v08-ok", "v12-ok", "v18-ok"):
            text = fixture(name)
            m = grid_model(text)
            self.assertTrue(m["ok"])
            self.assertEqual(m["lossy"], [], name)
            out = apply_grid(text, {k: m[k] for k in ("first", "follow", "table")})
            a, b = parse_answer(text), parse_answer(out["text"])
            self.assertEqual((a.first, a.follow, a.table), (b.first, b.follow, b.table), name)
            self.assertEqual(len(a.traces), len(b.traces))
            self.assertEqual(a.conflict_choices, b.conflict_choices)
            self.assertEqual(check(b).findings, [], name)
            # повторное применение ничего не меняет
            m2 = grid_model(out["text"])
            again = apply_grid(out["text"], {k: m2[k] for k in ("first", "follow", "table")})
            self.assertEqual(again["text"], out["text"])

    def test_model_shape(self):
        m = grid_model(fixture("v18-ok"))
        self.assertEqual(m["columns"][-1], "$")
        self.assertIn("'<>'", m["labels"].values())
        self.assertEqual(m["alternatives"]["X"], ["else O", "eps"])
        self.assertEqual(m["table"]["X"]["else"], [0, 1])       # конфликт — два правила
        self.assertEqual(m["cell_keys"]["X"]["else"], "M[X, else]")

    def test_sections_are_inserted_in_order(self):
        base = fixture("v08-ok")
        text = base.split("first:")[0] + base[base.index('trace "'):]
        m = grid_model(text)
        self.assertIsNone(m["first"])
        self.assertIsNone(m["table"])
        out = apply_grid(text, {"first": {"N": ["t", EPS]}, "follow": None,
                                "table": {"N": {"t": [0], "$": [1]}}})["text"]
        self.assertLess(out.index("grammar:"), out.index("first:"))
        self.assertLess(out.index("first:"), out.index("table:"))
        self.assertLess(out.index("table:"), out.index('trace "'))
        self.assertNotIn("follow:", out)
        ans = parse_answer(out)
        self.assertEqual(ans.first, {"N": {"t", EPS}})
        self.assertEqual(ans.table, {("N", "t"): [("N", ("t", "i", "N"))], ("N", END): [("N", ())]})

    def test_untouched_text_is_preserved(self):
        text = "# мой вариант 8\nversion: 1\n\n" + fixture("v08-ok").split("version: 1\n")[1]
        m = grid_model(text)
        grid = {k: m[k] for k in ("first", "follow", "table")}
        grid["follow"]["N"] = ["$"]
        out = apply_grid(text, grid)["text"]
        self.assertTrue(out.startswith("# мой вариант 8\nversion: 1\n"))
        self.assertEqual(out.split("follow:")[0], text.split("follow:")[0])
        self.assertIn("  N = { $ }", out)
        self.assertEqual(out[out.index('trace "'):], text[text.index('trace "'):])

    def test_lossy_entries_reported(self):
        text = ("grammar:\n  S -> a S | b\nfirst:\n  S = { a, b, c }\n  Q = { a }\n"
                "table:\n  M[S, a] = S -> a S\n  M[S, b] = S -> b b\n  M[Q, a] = S -> b\n")
        m = grid_model(text)
        self.assertEqual(m["first"], {"S": ["a", "b"]})
        self.assertEqual(m["table"], {"S": {"a": [0]}})
        self.assertEqual(len(m["lossy"]), 4, m["lossy"])

    def test_unparsed_text(self):
        self.assertFalse(grid_model("grammar:\n  B -> b ;\n")["ok"])
        r = apply_grid("grammar:\n  B -> b ;\n", {"first": {}})
        self.assertFalse(r["ok"])

    def test_json_bridge(self):
        text = fixture("v08-ok")
        m = json.loads(grid_json(text))
        grid = json.dumps({"first": m["first"], "follow": m["follow"], "table": m["table"]})
        out = json.loads(apply_grid_json(text, grid))
        self.assertTrue(out["ok"])
        self.assertEqual(check(parse_answer(out["text"])).findings, [])


class Interfaces(unittest.TestCase):
    def test_web_json(self):
        data = json.loads(check_json(fixture("v08-ok")))
        self.assertTrue(data["ok"])
        self.assertEqual(data["findings"], [])
        self.assertIn("P -> H G", data["interpretation"])
        bad = json.loads(check_json("grammar:\n  B -> b ;\n"))
        self.assertFalse(bad["ok"])
        self.assertEqual(bad["parse"][0]["code"], "S007")

    def test_cli_exit_codes(self):
        # T-13
        def run(text, *args):
            return subprocess.run([sys.executable, "-m", "grammarlab", "check", "-", *args],
                                  input=text, capture_output=True, text=True, cwd=ROOT)
        self.assertEqual(run(fixture("v08-ok")).returncode, 0)
        r = run(self.mutant(), "--reveal")
        self.assertEqual(r.returncode, 1)
        self.assertIn("эталон: FOLLOW(N) = { b, $ }", r.stdout)
        self.assertEqual(run("grammar:\n  B -> b ;\n").returncode, 2)

    @staticmethod
    def mutant():
        return fixture("v08-ok").replace("N = { b, $ }", "N = { $ }", 1)


if __name__ == "__main__":
    unittest.main()
