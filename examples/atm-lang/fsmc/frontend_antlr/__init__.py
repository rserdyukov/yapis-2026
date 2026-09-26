"""Фронтенд на ANTLR 4: grammar/Fsm.g4 → сгенерированный парсер → Visitor → AST.

Здесь та же схема, что в лабораторных 2–3: грамматика в .g4, парсер
сгенерирован заранее, свой ErrorListener собирает ошибки, Visitor строит AST.
"""

from __future__ import annotations

from antlr4 import CommonTokenStream, InputStream
from antlr4.error.ErrorListener import ErrorListener

from .. import ast as A
from ..diagnostics import Diagnostics, SyntaxFailure
from .generated.FsmLexer import FsmLexer
from .generated.FsmParser import FsmParser
from .generated.FsmVisitor import FsmVisitor

NAME = "antlr"


class _Collect(ErrorListener):
    """Складывает ошибки в общую диагностику вместо печати в stderr."""

    def __init__(self, diags: Diagnostics, code: str):
        self.diags = diags
        self.code = code

    def syntaxError(self, recognizer, offending, line, column, msg, e):
        self.diags.error(self.code, _russify(msg), line, column + 1)


def _russify(msg: str) -> str:
    # Сообщения ANTLR на английском; переводим самые частые шаблоны.
    for en, ru in (("token recognition error at:", "недопустимый символ"),
                   ("mismatched input", "неожиданное"),
                   ("extraneous input", "лишнее"),
                   ("missing", "пропущено"),
                   ("no viable alternative at input", "не удалось разобрать"),
                   ("expecting", "ожидалось"),
                   ("<EOF>", "конец файла")):
        msg = msg.replace(en, ru)
    return msg


def parse(source: str, diags: Diagnostics) -> A.Program:
    lexer = FsmLexer(InputStream(source))
    lexer.removeErrorListeners()
    lexer.addErrorListener(_Collect(diags, "E001"))
    parser = FsmParser(CommonTokenStream(lexer))
    parser.removeErrorListeners()
    parser.addErrorListener(_Collect(diags, "E002"))
    tree = parser.program()
    if diags.has_errors:
        raise SyntaxFailure()
    return AstBuilder().visit(tree)


def _pos(tok) -> tuple[int, int]:
    return tok.line, tok.column + 1


def _name(tok) -> A.Name:
    return A.Name(tok.text, *_pos(tok))


def _type(tok) -> A.TypeRef:
    return A.TypeRef(tok.text, *_pos(tok))


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


