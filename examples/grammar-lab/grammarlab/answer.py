"""Разбор ответа студента (DSL v1) в структуру Answer.

answer.lark задаёт синтаксис строк; здесь — секции, проверка, что строка
стоит в подходящей секции, различение терминалов и нетерминалов и русские
сообщения об ошибках. Код диагностики — контракт тестов; текст можно менять.

Коды:
  S001 недопустимый символ          S002 неожиданная лексема
  S003 строка вне секции / не та секция
  S004 неизвестная секция           S005 секция повторяется
  S006 нет секции grammar           S007 пунктуация без кавычек      S008 eps или $ как символ грамматики
  W101 символ похож на слитную запись нескольких символов
  W102 символ встречается в first/follow/table, но не в грамматике
  W103 $ в заголовке trace
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

from lark import Lark, Token, Transformer, Tree
from lark.exceptions import UnexpectedCharacters, UnexpectedEOF, UnexpectedInput, UnexpectedToken

from .grammar import END, EPS, Grammar, Rule

SECTIONS = ("grammar", "first", "follow", "table", "conflicts")

ERROR, WARNING = "error", "warning"


@dataclass
class Diagnostic:
    level: str
    code: str
    message: str
    line: int = 0
    col: int = 0

    def to_dict(self) -> dict:
        return {"level": self.level, "code": self.code, "message": self.message,
                "line": self.line, "col": self.col}

    def format(self) -> str:
        where = f"строка {self.line}" + (f", позиция {self.col}" if self.col else "") if self.line else ""
        kind = "ошибка" if self.level == ERROR else "предупреждение"
        return f"{where}: {kind} {self.code}: {self.message}" if where else f"{kind} {self.code}: {self.message}"


@dataclass
class TraceRow:
    stack: list[str]
    rest: list[str]
    action: str            # 'rule' | 'match' | 'accept' | 'error'
    rule: Rule | None = None
    matched: str | None = None
    line: int = 0


@dataclass
class Trace:
    word: list[str]
    rows: list[TraceRow]
    line: int = 0


@dataclass
class Answer:
    grammar: Grammar | None = None
    grammar_lines: dict[str, int] = field(default_factory=dict)   # нетерминал → строка
    first: dict[str, set[str]] | None = None
    follow: dict[str, set[str]] | None = None
    set_lines: dict[tuple[str, str], int] = field(default_factory=dict)  # (секция, A) → строка
    table: dict[tuple[str, str], list[Rule]] | None = None
    cell_lines: dict[tuple[str, str], int] = field(default_factory=dict)
    conflict_witnesses: dict[tuple[str, str], list[str]] = field(default_factory=dict)
    conflict_choices: dict[tuple[str, str], Rule] = field(default_factory=dict)
    traces: list[Trace] = field(default_factory=list)
    diagnostics: list[Diagnostic] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not any(d.level == ERROR for d in self.diagnostics)


# ------------------------------------------------------------------ парсер

_parser: Lark | None = None


def _get_parser() -> Lark:
    global _parser
    if _parser is None:
        text = Path(__file__).with_name("answer.lark").read_text(encoding="utf-8")
        _parser = Lark(text, parser="lalr", lexer="contextual",
                       propagate_positions=True, maybe_placeholders=True)
    return _parser


_TERMINALS = {
    "NAME": "имя", "QUOTED": "терминал в кавычках", "STRING": "строка в кавычках",
    "INT": "число", "ARROW": "'->'", "DSEMI": "';;'", "VBAR": "'|'", "COLON": "':'",
    "EQUAL": "'='", "LBRACE": "'{'", "RBRACE": "'}'", "LSQB": "'['", "RSQB": "']'",
    "COMMA": "','", "DOLLAR": "'$'", "EPSILON": "eps", "CHOOSE_KW": "choose",
    "MATCH_KW": "match", "ACCEPT_KW": "accept", "ERROR_KW": "error",
    "_NL": "конец строки", "$END": "конец текста",
}


def _expected(names) -> str:
    shown = sorted({_TERMINALS.get(n, n) for n in names})
    return ", ".join(shown[:8]) + (", …" if len(shown) > 8 else "")


_PUNCT = re.compile(r"[^\sA-Za-zА-Яа-яЁё0-9_'\"#]")


def _syntax_error(text: str, e: UnexpectedInput) -> Diagnostic:
    line, col = getattr(e, "line", 0) or 0, getattr(e, "column", 0) or 0
    if isinstance(e, UnexpectedCharacters):
        ch = text[e.pos_in_stream]
        if ch == "'":
            return Diagnostic(ERROR, "S001", "незакрытая кавычка или пробел внутри кавычек", line, col)
        if _PUNCT.match(ch):
            return Diagnostic(ERROR, "S007",
                              f"символ '{ch}' нужно взять в одинарные кавычки: '{ch}'", line, col)
        return Diagnostic(ERROR, "S001", f"недопустимый символ '{ch}'", line, col)
    if isinstance(e, UnexpectedToken) and e.token.type != "$END":
        tok = e.token
        if tok.type == "VBAR" and "EPSILON" in e.expected:
            msg = "после '|' нет альтернативы; пустую альтернативу пишите как eps, терминал '|' — в кавычках"
        elif tok.type in ("DSEMI", "COMMA", "COLON", "EQUAL", "LSQB", "RSQB", "LBRACE", "RBRACE"):
            msg = (f"неожиданное '{tok}', ожидалось: {_expected(e.expected)}. "
                   f"Если это терминал, возьмите его в кавычки: '{tok}'")
        else:
            msg = f"неожиданное '{tok}', ожидалось: {_expected(e.expected)}"
        return Diagnostic(ERROR, "S002", msg, line, col)
    lines = text.split("\n")
    expected = getattr(e, "expected", ())
    return Diagnostic(ERROR, "S002", f"неожиданный конец текста, ожидалось: {_expected(expected)}",
                      len(lines), len(lines[-1]) + 1)


# -------------------------------------------------------- дерево → записи

class _Rows(Transformer):
    """Строки DSL → кортежи (вид, строка, данные). Символы — сырые токены."""

    def start(self, items):
        return [i for i in items if i is not None]

    def name(self, c):
        return c[0]

    def sym_name(self, c):
        return ("name", c[0])

    def sym_quoted(self, c):
        return ("quoted", c[0])

    def eps(self, c):
        return ("eps", c[0])

    def end(self, c):
        return ("end", c[0])

    def alt(self, c):
        return list(c)

    def alt_eps(self, c):
        return []

    def rule(self, c):
        return (c[0], c[2])

    def index(self, c):
        return (c[0], c[2], c[4])

    def word(self, c):
        return list(c)

    def tokens(self, c):
        return list(c)

    def act_match(self, c):
        return ("match", c[1])

    def act_accept(self, c):
        return ("accept",)

    def act_error(self, c):
        return ("error",)

    def section(self, c):
        return ("section", c[0].line, c[0])

    def version(self, c):
        return ("version", c[0].line, c[0], c[2])

    def trace_header(self, c):
        return ("trace", c[0].line, c[0], c[1])

    def production(self, c):
        head = c[0]
        alts = [x for x in c[2:] if not isinstance(x, Token)]
        return ("production", head.line, head, alts)

    def set_line(self, c):
        elems = [x for x in c[3:-1] if x is not None and not (isinstance(x, Token) and x.type == "COMMA")]
        return ("set", c[0].line, c[0], elems)

    def cell(self, c):
        idx = c[0]
        rules = [x for x in c[2:] if not isinstance(x, Token)]
        return ("cell", idx[0].line, idx, rules)

    def conflict_witness(self, c):
        return ("witness", c[0][0].line, c[0], c[2])

    def conflict_choice(self, c):
        return ("choice", c[0].line, c[1], c[3])

    def trace_row(self, c):
        stack, rest, action = c[0], c[2], c[4]
        first = stack[0][1]
        return ("row", first.line, stack, rest, action)


# ---------------------------------------------------------------- сборка

def parse_answer(text: str) -> Answer:
    ans = Answer()
    diags = ans.diagnostics
    text = text.lstrip("\ufeff").replace("\u00a0", " ")
    try:
        tree = _get_parser().parse(text if text.endswith("\n") else text + "\n")
    except UnexpectedInput as e:
        diags.append(_syntax_error(text, e))
        return ans
    rows = _Rows().transform(tree)

    # 1. Разложить строки по секциям.
    current: str | None = None
    seen: set[str] = set()
    grammar_rows, set_rows, cell_rows, conf_rows = [], {"first": [], "follow": []}, [], []
    trace: list | None = None
    traces: list = []
    for row in rows:
        kind, line = row[0], row[1]
        if kind == "version":
            if str(row[2]) != "version":
                diags.append(Diagnostic(ERROR, "S004", f"неизвестная секция «{row[2]}»", line))
            elif str(row[3]) != "1":
                diags.append(Diagnostic(ERROR, "S004", "поддерживается только version: 1", line))
            continue
        if kind == "section":
            name = str(row[2])
            if name not in SECTIONS:
                diags.append(Diagnostic(ERROR, "S004",
                                        f"неизвестная секция «{name}:»; допустимы: "
                                        + ", ".join(SECTIONS) + ", trace \"…\"", line))
                current = None
                continue
            if name in seen:
                diags.append(Diagnostic(ERROR, "S005", f"секция «{name}:» встречается второй раз", line))
            seen.add(name)
            current = name
            trace = None
            continue
        if kind == "trace":
            if str(row[2]) != "trace":
                diags.append(Diagnostic(ERROR, "S004", f"неизвестная секция «{row[2]} {row[3]}:»", line))
                current = None
                continue
            current = "trace"
            trace = {"word": str(row[3])[1:-1], "line": line, "rows": []}
            traces.append(trace)
            continue
        expected = {"production": "grammar", "set": ("first", "follow"), "cell": "table",
                    "witness": "conflicts", "choice": "conflicts", "row": "trace"}[kind]
        ok = current in expected if isinstance(expected, tuple) else current == expected
        if not ok:
            where = f"в секции «{current}»" if current else "вне секций"
            diags.append(Diagnostic(ERROR, "S003", f"{_KIND_RU[kind]} {where}; ожидалась секция "
                                    f"«{expected if isinstance(expected, str) else 'first/follow'}»", line))
            continue
        if kind == "production":
            grammar_rows.append(row)
        elif kind == "set":
            set_rows[current].append(row)
        elif kind == "cell":
            cell_rows.append(row)
        elif kind in ("witness", "choice"):
            conf_rows.append(row)
        else:
            trace["rows"].append(row)

    if not grammar_rows:
        if "grammar" not in seen:
            diags.append(Diagnostic(ERROR, "S006", "нет секции «grammar:» — проверять не с чем"))
        else:
            diags.append(Diagnostic(ERROR, "S006", "секция «grammar:» пуста — запишите правила вида A -> α | β"))
        return ans

    # 2. Грамматика: нетерминалы — левые части.
    nts: list[str] = []
    for _, line, head, _ in grammar_rows:
        if str(head) not in nts:
            nts.append(str(head))
            ans.grammar_lines[str(head)] = line
    ntset = set(nts)

    def sym(s) -> str:
        kind, tok = s
        if kind == "quoted":
            return str(tok)[1:-1]
        if kind == "eps":
            return EPS
        if kind == "end":
            return END
        return str(tok)

    rules: list[Rule] = []
    for _, line, head, alts in grammar_rows:
        for alt in alts:
            for kind, tok in alt:
                if (kind == "quoted" and str(tok)[1:-1] in (EPS, END, "eps")) or \
                        (kind == "name" and str(tok) in ("eps", EPS)):
                    diags.append(Diagnostic(
                        ERROR, "S008",
                        f"«{tok}» нельзя использовать как символ: eps — пустая цепочка (пишется отдельной "
                        f"альтернативой), $ — конец входа", tok.line, tok.column))
            body = tuple(sym(s) for s in alt)
            rules.append((str(head), body))
    if any(d.level == ERROR for d in diags):
        return ans
    ans.grammar = Grammar(nts[0], rules)

    # Предупреждение о слитной записи: tiN, bM и т. п.
    reported = set()
    for _, line, head, alts in grammar_rows:
        for alt in alts:
            for kind, tok in alt:
                name = str(tok)
                if kind == "name" and name not in ntset and len(name) > 1 and name not in reported:
                    parts = _split_glued(name, ntset)
                    if parts:
                        reported.add(name)
                        diags.append(Diagnostic(
                            WARNING, "W101",
                            f"«{name}» прочитан как один терминал. Если это несколько символов, "
                            f"разделите пробелами: {' '.join(parts)}", tok.line, tok.column))

    known = ntset | set(ans.grammar.terminals)

    def check_known(s: str, tok: Token, what: str):
        if s not in known and s not in (EPS, END):
            diags.append(Diagnostic(WARNING, "W102",
                                    f"символ «{s}» в {what} не встречается в грамматике",
                                    tok.line, tok.column))

    # 3. FIRST/FOLLOW
    for sec in ("first", "follow"):
        if sec not in seen:
            continue
        sets: dict[str, set[str]] = {}
        for _, line, head, elems in set_rows[sec]:
            a = str(head)
            if a not in ntset:
                diags.append(Diagnostic(WARNING, "W102", f"{sec.upper()}({a}): «{a}» не нетерминал грамматики",
                                        line, head.column))
            vals = set()
            for e in elems:
                v = sym(e)
                check_known(v, e[1], f"{sec.upper()}({a})")
                vals.add(v)
            sets.setdefault(a, set()).update(vals)
            ans.set_lines[(sec, a)] = line
        setattr(ans, sec, sets)

    # 4. Таблица
    def to_rule(r) -> Rule:
        head, alt = r
        return (str(head), tuple(sym(s) for s in alt))

    if "table" in seen:
        table: dict[tuple[str, str], list[Rule]] = {}
        for _, line, idx, rs in cell_rows:
            key = (str(idx[1]), sym(idx[2]))
            if str(idx[0]) != "M":
                diags.append(Diagnostic(WARNING, "W102", f"ячейка таблицы записывается как M[A, a], а не {idx[0]}[…]",
                                        line))
            for r in rs:
                rr = to_rule(r)
                cell = table.setdefault(key, [])
                if rr not in cell:
                    cell.append(rr)
            ans.cell_lines[key] = line
        ans.table = table

    # 5. Конфликты
    for row in conf_rows:
        if row[0] == "witness":
            _, line, idx, word = row
            ans.conflict_witnesses[(str(idx[1]), sym(idx[2]))] = [sym(s) for s in word]
        else:
            _, line, idx, r = row
            ans.conflict_choices[(str(idx[1]), sym(idx[2]))] = to_rule(r)

    # 6. Трассы
    for t in traces:
        word = t["word"].split()
        word = [w[1:-1] if len(w) > 2 and w[0] == w[-1] == "'" else w for w in word]
        if word and word[-1] == END:
            word.pop()
            diags.append(Diagnostic(WARNING, "W103", "в заголовке trace «$» не пишется — он дописывается "
                                    "автоматически", t["line"]))
        out = []
        for _, line, stack, rest, action in t["rows"]:
            tr = TraceRow([sym(s) for s in stack], [sym(s) for s in rest], "rule", line=line)
            if isinstance(action, tuple) and action and action[0] == "match":
                tr.action, tr.matched = "match", sym(action[1])
            elif action == ("accept",):
                tr.action = "accept"
            elif action == ("error",):
                tr.action = "error"
            else:
                tr.rule = to_rule(action)
            out.append(tr)
        ans.traces.append(Trace(word, out, t["line"]))
    return ans


_KIND_RU = {"production": "правило грамматики", "set": "строка множества",
            "cell": "ячейка таблицы", "witness": "свидетель конфликта",
            "choice": "выбор в конфликте", "row": "строка трассы"}


def _split_glued(name: str, nts: set[str]) -> list[str] | None:
    """Разбить имя на односимвольные терминалы и известные нетерминалы: tiN → t i N.

    Подсказываем только если в разбиении есть хотя бы один нетерминал или имя —
    из одних букв нижнего регистра длиной 2–3 (частая слитная запись терминалов).
    """
    parts: list[str] = []
    i = 0
    while i < len(name):
        for nt in sorted(nts, key=len, reverse=True):
            if name.startswith(nt, i):
                parts.append(nt)
                i += len(nt)
                break
        else:
            parts.append(name[i])
            i += 1
    if any(p in nts for p in parts):
        return parts
    return None


# ------------------------------------------------------------- вывод обратно

def q(sym: str) -> str:
    """Символ в записи DSL: пунктуация — в кавычках."""
    if sym == EPS:
        return "eps"
    if sym == END or re.fullmatch(r"[A-Za-zА-Яа-яЁё_][A-Za-zА-Яа-яЁё0-9_']*", sym):
        return sym
    return f"'{sym}'"


def fmt_body(body) -> str:
    return " ".join(q(s) for s in body) if body else "eps"


def fmt_rule(rule: Rule) -> str:
    return f"{rule[0]} -> {fmt_body(rule[1])}"


def fmt_set(values) -> str:
    order = sorted(values, key=lambda s: (s in (EPS, END), s))
    return "{ " + ", ".join(q(s) for s in order) + " }"


def fmt_grammar(g: Grammar) -> list[str]:
    return [f"{a} -> " + " | ".join(fmt_body(b) for b in g.alternatives(a)) for a in g.nonterminals]
