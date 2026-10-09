"""Мутанты: программы с одним изменением и известным ожиданием."""

from __future__ import annotations

import re
from dataclasses import dataclass, field

from .lexing import ASSIGN_OPS, COND_KW, IDENT_RE, LangInfo, Lexed
from .structure import Func, defined_names, find_funcs, in_funcs, match_close, var_names, var_uses


# --- мутанты ----------------------------------------------------------------


@dataclass
class Mutant:
    id: str
    op: str
    mode: str
    expect: str            # error | pass
    confidence: str        # high | medium
    seed: str
    line: int
    desc: str
    text: str
    before: str = ""
    after: str = ""
    lines: list[int] = field(default_factory=list)   # строки, на которые должно указывать сообщение
    # заполняется после запуска
    exit: int | None = None
    kind: str = ""
    output: str = ""
    verdict: str = ""
    note: str = ""


def edit(text: str, edits: list[tuple[int, int, str]]) -> str:
    for s, e, new in sorted(edits, key=lambda x: -x[0]):
        text = text[:s] + new + text[e:]
    return text


def line_of(text: str, n: int) -> str:
    ls = text.split("\n")
    return ls[n - 1] if 0 < n <= len(ls) else ""


FRESH = "zz_labgen"


def assign_template(lx: Lexed, li: LangInfo, funcs: list[Func]) -> tuple[str, str] | None:
    """Префикс объявления/присваивания новой глобальной переменной по образцу примера:
    `var zz_labgen_leak = ` или `zz_labgen_leak = `, и хвост строки (`;`)."""
    for ln in range(1, len(lx.lines) + 1):
        if in_funcs(funcs, ln) or lx.indent(ln) != 0:
            continue
        code = [x for x in lx.by_line.get(ln, []) if x.text.strip()]
        k = next((j for j, x in enumerate(code) if x.text in ASSIGN_OPS), None)
        if k is None or k == 0 or code[k - 1].type != li.id_type:
            continue
        if not all((x.lit and IDENT_RE.match(x.lit)) or x.type == li.id_type for x in code[:k - 1]):
            continue
        tail = code[-1].text if code[-1].text in {";"} else ""
        prefix = lx.lines[ln - 1][:code[k - 1].col] + FRESH + "_leak " + code[k].text + " "
        return prefix, tail
    return None


