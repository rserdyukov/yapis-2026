"""Табличный редактор FIRST/FOLLOW и таблицы M.

Источник правды — текст ответа на DSL. Редактор — другое представление
секций first/follow/table:

* grid_model(text) — модель сетки из текста: строки — нетерминалы
  грамматики, столбцы — терминалы и $; выбранные элементы и правила;
* apply_grid(text, grid) — записать сетку обратно в текст: секции first,
  follow, table заменяются (или добавляются), остальной текст — как был.

Сериализация живёт здесь, а не в JS: формат DSL описан в одном месте.
"""

from __future__ import annotations

import re

from .answer import fmt_rule, fmt_set, parse_answer, q
from .grammar import END, EPS

_HEADER = re.compile(r"^\s*(grammar|first|follow|table|conflicts)\s*:\s*(#.*)?$")
_TRACE = re.compile(r'^\s*trace\s*"[^"\n]*"\s*:\s*(#.*)?$')
_VERSION = re.compile(r"^\s*version\s*:\s*\d+\s*(#.*)?$")
ORDER = ("version", "grammar", "first", "follow", "table", "conflicts", "trace")


def cell_key(a: str, t: str) -> str:
    """Ключ ячейки так же, как в Finding.key (check.py)."""
    return f"M[{a}, {q(t)}]"


def grid_model(text: str) -> dict:
    ans = parse_answer(text)
    errors = [d.to_dict() for d in ans.diagnostics if d.level == "error"]
    if errors or ans.grammar is None:
        return {"ok": False, "errors": errors or
                [{"code": "S006", "message": "нет грамматики", "line": 0, "col": 0}]}
    g = ans.grammar
    nts, terms = g.nonterminals, g.terminals
    columns = terms + [END]
    alts = {a: g.alternatives(a) for a in nts}
    lossy: list[str] = []
    lossy_by: dict[str, list[str]] = {"first": [], "follow": [], "table": []}

    def lose(section: str, msg: str):
        lossy.append(msg)
        lossy_by[section].append(msg)

    def sets(given, allowed, name):
        if given is None:
            return None
        out = {}
        for a, vals in given.items():
            if a not in alts:
                lose(name.lower(), f"{name}({a}): {a} — не нетерминал")
                continue
            bad = sorted(v for v in vals if v not in allowed)
            for v in bad:
                lose(name.lower(), f"{name}({a}): элемент {q(v)} не терминал грамматики")
            out[a] = [v for v in allowed if v in vals]
        return out

    table = None
    if ans.table is not None:
        table = {}
        for (a, t), rules in ans.table.items():
            if a not in alts or t not in columns:
                lose("table", f"{cell_key(a, t)}: такой ячейки нет в таблице этой грамматики")
                continue
            idx = []
            for rule in rules:
                if rule[0] == a and rule[1] in alts[a]:
                    idx.append(alts[a].index(rule[1]))
                else:
                    lose("table", f"{cell_key(a, t)}: правила {fmt_rule(rule)} нет в грамматике")
            if idx:
                table.setdefault(a, {})[t] = sorted(set(idx))
    return {
        "ok": True,
        "nonterminals": nts,
        "terminals": terms,
        "columns": columns,
        "labels": {s: q(s) for s in terms + [EPS, END]},
        "alternatives": {a: [fmt_rule((a, b)).split(" -> ", 1)[1] for b in alts[a]] for a in nts},
        "first": sets(ans.first, terms + [EPS], "FIRST"),
        "follow": sets(ans.follow, terms + [END], "FOLLOW"),
        "table": table,
        "cell_keys": {a: {t: cell_key(a, t) for t in columns} for a in nts},
        # Для сборки текста секции в браузере (render.mjs) без вызова Python:
        # метки правил и порядок элементов множества — как в fmt_set/fmt_rule.
        "rules": {a: [fmt_rule((a, b)) for b in alts[a]] for a in nts},
        "set_order": sorted(terms + [EPS, END], key=lambda s: (s in (EPS, END), s)),
        "lossy": lossy,
        "lossy_by_section": lossy_by,
    }


# ------------------------------------------------------------ запись в текст

def _blocks(text: str) -> tuple[list[str], list[tuple[str, list[str]]]]:
    """Преамбула (до первого заголовка) и секции (имя, строки с заголовком)."""
    pre: list[str] = []
    blocks: list[tuple[str, list[str]]] = []
    for line in text.split("\n"):
        m = _HEADER.match(line)
        name = m.group(1) if m else ("trace" if _TRACE.match(line) else None)
        if _VERSION.match(line):
            name = "version"
        if name:
            blocks.append((name, [line]))
        elif blocks:
            blocks[-1][1].append(line)
        else:
            pre.append(line)
    return pre, blocks


