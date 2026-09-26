"""Фронтенд на Lark: fsm.lark → LALR(1)-парсер → Transformer → AST.

Lark — библиотека на чистом Python: грамматика читается при запуске,
отдельного шага генерации нет, Java не нужна. Поэтому этот фронтенд легче
(примерно 0,5 МБ против ~1 МБ у ANTLR runtime вместе со сгенерированным
парсером) и быстрее стартует в браузере.

Transformer — аналог Visitor из ANTLR, но обходит дерево снизу вверх:
метод правила получает уже преобразованных детей. Для генерации кода это
было бы неудобно (HOWTO, § 2.2), а для построения AST — в самый раз.
"""

from __future__ import annotations

from pathlib import Path

from lark import Lark, Token, Transformer, v_args
from lark.exceptions import UnexpectedCharacters, UnexpectedEOF, UnexpectedInput, UnexpectedToken

from .. import ast as A
from ..diagnostics import Diagnostics, SyntaxFailure

NAME = "lark"

_parser: Lark | None = None


def _get_parser() -> Lark:
    # Построение LALR-таблиц — самая дорогая часть; делаем один раз.
    global _parser
    if _parser is None:
        grammar = (Path(__file__).with_name("fsm.lark")).read_text(encoding="utf-8")
        _parser = Lark(grammar, parser="lalr", lexer="contextual",
                       propagate_positions=True, maybe_placeholders=True)
    return _parser


# Имена терминалов Lark → то, что увидит пользователь.
_TERMINALS = {
    "ID": "имя", "INT": "число", "STRING": "строка", "DASHES": "'--'", "ARROW": "'->'",
    "LBRACE": "'{'", "RBRACE": "'}'", "LPAR": "'('", "RPAR": "')'", "PARAMS_OPEN": "'('",
    "LSQB": "'['", "RSQB": "']'", "COMMA": "','", "COLON": "':'", "EQUAL": "'='",
    "SLASH": "'/'", "VBAR": "'|'", "$END": "конец файла",
}


def _expected(names) -> str:
    shown = sorted({_TERMINALS.get(n, n.lower().strip("_")) for n in names})
    return ", ".join(shown[:8]) + (", …" if len(shown) > 8 else "")


def parse(source: str, diags: Diagnostics) -> A.Program:
    try:
        tree = _get_parser().parse(source)
    except UnexpectedCharacters as e:
        diags.error("E001", f"недопустимый символ '{source[e.pos_in_stream]}'", e.line, e.column)
        raise SyntaxFailure() from None
    except UnexpectedEOF as e:
        diags.error("E002", f"неожиданный конец файла, ожидалось: {_expected(e.expected)}",
                    *_eof_pos(source))
        raise SyntaxFailure() from None
    except UnexpectedToken as e:
        if e.token.type == "$END":
            diags.error("E002", f"неожиданный конец файла, ожидалось: {_expected(e.expected)}",
                        *_eof_pos(source))
        else:
            diags.error("E002", f"неожиданное '{e.token}', ожидалось: {_expected(e.expected)}",
                        e.line, e.column)
        raise SyntaxFailure() from None
    except UnexpectedInput as e:  # pragma: no cover — прочие ошибки Lark
        diags.error("E002", str(e).splitlines()[0], getattr(e, "line", 0), getattr(e, "column", 0))
        raise SyntaxFailure() from None
    return AstBuilder().transform(tree)


def _eof_pos(source: str) -> tuple[int, int]:
    lines = source.split("\n")
    return len(lines), len(lines[-1]) + 1


def _name(tok: Token) -> A.Name:
    return A.Name(str(tok), tok.line, tok.column)


def _type(tok: Token | None) -> A.TypeRef | None:
    return A.TypeRef(str(tok), tok.line, tok.column) if tok is not None else None


def _unescape(raw: str) -> str:
    body = raw[1:-1]
    out, i = [], 0
    while i < len(body):
        if body[i] == "\\":
            out.append({"n": "\n"}.get(body[i + 1], body[i + 1]))
            i += 2
        else:
            out.append(body[i])
            i += 1
    return "".join(out)


def _params(items) -> list[A.Param]:
    """``[PARAMS_OPEN [params] ")"]`` → список параметров (скобки не важны)."""
    _, params = items
    return params or []


