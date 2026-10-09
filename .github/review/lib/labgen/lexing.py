"""Токены примеров: лексер грамматики работы (интерпретатор ANTLR) и запасной."""

from __future__ import annotations

import os
import re
import subprocess
from dataclasses import dataclass, field
from pathlib import Path


# --- токены ----------------------------------------------------------------


@dataclass
class Tok:
    i: int
    start: int          # смещение в тексте (включительно)
    stop: int           # смещение в тексте (включительно)
    text: str
    type: str           # имя типа: ID, NUMBER или литерал вида 'func'
    line: int           # с 1
    col: int            # с 0

    @property
    def lit(self) -> str | None:
        return self.type[1:-1] if self.type.startswith("'") else None


IDENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
NUM_RE = re.compile(r"^[0-9][0-9_]*(\.[0-9_]+)?([eE][+-]?[0-9]+)?[a-zA-Z]?$")
TOKEN_LINE = re.compile(
    r"^\[@(\d+),(\d+):(\d+)='(.*)',<('(?:[^'\\]|\\.)*'|[A-Za-z_]\w*)>,(?:channel=(\d+),)?(\d+):(\d+)\]$"
)

CONTROL_KW = {
    "if", "elif", "elsif", "elseif", "else", "while", "until", "for", "foreach", "return",
    "not", "and", "or", "in", "do", "then", "switch", "case", "repeat", "throw", "catch",
    "print", "write", "read", "println", "new", "loop", "unless", "when", "match",
}
COND_KW = {"if", "elif", "elsif", "elseif", "while", "until", "unless"}
EXPR_PREV_KW = {"return", "not", "and", "or", "if", "elif", "elsif", "elseif", "while",
                "until", "in", "to", "downto", "unless", "then", "do", "step"}
EXPR_PREV_OPS = {"+", "-", "*", "/", "%", "<", ">", "<=", ">=", "==", "!=", "=", ":=", "(",
                 ",", "[", "..", "&&", "||", "!", "**", "^", "<>", "+=", "-=", "*=", "/="}
ASSIGN_OPS = {"=", ":=", "<-"}


class Lexed:
    """Токены одного файла и производные сведения о структуре программы."""

    def __init__(self, path: Path, text: str, toks: list[Tok]):
        self.path, self.text = path, text
        self.toks = [t for t in toks if text[t.start:t.stop + 1] == t.text or self._fix(t)]
        self.lines = text.split("\n")
        self.by_line: dict[int, list[Tok]] = {}
        for t in self.toks:
            self.by_line.setdefault(t.line, []).append(t)

    def _fix(self, t: Tok) -> bool:
        # Интерпретатор печатает экранированный текст ('\n'); берём из исходника.
        t.text = self.text[t.start:t.stop + 1]
        return True

    def prev(self, t: Tok, skip_nl: bool = False) -> Tok | None:
        j = self.toks.index(t) - 1
        while j >= 0:
            p = self.toks[j]
            if not (skip_nl and p.text.strip() == ""):
                return p
            j -= 1
        return None

    def next(self, t: Tok) -> Tok | None:
        j = self.toks.index(t) + 1
        return self.toks[j] if j < len(self.toks) else None

    def indent(self, line: int) -> int:
        s = self.lines[line - 1] if 0 < line <= len(self.lines) else ""
        return len(s) - len(s.lstrip(" \t"))

    def code_line(self, line: int) -> bool:
        return any(t.text.strip() for t in self.by_line.get(line, []))


@dataclass
class LangInfo:
    id_type: str = "ID"
    num_types: set[str] = field(default_factory=set)
    str_types: set[str] = field(default_factory=set)
    keywords: set[str] = field(default_factory=set)
    literals: set[str] = field(default_factory=set)   # все литеральные токены грамматики
    has_bool: bool = False
    string_sample: str = '"x"'
    number_sample: str = "1"
    props: dict[str, str] = field(default_factory=dict)   # свойства варианта из README


def infer_lang(lexed: list[Lexed], grammar_text: str) -> LangInfo:
    li = LangInfo()
    li.literals = set(re.findall(r"'((?:[^'\\]|\\.)+)'", grammar_text))
    li.keywords = {x for x in li.literals if IDENT_RE.match(x)}
    li.has_bool = bool({"bool", "boolean", "true", "True", "TRUE"} & li.keywords)
    by_type: dict[str, list[str]] = {}
    for lx in lexed:
        for t in lx.toks:
            if not t.lit:
                by_type.setdefault(t.type, []).append(t.text)
    best = 0
    for ty, texts in by_type.items():
        if all(IDENT_RE.match(x) for x in texts) and len(set(texts)) > best:
            best, li.id_type = len(set(texts)), ty
        if all(NUM_RE.match(x) for x in texts):
            li.num_types.add(ty)
        if all(x[:1] in "\"'" and len(x) >= 2 for x in texts):
            li.str_types.add(ty)
    for lx in lexed:
        for t in lx.toks:
            if t.type in li.str_types and len(t.text) >= 2:
                q = t.text[0]
                li.string_sample = f"{q}labgen{q}"
                break
    return li


