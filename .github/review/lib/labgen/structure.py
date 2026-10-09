"""Структура программы по токенам: функции, параметры, использования имён."""

from __future__ import annotations

from dataclasses import dataclass, field

from .lexing import (ASSIGN_OPS, CONTROL_KW, EXPR_PREV_KW, EXPR_PREV_OPS, IDENT_RE,
                     LangInfo, Lexed, Tok)


# --- анализ структуры ------------------------------------------------------


@dataclass
class Func:
    name: str
    name_tok: Tok
    header_lines: tuple[int, int]
    params: list[Tok]           # имена параметров (если удалось определить однозначно)
    body: tuple[int, int]       # строки тела (включительно), включая заголовок
    returns_value: bool
    param_groups: list[tuple[int, int]] = field(default_factory=list)  # смещения групп
    close_paren: int = 0


def match_close(lx: Lexed, open_tok: Tok) -> Tok | None:
    pair = {"(": ")", "[": "]", "{": "}"}[open_tok.text]
    depth = 0
    for t in lx.toks[lx.toks.index(open_tok):]:
        if t.text == open_tok.text:
            depth += 1
        elif t.text == pair:
            depth -= 1
            if depth == 0:
                return t
    return None


def find_funcs(lx: Lexed, li: LangInfo) -> list[Func]:
    out = []
    for t in lx.toks:
        nx = lx.next(t)
        if t.type != li.id_type or not nx or nx.text != "(":
            continue
        line_toks = lx.by_line[t.line]
        first = next((x for x in line_toks if x.text.strip()), None)
        before = [x for x in line_toks if x.start < t.start]
        if not before or not all(x.lit and IDENT_RE.match(x.lit) or x.type == li.id_type for x in before):
            continue
        if first.lit in CONTROL_KW or first.text in CONTROL_KW:
            continue
        close = match_close(lx, nx)
        if not close:
            continue
        # После скобок — начало тела: '{', ':', '->', 'begin', 'is' или пусто + отступ.
        after = [x for x in lx.toks[lx.toks.index(close) + 1:] if x.line == close.line and x.text.strip()]
        opener = after[-1].text if after else ""
        nxt_line = close.line + 1
        while nxt_line <= len(lx.lines) and not lx.code_line(nxt_line):
            nxt_line += 1
        if not (opener in {"{", ":", "begin", "is", "as", "do"} or any(x.text in {"->", ":"} for x in after)
                or (nxt_line <= len(lx.lines) and (lx.indent(nxt_line) > lx.indent(t.line)
                                                   or lx.lines[nxt_line - 1].strip().startswith("{")))):
            continue
        # Параметры: группы между запятыми верхнего уровня, в группе ровно один ID.
        params, group, depth = [], [], 0
        for x in lx.toks[lx.toks.index(nx) + 1:lx.toks.index(close)]:
            if x.text in "([{":
                depth += 1
            elif x.text in ")]}":
                depth -= 1
            if x.text == "," and depth == 0:
                params.append(group)
                group = []
            else:
                group.append(x)
        if group:
            params.append(group)
        names = []
        for g in params:
            ids = [x for x in g if x.type == li.id_type]
            names.append(ids[0] if len(ids) == 1 else None)
        param_names = [n for n in names if n] if all(names) else []
        # Тело.
        body_end = close.line
        brace = next((x for x in lx.toks[lx.toks.index(close):] if x.text == "{" and x.line <= nxt_line), None)
        if brace:
            end = match_close(lx, brace)
            if not end:
                continue
            body_end = end.line
        else:
            base = lx.indent(t.line)
            ln = close.line + 1
            while ln <= len(lx.lines):
                if lx.code_line(ln):
                    if lx.indent(ln) <= base:
                        if lx.lines[ln - 1].strip().split()[0] in {"end", "endfunc", "endfunction", "end;"}:
                            body_end = ln
                        break
                    body_end = ln
                ln += 1
            if body_end == close.line:
                continue
        body_toks = [x for ln in range(close.line + 1, body_end + 1) for x in lx.by_line.get(ln, [])]
        ret_value = False
        for x in body_toks:
            if x.lit == "return":
                n2 = lx.next(x)
                if n2 and n2.line == x.line and n2.text.strip() and n2.text not in {";", "}"}:
                    ret_value = True
        groups = [(g[0].start, g[-1].stop + 1) for g in params if g]
        out.append(Func(t.text, t, (t.line, close.line), param_names, (t.line, body_end), ret_value,
                        groups, close.start))
    return out


def in_funcs(funcs: list[Func], line: int) -> Func | None:
    return next((f for f in funcs if f.body[0] <= line <= f.body[1]), None)


def var_uses(lx: Lexed, li: LangInfo, funcs: list[Func]) -> list[Tok]:
    """ID в позиции выражения: не объявление, не левая часть, не вызов, не поле."""
    fnames = {f.name for f in funcs}
    headers = {ln for f in funcs for ln in range(f.header_lines[0], f.header_lines[1] + 1)}
    res = []
    for t in lx.toks:
        if t.type != li.id_type or t.text in fnames or t.line in headers:
            continue
        p, n = lx.prev(t), lx.next(t)
        if not p or p.text in {".", "->"}:
            continue
        if not (p.text in EXPR_PREV_OPS or (p.lit or "") in EXPR_PREV_KW):
            continue
        if n and (n.text in {"(", "."} or n.text in ASSIGN_OPS):
            continue
        res.append(t)
    return res


def defined_names(lx: Lexed, li: LangInfo, funcs: list[Func]) -> set[str]:
    out = {p.text for f in funcs for p in f.params}
    for t in lx.toks:
        if t.type != li.id_type:
            continue
        n, p = lx.next(t), lx.prev(t)
        if n and n.text in ASSIGN_OPS | {"in", ":"} and not (p and p.text in {".", ","}):
            if n.text == ":" and not (p and (p.lit or "") in {"for", "foreach", "var", "let"}):
                continue
            out.add(t.text)
        if p and (p.lit or "") in {"for", "foreach"}:
            out.add(t.text)
    return out


def var_names(lx: Lexed, li: LangInfo, funcs: list[Func]) -> set[str]:
    fnames = {f.name for f in funcs}
    out = set()
    for t in lx.toks:
        n, p = lx.next(t), lx.prev(t)
        if t.type == li.id_type and t.text not in fnames and not (n and n.text == "(") \
                and not (p and p.text == "."):
            out.add(t.text)
    return out
