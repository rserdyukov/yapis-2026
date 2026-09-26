"""Абстрактное синтаксическое дерево языка FSM.

Оба фронтенда (ANTLR и Lark) строят именно эти узлы, поэтому всё, что идёт
после разбора, — семантика, генерация кода, диаграммы — от выбора парсера не
зависит. Тест test_frontends сравнивает деревья обоих фронтендов через ``==``.

Позиции (line, col) считаются с единицы. Поля, которые заполняет семантический
анализатор (``ty``, ``ref``), объявлены с ``compare=False``: аннотации не
должны влиять на сравнение деревьев.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional, Union


@dataclass
class Name:
    text: str
    line: int
    col: int


@dataclass
class TypeRef:
    name: str
    line: int
    col: int


# ---------------------------------------------------------------- выражения


@dataclass
class IntLit:
    value: int
    line: int
    col: int
    ty: Optional[str] = field(default=None, compare=False)


@dataclass
class StrLit:
    value: str
    line: int
    col: int
    ty: Optional[str] = field(default=None, compare=False)


@dataclass
class BoolLit:
    value: bool
    line: int
    col: int
    ty: Optional[str] = field(default=None, compare=False)


@dataclass
class Ref:
    """Имя в выражении: поле контекста, константа, параметр действия или
    имя, связанное образцом события. Что именно — решает семантика и
    записывает в ``ref`` = (вид, данные)."""

    name: str
    line: int
    col: int
    ty: Optional[str] = field(default=None, compare=False)
    ref: Optional[tuple] = field(default=None, compare=False)


@dataclass
class Unary:
    op: str  # "-" | "not"
    operand: "Expr"
    line: int
    col: int
    ty: Optional[str] = field(default=None, compare=False)


@dataclass
class Binary:
    op: str  # + - * / % == != < <= > >= and or
    left: "Expr"
    right: "Expr"
    line: int
    col: int
    ty: Optional[str] = field(default=None, compare=False)


Expr = Union[IntLit, StrLit, BoolLit, Ref, Unary, Binary]


# ---------------------------------------------------------------- операторы


@dataclass
class Assign:
    target: Name
    value: Expr
    line: int
    col: int


@dataclass
class Say:
    items: list[Expr]
    line: int
    col: int


@dataclass
class If:
    cond: Expr
    then: list["Stmt"]
    else_: Optional[list["Stmt"]]
    line: int
    col: int


Stmt = Union[Assign, Say, If]


# ---------------------------------------------------------------- объявления


@dataclass
class Const:
    name: Name
    type: TypeRef
    value: Expr


@dataclass
class Field:
    name: Name
    type: TypeRef
    init: Optional[Expr]


@dataclass
class Param:
    name: Name
    type: TypeRef


@dataclass
class EventDecl:
    name: Name
    params: list[Param]


@dataclass
class Action:
    name: Name
    params: list[Param]
    body: list[Stmt]


@dataclass
class Pattern:
    """Образец параметра события: ``c``, ``_`` или ``s: money``."""

    name: Name
    type: Optional[TypeRef]


@dataclass
class Trigger:
    """``pin(c)``. ``patterns is None`` — событие записано без скобок."""

    event: Name
    patterns: Optional[list[Pattern]]


@dataclass
class Call:
    name: Name
    args: list[Expr]


@dataclass
class Transition:
    source: Name
    triggers: list[Trigger]
    guard: Optional[Expr]
    ordered: bool  # записан ли ``else``: явный порядок проверки guard'ов
    target: Optional[Name]  # None — переход в себя
    actions: list[Call]
    ignore: bool
    line: int
    col: int


@dataclass
class Program:
    name: Name
    consts: list[Const] = field(default_factory=list)
    fields: list[Field] = field(default_factory=list)
    events: list[EventDecl] = field(default_factory=list)
    states: list[Name] = field(default_factory=list)
    initial: list[Name] = field(default_factory=list)
    terminal: list[Name] = field(default_factory=list)
    actions: list[Action] = field(default_factory=list)
    transitions: list[Transition] = field(default_factory=list)


# ---------------------------------------------------------------- печать


_PREC = {"or": 1, "and": 2, "==": 4, "!=": 4, "<": 4, "<=": 4, ">": 4, ">=": 4,
         "+": 5, "-": 5, "*": 6, "/": 6, "%": 6}


def show_expr(e: Expr, parent: int = 0) -> str:
    """Выражение обратно в текст — для диаграмм и сообщений об ошибках."""
    if isinstance(e, IntLit):
        return str(e.value)
    if isinstance(e, StrLit):
        return '"' + e.value.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(e, BoolLit):
        return "true" if e.value else "false"
    if isinstance(e, Ref):
        return e.name
    if isinstance(e, Unary):
        prec = 3 if e.op == "not" else 7
        inner = show_expr(e.operand, prec)
        text = f"not {inner}" if e.op == "not" else f"-{inner}"
        return f"({text})" if parent > prec else text
    prec = _PREC[e.op]
    text = f"{show_expr(e.left, prec)} {e.op} {show_expr(e.right, prec + 1)}"
    return f"({text})" if prec < parent else text