def gen_sem(lx: Lexed, li: LangInfo) -> list[Mutant]:
    funcs = find_funcs(lx, li)
    fnames = {f.name for f in funcs}
    dup_names = {n for n in fnames if sum(f.name == n for f in funcs) > 1}
    seed = lx.path.name
    T = lx.text
    out: list[Mutant] = []

    def mk(op, expect, conf, line, desc, new_text, lines=None):
        out.append(Mutant("", op, "sem", expect, conf, seed, line, desc, new_text,
                          line_of(T, line), line_of(new_text, line), lines or [line]))

    # Необъявленная переменная: только имена, которые где-то получают значение
    # (левая часть присваивания, параметр, переменная цикла). Иначе это может быть
    # не переменная (имя вершины, метка, поле).
    defined = defined_names(lx, li, funcs)
    for t in var_uses(lx, li, funcs):
        if t.text not in defined:
            continue
        mk("undeclared-var", "error", "high", t.line,
           f"`{t.text}` заменено на необъявленное `{FRESH}_v`",
           edit(T, [(t.start, t.stop + 1, f"{FRESH}_v")]))

    # Вызовы.
    for t in lx.toks:
        n = lx.next(t)
        if t.type != li.id_type or not n or n.text != "(":
            continue
        if any(f.name_tok is t for f in funcs):
            continue
        p = lx.prev(t)
        if p and p.text == ".":
            continue
        mk("unknown-func", "error", "high", t.line,
           f"вызов `{t.text}(…)` заменён на необъявленную `{FRESH}_f(…)`",
           edit(T, [(t.start, t.stop + 1, f"{FRESH}_f")]))
        if t.text in fnames and t.text not in dup_names:
            close = match_close(lx, n)
            if not close:
                continue
            inner = lx.toks[lx.toks.index(n) + 1:lx.toks.index(close)]
            args, depth, cur = [], 0, []
            for x in inner:
                if x.text in "([{":
                    depth += 1
                elif x.text in ")]}":
                    depth -= 1
                if x.text == "," and depth == 0:
                    args.append(cur)
                    cur = []
                else:
                    cur.append(x)
            if cur:
                args.append(cur)
            if args:
                last = args[-1]
                cut_from = (args[-2][-1].stop + 1) if len(args) > 1 else n.stop + 1
                mk("arg-count", "error", "high", t.line,
                   f"у вызова `{t.text}` убран последний аргумент ({len(args)} → {len(args) - 1})",
                   edit(T, [(cut_from, close.start, "")]))
                extra = T[last[0].start:last[-1].stop + 1]
                mk("arg-count", "error", "high", t.line,
                   f"у вызова `{t.text}` добавлен аргумент ({len(args)} → {len(args) + 1})",
                   edit(T, [(close.start, close.start, f", {extra}")]))
            else:
                mk("arg-count", "error", "high", t.line,
                   f"у вызова `{t.text}` добавлен аргумент (0 → 1)",
                   edit(T, [(close.start, close.start, li.number_sample)]))

    # Строка в арифметике.
    for t in lx.toks:
        if t.type not in li.num_types:
            continue
        p, n = lx.prev(t), lx.next(t)
        if (p and p.text in {"-", "*", "/"}) or (n and n.text in {"-", "*", "/"}):
            mk("string-arith", "error", "high", t.line,
               f"число `{t.text}` в арифметике заменено строкой {li.string_sample}",
               edit(T, [(t.start, t.stop + 1, li.string_sample)]))

    # Строка в условии.
    if li.has_bool:
        for t in lx.toks:
            if (t.lit or "") not in COND_KW:
                continue
            n = lx.next(t)
            if not n:
                continue
            if n.text == "(":
                c = match_close(lx, n)
                if c and c.line == t.line:
                    mk("string-cond", "error", "medium", t.line,
                       f"условие `{t.lit}` заменено строкой {li.string_sample}",
                       edit(T, [(n.stop + 1, c.start, li.string_sample)]))
                continue
            seg = []
            for x in lx.toks[lx.toks.index(n):]:
                if x.line != t.line or x.text in {":", "{", "then", "do"} or not x.text.strip():
                    break
                seg.append(x)
            if seg:
                mk("string-cond", "error", "medium", t.line,
                   f"условие `{t.lit}` заменено строкой {li.string_sample}",
                   edit(T, [(seg[0].start, seg[-1].stop + 1, li.string_sample)]))

    lines = T.split("\n")
    for f in funcs:
        # Нет return: удаляем все строки-return с выражением.
        if f.returns_value:
            ret_lines = []
            ok = True
            for ln in range(f.header_lines[1] + 1, f.body[1] + 1):
                code = [x for x in lx.by_line.get(ln, []) if x.text.strip()]
                if any(x.lit == "return" for x in code):
                    if code[0].lit != "return":
                        ok = False
                    ret_lines.append(ln)
            body_code = [ln for ln in range(f.header_lines[1] + 1, f.body[1] + 1) if lx.code_line(ln)]
            if ok and ret_lines and len(body_code) - len(ret_lines) >= 1:
                new = "\n".join(("" if i + 1 in ret_lines else s) for i, s in enumerate(lines))
                mk("missing-return", "error", "high", ret_lines[0],
                   f"из функции `{f.name}` удалены все return ({len(ret_lines)})", new,
                   list(range(f.body[0], f.body[1] + 2)))
        # Повторное объявление функции сразу после исходной.
        block = "\n".join(lines[f.body[0] - 1:f.body[1]])
        new = "\n".join(lines[:f.body[1]] + ["", block] + lines[f.body[1]:])
        n_lines = f.body[1] - f.body[0] + 1
        mk("dup-func", "error", "high", f.body[1] + 2, f"функция `{f.name}` объявлена второй раз", new,
           [f.body[0]] + list(range(f.body[1] + 2, f.body[1] + 3 + n_lines)))
        # Повторный параметр: первая группа параметров продублирована в конце списка.
        # При перегрузке это новая сигнатура — проверка «не та» (вызовы не сойдутся).
        if f.params and f.param_groups and li.props.get("overload") != "yes":
            g0 = T[f.param_groups[0][0]:f.param_groups[0][1]]
            mk("dup-param", "error", "high", f.header_lines[0],
               f"параметр `{f.params[0].text}` функции `{f.name}` объявлен второй раз",
               edit(T, [(f.close_paren, f.close_paren, ", " + g0)]))

    # Локальная переменная вне функции.
    names_out = {t.text for t in lx.toks if t.type == li.id_type and not in_funcs(funcs, t.line)}
    template = assign_template(lx, li, funcs)
    if template:
        for f in funcs:
            local = []
            for t in lx.toks:
                if t.type == li.id_type and f.header_lines[1] < t.line <= f.body[1] and t.text not in names_out \
                        and t.text not in fnames:
                    n = lx.next(t)
                    if n and n.text in ASSIGN_OPS and t.text not in [p.text for p in f.params]:
                        local.append(t.text)
            for name in dict.fromkeys(local):
                new = T.rstrip("\n") + "\n" + template[0] + name + template[1] + "\n"
                mk("local-leak", "error", "high", len(T.rstrip("\n").split("\n")) + 1,
                   f"локальная переменная `{name}` функции `{f.name}` использована вне функции", new)

    # Неявное приведение: вещественный литерал заменён целым. Ожидание — по варианту.
    conv = li.props.get("conversion", "")
    for t in lx.toks:
        if t.type not in li.num_types or not re.fullmatch(r"\d+\.0+", t.text):
            continue
        p, n = lx.prev(t), lx.next(t)
        if not p or p.text not in {"=", ":=", "+", "-", "*", "/", "<", ">", "<=", ">=", "==", "!="}:
            continue
        if p.text in ASSIGN_OPS:
            # Только присваивание уже объявленной переменной: при неявном объявлении
            # `x = 0` в первой строке просто создаёт int-переменную.
            lhs = lx.prev(p)
            if not lhs or lhs.type != li.id_type:
                continue
            typed_decl = (q := lx.prev(lhs)) and q.line == lhs.line and (q.lit or "") in li.keywords
            earlier = any(x.text == lhs.text and x.type == li.id_type and x.start < lhs.start for x in lx.toks)
            if not (typed_decl or earlier):
                continue
        if n and n.text.strip() and n.text not in {"+", "-", "*", "/", ")", ";", ":"} and n.line == t.line:
            continue
        expect = {"explicit": "error", "implicit": "pass"}.get(conv)
        if expect:
            mk("implicit-cast" if expect == "error" else "ctl-implicit-cast", expect, "medium", t.line,
               f"вещественный `{t.text}` заменён целым `{t.text.split('.')[0]}` (преобразование: {conv})",
               edit(T, [(t.start, t.stop + 1, t.text.split(".")[0])]))

    # Значение void-функции в присваивании.
    if "void" in li.keywords:
        assign_tpl = assign_template(lx, li, funcs)
        for f in funcs:
            if f.returns_value:
                continue
            header = [x.text for ln in range(f.header_lines[0], f.header_lines[1] + 1) for x in lx.by_line[ln]]
            if "void" not in header:
                continue
            for t in lx.toks:
                if t.text != f.name or t is f.name_tok:
                    continue
                code = [x for x in lx.by_line[t.line] if x.text.strip()]
                if code and code[0] is t and assign_tpl:
                    ls = T.split("\n")
                    ind = ls[t.line - 1][:t.col]
                    ls[t.line - 1] = ind + assign_tpl[0].lstrip() + ls[t.line - 1][t.col:]
                    mk("void-value", "error", "high", t.line,
                       f"результат void-функции `{f.name}` присвоен переменной", "\n".join(ls))

    # Каскад: необъявленное имя в правой части присваивания, левая часть потом используется.
    # Ожидание — ровно одно сообщение об ошибке.
    for t in var_uses(lx, li, funcs):
        code = [x for x in lx.by_line[t.line] if x.text.strip()]
        if len(code) < 3 or code[1].text not in ASSIGN_OPS or code[0].type != li.id_type:
            continue
        lhs = code[0].text
        if sum(1 for x in lx.toks if x.text == lhs and x.line > t.line) == 0:
            continue
        if sum(1 for x in lx.toks if x.text == lhs and x.line < t.line and x.type == li.id_type) > 0:
            continue  # уже объявлена раньше — каскада не будет
        m0 = len(out)
        mk("cascade", "one-error", "medium", t.line,
           f"`{t.text}` в инициализации `{lhs}` заменено необъявленным; `{lhs}` используется ниже",
           edit(T, [(t.start, t.stop + 1, f"{FRESH}_v")]))
        if len(out) > m0 and sum(m.op == "cascade" for m in out) >= 3:
            break

    # Глубокое выражение по образцу присваивания из примера: не должно падать.
    for t in lx.toks:
        if t.type not in li.num_types:
            continue
        p, n = lx.prev(t), lx.next(t)
        if p and p.text in ASSIGN_OPS and n and (n.line != t.line or not n.text.strip() or n.text == ";"):
            deep = " + ".join([t.text] * 3000)
            mk("deep-expr", "no-crash", "high", t.line, "правая часть присваивания — сумма из 3000 слагаемых",
               edit(T, [(t.start, t.stop + 1, deep)]))
            nest = "(" * 500 + t.text + ")" * 500
            mk("deep-expr", "no-crash", "high", t.line, "правая часть — 500 вложенных скобок",
               edit(T, [(t.start, t.stop + 1, nest)]))
            break

    # Контроль: согласованное переименование — анализатор обязан принять.
    for name in sorted(var_names(lx, li, funcs) - li.keywords):
        occ = [t for t in lx.toks if t.type == li.id_type and t.text == name
               and not ((p := lx.prev(t)) and p.text == ".")]
        if len(occ) >= 2:
            mk("ctl-rename-var", "pass", "high", occ[0].line,
               f"переменная `{name}` согласованно переименована ({len(occ)} мест)",
               edit(T, [(t.start, t.stop + 1, f"{FRESH}_{name}") for t in occ]))
    for name in sorted(fnames - dup_names):
        occ = [t for t in lx.toks if t.type == li.id_type and t.text == name]
        mk("ctl-rename-func", "pass", "high", occ[0].line,
           f"функция `{name}` согласованно переименована ({len(occ)} мест)",
           edit(T, [(t.start, t.stop + 1, f"{FRESH}_{name}") for t in occ]))
    return out


