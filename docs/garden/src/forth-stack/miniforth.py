#!/usr/bin/env python3
r"""miniforth: учебное подмножество Forth для статьи «Forth: стек вместо синтаксиса».

Это не gforth и не полная реализация Forth-2012. Поддерживаются: целые числа,
+ - * / < = 0= 1-, . .S CR, DUP DROP SWAP OVER ROT, : ; RECURSE,
IF ELSE THEN, IMMEDIATE POSTPONE [ ] LITERAL, комментарии ( ... ) и \ .
Нет DO/LOOP, CREATE/DOES>, VARIABLE, строк и памяти.
Запуск: python3 miniforth.py файл.fs
"""
import sys


class ForthError(Exception):
    pass


class Word:
    def __init__(self, name, action=None, code=None, immediate=False):
        self.name = name
        self.action = action        # встроенное слово: функция Python
        self.code = code            # слово-определение: список команд
        self.immediate = immediate  # выполнять даже в режиме компиляции


class Forth:
    def __init__(self, out=sys.stdout):
        self.stack = []             # стек данных
        self.dictionary = {}        # словарь: имя -> Word
        self.compiling = False      # STATE: интерпретация или компиляция
        self.current = None         # определение, которое сейчас компилируется
        self.control = []           # стек управления для IF/ELSE/THEN
        self.out = out
        self.define_primitives()

    # --- стек -------------------------------------------------------------
    def pop(self):
        if not self.stack:
            raise ForthError("stack underflow")
        return self.stack.pop()

    def push(self, x):
        self.stack.append(x)

    # --8<-- [start:primitives]
    def define_primitives(self):
        p, d = self.pop, self.push
        def binary(f):
            return lambda: (lambda b, a: d(f(a, b)))(p(), p())
        prims = {
            "+": binary(lambda a, b: a + b),
            "-": binary(lambda a, b: a - b),
            "*": binary(lambda a, b: a * b),
            "/": binary(lambda a, b: int(a / b)),     # деление с усечением
            "<": binary(lambda a, b: -1 if a < b else 0),  # истина = все биты 1
            "=": binary(lambda a, b: -1 if a == b else 0),
            "0=": lambda: d(-1 if p() == 0 else 0),
            "1-": lambda: d(p() - 1),
            "DUP": lambda: (lambda a: (d(a), d(a)))(p()),
            "DROP": lambda: p(),
            "SWAP": lambda: (lambda b, a: (d(b), d(a)))(p(), p()),
            "OVER": lambda: (lambda b, a: (d(a), d(b), d(a)))(p(), p()),
            "ROT": lambda: (lambda c, b, a: (d(b), d(c), d(a)))(p(), p(), p()),
            ".": lambda: self.out.write(f"{p()} "),
            ".S": lambda: self.out.write(
                f"<{len(self.stack)}> " + "".join(f"{x} " for x in self.stack)),
            "CR": lambda: self.out.write("\n"),
        }
        for name, fn in prims.items():
            self.dictionary[name] = Word(name, action=fn)
        # --8<-- [end:primitives]

        # --8<-- [start:immediate]
        # Немедленные слова: работают во время компиляции и дописывают
        # код текущего определения. IF/ELSE/THEN — такие же слова словаря.
        def colon():
            self.current = Word(self.next_token().upper(), code=[])
            self.compiling = True       # имя ещё не видно в словаре
        def semicolon():
            if self.control:
                raise ForthError("unbalanced IF/THEN")
            self.dictionary[self.current.name] = self.current
            self.compiling = False
        def if_():
            self.control.append(len(self.current.code))
            self.current.code.append(["jz", None])      # адрес узнаем позже
        def else_():
            orig = self.control.pop()
            self.control.append(len(self.current.code))
            self.current.code.append(["jmp", None])
            self.current.code[orig][1] = len(self.current.code)
        def then():
            self.current.code[self.control.pop()][1] = len(self.current.code)
        def recurse():
            self.current.code.append(["call", self.current])
        def literal():
            self.current.code.append(["lit", self.pop()])
        def immediate():
            self.current.immediate = True   # последнее определение
        def postpone():
            word = self.dictionary[self.next_token().upper()]
            if word.immediate:          # выполнить его позже, при компиляции
                self.current.code.append(["call", word])
            else:                       # позже скомпилировать вызов word
                self.current.code.append(["compile", word])
        imm = {":": colon, ";": semicolon, "IF": if_, "ELSE": else_,
               "THEN": then, "RECURSE": recurse, "LITERAL": literal,
               "IMMEDIATE": immediate, "POSTPONE": postpone,
               "[": lambda: setattr(self, "compiling", False),
               "]": lambda: setattr(self, "compiling", True),
               "(": lambda: self.skip_until(")"),
               "\\": lambda: self.skip_line()}
        for name, fn in imm.items():
            self.dictionary[name] = Word(name, action=fn, immediate=True)
        # --8<-- [end:immediate]

    # --- входной поток: слова, разделённые пробелами ----------------------
    def next_token(self):
        if not self.tokens:
            raise ForthError("unexpected end of line")
        return self.tokens.pop(0)

    def skip_until(self, end):
        while self.tokens and not self.next_token().endswith(end):
            pass

    def skip_line(self):
        self.tokens = []

    # --8<-- [start:inner]
    # Внутренний интерпретатор: исполняет скомпилированный список команд.
    def execute(self, word):
        if word.action:
            return word.action()
        code, pc = word.code, 0
        while pc < len(code):
            op, arg = code[pc]
            pc += 1
            if op == "lit":
                self.push(arg)
            elif op == "call":
                self.execute(arg)
            elif op == "jz":            # IF: переход, если на вершине 0
                if self.pop() == 0:
                    pc = arg
            elif op == "jmp":           # ELSE: безусловный переход
                pc = arg
            elif op == "compile":       # результат POSTPONE
                self.current.code.append(["call", arg])
    # --8<-- [end:inner]

    # --8<-- [start:outer]
    # Внешний (текстовый) интерпретатор: и интерпретатор, и компилятор.
    def interpret_line(self, line):
        self.tokens = line.split()      # весь «лексер» Forth
        while self.tokens:
            name = self.tokens.pop(0)
            word = self.dictionary.get(name.upper())
            if word is not None:
                if self.compiling and not word.immediate:
                    self.current.code.append(["call", word])  # компилировать
                else:
                    self.execute(word)                        # выполнить
                continue
            try:
                n = int(name)
            except ValueError:
                raise ForthError(f"undefined word: {name}")
            if self.compiling:
                self.current.code.append(["lit", n])
            else:
                self.push(n)
    # --8<-- [end:outer]

    def run(self, text):
        for lineno, line in enumerate(text.splitlines(), 1):
            try:
                self.interpret_line(line)
            except ForthError as e:
                self.out.write(f"error (line {lineno}): {e}\n")
                self.stack.clear()
                self.compiling, self.control = False, []


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as f:
        Forth().run(f.read())
