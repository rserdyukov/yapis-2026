#!/usr/bin/env python3
r"""miniapl: учебная модель подмножества APL для статьи «APL: нотация как инструмент мышления».

Это не Dyalog APL и не ISO APL. Модель нужна, чтобы (1) проверить
вычисления из статьи и (2) показать, как разбирается выражение без уровней
приоритета. Поддерживаются: числа и векторы (страндинг `1 2 3`, `¯2`),
вложенные векторы `(1 2)(3 4)`, имена-массивы и `←`, скобки, комментарии `⍝`;
функции + - × ÷ * | ⌈ ⌊ = < > (скалярные, с распространением скаляра),
~ ⍳ ≢ ⍴ (монадные), ∊ ↓ ⍴ и / как replicate (диадные);
операторы f/ (reduce), f\ (scan), f¨ (each), ∘.f (внешнее произведение).
Нет: функций пользователя, dfns, поездов, осей, символьных данных, ⎕IO≠1.
Запуск: python3 miniapl.py файл.apl
"""
import re
import sys
from itertools import accumulate


class APLError(Exception):
    pass


# --- значения: число, список (вектор, возможно вложенный) или Matrix -------
class Matrix(list):
    """Матрица ранга 2 — список строк; отличается от вектора векторов."""


def scalar_dyad(f):
    """Скалярная функция: поэлементно на любой глубине, скаляр размножается."""
    def g(a, b):
        wrap = Matrix if isinstance(a, Matrix) or isinstance(b, Matrix) else list
        if isinstance(a, list) and isinstance(b, list):
            if len(a) != len(b):
                raise APLError("LENGTH ERROR")
            return wrap(g(x, y) for x, y in zip(a, b))
        if isinstance(a, list):
            return wrap(g(x, b) for x in a)
        if isinstance(b, list):
            return wrap(g(a, y) for y in b)
        return f(a, b)
    return g


def scalar_monad(f):
    def g(a):
        return [g(x) for x in a] if isinstance(a, list) else f(a)
    return g


def num(x):
    return int(x) if isinstance(x, float) and x.is_integer() else x


def ravel(a):
    if isinstance(a, Matrix):
        return [x for row in a for x in row]
    return a if isinstance(a, list) else [a]


def replicate(a, b):
    a, b = ravel(a), ravel(b)
    if len(a) == 1:
        a = a * len(b)
    if len(a) != len(b):
        raise APLError("LENGTH ERROR")
    return [y for k, y in zip(a, b) for _ in range(k)]


def reshape(shape, b):
    items, shape = ravel(b), ravel(shape)
    flat = [items[i % len(items)] for i in range(eval_prod(shape))]
    if len(shape) == 1:
        return flat
    n = shape[1]
    return Matrix(flat[i:i + n] for i in range(0, len(flat), n))


def eval_prod(xs):
    p = 1
    for x in xs:
        p *= x
    return p


# --8<-- [start:functions]
DYADIC = {
    "+": scalar_dyad(lambda a, b: a + b),
    "-": scalar_dyad(lambda a, b: a - b),
    "×": scalar_dyad(lambda a, b: a * b),
    "÷": scalar_dyad(lambda a, b: num(a / b)),
    "*": scalar_dyad(lambda a, b: num(a ** b)),
    "|": scalar_dyad(lambda a, b: b % a),       # остаток: 3|7 — это 1
    "⌈": scalar_dyad(max),
    "⌊": scalar_dyad(min),
    "=": scalar_dyad(lambda a, b: int(a == b)),
    "<": scalar_dyad(lambda a, b: int(a < b)),
    ">": scalar_dyad(lambda a, b: int(a > b)),
    "∊": lambda a, b: keep_shape(a, lambda x: int(x in flatten(b))),
    "↓": lambda a, b: ravel(b)[a:],
    "/": replicate,                             # 1 0 1/V — отбор
    "⍴": reshape,
}
MONADIC = {
    "+": lambda a: a,
    "-": scalar_monad(lambda a: -a),
    "×": scalar_monad(lambda a: (a > 0) - (a < 0)),
    "÷": scalar_monad(lambda a: num(1 / a)),
    "~": lambda a: keep_shape(a, lambda x: 1 - x),
    "⍳": lambda n: list(range(1, n + 1)),       # ⎕IO=1
    "≢": lambda a: len(a) if isinstance(a, list) else 1,
    "⍴": lambda a: [len(a)] if isinstance(a, list) else [],
}
# --8<-- [end:functions]


def keep_shape(a, f):
    """Поэлементно, сохраняя форму (в том числе Matrix)."""
    if isinstance(a, Matrix):
        return Matrix([f(x) for x in row] for row in a)
    return scalar_monad(f)(a)


def flatten(a):
    if not isinstance(a, list):
        return [a]
    return [y for x in a for y in flatten(x)]


# --8<-- [start:operators]
def reduce_(f):             # f/ : 1 2 3 4 → 1 f (2 f (3 f 4)), справа налево
    def g(w):
        items = ravel(w)
        if not items:
            raise APLError("DOMAIN ERROR")
        acc = items[-1]
        for x in reversed(items[:-1]):
            acc = f(x, acc)
        return acc
    return g


def scan(f):                # f\ : i-й элемент — f/ первых i элементов
    return lambda w: [reduce_(f)(ravel(w)[:i + 1]) for i in range(len(ravel(w)))]