def _render(name: str, grid: dict, model: dict) -> list[str]:
    nts = model["nonterminals"]
    if name in ("first", "follow"):
        rows = grid.get(name) or {}
        return [f"{name}:"] + [f"  {a} = {fmt_set(rows[a])}" for a in nts if a in rows] + [""]
    lines = ["table:"]
    table = grid.get("table") or {}
    for a in nts:
        row = table.get(a) or {}
        for t in model["columns"]:
            idx = row.get(t) or []
            if idx:
                bodies = model["_bodies"][a]
                lines.append(f"  {cell_key(a, t)} = " + " ;; ".join(fmt_rule((a, bodies[i])) for i in idx))
    return lines + [""]


def apply_grid(text: str, grid: dict) -> dict:
    """grid: {"first": {A: [символы]} | None, "follow": …, "table": {A: {t: [номера альтернатив]}} | None}.
    Секция, для которой пришло None, не трогается."""
    ans = parse_answer(text)
    if ans.grammar is None or not ans.ok:
        return {"ok": False, "text": text}
    g = ans.grammar
    model = {"nonterminals": g.nonterminals, "columns": g.terminals + [END],
             "_bodies": {a: g.alternatives(a) for a in g.nonterminals}}
    pre, blocks = _blocks(text)
    for name in ("first", "follow", "table"):
        if grid.get(name) is None:
            continue
        new = _render(name, grid, model)
        for i, (bname, old) in enumerate(blocks):
            if bname == name:
                # хвост старого блока (пустые строки, комментарии после секции) сохраняется
                tail = len(old)
                while tail > 1 and (not old[tail - 1].strip() or old[tail - 1].lstrip().startswith("#")):
                    tail -= 1
                blocks[i] = (name, new[:-1] + old[tail:] if old[tail:] else new)
                break
        else:
            pos = len(blocks)
            rank = ORDER.index(name)
            for i, (bname, _) in enumerate(blocks):
                if ORDER.index(bname) > rank:
                    pos = i
                    break
            if pos > 0 and blocks[pos - 1][1] and blocks[pos - 1][1][-1].strip():
                blocks[pos - 1][1].append("")
            blocks.insert(pos, (name, new))
    lines = pre + [line for _, block in blocks for line in block]
    return {"ok": True, "text": "\n".join(lines).rstrip("\n") + "\n"}


# -------------------------------------------------------------- разметка текста

def layout(text: str) -> dict:
    """Всё, что нужно редактору: секции (строки 1…), диагностика разбора,
    модель сетки и разобранные строки трасс.

    Секция — заголовок и строки до следующего заголовка без хвостовых пустых
    строк и комментариев: её диапазон заменяется таблицей в редакторе.
    """
    from .answer import parse_answer as _parse

    ans = _parse(text)
    lines = text.split("\n")
    sections = []
    cur = None
    for i, line in enumerate(lines, 1):
        m = _HEADER.match(line)
        t = _TRACE.match(line)
        if m or t:
            cur = {"name": m.group(1) if m else "trace", "start": i, "end": i, "comments": False}
            if t:
                cur["word"] = re.search(r'"([^"\n]*)"', line).group(1)
            sections.append(cur)
        elif _VERSION.match(line):
            cur = None
        elif cur is not None and line.strip():
            if line.lstrip().startswith("#"):
                cur["_pending_comment"] = True
                continue
            if cur.pop("_pending_comment", False):
                cur["comments"] = True     # комментарий внутри секции
            if "#" in _strip_quoted(line):
                cur["comments"] = True     # комментарий в конце строки
            cur["end"] = i
    for sec in sections:
        sec.pop("_pending_comment", None)
    grid = grid_model(text)
    trace_rows = []
    if ans.ok:
        for tr in ans.traces:
            trace_rows.append({
                "line": tr.line,
                "rows": [{"line": r.line, "stack": [q(s) for s in r.stack],
                          "rest": [q(s) for s in r.rest], "action": _action(r)} for r in tr.rows],
            })
    return {
        "ok": ans.ok,
        "diagnostics": [d.to_dict() for d in ans.diagnostics],
        "sections": sections,
        "nonterminals": ans.grammar.nonterminals if ans.grammar else [],
        "terminals": [q(t) for t in ans.grammar.terminals] if ans.grammar else [],
        "grid": grid,
        "traces": trace_rows,
    }


def _strip_quoted(line: str) -> str:
    return re.sub(r"'[^'\s]+'|\"[^\"\n]*\"", "", line)


def _action(r) -> str:
    if r.action == "rule":
        return fmt_rule(r.rule)
    if r.action == "match":
        return f"match {q(r.matched)}"
    return r.action
