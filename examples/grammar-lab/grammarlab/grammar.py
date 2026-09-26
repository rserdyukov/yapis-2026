"""Модель КС-грамматики и алгоритмы задачи 3.

FIRST/FOLLOW с запоминанием причин (из них строятся выводы-свидетели),
таблица предиктивного анализатора с конфликтами, симуляция трассы,
принадлежность слова языку (Earley).

Символ — строка. Правая часть правила — кортеж символов, пустой кортеж — ε.
В множествах FIRST пустая цепочка обозначается EPS, конец входа — END.
"""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field

EPS = "ε"
END = "$"

Rule = tuple[str, tuple[str, ...]]


@dataclass
class Grammar:
    start: str
    rules: list[Rule]
    nonterminals: list[str] = field(init=False)

    def __post_init__(self):
        seen: list[str] = []
        for head, _ in self.rules:
            if head not in seen:
                seen.append(head)
        self.nonterminals = seen
        self._nt = set(seen)

    @classmethod
    def from_dict(cls, start: str, prods: dict[str, list[list[str]]]) -> "Grammar":
        return cls(start, [(a, tuple(b)) for a, alts in prods.items() for b in alts])

    def is_nt(self, symbol: str) -> bool:
        return symbol in self._nt

    def alternatives(self, head: str) -> list[tuple[str, ...]]:
        return [body for h, body in self.rules if h == head]

    @property
    def terminals(self) -> list[str]:
        out: list[str] = []
        for _, body in self.rules:
            for s in body:
                if not self.is_nt(s) and s not in out:
                    out.append(s)
        return out

    # ---------------------------------------------------------------- свойства

    def nullable(self) -> set[str]:
        null: set[str] = set()
        changed = True
        while changed:
            changed = False
            for head, body in self.rules:
                if head not in null and all(s in null for s in body):
                    null.add(head)
                    changed = True
        return null

    def productive(self) -> set[str]:
        prod: set[str] = set()
        changed = True
        while changed:
            changed = False
            for head, body in self.rules:
                if head not in prod and all(not self.is_nt(s) or s in prod for s in body):
                    prod.add(head)
                    changed = True
        return prod

    def reachable(self) -> set[str]:
        seen = {self.start}
        queue = deque([self.start])
        while queue:
            a = queue.popleft()
            for body in self.alternatives(a):
                for s in body:
                    if self.is_nt(s) and s not in seen:
                        seen.add(s)
                        queue.append(s)
        return seen

    def left_recursive(self) -> set[str]:
        """Нетерминалы A, для которых A ⇒+ A… (с учётом обнуляемых префиксов)."""
        nullable = self.nullable()
        edges: dict[str, set[str]] = {a: set() for a in self.nonterminals}
        for head, body in self.rules:
            for s in body:
                if self.is_nt(s):
                    edges[head].add(s)
                if s not in nullable:
                    break
        out = set()
        for a in self.nonterminals:
            stack, seen = list(edges[a]), set()
            while stack:
                b = stack.pop()
                if b == a:
                    out.add(a)
                    break
                if b not in seen:
                    seen.add(b)
                    stack.extend(edges[b])
        return out


# -------------------------------------------------------------- FIRST/FOLLOW

@dataclass(frozen=True)
class Reason:
    """Почему элемент попал в множество.

    FIRST(A):  'terminal' — правило A → β t …, β ⇒* ε, t на позиции pos;
               'first'    — правило A → β B …, β ⇒* ε, B на позиции pos;
               'eps'      — правило A → β, β ⇒* ε.
    FOLLOW(A): 'start'    — A стартовый, элемент $;
               'follow-first'  — правило X → α A γ, элемент ∈ FIRST(γ);
               'follow-follow' — правило X → α A γ, γ ⇒* ε, элемент ∈ FOLLOW(X).
    pos — позиция A (для FOLLOW) или символа-источника (для FIRST) в правой части.
    """
    kind: str
    rule: Rule | None = None
    pos: int = -1


@dataclass
class Sets:
    first: dict[str, set[str]]
    follow: dict[str, set[str]]
    first_why: dict[tuple[str, str], Reason]
    follow_why: dict[tuple[str, str], Reason]


