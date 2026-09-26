"""Семантический анализ программы на FSM.

Два прохода:

1. **Таблицы символов и типы.** Состояния, события, действия, константы и
   поля контекста собираются в словари; каждое выражение получает тип
   (``expr.ty``), каждое имя — ссылку на символ (``Ref.ref``). Генератор кода
   читает только эти аннотации и ничего не выводит заново (HOWTO, § 2.1).
2. **Свойства автомата.** Проверки, ради которых язык существует: они
   доказывают свойства графа переходов, а не типы. Реализованы обходом
   графа в ширину.

Коды проверок E1NN совпадают с номерами строк таблицы из карточки задачи
(раздел 5), дополнительные проверки нумеруются с 113. Список — в README.md.
"""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field

from . import ast as A
from .diagnostics import Diagnostics

INT, MONEY, STRING, BOOL = "int", "money", "string", "bool"
TYPES = {INT, MONEY, STRING, BOOL}
NUMERIC = {INT, MONEY}


@dataclass
class EventInfo:
    index: int
    decl: A.EventDecl

    @property
    def param_types(self) -> list[str]:
        return [p.type.name for p in self.decl.params]


@dataclass
class Model:
    """Аннотированная программа: вход генератора кода и построителя диаграмм."""

    program: A.Program
    states: list[str] = field(default_factory=list)
    events: dict[str, EventInfo] = field(default_factory=dict)
    actions: dict[str, A.Action] = field(default_factory=dict)
    consts: dict[str, A.Const] = field(default_factory=dict)
    fields: dict[str, A.Field] = field(default_factory=dict)
    initial: str = ""
    terminal: list[str] = field(default_factory=list)
    # (состояние, событие) -> переходы в порядке записи; «*» уже раскрыта
    table: dict[tuple[str, str], list[A.Transition]] = field(default_factory=dict)
    # Итоги анализа графа: недостижимые (E102) и ловушки (E103)
    unreachable: set[str] = field(default_factory=set)
    trapped: set[str] = field(default_factory=set)

    def state_index(self, name: str) -> int:
        return self.states.index(name)


def assignable(target: str, source: str) -> bool:
    """int неявно расширяется до money; обратно — нельзя."""
    return target == source or (target == MONEY and source == INT)


