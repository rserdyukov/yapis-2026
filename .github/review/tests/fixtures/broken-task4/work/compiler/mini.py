#!/usr/bin/env python3
"""Анализатор языка Mini: синтаксис (построчно) и семантика.

Программа — последовательность строк:
    <тип> <имя> = <выражение>
    <имя> = <выражение>
    func <тип> <имя>(<val|res> <тип> <имя>, ...)
    if <выражение>
    end
    return <выражение>
    <имя>(<аргументы>)
"""
import re
import sys

TYPES = {"int", "float", "bool", "void"}
IDENT = r"[A-Za-z_][A-Za-z0-9_]*"


class MiniError(Exception):
    def __init__(self, kind, line, col, text):
        super().__init__(f"{kind} ошибка [{line}:{col}]: {text}")


class Symbol:
    def __init__(self, name, typ, kind="var", params=None):
        self.name, self.type, self.kind, self.params = name, typ, kind, params or []


class Scope:
    def __init__(self, parent=None):
        self.parent, self.names = parent, {}

    def define(self, sym, line):
        if sym.name in self.names:
            raise MiniError("Семантическая", line, 1, f"повторное объявление «{sym.name}»")
        self.names[sym.name] = sym

    def lookup(self, name):
        s = self
        while s:
            if name in s.names:
                return s.names[name]
            s = s.parent
        return None


def assignable(target, source):
    """Можно ли значение типа source записать в переменную типа target."""
    if target == source:
        return True
    # Расширение int -> float.
    return target == "float" and source == "int"


class Analyzer:
    def __init__(self):
        self.scope = Scope()
        self.func = None

    def expr_type(self, text, line):
        text = text.strip()
        call = re.fullmatch(rf"({IDENT})\((.*)\)", text)
        if call:
            return self.check_call(call.group(1), call.group(2), line)
        if re.fullmatch(r"\d+", text):
            return "int"
        if re.fullmatch(r"\d+\.\d+", text):
            return "float"
        if text in ("true", "false"):
            return "bool"
        m = re.fullmatch(rf"(.+?)\s*([+\-*/<>])\s*(.+)", text)
        if m:
            left, right = self.expr_type(m.group(1), line), self.expr_type(m.group(3), line)
            if m.group(2) in "<>":
                return "bool"
            if left == right:
                return left
            if {left, right} == {"int", "float"}:
                return "float"
            raise MiniError("Семантическая", line, 1, f"операция {m.group(2)} над {left} и {right}")
        if re.fullmatch(IDENT, text):
            sym = self.scope.lookup(text)
            if not sym:
                raise MiniError("Семантическая", line, 1, f"переменная «{text}» не объявлена")
            return sym.type
        raise MiniError("Синтаксическая", line, 1, f"не разобрано выражение «{text}»")

    def check_call(self, name, args_text, line):
        fn = self.scope.lookup(name)
        if not fn or fn.kind != "func":
            raise MiniError("Семантическая", line, 1, f"функция «{name}» не объявлена")
        args = [a.strip() for a in args_text.split(",") if a.strip()]
        if len(args) != len(fn.params):
            raise MiniError("Семантическая", line, 1,
                            f"«{name}» ожидает {len(fn.params)} аргументов, передано {len(args)}")
        for (mode, ptype, _), arg in zip(fn.params, args):
            if mode == "res":
                var = self.scope.lookup(arg)
                if not var or var.kind != "var":
                    raise MiniError("Семантическая", line, 1, "res-аргумент должен быть переменной")
                if not assignable(ptype, var.type):
                    raise MiniError("Семантическая", line, 1, f"res: {var.type} несовместим с {ptype}")
            else:
                atype = self.expr_type(arg, line)
                if not assignable(ptype, atype):
                    raise MiniError("Семантическая", line, 1, f"аргумент {atype} вместо {ptype}")
        return fn.type

    def run(self, lines):
        for no, raw in enumerate(lines, 1):
            line = raw.split("#", 1)[0].strip()
            if not line:
                continue
            self.statement(line, no)

    def statement(self, line, no):
        m = re.fullmatch(rf"func\s+(\w+)\s+({IDENT})\((.*)\)", line)
        if m:
            params = []
            for p in filter(None, (x.strip() for x in m.group(3).split(","))):
                pm = re.fullmatch(rf"(val|res)\s+(\w+)\s+({IDENT})", p)
                if not pm:
                    raise MiniError("Синтаксическая", no, 1, f"параметр «{p}»")
                params.append(pm.groups())
            fn = Symbol(m.group(2), m.group(1), "func", params)
            self.scope.define(fn, no)
            self.scope = Scope(self.scope)
            for _, ptype, pname in params:
                self.scope.define(Symbol(pname, ptype), no)
            self.func = fn
            return
        if line.startswith("if "):
            if self.expr_type(line[3:], no) != "bool":
                raise MiniError("Семантическая", no, 4, "условие if должно быть bool")
            self.scope = Scope(self.scope)
            return
        if line == "end":
            if self.scope.parent is None:
                raise MiniError("Синтаксическая", no, 1, "лишний end")
            self.scope = self.scope.parent
            if self.scope.parent is None:
                self.func = None
            return
        if line.startswith("return "):
            if not self.func:
                raise MiniError("Семантическая", no, 1, "return вне функции")
            t = self.expr_type(line[7:], no)
            if not assignable(self.func.type, t):
                raise MiniError("Семантическая", no, 8, f"return {t} в функции типа {self.func.type}")
            return
        m = re.fullmatch(rf"(\w+)\s+({IDENT})\s*=\s*(.+)", line)
        if m and m.group(1) in TYPES:
            t = self.expr_type(m.group(3), no)
            if not assignable(m.group(1), t):
                raise MiniError("Семантическая", no, 1, f"нельзя присвоить {t} в {m.group(1)}")
            self.scope.define(Symbol(m.group(2), m.group(1)), no)
            return
        m = re.fullmatch(rf"({IDENT})\s*=\s*(.+)", line)
        if m:
            sym = self.scope.lookup(m.group(1))
            if not sym:
                raise MiniError("Семантическая", no, 1, f"переменная «{m.group(1)}» не объявлена")
            t = self.expr_type(m.group(2), no)
            if not assignable(sym.type, t):
                raise MiniError("Семантическая", no, 1, f"нельзя присвоить {t} в {sym.type}")
            return
        if re.fullmatch(rf"{IDENT}\(.*\)", line):
            self.expr_type(line, no)
            return
        raise MiniError("Синтаксическая", no, 1, f"неизвестная инструкция «{line}»")


def main():
    with open(sys.argv[1], encoding="utf-8") as f:
        lines = f.read().splitlines()
    try:
        Analyzer().run(lines)
    except MiniError as e:
        print(e, file=sys.stderr)
        return 1
    print("ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