def first_of_seq(g: Grammar, first: dict[str, set[str]], seq) -> set[str]:
    out: set[str] = set()
    for s in seq:
        f = first[s] if g.is_nt(s) else {s}
        out |= f - {EPS}
        if EPS not in f:
            return out
    out.add(EPS)
    return out


def compute_sets(g: Grammar) -> Sets:
    first: dict[str, set[str]] = {a: set() for a in g.nonterminals}
    fwhy: dict[tuple[str, str], Reason] = {}

    def add_first(a, t, reason):
        if t not in first[a]:
            first[a].add(t)
            fwhy[(a, t)] = reason
            return True
        return False

    changed = True
    while changed:
        changed = False
        for rule in g.rules:
            head, body = rule
            for i, s in enumerate(body):
                if not g.is_nt(s):
                    changed |= add_first(head, s, Reason("terminal", rule, i))
                    break
                for t in sorted(first[s] - {EPS}):
                    changed |= add_first(head, t, Reason("first", rule, i))
                if EPS not in first[s]:
                    break
            else:
                changed |= add_first(head, EPS, Reason("eps", rule))

    follow: dict[str, set[str]] = {a: set() for a in g.nonterminals}
    owhy: dict[tuple[str, str], Reason] = {}

    def add_follow(a, t, reason):
        if t not in follow[a]:
            follow[a].add(t)
            owhy[(a, t)] = reason
            return True
        return False

    add_follow(g.start, END, Reason("start"))
    changed = True
    while changed:
        changed = False
        for rule in g.rules:
            head, body = rule
            for i, s in enumerate(body):
                if not g.is_nt(s):
                    continue
                rest = first_of_seq(g, first, body[i + 1:])
                for t in sorted(rest - {EPS}):
                    changed |= add_follow(s, t, Reason("follow-first", rule, i))
                if EPS in rest:
                    for t in sorted(follow[head]):
                        changed |= add_follow(s, t, Reason("follow-follow", rule, i))
    return Sets(first, follow, fwhy, owhy)


# ------------------------------------------------------------------- таблица

Table = dict[tuple[str, str], list[Rule]]


def build_table(g: Grammar, sets: Sets) -> Table:
    table: Table = {}
    for rule in g.rules:
        head, body = rule
        f = first_of_seq(g, sets.first, body)
        cols = (f - {EPS}) | (sets.follow[head] if EPS in f else set())
        for t in cols:
            cell = table.setdefault((head, t), [])
            if rule not in cell:
                cell.append(rule)
    return table


def conflicts(table: Table) -> list[tuple[str, str]]:
    return sorted(k for k, v in table.items() if len(v) > 1)


# -------------------------------------------------------------------- трасса

@dataclass(frozen=True)
class Step:
    stack: tuple[str, ...]   # вершина слева, END в конце
    rest: tuple[str, ...]    # остаток входа, END в конце
    action: str              # 'rule' | 'match' | 'accept' | 'error'
    rule: Rule | None = None


def simulate(g: Grammar, table: Table, word: list[str],
             choose: dict[tuple[str, str], Rule] | None = None,
             limit: int = 500) -> list[Step]:
    """Трасса предиктивного анализатора по таблице.

    В конфликтной ячейке берётся правило из choose; если выбора нет — error.
    """
    stack = [g.start, END]
    inp = list(word) + [END]
    steps: list[Step] = []
    # Без левой рекурсии стек не растёт больше чем на |N| правил подряд без
    # match; иначе таблица зациклилась (например, не устранена левая рекурсия).
    since_match = 0
    max_rules = len(g.nonterminals) + 1
    while len(steps) < limit:
        top, la = stack[0], inp[0]
        snap = (tuple(stack), tuple(inp))
        if top == END and la == END:
            steps.append(Step(*snap, "accept"))
            return steps
        if not g.is_nt(top):
            if top == la:
                steps.append(Step(*snap, "match"))
                stack.pop(0)
                inp.pop(0)
                since_match = 0
                continue
            steps.append(Step(*snap, "error"))
            return steps
        cell = table.get((top, la), [])
        rule = cell[0] if len(cell) == 1 else (choose or {}).get((top, la))
        if rule is None:
            steps.append(Step(*snap, "error"))
            return steps
        since_match += 1
        if since_match > max_rules:
            steps.append(Step(*snap, "error"))
            return steps
        steps.append(Step(*snap, "rule", rule))
        stack = list(rule[1]) + stack[1:]
    steps.append(Step(tuple(stack), tuple(inp), "error"))
    return steps