class AstBuilder(FsmVisitor):
    """Дерево разбора ANTLR → AST. Порядок обхода задаём сами (Visitor)."""

    def visitProgram(self, ctx: FsmParser.ProgramContext) -> A.Program:
        prog = A.Program(name=_name(ctx.name))
        for d in ctx.decl():
            node = self.visit(d.getChild(0))
            kind = d.getChild(0)
            if isinstance(kind, FsmParser.ConstDeclContext):
                prog.consts.append(node)
            elif isinstance(kind, FsmParser.ContextDeclContext):
                prog.fields.extend(node)
            elif isinstance(kind, FsmParser.EventsDeclContext):
                prog.events.extend(node)
            elif isinstance(kind, FsmParser.StatesDeclContext):
                prog.states.extend(node)
            elif isinstance(kind, FsmParser.InitialDeclContext):
                prog.initial.extend(node)
            elif isinstance(kind, FsmParser.TerminalDeclContext):
                prog.terminal.extend(node)
            elif isinstance(kind, FsmParser.ActionDeclContext):
                prog.actions.append(node)
            else:
                prog.transitions.append(node)
        return prog

    # ------------------------------------------------------------ объявления

    def visitConstDecl(self, ctx):
        return A.Const(_name(ctx.name), _type(ctx.ty), self.visit(ctx.expr()))

    def visitContextDecl(self, ctx):
        return [self.visit(f) for f in ctx.field()]

    def visitField(self, ctx):
        init = self.visit(ctx.expr()) if ctx.expr() else None
        return A.Field(_name(ctx.name), _type(ctx.ty), init)

    def visitEventsDecl(self, ctx):
        return [self.visit(e) for e in ctx.eventSig()]

    def visitEventSig(self, ctx):
        return A.EventDecl(_name(ctx.name), self._params(ctx.params()))

    def _params(self, ctx) -> list[A.Param]:
        if ctx is None:
            return []
        return [A.Param(_name(p.name), _type(p.ty)) for p in ctx.param()]

    def visitStatesDecl(self, ctx):
        return self.visit(ctx.idList())

    visitInitialDecl = visitStatesDecl
    visitTerminalDecl = visitStatesDecl

    def visitIdList(self, ctx):
        return [_name(t.symbol) for t in ctx.ID()]

    def visitActionDecl(self, ctx):
        return A.Action(_name(ctx.name), self._params(ctx.params()), self.visit(ctx.block()))

    # ------------------------------------------------------------ переходы

    def _transition(self, ctx, *, triggers, target=None, calls=None, ignore=False):
        guard, ordered = None, False
        g = getattr(ctx, "guard", lambda: None)()
        if g is not None:
            ordered = g.getChild(0).getText() == "else"
            guard = self.visit(g.expr()) if g.expr() else None
        return A.Transition(
            source=_name(ctx.source), triggers=triggers, guard=guard, ordered=ordered,
            target=_name(target) if target is not None else None,
            actions=self.visit(calls) if calls is not None else [],
            ignore=ignore, line=ctx.source.line, col=ctx.source.column + 1)

    def visitMoveTransition(self, ctx):
        return self._transition(ctx, triggers=self.visit(ctx.triggers()),
                                target=ctx.target, calls=ctx.calls())

    def visitSelfTransition(self, ctx):
        return self._transition(ctx, triggers=self.visit(ctx.triggers()), calls=ctx.calls())

    def visitIgnoreTransition(self, ctx):
        return self._transition(ctx, triggers=self.visit(ctx.triggers()), ignore=True)

    def visitTriggers(self, ctx):
        return [self.visit(t) for t in ctx.trigger()]

    def visitTrigger(self, ctx):
        patterns = None
        if ctx.getChildCount() > 1:  # есть скобки, пусть даже пустые
            patterns = [A.Pattern(_name(p.name), _type(p.ty) if p.ty else None)
                        for p in ctx.pattern()]
        return A.Trigger(_name(ctx.event), patterns)

    def visitCalls(self, ctx):
        return [A.Call(_name(c.name), [self.visit(e) for e in c.expr()]) for c in ctx.call()]

    # ------------------------------------------------------------ операторы

    def visitBlock(self, ctx):
        return [self.visit(s) for s in ctx.stmt()]

    def visitStmt(self, ctx):
        return self.visit(ctx.getChild(0))

    def visitAssignStmt(self, ctx):
        return A.Assign(_name(ctx.target), self.visit(ctx.expr()), *_pos(ctx.start))

    def visitSayStmt(self, ctx):
        return A.Say([self.visit(e) for e in ctx.expr()], *_pos(ctx.start))

    def visitIfStmt(self, ctx):
        blocks = ctx.block()
        else_ = None
        if len(blocks) == 2:
            else_ = self.visit(blocks[1])
        elif ctx.ifStmt() is not None:
            else_ = [self.visit(ctx.ifStmt())]
        return A.If(self.visit(ctx.expr()), self.visit(blocks[0]), else_, *_pos(ctx.start))

    # ------------------------------------------------------------ выражения

    def visitParenExpr(self, ctx):
        return self.visit(ctx.expr())

    def visitNegExpr(self, ctx):
        return A.Unary("-", self.visit(ctx.expr()), *_pos(ctx.op))

    def visitNotExpr(self, ctx):
        return A.Unary("not", self.visit(ctx.expr()), *_pos(ctx.op))

    def visitBinExpr(self, ctx):
        left, right = ctx.expr()
        return A.Binary(ctx.op.text, self.visit(left), self.visit(right), *_pos(ctx.op))

    def visitIntExpr(self, ctx):
        return A.IntLit(int(ctx.getText()), *_pos(ctx.start))

    def visitStrExpr(self, ctx):
        return A.StrLit(_unescape(ctx.getText()), *_pos(ctx.start))

    def visitBoolExpr(self, ctx):
        return A.BoolLit(ctx.value.text == "true", *_pos(ctx.start))

    def visitRefExpr(self, ctx):
        return A.Ref(ctx.getText(), *_pos(ctx.start))
