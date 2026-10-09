#!/usr/bin/env python3
"""Эталонный анализатор языка Mini для тестов labgen.

Корректно выполняет все проверки, которые labgen умеет порождать. Переменная
окружения LABGEN_MOCK_DEFECTS (через запятую) включает заложенные дефекты:

  no-return-check  — функция без return принимается;
  no-arg-count     — число аргументов не проверяется;
  crash-dup-func   — повторная функция роняет анализатор трассой;
  reject-fresh     — любое имя zz_labgen_* считается ошибкой (ложная тревога).
"""
import os
import re
import sys

sys.setrecursionlimit(50000)
DEFECTS = set(filter(None, os.environ.get("LABGEN_MOCK_DEFECTS", "").split(",")))

TYPES = {"int", "float", "bool", "string", "void"}
KEYWORDS = TYPES | {"if", "else", "while", "return", "print", "true", "false"}
TOKEN = re.compile(r"""
    (?P<ws>[ \t\r]+) | (?P<nl>\n) | (?P<comment>//[^\n]*)
  | (?P<float>\d+\.\d+) | (?P<int>\d+)
  | (?P<string>"[^"\n]*")
  | (?P<id>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<op>==|!=|<=|>=|[-+*/<>=(){},;])
""", re.X)


class Fail(Exception):
    def __init__(self, kind, line, msg):
        super().__init__(f"{kind} ошибка: строка {line}: {msg}")


def lex(text):
    toks, line, pos = [], 1, 0
    while pos < len(text):
        m = TOKEN.match(text, pos)
        if not m:
            what = "незакрытая строка" if text[pos] == '"' else f"недопустимый символ «{text[pos]}»"
            raise Fail("Лексическая", line, what)
        kind, val = m.lastgroup, m.group()
        if kind == "nl":
            line += 1
        elif kind == "id" and val in KEYWORDS:
            toks.append((val, val, line))
        elif kind == "op":
            toks.append((val, val, line))
        elif kind not in {"ws", "comment"}:
            toks.append((kind, val, line))
        pos = m.end()
    toks.append(("eof", "", line))
    return toks


class Parser:
    def __init__(self, toks):
        self.toks, self.i = toks, 0

    def peek(self, k=0):
        return self.toks[self.i + k]

    def eat(self, kind=None):
        t = self.peek()
        if kind and t[0] != kind:
            raise Fail("Синтаксическая", t[2], f"ожидалось «{kind}», найдено «{t[1] or 'конец файла'}»")
        self.i += 1
        return t

    def program(self):
        items = []
        while self.peek()[0] != "eof":
            if self.peek()[0] in TYPES and self.peek(1)[0] == "id" and self.peek(2)[0] == "(":
                items.append(self.func())
            else:
                items.append(self.stmt())
        return items

    def func(self):
        typ = self.eat()[0]
        name = self.eat("id")
        self.eat("(")
        params = []
        if self.peek()[0] != ")":
            while True:
                pt = self.eat()
                if pt[0] not in TYPES - {"void"}:
                    raise Fail("Синтаксическая", pt[2], "ожидался тип параметра")
                params.append((pt[0], self.eat("id")))
                if self.peek()[0] != ",":
                    break
                self.eat(",")
        self.eat(")")
        return ("func", typ, name, params, self.block())

    def block(self):
        self.eat("{")
        body = []
        while self.peek()[0] != "}":
            if self.peek()[0] == "eof":
                self.eat("}")
            body.append(self.stmt())
        end = self.eat("}")
        return body, end[2]

    def stmt(self):
        t = self.peek()
        if t[0] in TYPES - {"void"}:
            self.eat()
            name = self.eat("id")
            self.eat("=")
            e = self.expr()
            self.eat(";")
            return ("decl", t[0], name, e)
        if t[0] == "if":
            self.eat()
            self.eat("(")
            c = self.expr()
            self.eat(")")
            then = self.block()
            other = None
            if self.peek()[0] == "else":
                self.eat()
                other = self.block()
            return ("if", t[2], c, then, other)
        if t[0] == "while":
            self.eat()
            self.eat("(")
            c = self.expr()
            self.eat(")")
            return ("while", t[2], c, self.block())
        if t[0] == "return":
            self.eat()
            e = None if self.peek()[0] == ";" else self.expr()
            self.eat(";")
            return ("return", t[2], e)
        if t[0] == "print":
            self.eat()
            self.eat("(")
            e = self.expr()
            self.eat(")")
            self.eat(";")
            return ("print", t[2], e)
        if t[0] == "id" and self.peek(1)[0] == "=":
            name = self.eat()
            self.eat("=")
            e = self.expr()
            self.eat(";")
            return ("assign", name, e)
        if t[0] == "id" and self.peek(1)[0] == "(":
            e = self.primary()
            self.eat(";")
            return ("expr", t[2], e)
        raise Fail("Синтаксическая", t[2], f"неожиданное «{t[1] or 'конец файла'}»")

    def expr(self):
        left = self.add()
        if self.peek()[0] in {"<", ">", "<=", ">=", "==", "!="}:
            op = self.eat()
            left = ("bin", op[2], op[0], left, self.add())
        return left

    def add(self):
        left = self.mul()
        while self.peek()[0] in {"+", "-"}:
            op = self.eat()
            left = ("bin", op[2], op[0], left, self.mul())
        return left

    def mul(self):
        left = self.unary()
        while self.peek()[0] in {"*", "/"}:
            op = self.eat()
            left = ("bin", op[2], op[0], left, self.unary())
        return left

    def unary(self):
        if self.peek()[0] == "-":
            op = self.eat()
            return ("neg", op[2], self.unary())
        return self.primary()

    def primary(self):
        t = self.eat()
        if t[0] in {"int", "float", "string"} and t[1] != t[0]:
            return ("lit", t[2], t[0])
        if t[0] in {"true", "false"}:
            return ("lit", t[2], "bool")
        if t[0] == "id" and self.peek()[0] == "(":
            self.eat("(")
            args = []
            if self.peek()[0] != ")":
                args.append(self.expr())
                while self.peek()[0] == ",":
                    self.eat()
                    args.append(self.expr())
            self.eat(")")
            return ("call", t, args)
        if t[0] == "id":
            return ("var", t)
        if t[0] == "(":
            e = self.expr()
            self.eat(")")
            return e
        raise Fail("Синтаксическая", t[2], f"ожидалось выражение, найдено «{t[1] or 'конец файла'}»")