def gen_syn(lx: Lexed, li: LangInfo) -> list[Mutant]:
    T, seed, out = lx.text, lx.path.name, []

    def mk(op, line, desc, new_text):
        out.append(Mutant("", op, "syn", "error", "high", seed, line, desc, new_text,
                          line_of(T, line), line_of(new_text, line), [line]))

    for t in lx.toks:
        if t.text == ")":
            mk("drop-rparen", t.line, "удалена закрывающая `)`", edit(T, [(t.start, t.stop + 1, "")]))
    bad = next((c for c in "@$`?~^" if c not in "".join(li.literals)), None)
    funcs = find_funcs(lx, li)
    if bad:
        for t in var_uses(lx, li, funcs):
            mk("bad-char", t.line, f"перед `{t.text}` вставлен недопустимый символ `{bad}`",
               edit(T, [(t.start, t.start, bad)]))
    for t in lx.toks:
        if t.type in li.str_types and len(t.text) >= 2:
            mk("unclosed-string", t.line, f"у строки {t.text[:20]} удалена закрывающая кавычка",
               edit(T, [(t.stop, t.stop + 1, "")]))
    for t in lx.toks:
        if (t.lit or "") in COND_KW:
            code = [x for x in lx.by_line[t.line] if x.text.strip()]
            if code and code[-1].text in {":", "{", "then", "do"}:
                last = code[-1]
                mk("drop-delim", t.line, f"после условия `{t.lit}` удалён `{last.text}`",
                   edit(T, [(last.start, last.stop + 1, "")]))
    return out