class Analyzer:
    def __init__(self, program: A.Program, diags: Diagnostics):
        self.p = program
        self.d = diags
        self.m = Model(program)

    # ================================================================ вход

    def run(self) -> Model:
        self._declarations()
        self._actions()
        self._transitions()
        self._graph()
        return self.m

    # ================================================================ объявления

    def _unique(self, names: list[A.Name], what: str) -> dict[str, A.Name]:
        seen: dict[str, A.Name] = {}
        for n in names:
            if n.text in seen:
                self.d.error("E113", f"{what} '{n.text}' объявлено повторно "
                             f"(первое объявление в строке {seen[n.text].line})", n.line, n.col)
            else:
                seen[n.text] = n
        return seen

    def _check_type(self, t: A.TypeRef) -> str | None:
        if t.name not in TYPES:
            self.d.error("E115", f"неизвестный тип '{t.name}', допустимы: "
                         + ", ".join(sorted(TYPES)), t.line, t.col)
            return None
        return t.name

    def _declarations(self) -> None:
        p, m = self.p, self.m
        m.states = list(self._unique(p.states, "состояние"))
        if not p.states:
            self.d.error("E112", "не объявлено ни одного состояния (states ...)",
                         p.name.line, p.name.col)

        # E112: ровно одно начальное, минимум одно терминальное.
        if not p.initial:
            self.d.error("E112", "начальное состояние не объявлено", p.name.line, p.name.col)
        elif len(p.initial) > 1:
            extra = p.initial[1]
            self.d.error("E112", "начальное состояние должно быть ровно одно, объявлено "
                         + str(len(p.initial)), extra.line, extra.col)
        if not p.terminal:
            self.d.error("E112", "терминальное состояние не объявлено", p.name.line, p.name.col)
        for n in p.initial + p.terminal:
            self._state_ref(n, "объявлено необъявленное состояние")
        if p.initial and p.initial[0].text in m.states:
            m.initial = p.initial[0].text
        m.terminal = [n.text for n in p.terminal if n.text in m.states]

        # События
        names = self._unique([e.name for e in p.events], "событие")
        for i, e in enumerate(ev for ev in p.events if names.get(ev.name.text) is ev.name):
            m.events[e.name.text] = EventInfo(i, e)
            self._unique([pr.name for pr in e.params], f"параметр события {e.name.text}")
            for pr in e.params:
                self._check_type(pr.type)

        # Константы: тип значения должен совпадать с объявленным,
        # значение — константное выражение (только литералы и другие константы).
        # Пространство имён общее: константа и поле контекста не могут совпадать.
        self._unique([c.name for c in p.consts] + [f.name for f in p.fields],
                     "имя константы или поля")
        for c in p.consts:
            ty = self._check_type(c.type)
            # Константа видит только константы, объявленные ВЫШЕ неё:
            # так циклы вида `const A: int = A` невозможны по построению.
            vt = self._expr(c.value, self._const_scope(), what="значение константы")
            if ty and vt and not assignable(ty, vt):
                self.d.error("E115", f"константа {c.name.text}: ожидается {ty}, получено {vt}",
                             c.name.line, c.name.col)
            if ty:  # ошибка в значении уже выдана; имя всё равно известно
                m.consts.setdefault(c.name.text, c)
        for f in p.fields:
            ty = self._check_type(f.type)
            if f.init is not None:
                vt = self._expr(f.init, self._const_scope(), what="начальное значение поля")
                if ty and vt and not assignable(ty, vt):
                    self.d.error("E115", f"поле {f.name.text}: ожидается {ty}, получено {vt}",
                                 f.name.line, f.name.col)
            m.fields.setdefault(f.name.text, f)

        names = self._unique([a.name for a in p.actions], "действие")
        for a in p.actions:
            if names.get(a.name.text) is a.name:
                m.actions[a.name.text] = a

    def _state_ref(self, n: A.Name, what: str) -> bool:
        if n.text in self.m.states:
            return True
        self.d.error("E101", f"{what} '{n.text}'" + _hint(n.text, self.m.states),
                     n.line, n.col)
        return False

    # ================================================================ области видимости
    # Область видимости — словарь имя -> (вид, тип, данные). Вид определяет,
    # как генератор загрузит значение: константа, поле (global), параметр (local).

    def _const_scope(self) -> dict:
        return {name: ("const", c.type.name, c) for name, c in self.m.consts.items()}

    def _base_scope(self) -> dict:
        scope = self._const_scope()
        for name, f in self.m.fields.items():
            scope[name] = ("field", f.type.name, name)
        return scope

    # ================================================================ действия

    def _actions(self) -> None:
        for a in self.m.actions.values():
            self._unique([pr.name for pr in a.params], f"параметр действия {a.name.text}")
            scope = self._base_scope()
            for i, pr in enumerate(a.params):
                ty = self._check_type(pr.type)
                scope[pr.name.text] = ("param", ty, i)
            self._block(a.body, scope)

    def _block(self, body: list[A.Stmt], scope: dict) -> None:
        for s in body:
            if isinstance(s, A.Assign):
                self._assign(s, scope)
            elif isinstance(s, A.Say):
                for e in s.items:
                    self._expr(e, scope)
            elif isinstance(s, A.If):
                self._condition(s.cond, scope, "условие if")
                self._block(s.then, scope)
                if s.else_ is not None:
                    self._block(s.else_, scope)

    def _assign(self, s: A.Assign, scope: dict) -> None:
        vt = self._expr(s.value, scope)
        sym = scope.get(s.target.text)
        if sym is None:
            self.d.error("E110", f"присваивание несуществующему полю '{s.target.text}'"
                         + _hint(s.target.text, self.m.fields), s.target.line, s.target.col)
            return
        kind, ty, _ = sym
        if kind != "field":
            what = {"const": "константе", "param": "параметру"}[kind]
            self.d.error("E115", f"нельзя присвоить значение {what} '{s.target.text}': "
                         "изменять можно только поля контекста", s.target.line, s.target.col)
            return
        if ty and vt and not assignable(ty, vt):
            self.d.error("E115", f"полю {s.target.text} типа {ty} присваивается {vt}",
                         s.line, s.col)

    def _condition(self, e: A.Expr, scope: dict, what: str, code: str = "E115") -> None:
        ty = self._expr(e, scope, what=what)
        if ty is not None and ty != BOOL:
            self.d.error(code, f"{what} должно иметь тип bool, получено {ty}", e.line, e.col)

    # ================================================================ выражения

    def _expr(self, e: A.Expr, scope: dict, what: str = "выражение") -> str | None:
        """Вывести тип, записать его в ``e.ty``. None — ошибка уже выдана."""
        ty = self._infer(e, scope, what)
        e.ty = ty
        return ty

    def _infer(self, e: A.Expr, scope: dict, what: str) -> str | None:
        if isinstance(e, A.IntLit):
            return INT
        if isinstance(e, A.StrLit):
            return STRING
        if isinstance(e, A.BoolLit):
            return BOOL
        if isinstance(e, A.Ref):
            sym = scope.get(e.name)
            if sym is None:
                pool = [n for n in scope]
                self.d.error("E110", f"{what} ссылается на несуществующее имя '{e.name}'"
                             + _hint(e.name, pool), e.line, e.col)
                return None
            kind, ty, data = sym
            e.ref = (kind, data)
            return ty
        if isinstance(e, A.Unary):
            t = self._expr(e.operand, scope, what)
            if t is None:
                return None
            if e.op == "not":
                if t != BOOL:
                    return self._bad(e, f"операция not требует bool, получено {t}")
                return BOOL
            if t not in NUMERIC:
                return self._bad(e, f"унарный минус требует число, получено {t}")
            return t
        lt = self._expr(e.left, scope, what)
        rt = self._expr(e.right, scope, what)
        if lt is None or rt is None:
            return None
        return self._binary(e, lt, rt)

    def _binary(self, e: A.Binary, lt: str, rt: str) -> str | None:
        op = e.op
        if op in ("and", "or"):
            if lt == BOOL and rt == BOOL:
                return BOOL
            return self._bad(e, f"операция {op} требует bool, получено {lt} и {rt}")
        if op in ("==", "!="):
            if lt == rt or {lt, rt} == NUMERIC:
                return BOOL
            return self._bad(e, f"нельзя сравнивать {lt} и {rt}")
        if op in ("<", "<=", ">", ">="):
            if lt in NUMERIC and rt in NUMERIC:
                return BOOL
            return self._bad(e, f"операция {op} определена для чисел, получено {lt} и {rt}")
        # Арифметика. money — деньги: их можно складывать между собой и
        # умножать на int, но не умножать деньги на деньги.
        if lt not in NUMERIC or rt not in NUMERIC:
            return self._bad(e, f"операция {op} определена для чисел, получено {lt} и {rt}")
        if op in ("+", "-"):
            return MONEY if MONEY in (lt, rt) else INT
        if op == "*":
            if lt == MONEY and rt == MONEY:
                return self._bad(e, "нельзя умножать money на money")
            return MONEY if MONEY in (lt, rt) else INT
        # / и %
        if lt == INT and rt == MONEY:
            return self._bad(e, "нельзя делить int на money")
        if lt == MONEY and rt == MONEY:
            return INT if op == "/" else MONEY
        return lt

    def _bad(self, e, message: str) -> None:
        self.d.error("E115", message, e.line, e.col)
        return None

    # ================================================================ переходы

    def _transitions(self) -> None:
        m = self.m
        for t in self.p.transitions:
            src_ok = self._state_ref(t.source, "переход из необъявленного состояния")
            if t.target is not None:
                self._state_ref(t.target, "переход ведёт в необъявленное состояние")
            # Guard и действия проверяются один раз на переход, даже если
            # событий несколько (`cancel | timeout`). Поэтому образцы всех
            # событий обязаны связывать одни и те же имена с одними и теми же
            # позициями и типами — иначе у guard'а был бы разный смысл.
            scopes = []
            for trig in t.triggers:
                scope = self._trigger(t, trig)
                if scope is None:
                    continue
                scopes.append((trig, scope))
                if src_ok:
                    m.table.setdefault((t.source.text, trig.event.text), []).append(t)
            if not scopes:
                continue
            bound = [{k: v for k, v in s.items() if v[0] == "param"} for _, s in scopes]
            for (trig, _), b in zip(scopes[1:], bound[1:]):
                if b != bound[0]:
                    self.d.error("E116", f"образцы событий {scopes[0][0].event.text} и "
                                 f"{trig.event.text} связывают разные имена: у перехода "
                                 "с несколькими событиями они должны совпадать",
                                 trig.event.line, trig.event.col)
            scope = scopes[0][1]
            if t.guard is not None:
                self._condition(t.guard, scope, "guard", code="E111")
            self._calls(t, scope)
        self._determinism()

    def _trigger(self, t: A.Transition, trig: A.Trigger) -> dict | None:
        """Проверить образец события и вернуть область видимости перехода."""
        info = self.m.events.get(trig.event.text)
        if info is None:
            self.d.error("E104", f"неизвестное событие '{trig.event.text}'"
                         + _hint(trig.event.text, self.m.events),
                         trig.event.line, trig.event.col)
            return None
        params = info.decl.params
        scope = self._base_scope()
        # Событие с параметрами записывается только с образцом: `withdraw(_)`,
        # а не `withdraw`. Так пропущенный аргумент не проходит молча.
        patterns = trig.patterns if trig.patterns is not None else []
        if len(patterns) != len(params):
            sig = ", ".join(p.type.name for p in params) or "без параметров"
            self.d.error("E105", f"{trig.event.text} ожидает {len(params)} "
                         f"параметр(а) ({sig}), в образце {len(patterns)}",
                         trig.event.line, trig.event.col)
            return scope
        for i, (pat, decl) in enumerate(zip(patterns, params)):
            if pat.type is not None and pat.type.name != decl.type.name:
                self.d.error("E105", f"{trig.event.text} ожидает {decl.type.name}, "
                             f"получено {pat.type.name}", pat.type.line, pat.type.col)
            if pat.name.text == "_":
                continue
            if pat.name.text in self.m.fields or pat.name.text in self.m.consts:
                self.d.error("E113", f"имя образца '{pat.name.text}' совпадает с полем или "
                             "константой", pat.name.line, pat.name.col)
                continue
            scope[pat.name.text] = ("param", decl.type.name, i)
        return scope

    def _calls(self, t: A.Transition, scope: dict) -> None:
        for call in t.actions:
            action = self.m.actions.get(call.name.text)
            if action is None:
                self.d.error("E109", f"неизвестное действие '{call.name.text}'"
                             + _hint(call.name.text, self.m.actions),
                             call.name.line, call.name.col)
                for a in call.args:
                    self._expr(a, scope, what="аргумент действия")
                continue
            types = [self._expr(a, scope, what="аргумент действия") for a in call.args]
            if len(types) != len(action.params):
                self.d.error("E114", f"действие {call.name.text} ожидает "
                             f"{len(action.params)} аргумент(а), передано {len(types)}",
                             call.name.line, call.name.col)
                continue
            for arg, ty, pr in zip(call.args, types, action.params):
                if ty and not assignable(pr.type.name, ty):
                    self.d.error("E114", f"действие {call.name.text}: параметр "
                                 f"{pr.name.text} ожидает {pr.type.name}, получено {ty}",
                                 arg.line, arg.col)

    def _determinism(self) -> None:
        for (state, event), ts in self.m.table.items():
            unguarded = [t for t in ts if t.guard is None]
            # E106: два перехода без guard'а — какой сработает, неизвестно.
            for t in unguarded[1:]:
                self.d.error("E106", f"недетерминизм: '{state}' -- {event} без guard'а "
                             f"определён повторно (первый — строка {unguarded[0].line})",
                             t.line, t.col)
            if unguarded:
                first = ts.index(unguarded[0])
                for t in ts[first + 1:]:
                    if t.guard is not None:
                        self.d.warning("W117", f"переход '{state}' -- {event} никогда не "
                                       "сработает: выше стоит переход без guard'а", t.line, t.col)
            guarded = [t for t in ts if t.guard is not None]
            # W107: несколько guard'ов без явного порядка.
            for t in guarded[1:]:
                if not t.ordered:
                    self.d.warning("W107", f"guard'ы '{state}' -- {event} могут перекрываться, "
                                   "применяется первый подходящий; напишите else [...], "
                                   "чтобы задать порядок явно", t.line, t.col)
            if ts and not unguarded:
                t = ts[-1]
                self.d.warning("W118", f"в '{state}' событие {event} может остаться "
                               "необработанным: у всех переходов есть guard, "
                               "добавьте переход с else", t.line, t.col)

    # ================================================================ граф

    def edges(self) -> dict[str, list[tuple[str, str]]]:
        """Граф переходов: состояние -> [(событие, цель)]. Guard'ы не
        учитываются: считаем, что каждый может выполниться (консервативно)."""
        g: dict[str, list[tuple[str, str]]] = {s: [] for s in self.m.states}
        for (state, event), ts in self.m.table.items():
            for t in ts:
                if t.ignore:
                    continue
                target = t.target.text if t.target else state
                if target in self.m.states:
                    g[state].append((event, target))
        return g

    def _graph(self) -> None:
        m = self.m
        g = self.edges()
        where = {n.text: n for n in self.p.states}

        # W108: каждое событие обработано в каждом состоянии или явно
        # проигнорировано. Сообщение группирует события одного состояния.
        for s in m.states:
            missing = [e for e in m.events if (s, e) not in m.table]
            if missing:
                n = where[s]
                self.d.warning("W108", f"в '{s}' не обработаны события: {', '.join(missing)} "
                               f"(добавьте переход или `{s} -- ... ignore`)", n.line, n.col)

        # E102: достижимость из начального — обход в ширину.
        if m.initial:
            seen = _bfs(m.initial, g)
            for s in m.states:
                if s not in seen:
                    m.unreachable.add(s)
                    n = where[s]
                    self.d.error("E102", f"состояние '{s}' недостижимо из начального "
                                 f"'{m.initial}'", n.line, n.col)

        # E103: из каждого состояния достижимо терминальное — обход в ширину
        # по обращённому графу от всех терминальных сразу.
        if m.terminal:
            reverse: dict[str, list[tuple[str, str]]] = {s: [] for s in m.states}
            for s, out in g.items():
                for ev, t in out:
                    reverse[t].append((ev, s))
            back = set()
            for term in m.terminal:
                back |= set(_bfs(term, reverse))
            for s in m.states:
                if s not in back:
                    m.trapped.add(s)
                    n = where[s]
                    self.d.error("E103", f"из '{s}' нет пути в терминальное состояние "
                                 f"({', '.join(m.terminal)})", n.line, n.col)

        used = {c.name.text for t in self.p.transitions for c in t.actions}
        for name, a in m.actions.items():
            if name not in used:
                self.d.warning("W120", f"действие '{name}' нигде не вызывается",
                               a.name.line, a.name.col)


def _bfs(start: str, g: dict[str, list[tuple[str, str]]]) -> dict[str, list[str]]:
    """Достижимые вершины и для каждой — кратчайший путь событий до неё."""
    paths = {start: []}
    queue = deque([start])
    while queue:
        s = queue.popleft()
        for ev, t in g.get(s, []):
            if t not in paths:
                paths[t] = paths[s] + [ev]
                queue.append(t)
    return paths


def _closest(name: str, pool) -> str | None:
    import difflib
    found = difflib.get_close_matches(name, list(pool), n=1, cutoff=0.75)
    return found[0] if found else None


def _hint(name: str, pool) -> str:
    c = _closest(name, pool)
    return f" — возможно, '{c}'?" if c else ""


def analyze(program: A.Program, diags: Diagnostics) -> Model:
    return Analyzer(program, diags).run()
