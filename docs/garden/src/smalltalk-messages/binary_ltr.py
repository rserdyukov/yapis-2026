# Мини-вычислитель выражений по правилам Smalltalk:
#   унарные > бинарные (строго слева направо) > ключевые; скобки — первыми.
import math
import re

UNARY = {"factorial": math.factorial, "negated": lambda x: -x,
         "squared": lambda x: x * x}
BINARY = {"+": lambda a, b: a + b, "-": lambda a, b: a - b,
          "*": lambda a, b: a * b, "/": lambda a, b: a / b,
          ">": lambda a, b: a > b}
KEYWORD = {"max:": max, "raisedTo:": pow,
           "between:and:": lambda x, lo, hi: lo <= x <= hi}


def evaluate(src):
    toks = re.findall(r"\d+|[a-zA-Z]+:|[a-zA-Z]+|[-+*/>()]", src)
    pos = 0

    def peek():
        return toks[pos] if pos < len(toks) else None

    def take():
        nonlocal pos
        pos += 1
        return toks[pos - 1]

    def primary():
        if peek() == "(":
            take(); v = keyword_expr(); take()      # ')'
            return v
        return int(take())

    def unary_expr():                   # 3 factorial squared
        v = primary()
        while peek() in UNARY:
            v = UNARY[take()](v)
        return v

    def binary_expr():                  # все бинарные равны, слева направо
        v = unary_expr()
        while peek() in BINARY:
            op = take()
            v = BINARY[op](v, unary_expr())
        return v

    def keyword_expr():                 # части селектора собираются в одно имя
        v = binary_expr()
        sel, args = "", []
        while peek() and peek().endswith(":"):
            sel += take()
            args.append(binary_expr())
        return KEYWORD[sel](v, *args) if sel else v

    return keyword_expr()


for e in ["3 + 4 * 2", "3 + (4 * 2)", "3 + 4 factorial", "2 raisedTo: 1 + 2",
          "3 max: 2 * 5 - 1", "5 between: 1 and: 2 * 3"]:
    print(f"{e:26} => {evaluate(e)}")

print(f"{'Python: 3 + 4 * 2':26} => {3 + 4 * 2}")