@v_args(inline=True)
class AstBuilder(Transformer):
    """Дерево Lark → AST. Каждый метод получает детей правила аргументами."""

    def start(self, name, *decls):
        prog = A.Program(name=_name(name))
        for kind, node in decls:
            if kind == "const":
                prog.consts.append(node)
            elif kind == "fields":
                prog.fields.extend(node)
            elif kind == "events":
                prog.events.extend(node)
            elif kind == "states":
                prog.states.extend(node)
            elif kind == "initial":
                prog.initial.extend(node)
            elif kind == "terminal":
                prog.terminal.extend(node)
            elif kind == "action":
                prog.actions.append(node)
            else:
                prog.transitions.append(node)
        return prog

    # ------------------------------------------------------------ объявления
    # Объявления возвращают пару (вид, узел): start раскладывает их по полям.

    def const_decl(self, name, ty, expr):
        return "const", A.Const(_name(name), _type(ty), expr)

    def context_decl(self, *fields):
        return "fields", [f for f in fields if f is not None]

    def field(self, name, ty, init):
        return A.Field(_name(name), _type(ty), init)

    def events_decl(self, *events):
        return "events", [e for e in events if e is not None]

    def event_sig(self, name, opened, params):
        return A.EventDecl(_name(name), params or [])

    def params(self, *items):
        return list(items)

    def param(self, name, ty):
        return A.Param(_name(name), _type(ty))

    def id_list(self, *names):
        return [_name(n) for n in names]

    def states_decl(self, names):
        return "states", names

    def initial_decl(self, names):
        return "initial", names

    def terminal_decl(self, names):
        return "terminal", names

    def action_decl(self, name, opened, params, body):
        return "action", A.Action(_name(name), params or [], body)

    # ------------------------------------------------------------ переходы

    @staticmethod
    def _transition(src, triggers, guard=None, target=None, calls=None, ignore=False):
        ordered, expr = guard if guard is not None else (False, None)
        return "transition", A.Transition(
            source=_name(src), triggers=triggers, guard=expr, ordered=ordered,
            target=_name(target) if target is not None else None,
            actions=calls or [], ignore=ignore, line=src.line, col=src.column)

    def move_transition(self, src, _dashes, triggers, guard, _arrow, target, calls):
        return self._transition(src, triggers, guard, target, calls)

    def self_transition(self, src, _dashes, triggers, guard, _arrow, calls):
        return self._transition(src, triggers, guard, None, calls)

    def ignore_transition(self, src, _dashes, triggers):
        return self._transition(src, triggers, ignore=True)

    def triggers(self, *items):
        return list(items)

    def trigger(self, event, opened, *patterns):
        if opened is None:
            return A.Trigger(_name(event), None)
        return A.Trigger(_name(event), [p for p in patterns if p is not None])

    def pattern(self, name, ty):
        return A.Pattern(_name(name), _type(ty))

    def guard(self, else_kw, expr=None):
        return else_kw is not None, expr

    def calls(self, *items):
        return list(items)

    def call(self, name, opened, *args):
        return A.Call(_name(name), [a for a in args if a is not None])

    # ------------------------------------------------------------ операторы

    def block(self, *stmts):
        return list(stmts)

    def assign(self, target, expr):
        return A.Assign(_name(target), expr, target.line, target.column)

    def say(self, kw, *exprs):
        return A.Say(list(exprs), kw.line, kw.column)

    def if_stmt(self, kw, cond, then, _else_kw, else_):
        if isinstance(else_, A.If):
            else_ = [else_]
        return A.If(cond, then, else_, kw.line, kw.column)

    # ------------------------------------------------------------ выражения

    def bin(self, left, op, right):
        return A.Binary(str(op), left, right, op.line, op.column)

    def unary(self, op, operand):
        return A.Unary(str(op), operand, op.line, op.column)

    def int_lit(self, tok):
        return A.IntLit(int(tok), tok.line, tok.column)

    def str_lit(self, tok):
        return A.StrLit(_unescape(str(tok)), tok.line, tok.column)

    def bool_lit(self, tok):
        return A.BoolLit(str(tok) == "true", tok.line, tok.column)

    def ref(self, tok):
        return A.Ref(str(tok), tok.line, tok.column)