def read_props(readme: Path) -> dict[str, str]:
    """Свойства варианта из таблицы «Свойства языка по варианту» в README."""
    props: dict[str, str] = {}
    if not readme.is_file():
        return props
    for ln in readme.read_text(errors="replace").splitlines():
        cells = [c.strip().lower() for c in ln.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        key, val = cells[0], cells[1]
        if "преобразован" in key:
            props["conversion"] = "explicit" if "явн" in val and "неявн" not in val else (
                "implicit" if "неявн" in val else "")
        elif "объявлени" in key and "перемен" in key:
            props["declaration"] = "implicit" if "неявн" in val else ("explicit" if "явн" in val else "")
        elif "перегрузк" in key:
            props["overload"] = "no" if re.search(r"нет|отсутств|не поддерж", val) else "yes"
    return {k: v for k, v in props.items() if v}


# --- лексер ----------------------------------------------------------------


def find_grammar(work: Path) -> list[Path]:
    g4 = [p for p in work.rglob("*.g4")
          if not any(part.startswith(".") or part in {"gen", "generated", "build", "target", "node_modules"}
                     for part in p.relative_to(work).parts[:-1])]
    if not g4:
        return []
    compile_sh = (work / "compile.sh").read_text(errors="replace") if (work / "compile.sh").is_file() else ""
    mentioned = [p for p in g4 if p.name in compile_sh or p.stem in compile_sh]
    pool = mentioned or g4
    lexers = [p for p in pool if re.search(r"^\s*lexer\s+grammar", p.read_text(errors="replace"), re.M)]
    parsers = [p for p in pool if re.search(r"^\s*parser\s+grammar", p.read_text(errors="replace"), re.M)]
    if parsers and lexers:
        return [parsers[0], lexers[0]]
    combined = [p for p in pool if p not in lexers and p not in parsers]
    combined.sort(key=lambda p: -len(p.read_text(errors="replace")))
    return combined[:1] or pool[:1]


def start_rule(grammar: Path) -> str:
    src = re.sub(r"/\*.*?\*/|//[^\n]*", "", grammar.read_text(errors="replace"), flags=re.S)
    for m in re.finditer(r"^\s*(?:fragment\s+)?([a-z]\w*)\s*(?:\[[^\]]*\])?\s*(?:returns[^:]*)?:", src, re.M):
        return m.group(1)
    return "program"


def find_jar(arg: str | None) -> str | None:
    cands = [arg, os.environ.get("ANTLR_JAR")]
    for pat in ["/usr/local/lib/antlr-*-complete.jar", "/usr/share/java/antlr*-complete.jar",
                "/opt/homebrew/Cellar/antlr/*/antlr-*-complete.jar",
                str(Path.home() / ".m2/repository/org/antlr/antlr4/*/antlr4-*-complete.jar")]:
        cands += sorted(Path("/").glob(pat.lstrip("/")))
    for c in cands:
        if c and Path(c).is_file():
            return str(c)
    return None


def lex_antlr(jar: str, grammars: list[Path], path: Path) -> list[Tok] | None:
    cmd = ["java", "-cp", jar, "org.antlr.v4.gui.Interpreter", *map(str, grammars),
           start_rule(grammars[0]), "-tokens", str(path)]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired):
        return None
    toks = []
    for ln in r.stdout.splitlines():
        m = TOKEN_LINE.match(ln)
        if not m:
            continue
        i, s, e, txt, ty, ch, line, col = m.groups()
        if ty == "EOF" or (ch and ch != "0"):
            continue
        toks.append(Tok(int(i), int(s), int(e), txt, ty, int(line), int(col)))
    if not toks or "token recognition error" in r.stderr:
        return None
    return toks


def lex_fallback(text: str, li_literals: set[str]) -> list[Tok]:
    """Грубый лексер на случай, если интерпретатор ANTLR не справился."""
    ops = sorted((x for x in li_literals if not IDENT_RE.match(x)), key=len, reverse=True)
    kws = {x for x in li_literals if IDENT_RE.match(x)}
    pat = re.compile(
        r"(?P<c>//[^\n]*|/\*.*?\*/|#[^\n]*)|(?P<s>\"(?:[^\"\\\n]|\\.)*\"|'(?:[^'\\\n]|\\.)*')"
        r"|(?P<n>[0-9]+(?:\.[0-9]+)?)|(?P<i>[A-Za-z_]\w*)|(?P<nl>\n)|(?P<w>[ \t\r]+)"
        + ("|(?P<o>" + "|".join(map(re.escape, ops)) + ")" if ops else "") + r"|(?P<x>.)", re.S)
    toks, line, lstart = [], 1, 0
    for m in pat.finditer(text):
        kind, s = m.lastgroup, m.group()
        if kind in {"c", "w"}:
            pass
        else:
            ty = {"s": "STRING", "n": "NUMBER", "nl": "NEWLINE"}.get(kind)
            if kind == "i":
                ty = f"'{s}'" if s in kws else "ID"
            elif kind in {"o", "x"}:
                ty = f"'{s}'"
            toks.append(Tok(len(toks), m.start(), m.end() - 1, s, ty, line, m.start() - lstart))
        for k, ch in enumerate(s):
            if ch == "\n":
                line += 1
                lstart = m.start() + k + 1
    return toks