def sem(kind_line, msg):
    return Fail("Семантическая", kind_line, msg)


class Checker:
    def __init__(self):
        self.scopes = [{}]
        self.funcs = {}
        self.ret = None

    def lookup(self, name):
        for s in reversed(self.scopes):
            if name in s:
                return s[name]
        return None

    def define(self, tok, typ):
        if tok[1] in self.scopes[-1]:
            raise sem(tok[2], f"повторное объявление «{tok[1]}»")
        if "reject-fresh" in DEFECTS and tok[1].startswith("zz_labgen_"):
            raise sem(tok[2], f"подозрительное имя «{tok[1]}»")
        self.scopes[-1][tok[1]] = typ

    def program(self, items):
        for it in items:
            if it[0] == "func":
                self.func(it)
            else:
                self.stmt(it)

    def func(self, it):
        _, typ, name, params, (body, end) = it
        if name[1] in self.funcs:
            if "crash-dup-func" in DEFECTS:
                None.attr  # noqa: B018 — заложенное падение
            raise sem(name[2], f"функция «{name[1]}» уже объявлена")
        self.funcs[name[1]] = (typ, [p[0] for p in params])
        self.scopes.append({})
        for ptyp, ptok in params:
            self.define(ptok, ptyp)
        self.ret = typ
        returns = self.block(body)
        self.ret = None
        self.scopes.pop()
        if typ != "void" and not returns and "no-return-check" not in DEFECTS:
            raise sem(end, f"функция «{name[1]}» не возвращает значение на всех путях")

    def block(self, body):
        self.scopes.append({})
        returns = False
        for st in body:
            returns = self.stmt(st) or returns
        self.scopes.pop()
        return returns

    def stmt(self, st):
        k = st[0]
        if k == "decl":
            _, typ, name, e = st
            et = self.expr(e)
            self.assign_check(typ, et, name[2])
            self.define(name, typ)
        elif k == "assign":
            _, name, e = st
            vt = self.lookup(name[1])
            if vt is None:
                raise sem(name[2], f"переменная «{name[1]}» не объявлена")
            self.assign_check(vt, self.expr(e), name[2])
        elif k in {"if", "while"}:
            if self.expr(st[2]) != "bool":
                raise sem(st[1], "условие должно иметь тип bool")
            if k == "while":
                self.block(st[3][0])
                return False
            r1 = self.block(st[3][0])
            r2 = self.block(st[4][0]) if st[4] else False
            return r1 and r2
        elif k == "return":
            if self.ret is None:
                raise sem(st[1], "return вне функции")
            et = "void" if st[2] is None else self.expr(st[2])
            if et != self.ret:
                raise sem(st[1], f"функция типа {self.ret} возвращает {et}")
            return True
        elif k == "print":
            if self.expr(st[2]) == "void":
                raise sem(st[1], "значение void нельзя напечатать")
        elif k == "expr":
            self.expr(st[2])
        return False

    def assign_check(self, target, source, line):
        if source == "void":
            raise sem(line, "результат void-функции нельзя присвоить")
        if target != source:
            raise sem(line, f"нельзя присвоить {source} переменной типа {target} без явного преобразования")

    def expr(self, e):
        k = e[0]
        if k == "lit":
            return e[2]
        if k == "var":
            t = self.lookup(e[1][1])
            if t is None:
                raise sem(e[1][2], f"переменная «{e[1][1]}» не объявлена")
            return t
        if k == "call":
            name, args = e[1], e[2]
            f = self.funcs.get(name[1])
            if f is None:
                raise sem(name[2], f"функция «{name[1]}» не объявлена")
            types = [self.expr(a) for a in args]
            if len(types) != len(f[1]):
                if "no-arg-count" in DEFECTS:
                    return f[0]
                raise sem(name[2], f"«{name[1]}» ожидает {len(f[1])} аргументов, передано {len(types)}")
            for a, p in zip(types, f[1]):
                if a != p:
                    raise sem(name[2], f"аргумент типа {a} вместо {p}")
            return f[0]
        if k == "neg":
            t = self.expr(e[2])
            if t not in {"int", "float"}:
                raise sem(e[1], "унарный минус к нечисловому значению")
            return t
        _, line, op, a, b = e
        ta, tb = self.expr(a), self.expr(b)
        if op in {"==", "!="}:
            if ta != tb or ta == "void":
                raise sem(line, f"сравнение {ta} и {tb}")
            return "bool"
        if ta not in {"int", "float"} or ta != tb:
            raise sem(line, f"операция «{op}» над {ta} и {tb}")
        return "bool" if op in {"<", ">", "<=", ">="} else ta


def depth(e):
    if e[0] == "bin":
        return 1 + max(depth(e[3]), depth(e[4]))
    if e[0] == "neg":
        return 1 + depth(e[2])
    return 1


def main():
    text = open(sys.argv[1], encoding="utf-8").read()
    try:
        items = Parser(lex(text)).program()
        Checker().program(items)
    except Fail as e:
        print(e)
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