def each(f):                # f¨ : применить к каждому элементу
    return lambda w: [f(x) for x in ravel(w)]


def outer(f):               # ∘.f : таблица f для всех пар
    return lambda a, w: Matrix([f(x, y) for y in ravel(w)] for x in ravel(a))
# --8<-- [end:operators]


TOKEN = re.compile(r"\s*(¯?\d+(?:\.\d+)?|[A-Za-z_]\w*|∘\.|.)")
FUNCS = set(DYADIC) | set(MONADIC)


def tokenize(line):
    line = line.split("⍝", 1)[0]
    return [t for t in TOKEN.findall(line) if t.strip()]


# --8<-- [start:parser]
# Грамматика без уровней приоритета (все функции равноправны):
#   expr  ::= NAME '←' expr | fn expr | value [ fn expr ]
#   fn    ::= '∘.' PRIM | PRIM { '/' | '\' | '¨' }
#   value ::= atom { atom }              (страндинг: 1 2 3)
#   atom  ::= NUMBER | NAME | '(' expr ')'
# Правая рекурсия в expr и даёт вычисление «справа налево».
class Parser:
    def __init__(self, tokens):
        self.t, self.i = tokens, 0

    def peek(self, k=0):
        j = self.i + k
        return self.t[j] if j < len(self.t) else None

    def take(self):
        tok = self.peek()
        self.i += 1
        return tok

    def expr(self):
        if is_name(self.peek()) and self.peek(1) == "←":
            name = self.take()
            self.take()
            return ("assign", name, self.expr())
        if self.peek() in FUNCS or self.peek() == "∘.":
            return ("monad", self.fn(), self.expr())
        left = self.value()
        if self.peek() in (None, ")"):
            return left
        return ("dyad", self.fn(), left, self.expr())

    def fn(self):
        if self.peek() == "∘.":
            self.take()
            return ("outer", self.take())
        f = ("prim", self.take())
        while self.peek() in ("/", "\\", "¨"):  # '/' после функции — оператор
            f = ({"/": "reduce", "\\": "scan", "¨": "each"}[self.take()], f)
        return f

    def value(self):
        items = []
        while self.peek() is not None and (
                is_number(self.peek()) or self.peek() == "("
                or (is_name(self.peek()) and self.peek(1) != "←")):
            if self.peek() == "(":
                self.take()
                items.append(self.expr())
                if self.take() != ")":
                    raise APLError("SYNTAX ERROR")
            else:
                items.append(("atom", self.take()))
        if not items:
            raise APLError("SYNTAX ERROR")
        return items[0] if len(items) == 1 else ("strand", items)
# --8<-- [end:parser]


def is_number(tok):
    return tok is not None and re.fullmatch(r"¯?\d+(?:\.\d+)?", tok) is not None


def is_name(tok):
    return tok is not None and re.fullmatch(r"[A-Za-z_]\w*", tok) is not None


# --8<-- [start:eval]
class Interpreter:
    def __init__(self):
        self.env = {}

    def eval(self, node):
        kind = node[0]
        if kind == "atom":
            tok = node[1]
            if is_number(tok):
                return num(float(tok.replace("¯", "-")))
            if tok not in self.env:
                raise APLError("VALUE ERROR: " + tok)
            return self.env[tok]
        if kind == "strand":
            return [self.eval(n) for n in node[1]]
        if kind == "assign":
            self.env[node[1]] = self.eval(node[2])
            return self.env[node[1]]
        if kind == "monad":
            return self.function(node[1], 1)(self.eval(node[2]))
        if kind == "dyad":                  # сначала правый аргумент
            right = self.eval(node[3])
            left = self.eval(node[2])
            return self.function(node[1], 2)(left, right)
        raise APLError("SYNTAX ERROR")

    def function(self, f, valence):
        kind = f[0]
        if kind == "prim":
            table = DYADIC if valence == 2 else MONADIC
            if f[1] not in table:
                raise APLError("VALENCE ERROR: " + f[1])
            return table[f[1]]
        if kind == "outer":
            return outer(DYADIC[f[1]])
        if kind in ("reduce", "scan"):
            op = reduce_ if kind == "reduce" else scan
            return op(self.function(f[1], 2))
        if kind == "each":
            return each(self.function(f[1], 1))
        raise APLError("SYNTAX ERROR")
# --8<-- [end:eval]


def fmt_num(x):
    s = str(num(x))
    return s.replace("-", "¯")


def show(v):
    if not isinstance(v, list):
        return fmt_num(v)
    if isinstance(v, Matrix):
        cells = [[fmt_num(x) for x in r] for r in v]
        width = [max(len(r[j]) for r in cells) for j in range(len(cells[0]))]
        return "\n".join(" ".join(c.rjust(w) for c, w in zip(r, width))
                         for r in cells)
    if any(isinstance(x, list) for x in v):            # вложенный вектор
        return " " + "  ".join(show(x) for x in v)
    return " ".join(fmt_num(x) for x in v)


def run(text):
    it = Interpreter()
    for line in text.splitlines():
        tokens = tokenize(line)
        if not tokens:
            continue
        try:
            tree = Parser(tokens).expr()
            value = it.eval(tree)
            if tree[0] != "assign":            # как в сессии APL
                print(show(value))
        except APLError as e:
            print(e)
        except (IndexError, KeyError, TypeError):
            print("SYNTAX ERROR")


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as f:
        run(f.read())