def accepts(g: Grammar, word: list[str]) -> bool:
    """Принадлежит ли слово языку грамматики (Earley; работает для любой КС-грамматики)."""
    nullable = g.nullable()
    n = len(word)
    root: Rule = ("⊤", (g.start,))
    chart: list[set[tuple[str, tuple[str, ...], int, int]]] = [set() for _ in range(n + 1)]
    chart[0].add((*root, 0, 0))
    for i in range(n + 1):
        agenda = list(chart[i])

        def add(item):
            if item not in chart[i]:
                chart[i].add(item)
                agenda.append(item)

        while agenda:
            head, body, dot, origin = agenda.pop()
            if dot < len(body):
                s = body[dot]
                if g.is_nt(s):
                    for alt in g.alternatives(s):
                        add((s, alt, 0, i))
                    if s in nullable:
                        add((head, body, dot + 1, origin))
                elif i < n and word[i] == s:
                    chart[i + 1].add((head, body, dot + 1, origin))
            else:
                for h2, b2, d2, o2 in list(chart[origin]):
                    if d2 < len(b2) and b2[d2] == head:
                        add((h2, b2, d2 + 1, o2))
    return (*root, 1, 0) in chart[n]


# ----------------------------------------------------------------- выводы
#
# Вывод — список сентенциальных форм; соседние формы отличаются ровно одним
# применением правила (проверяется в тестах). Для FOLLOW(A) ∋ t строится вывод
# S ⇒* α A t β, для FIRST(A) ∋ t — вывод A ⇒* t β.


class _Derivation:
    def __init__(self, g: Grammar, sets: Sets, start: list[str]):
        self.g, self.sets = g, sets
        self.forms = [list(start)]

    @property
    def form(self) -> list[str]:
        return self.forms[-1]

    def apply(self, idx: int, rule: Rule) -> None:
        f = self.form
        assert f[idx] == rule[0]
        self.forms.append(f[:idx] + list(rule[1]) + f[idx + 1:])

    def erase(self, idx: int) -> None:
        """Вывести ε из обнуляемого нетерминала на позиции idx."""
        sym = self.form[idx]
        reason = self.sets.first_why[(sym, EPS)]
        self.apply(idx, reason.rule)
        for _ in range(len(reason.rule[1])):
            self.erase(idx)

    def bring_first(self, idx: int, t: str) -> None:
        """Раскрыть символ на позиции idx так, чтобы там оказался терминал t."""
        sym = self.form[idx]
        if sym == t:
            return
        reason = self.sets.first_why[(sym, t)]
        self.apply(idx, reason.rule)
        for _ in range(reason.pos):
            self.erase(idx)
        self.bring_first(idx, t)


def _path_forms(g: Grammar, sets: Sets, target: str) -> tuple[_Derivation, int] | None:
    """Кратчайший по числу правил вывод S ⇒* α target β."""
    prev: dict[str, tuple[str, Rule, int] | None] = {g.start: None}
    queue = deque([g.start])
    while queue and target not in prev:
        a = queue.popleft()
        for rule in g.rules:
            if rule[0] != a:
                continue
            for i, s in enumerate(rule[1]):
                if g.is_nt(s) and s not in prev:
                    prev[s] = (a, rule, i)
                    queue.append(s)
    if target not in prev:
        return None
    chain = []
    cur = target
    while prev[cur] is not None:
        a, rule, i = prev[cur]
        chain.append((rule, i))
        cur = a
    d = _Derivation(g, sets, [g.start])
    idx = 0
    for rule, i in reversed(chain):
        d.apply(idx, rule)
        idx += i
    return d, idx


