"""Проверка ответа: эталон вычисляется из грамматики студента.

Результат — список Finding. У каждой находки три уровня текста:
  summary  — уровень 2: где ошибка;
  why      — уровень 3: почему (вывод-свидетель, строка-контрпример, правило);
  reveal   — эталон элемента (показывается только по запросу).
Уровень 1 («в шаге N k ошибок») собирается из количества находок.

note — стабильный машинный код ошибки (answer note): не зависит от текста.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from itertools import product

from .answer import Answer, fmt_body, fmt_rule, fmt_set, q
from .grammar import (END, EPS, Grammar, Rule, Step, accepts, build_table, compute_sets,
                      conflicts, count_trees, first_witness, follow_witness, is_derivation, simulate)

STEPS = {
    "grammar": "Грамматика",
    "first": "FIRST",
    "follow": "FOLLOW",
    "table": "Таблица M",
    "conflicts": "Конфликты",
    "trace": "Трассы разбора",
}


@dataclass
class Finding:
    step: str
    key: str            # элемент: 'FIRST(N)', 'M[N, t]', 'trace 2, строка 5'
    note: str
    summary: str
    why: str = ""
    reveal: str = ""
    line: int = 0
    severity: str = "error"   # 'error' | 'warning'

    def to_dict(self) -> dict:
        return self.__dict__.copy()


@dataclass
class Report:
    parse: list = field(default_factory=list)       # Diagnostic
    interpretation: list[str] = field(default_factory=list)
    checked: list[str] = field(default_factory=list)
    findings: list[Finding] = field(default_factory=list)
    verdict: str = ""

    def by_step(self) -> dict[str, list[Finding]]:
        out: dict[str, list[Finding]] = {}
        for f in self.findings:
            out.setdefault(f.step, []).append(f)
        return out

    def to_dict(self) -> dict:
        return {
            "parse": [d.to_dict() for d in self.parse],
            "interpretation": self.interpretation,
            "checked": self.checked,
            "steps": {s: STEPS[s] for s in self.checked},
            "findings": [f.to_dict() for f in self.findings],
            "verdict": self.verdict,
        }


def _forms(forms: list[list[str]]) -> str:
    return " ⇒ ".join(" ".join(q(s) for s in f) if f else "ε" for f in forms)


# -------------------------------------------------------------- грамматика

def _check_grammar(g: Grammar, rep: Report) -> bool:
    ok = True
    for a in g.nonterminals:
        if a not in g.productive():
            ok = False
            rep.findings.append(Finding(
                "grammar", a, "nonproductive",
                f"Из нетерминала {a} нельзя вывести ни одной терминальной цепочки.",
                "Каждая альтернатива содержит нетерминал, который сам не порождает слов. "
                "Проверьте, есть ли у рекурсии выход (например, альтернатива eps или терминал).",
                severity="error"))
    unreachable = [a for a in g.nonterminals if a not in g.reachable()]
    for a in unreachable:
        rep.findings.append(Finding(
            "grammar", a, "unreachable",
            f"Нетерминал {a} недостижим из стартового {g.start}.",
            f"Стартовый символ — левая часть первого правила ({g.start}). "
            f"Ни одно правило, выводимое из него, не содержит {a}.",
            severity="warning"))
    lr = g.left_recursive()
    for a in sorted(lr):
        rep.findings.append(Finding(
            "grammar", a, "left-recursion",
            f"Нетерминал {a} леворекурсивен: предиктивный анализатор для такой грамматики не построить.",
            "Устраните левую рекурсию (задача 2): A → A α | β заменяется на A → β A', A' → α A' | eps.",
            severity="warning"))
    return ok


# -------------------------------------------------------------- множества

def _check_sets(kind: str, g: Grammar, sets, given: dict[str, set[str]], ans: Answer, rep: Report):
    ref = sets.first if kind == "first" else sets.follow
    name = kind.upper()
    for a in g.nonterminals:
        got = given.get(a)
        line = ans.set_lines.get((kind, a), 0)
        if got is None:
            rep.findings.append(Finding(
                kind, f"{name}({a})", f"{kind}-missing-line",
                f"Не записано {name}({a}).",
                reveal=f"{name}({a}) = {fmt_set(ref[a])}", line=line))
            continue
        missing = ref[a] - got
        extra = got - ref[a]
        if not missing and not extra:
            continue
        parts = []
        if missing:
            parts.append("не хватает " + ", ".join(q(s) for s in sorted(missing)))
        if extra:
            parts.append("лишние " + ", ".join(q(s) for s in sorted(extra)))
        whys = []
        for t in sorted(missing):
            whys.append(_why_member(kind, g, sets, a, t))
        for t in sorted(extra):
            whys.append(_why_not_member(kind, g, sets, a, t))
        rep.findings.append(Finding(
            kind, f"{name}({a})", f"{kind}-wrong",
            f"{name}({a}): " + "; ".join(parts) + ".",
            "\n".join(whys),
            f"{name}({a}) = {fmt_set(ref[a])}", line))
    for a in given:
        if not g.is_nt(a):
            rep.findings.append(Finding(
                kind, f"{name}({a})", f"{kind}-unknown",
                f"{a} — не нетерминал грамматики; {name} считается только для нетерминалов.",
                line=ans.set_lines.get((kind, a), 0), severity="warning"))


def _why_member(kind, g, sets, a, t) -> str:
    if kind == "first":
        forms = first_witness(g, sets, a, t)
        if forms and is_derivation(g, forms):
            if t == EPS:
                return f"ε ∈ FIRST({a}), потому что {a} выводит пустую цепочку: {_forms(forms)}"
            return f"{q(t)} ∈ FIRST({a}), потому что {_forms(forms)}"
    else:
        forms = follow_witness(g, sets, a, t)
        if forms and is_derivation(g, forms):
            if t == END:
                return f"$ ∈ FOLLOW({a}): {a} может стоять в конце сентенциальной формы: {_forms(forms)}"
            return f"{q(t)} ∈ FOLLOW({a}): в выводе {_forms(forms)} сразу за {a} стоит {q(t)}"
    if kind == "follow":
        reason = sets.follow_why.get((a, t))
        if reason and reason.rule and reason.rule[0] not in g.reachable():
            return (f"{q(t)} ∈ FOLLOW({a}) по правилу {fmt_rule(reason.rule)}. Вывода из {g.start} нет: "
                    f"{reason.rule[0]} недостижим, но алгоритм FOLLOW учитывает все правила грамматики.")
    return f"{q(t)} должен входить в {kind.upper()}({a})"


def _why_not_member(kind, g, sets, a, t) -> str:
    if kind == "first":
        starts = [f"{fmt_rule((a, b))} даёт {fmt_set(_seq_first(g, sets, b))}" for b in g.alternatives(a)]
        return f"{q(t)} ∉ FIRST({a}): FIRST объединяет начала альтернатив — " + "; ".join(starts)
    places = []
    for head, body in g.rules:
        for i, s in enumerate(body):
            if s == a:
                rest = body[i + 1:]
                f = _seq_first(g, sets, rest)
                txt = f"в {fmt_rule((head, body))} за {a} идёт " + (fmt_body(rest) if rest else "конец правила")
                txt += f" → FIRST = {fmt_set(f - {EPS})}" if rest else ""
                if EPS in f:
                    txt += f", плюс FOLLOW({head}) = {fmt_set(sets.follow[head])}"
                places.append(txt)
    if a == g.start:
        places.append(f"{a} — стартовый, отсюда $")
    return f"{q(t)} ∉ FOLLOW({a}). Вхождения {a}: " + "; ".join(places or ["нет"])


def _seq_first(g, sets, body):
    from .grammar import first_of_seq
    return first_of_seq(g, sets.first, body)


# ---------------------------------------------------------------- таблица

# Бюджет поиска строк-контрпримеров на весь шаг «таблица»: в Pyodide проверка
# идёт в главном потоке страницы, поэтому перебор ограничен по времени.
CEX_BUDGET_S = 0.3
CEX_MAX_LEN = 6


def _check_table(g, sets, ref_table, given, ans: Answer, rep: Report):
    keys = sorted(set(ref_table) | set(given))
    deadline = time.monotonic() + CEX_BUDGET_S
    reachable = g.reachable()
    columns = set(g.terminals) | {END}
    searchable = not g.left_recursive()
    for key in keys:
        want = ref_table.get(key, [])
        got = given.get(key, [])
        if sorted(want) == sorted(got):
            continue
        a, t = key
        cell = f"M[{a}, {q(t)}]"
        line = ans.cell_lines.get(key, 0)
        if not got:
            summary = f"{cell} должна быть заполнена."
        elif not want:
            summary = f"{cell} должна быть пустой (ошибка разбора)."
        else:
            summary = f"В {cell} неверное правило."
        why = _cell_reason(g, sets, key, want, got) if g.is_nt(a) else ""
        if not g.is_nt(a):
            why = f"{a} — не нетерминал грамматики: строки таблицы соответствуют нетерминалам."
        elif t not in columns:
            why = f"{q(t)} не терминал грамматики: столбцы таблицы — терминалы и $."
        elif searchable and a in reachable:
            cex = _cell_counterexample(g, ref_table, given, key, ans.conflict_choices, deadline)
            if cex:
                why += "\n" + cex
        reveal = f"{cell} = " + (" ;; ".join(fmt_rule(r) for r in want) if want else "пусто")
        rep.findings.append(Finding("table", cell, "cell-wrong", summary, why, reveal, line))


def _cell_reason(g, sets, key, want, got) -> str:
    a, t = key
    out = []
    for rule in set(got) - set(want):
        f = _seq_first(g, sets, rule[1])
        txt = f"{fmt_rule(rule)}: FIRST(правой части) = {fmt_set(f)}"
        if EPS in f:
            txt += f", и она обнуляема — берём FOLLOW({a}) = {fmt_set(sets.follow[a])}"
        txt += f"; {q(t)} туда не входит."
        out.append(txt)
    for rule in set(want) - set(got):
        f = _seq_first(g, sets, rule[1])
        if t in f:
            out.append(f"{fmt_rule(rule)} попадает в столбец {q(t)}, потому что {q(t)} ∈ FIRST({fmt_body(rule[1])}).")
        else:
            out.append(f"{fmt_rule(rule)} попадает в столбец {q(t)}: правая часть обнуляема, "
                       f"а {q(t)} ∈ FOLLOW({a}).")
    return "\n".join(out)


def _cell_counterexample(g, ref_table, given, key, choose, deadline) -> str:
    """Короткая строка, на которой трасса по таблице студента расходится с правильной.
    Пустая строка — если за отведённое время не нашлась."""
    terms = [s for s in g.terminals]
    for n in range(0, CEX_MAX_LEN + 1):
        for word in product(terms, repeat=n):
            if time.monotonic() > deadline:
                return ""
            w = list(word)
            ref = simulate(g, ref_table, w, choose)
            got = simulate(g, given, w, choose)
            if _touches(ref, key) or _touches(got, key):
                if [(_s.stack, _s.rest, _s.action, _s.rule) for _s in ref] != \
                        [(_s.stack, _s.rest, _s.action, _s.rule) for _s in got]:
                    i = next(k for k, (x, y) in enumerate(zip(ref + [None], got + [None])) if x != y)
                    y = got[i] if i < len(got) else None
                    x = ref[i] if i < len(ref) else None
                    return (f"Пример: на входе «{' '.join(q(s) for s in w) or 'ε'}» трасса по вашей таблице "
                            f"расходится с правильной на шаге {i + 1}: у вас {_act(y)}, должно быть {_act(x)}.")
    return ""


def _touches(steps: list[Step], key) -> bool:
    return any(s.action in ("rule", "error") and s.stack and (s.stack[0], s.rest[0]) == key for s in steps)


def _act(s: Step | None) -> str:
    if s is None:
        return "конец трассы"
    if s.action == "rule":
        return fmt_rule(s.rule)
    if s.action == "match":
        return f"match {q(s.rest[0])}"
    return s.action


# -------------------------------------------------------------- конфликты

def _check_conflicts(g, ref_table, ans: Answer, rep: Report) -> list[tuple[str, str]]:
    conf = conflicts(ref_table)
    for key in conf:
        a, t = key
        cell = f"M[{a}, {q(t)}]"
        rules = " и ".join(fmt_rule(r) for r in ref_table[key])
        if key not in ans.conflict_witnesses:
            rep.findings.append(Finding(
                "conflicts", cell, "conflict-undeclared",
                f"Грамматика не LL(1): в {cell} попадают два правила ({rules}). Конфликт не объявлен.",
                "Если конфликт устраним — доделайте преобразование (шаг 3: левая факторизация, "
                "устранение левой рекурсии). Висячий else (варианты 18, 28, 29) не устраняется: "
                "объявите конфликт в секции conflicts, приведите строку с двумя деревьями и выбор правила.",
                severity="warning"))
        else:
            w = ans.conflict_witnesses[key]
            if not accepts(g, w):
                rep.findings.append(Finding(
                    "conflicts", cell, "witness-not-in-language",
                    f"Свидетель конфликта «{' '.join(q(s) for s in w)}» не выводится в грамматике."))
            elif count_trees(g, w, 2) < 2:
                rep.findings.append(Finding(
                    "conflicts", cell, "witness-not-ambiguous",
                    f"У строки «{' '.join(q(s) for s in w)}» одно дерево разбора: она не показывает, "
                    f"что грамматика неоднозначна.",
                    "Для висячего else подходит строка с двумя if и одним else, например "
                    "if i then if i then o else o."))
            elif not _passes_cell(g, ref_table, w, key):
                rep.findings.append(Finding(
                    "conflicts", cell, "witness-misses-cell",
                    f"Разбор свидетеля «{' '.join(q(s) for s in w)}» не проходит через {cell}: "
                    f"он не показывает этот конфликт.", severity="warning"))
        if key in ans.conflict_choices and ans.conflict_choices[key] not in ref_table[key]:
            rep.findings.append(Finding(
                "conflicts", cell, "choice-not-in-cell",
                f"Выбранное правило {fmt_rule(ans.conflict_choices[key])} не входит в {cell}: "
                f"там {rules}."))
        if key not in ans.conflict_choices:
            rep.findings.append(Finding(
                "conflicts", cell, "choice-missing",
                f"Для {cell} не указано, какое правило выбирает анализатор (choose M[…] = …).",
                "Для висячего else принято правило «else относится к ближайшему if»: выбирается "
                "правило, которое сразу забирает else.", severity="warning"))
    for key in ans.conflict_witnesses:
        if key not in conf:
            rep.findings.append(Finding(
                "conflicts", f"M[{key[0]}, {q(key[1])}]", "conflict-false",
                f"В M[{key[0]}, {q(key[1])}] конфликта нет — в ячейку попадает не больше одного правила."))
    return conf


def _passes_cell(g, table, word, key) -> bool:
    for rule in table[key]:
        steps = simulate(g, table, word, {key: rule})
        if _touches(steps, key):
            return True
    return False


# ----------------------------------------------------------------- трассы

def _check_traces(g, ref_table, ans: Answer, rep: Report):
    choose = dict(ans.conflict_choices)
    good = bad = 0
    for n, tr in enumerate(ans.traces, 1):
        ref = simulate(g, ref_table, tr.word, choose)
        in_lang = accepts(g, tr.word)
        label = f"трасса {n} «{' '.join(q(s) for s in tr.word)}»"
        if ref[-1].action == "accept":
            good += 1
        else:
            bad += 1
        if ref[-1].action == "accept" and not in_lang or ref[-1].action == "error" and in_lang:
            rep.findings.append(Finding(
                "trace", label, "trace-parser-disagrees",
                f"{label}: анализатор по таблице и грамматика расходятся "
                f"({'принимает' if ref[-1].action == 'accept' else 'отвергает'} строку, которая "
                f"{'не ' if not in_lang else ''}принадлежит языку). Проверьте конфликты таблицы.",
                severity="warning"))
        for i, (row, want) in enumerate(zip(tr.rows, ref)):
            if _row_eq(row, want):
                continue
            rep.findings.append(Finding(
                "trace", f"{label}, строка {i + 1}", "trace-row-wrong",
                f"{label}: первая неверная строка — {i + 1}.",
                _row_why(row, want),
                "Ожидалось: " + _fmt_row(want), row.line))
            break
        else:
            if len(tr.rows) < len(ref):
                rep.findings.append(Finding(
                    "trace", label, "trace-short",
                    f"{label}: трасса оборвана после строки {len(tr.rows)}; "
                    f"разбор ещё не закончен.",
                    reveal="Следующая строка: " + _fmt_row(ref[len(tr.rows)]),
                    line=tr.rows[-1].line if tr.rows else tr.line))
            elif len(tr.rows) > len(ref):
                rep.findings.append(Finding(
                    "trace", label, "trace-long",
                    f"{label}: после строки {len(ref)} ({ref[-1].action}) разбор уже закончен.",
                    line=tr.rows[len(ref)].line))
    if ans.traces and (good, bad) != (1, 2):
        rep.findings.append(Finding(
            "trace", "примеры", "trace-count",
            f"По условию нужны одна правильная и две неправильные строки; сейчас правильных {good}, "
            f"неправильных {bad}.", severity="warning"))


def _row_eq(row, want: Step) -> bool:
    if list(row.stack) != list(want.stack) or list(row.rest) != list(want.rest):
        return False
    if row.action != want.action:
        return False
    if row.action == "match" and row.matched != want.rest[0]:
        return False
    return row.action != "rule" or row.rule == want.rule


def _row_why(row, want: Step) -> str:
    if list(row.stack) != list(want.stack):
        return "Стек не совпадает: проверьте, что правая часть правила кладётся на стек целиком, первым символом наверх."
    if list(row.rest) != list(want.rest):
        return "Остаток входа не совпадает: терминал снимается только действием match."
    if want.action == "error":
        return (f"Ячейка M[{want.stack[0]}, {q(want.rest[0])}] пуста (или вершина-терминал не совпадает "
                f"с входом) — здесь анализатор сообщает об ошибке.")
    if want.action == "match":
        return f"На вершине терминал, совпадающий с входом, — нужно match {q(want.rest[0])}."
    if want.action == "accept":
        return "Стек и вход пусты ($ и $) — строка принята."
    return (f"Правило берётся из ячейки M[{want.stack[0]}, {q(want.rest[0])}] "
            f"(вершина стека и текущий входной символ).")


def _fmt_row(s: Step) -> str:
    return f"{' '.join(q(x) for x in s.stack)} | {' '.join(q(x) for x in s.rest)} | {_act(s)}"


# ------------------------------------------------------------------ сборка

def check(ans: Answer) -> Report:
    from .answer import fmt_grammar
    rep = Report(parse=list(ans.diagnostics))
    if not ans.ok or ans.grammar is None:
        rep.verdict = "Ответ не разобран: исправьте ошибки записи."
        return rep
    g = ans.grammar
    rep.interpretation = fmt_grammar(g) + [
        f"стартовый символ: {g.start}",
        "нетерминалы: " + ", ".join(g.nonterminals),
        "терминалы: " + ", ".join(q(t) for t in g.terminals),
    ]
    rep.checked.append("grammar")
    if not _check_grammar(g, rep):
        rep.verdict = "Грамматика содержит непродуктивные нетерминалы — остальные шаги не проверялись."
        return rep
    sets = compute_sets(g)
    table = build_table(g, sets)
    if ans.first is not None:
        rep.checked.append("first")
        _check_sets("first", g, sets, ans.first, ans, rep)
    if ans.follow is not None:
        rep.checked.append("follow")
        _check_sets("follow", g, sets, ans.follow, ans, rep)
    if ans.table is not None:
        rep.checked.append("table")
        _check_table(g, sets, table, ans.table, ans, rep)
    rep.checked.append("conflicts")
    conf = _check_conflicts(g, table, ans, rep)
    if ans.traces:
        rep.checked.append("trace")
        _check_traces(g, table, ans, rep)

    errors = [f for f in rep.findings if f.severity == "error"]
    if errors:
        rep.verdict = f"Найдено ошибок: {len(errors)}."
    elif g.left_recursive() or (conf and set(conf) - set(ans.conflict_choices)):
        rep.verdict = ("Алгоритм применён верно, но грамматика не пригодна для предиктивного анализа: "
                       "см. замечания по грамматике и конфликтам.")
    elif conf:
        cells = ", ".join(f"M[{a}, {q(t)}]" for a, t in conf)
        rep.verdict = (f"Алгоритм применён верно; конфликт в {cells} объявлен и разрешён. "
                       "Это допустимо только для неустранимого конфликта (висячий else, варианты "
                       "18, 28, 29) — в остальных вариантах доделайте преобразование грамматики.")
    else:
        missing = [STEPS[s] for s in ("first", "follow", "table", "trace") if s not in rep.checked]
        rep.verdict = ("Ошибок нет: алгоритм применён верно. "
                       "Соответствие грамматики описанию языка варианта не проверялось.")
        if missing:
            rep.verdict += " Не записаны: " + ", ".join(missing) + "."
    return rep
