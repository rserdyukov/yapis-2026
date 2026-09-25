# Дерево разбора в miniapl: одна правая рекурсия вместо уровней приоритета.
from miniapl import Parser, tokenize


def show(node):
    kind = node[0]
    if kind == "atom":
        return node[1]
    if kind == "strand":
        return "[" + " ".join(show(n) for n in node[1]) + "]"
    if kind == "monad":
        return f"({fn(node[1])} {show(node[2])})"
    if kind == "dyad":
        return f"({fn(node[1])} {show(node[2])} {show(node[3])})"
    if kind == "assign":
        return f"(← {node[1]} {show(node[2])})"


def fn(f):
    if f[0] == "prim":
        return f[1]
    if f[0] == "outer":
        return "∘." + f[1]
    return fn(f[1]) + {"reduce": "/", "scan": "\\", "each": "¨"}[f[0]]


for src in ["2×3+4", "(2×3)+4", "10-2-3", "-/1 2 3 4", "+/V÷≢V",
            "(~R∊R∘.×R)/R←1↓⍳N"]:
    print(f"{src:20} → {show(Parser(tokenize(src)).expr())}")