def follow_witness(g: Grammar, sets: Sets, a: str, t: str) -> list[list[str]] | None:
    """Вывод S ⇒* α a t β (для t = $ — a в конце формы) или None."""
    got = _follow(g, sets, a, t)
    return got[0].forms if got else None


def _follow(g: Grammar, sets: Sets, a: str, t: str) -> tuple[_Derivation, int] | None:
    reason = sets.follow_why.get((a, t))
    if reason is None:
        return None
    if reason.kind == "start":
        return _Derivation(g, sets, [g.start]), 0
    head, body = reason.rule
    if reason.kind == "follow-first":
        got = _path_forms(g, sets, head)
    else:
        got = _follow(g, sets, head, t)
    if got is None:
        return None
    d, idx = got
    d.apply(idx, reason.rule)
    a_idx = idx + reason.pos
    if reason.kind == "follow-first":
        # γ после a: стереть обнуляемый префикс, раскрыть символ, дающий t
        while True:
            nxt = d.form[a_idx + 1]
            if nxt == t:
                break
            if g.is_nt(nxt) and t in sets.first[nxt]:
                d.bring_first(a_idx + 1, t)
                break
            d.erase(a_idx + 1)
    else:
        for _ in range(len(body) - reason.pos - 1):
            d.erase(a_idx + 1)
    return d, a_idx


def first_witness(g: Grammar, sets: Sets, a: str, t: str) -> list[list[str]] | None:
    """Вывод a ⇒* t β (для t = ε — a ⇒* ε) или None."""
    if (a, t) not in sets.first_why:
        return None
    d = _Derivation(g, sets, [a])
    if t == EPS:
        d.erase(0)
    else:
        d.bring_first(0, t)
    return d.forms


def is_derivation(g: Grammar, forms: list[list[str]]) -> bool:
    """Каждая следующая форма получена из предыдущей применением одного правила."""
    for f, h in zip(forms, forms[1:]):
        ok = False
        for i, s in enumerate(f):
            if not g.is_nt(s):
                continue
            for body in g.alternatives(s):
                if f[:i] + list(body) + f[i + 1:] == h:
                    ok = True
                    break
            if ok:
                break
        if not ok:
            return False
    return True


def shortest_words(g: Grammar) -> dict[str, tuple[str, ...]]:
    """Кратчайшее терминальное слово для каждого продуктивного нетерминала."""
    best: dict[str, tuple[str, ...]] = {}
    changed = True
    while changed:
        changed = False
        for head, body in g.rules:
            if all(not g.is_nt(s) or s in best for s in body):
                w = tuple(x for s in body for x in (best[s] if g.is_nt(s) else (s,)))
                if head not in best or len(w) < len(best[head]):
                    best[head] = w
                    changed = True
    return best


def count_trees(g: Grammar, word: list[str], cap: int = 2) -> int:
    """Число деревьев разбора слова (не больше cap). ε-циклы дают cap."""
    import sys
    from functools import lru_cache

    n = len(word)
    active: set[tuple] = set()

    @lru_cache(maxsize=None)
    def sym(s: str, i: int, j: int) -> int:
        if not g.is_nt(s):
            return 1 if j == i + 1 and word[i] == s else 0
        key = (s, i, j)
        if key in active:          # цикл без потребления входа — бесконечно много деревьев
            return cap
        active.add(key)
        total = 0
        for body in g.alternatives(s):
            total += seq(body, i, j)
            if total >= cap:
                break
        active.discard(key)
        return min(total, cap)

    @lru_cache(maxsize=None)
    def seq(body: tuple[str, ...], i: int, j: int) -> int:
        if not body:
            return 1 if i == j else 0
        head, rest = body[0], body[1:]
        total = 0
        for k in range(i, j + 1):
            left = sym(head, i, k)
            if left:
                total += left * seq(rest, k, j)
                if total >= cap:
                    return cap
        return total

    old = sys.getrecursionlimit()
    sys.setrecursionlimit(max(old, 10000))
    try:
        return sym(g.start, 0, n)
    finally:
        sys.setrecursionlimit(old)
