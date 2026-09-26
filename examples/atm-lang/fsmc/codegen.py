"""Генерация кода: аннотированная модель → модуль WebAssembly.

Генератор запускается только при нуле ошибок и читает аннотации семантики
(``expr.ty``, ``Ref.ref``), ничего не выводя заново (HOWTO, § 2.1).

Раскладка модуля
----------------

* Типы: ``int``, ``money``, ``bool`` → ``i32``; ``string`` → ``i32``-указатель
  на ``[длина: i32][байты UTF-8]`` в линейной памяти.
* Строковые литералы — data-сегменты с адреса 8 (адрес 0 оставлен пустым,
  чтобы нулевой указатель не совпал ни с одной строкой). За ними — куча.
* Поля контекста — изменяемые глобальные ``$ctx_<имя>``; текущее состояние —
  глобальная ``$state`` (номер в порядке объявления ``states``).
* Действие — функция ``$act_<имя>`` со своими параметрами.
* Событие — экспортируемая функция ``on_<событие>(параметры) -> i32``.
  Она выбирает ветку по текущему состоянию инструкцией ``br_table`` (таблица
  переходов, а не цепочка сравнений), в ветке проверяет guard'ы сверху вниз,
  вызывает действия и записывает новое состояние. Результат:
  0 — переход выполнен, 1 — событие явно проигнорировано, 2 — не обработано.

Импорты хоста (runtime/fsm-host.mjs) — только вывод:
``env.print_str(ptr)``, ``env.print_int(i32)``, ``env.print_end()``.

Экспорты: ``memory``, ``init``, ``alloc`` (хост кладёт в память строковые
аргументы событий), ``state`` и ``ctx.<поле>`` (для отладки и playground),
``on_<событие>``. Описание машины для хоста — JSON в пользовательской
секции ``fsm.meta``.
"""

from __future__ import annotations

import json
import re

from . import ast as A
from .semantic import BOOL, STRING, Model  # noqa: F401 — Model для аннотаций
from .wasm import I32, Data, Func, Global, Import, Module

MOVED, IGNORED, UNHANDLED = 0, 1, 2
DATA_START = 8

_ID_OK = re.compile(r"^[A-Za-z0-9_]+$")


def wat_id(prefix: str, name: str) -> str:
    """Имя для WAT. Идентификаторы WAT — только ASCII, поэтому кириллические
    имена из программы кодируются: ``баланс`` → ``$ctx_u431_u430...``."""
    if not _ID_OK.match(name):
        name = "_".join(f"u{ord(ch):x}" if not _ID_OK.match(ch) else ch for ch in name)
    return f"${prefix}_{name}"


class Strings:
    """Пул строковых литералов. Смещения назначает только он (HOWTO, § 5.3):
    длина считается в байтах UTF-8, а не в символах."""

    def __init__(self) -> None:
        self.offsets: dict[str, int] = {}
        self.end = DATA_START

    def intern(self, s: str) -> int:
        if s not in self.offsets:
            self.offsets[s] = self.end
            size = 4 + len(s.encode("utf-8"))
            self.end += (size + 3) & ~3  # выравнивание на 4
        return self.offsets[s]

    def segments(self) -> list[Data]:
        out = []
        for s, off in self.offsets.items():
            data = s.encode("utf-8")
            out.append(Data(off, len(data).to_bytes(4, "little") + data,
                            comment=json.dumps(s, ensure_ascii=False)))
        return out


class Generator:
    def __init__(self, model: Model):
        self.m = model
        self.mod = Module()
        self.strings = Strings()
        self.labels = 0

    # ================================================================ вход

    def run(self) -> tuple[Module, dict]:
        m, mod = self.m, self.mod
        mod.header = [f"Автомат {m.program.name.text}: сгенерировано fsmc.",
                      "Состояния: " + ", ".join(f"{i}={s}" for i, s in enumerate(m.states))]
        mod.imports = [
            Import("env", "print_str", "$print_str", [I32], []),
            Import("env", "print_int", "$print_int", [I32], []),
            Import("env", "print_end", "$print_end", [], []),
        ]
        mod.globals.append(Global("$state", 0, comment="текущее состояние"))
        for name, f in m.fields.items():
            mod.globals.append(Global(wat_id("ctx", name), 0,
                                      comment=f"поле {name}: {f.type.name}"))

        mod.funcs.append(self._str_eq())
        mod.funcs.append(self._alloc_func())
        for action in m.actions.values():
            mod.funcs.append(self._action(action))
        handlers = [self._event(name) for name in m.events]
        mod.funcs.extend(handlers)
        mod.funcs.append(self._init())

        mod.exports.append(("memory", "memory", "$memory"))
        mod.exports.append(("init", "func", "$init"))
        mod.exports.append(("alloc", "func", "$alloc"))
        mod.exports.append(("state", "global", "$state"))
        for name in m.fields:
            mod.exports.append((f"ctx.{name}", "global", wat_id("ctx", name)))
        for name in m.events:
            mod.exports.append((f"on_{name}", "func", wat_id("on", name)))

        # Куча начинается сразу за строками. Глобальная $heap объявляется
        # последней: к этому моменту все литералы уже в пуле.
        heap = (self.strings.end + 7) & ~7
        mod.globals.append(Global("$heap_base", heap, mutable=False, comment="начало кучи"))
        mod.globals.append(Global("$heap", heap, comment="указатель bump-аллокатора"))
        mod.data = self.strings.segments()

        meta = self._meta()
        mod.custom.append(("fsm.meta", json.dumps(meta, ensure_ascii=False).encode("utf-8")))
        return mod, meta

    def _meta(self) -> dict:
        m = self.m
        return {
            "machine": m.program.name.text,
            "states": m.states,
            "initial": m.initial,
            "terminal": m.terminal,
            "events": [{"name": n, "export": f"on_{n}",
                        "params": [{"name": p.name.text, "type": p.type.name}
                                   for p in info.decl.params]}
                       for n, info in m.events.items()],
            "context": [{"name": n, "type": f.type.name, "export": f"ctx.{n}"}
                        for n, f in m.fields.items()],
            "status": {"moved": MOVED, "ignored": IGNORED, "unhandled": UNHANDLED},
        }

    def _label(self, base: str) -> str:
        self.labels += 1
        return f"${base}_{self.labels}"

    # ================================================================ runtime на WAT

    def _str_eq(self) -> Func:
        """Сравнение строк: длины, затем побайтно. Написано на WAT, а не
        импортировано из JS: так модуль не зависит от хоста в логике."""
        f = Func("$str_eq", [("$a", I32), ("$b", I32)], [I32],
                 comment="runtime: равенство строк [len][bytes]")
        f.local("$i")
        f.local("$n")
        e = f.emit
        e("local.get", "$a"); e("i32.load")
        e("local.tee", "$n")
        e("local.get", "$b"); e("i32.load")
        e("i32.ne")
        e("if", None)
        e("i32.const", 0); e("return")
        e("end")
        e("block", "$done")
        e("loop", "$next")
        e("local.get", "$i"); e("local.get", "$n"); e("i32.ge_u"); e("br_if", "$done")
        e("local.get", "$a"); e("local.get", "$i"); e("i32.add"); e("i32.load8_u", 4)
        e("local.get", "$b"); e("local.get", "$i"); e("i32.add"); e("i32.load8_u", 4)
        e("i32.ne")
        e("if", None)
        e("i32.const", 0); e("return")
        e("end")
        e("local.get", "$i"); e("i32.const", 1); e("i32.add"); e("local.set", "$i")
        e("br", "$next")
        e("end")
        e("end")
        e("i32.const", 1)
        return f

    def _alloc_func(self) -> Func:
        """Bump-аллокатор: хост просит память под строковый аргумент события."""
        f = Func("$alloc", [("$size", I32)], [I32],
                 comment="runtime: bump-аллокатор, выравнивание 8, рост памяти по страницам")
        f.local("$ptr")
        e = f.emit
        e("global.get", "$heap"); e("local.set", "$ptr")
        e("global.get", "$heap"); e("local.get", "$size"); e("i32.add")
        e("i32.const", 7); e("i32.add"); e("i32.const", -8); e("i32.and")
        e("global.set", "$heap")
        e("comment", "не хватает памяти — добавить страницы по 64 КиБ")
        e("block", "$ok")
        e("loop", "$grow")
        e("global.get", "$heap"); e("memory.size"); e("i32.const", 65536); e("i32.mul")
        e("i32.le_u"); e("br_if", "$ok")
        e("i32.const", 1); e("memory.grow"); e("i32.const", -1); e("i32.eq")
        e("if", None)
        e("unreachable")
        e("end")
        e("br", "$grow")
        e("end")
        e("end")
        e("local.get", "$ptr")
        return f

    # ================================================================ init

    def _init(self) -> Func:
        f = Func("$init", [], [], comment="сброс: начальное состояние и контекст")
        f.emit("i32.const", self.m.state_index(self.m.initial))
        f.emit("global.set", "$state")
        f.emit("global.get", "$heap_base")
        f.emit("global.set", "$heap")
        for name, fld in self.m.fields.items():
            if fld.init is not None:
                self._expr(f, fld.init, {})
            else:
                self._default(f, fld.type.name)
            f.emit("global.set", wat_id("ctx", name))
        return f

    def _default(self, f: Func, ty: str) -> None:
        f.emit("i32.const", self.strings.intern("") if ty == STRING else 0)

    # ================================================================ действия

    def _action(self, action: A.Action) -> Func:
        params = [(wat_id("a", p.name.text), I32) for p in action.params]
        f = Func(wat_id("act", action.name.text), params, [],
                 comment=f"action {action.name.text}")
        self._block(f, action.body, [n for n, _ in params])
        return f

    def _block(self, f: Func, body: list[A.Stmt], params: list[str]) -> None:
        for s in body:
            if isinstance(s, A.Assign):
                self._expr(f, s.value, params)
                f.emit("global.set", wat_id("ctx", s.target.text))
            elif isinstance(s, A.Say):
                for item in s.items:
                    self._print(f, item, params)
                f.emit("call", "$print_end")
            elif isinstance(s, A.If):
                self._expr(f, s.cond, params)
                f.emit("if", None)
                self._block(f, s.then, params)
                if s.else_:
                    f.emit("else")
                    self._block(f, s.else_, params)
                f.emit("end")

    def _print(self, f: Func, e: A.Expr, params: list[str]) -> None:
        if e.ty == STRING:
            self._expr(f, e, params)
            f.emit("call", "$print_str")
        elif e.ty == BOOL:
            # bool печатается словом: select между двумя строками.
            f.emit("i32.const", self.strings.intern("true"))
            f.emit("i32.const", self.strings.intern("false"))
            self._expr(f, e, params)
            f.emit("select")
            f.emit("call", "$print_str")
        else:
            self._expr(f, e, params)
            f.emit("call", "$print_int")

    # ================================================================ выражения
    # Контракт (HOWTO, § 2.4): после кода выражения на стеке ровно одно i32.
    # ``params`` — WAT-имена параметров текущей функции по номеру.

    _ARITH = {"+": "i32.add", "-": "i32.sub", "*": "i32.mul",
              "/": "i32.div_s", "%": "i32.rem_s"}
    _CMP = {"==": "i32.eq", "!=": "i32.ne", "<": "i32.lt_s", "<=": "i32.le_s",
            ">": "i32.gt_s", ">=": "i32.ge_s"}

    def _expr(self, f: Func, e: A.Expr, params) -> None:
        if isinstance(e, A.IntLit):
            f.emit("i32.const", e.value)
        elif isinstance(e, A.BoolLit):
            f.emit("i32.const", int(e.value))
        elif isinstance(e, A.StrLit):
            f.emit("i32.const", self.strings.intern(e.value))
        elif isinstance(e, A.Ref):
            kind, data = e.ref
            if kind == "const":
                # Константа подставляется своим выражением: оно содержит
                # только литералы и константы, объявленные выше.
                self._expr(f, data.value, params)
            elif kind == "field":
                f.emit("global.get", wat_id("ctx", data))
            else:
                f.emit("local.get", params[data])
        elif isinstance(e, A.Unary):
            if e.op == "not":
                self._expr(f, e.operand, params)
                f.emit("i32.eqz")
            else:
                f.emit("i32.const", 0)
                self._expr(f, e.operand, params)
                f.emit("i32.sub")
        elif e.op in ("and", "or"):
            # Короткое вычисление (HOWTO, § 3.5): правый операнд не
            # вычисляется, если результат уже известен.
            self._expr(f, e.left, params)
            f.emit("if", None, I32)
            if e.op == "and":
                self._expr(f, e.right, params)
                f.emit("else")
                f.emit("i32.const", 0)
            else:
                f.emit("i32.const", 1)
                f.emit("else")
                self._expr(f, e.right, params)
            f.emit("end")
        elif e.op in ("==", "!=") and e.left.ty == STRING:
            self._expr(f, e.left, params)
            self._expr(f, e.right, params)
            f.emit("call", "$str_eq")
            if e.op == "!=":
                f.emit("i32.eqz")
        else:
            self._expr(f, e.left, params)
            self._expr(f, e.right, params)
            f.emit(self._ARITH.get(e.op) or self._CMP[e.op])

    # ================================================================ события

    def _event(self, event: str) -> Func:
        m = self.m
        info = m.events[event]
        params = [(wat_id("e", p.name.text), I32) for p in info.decl.params]
        names = [n for n, _ in params]
        f = Func(wat_id("on", event), params, [I32],
                 comment=f"событие {event}: 0 — переход, 1 — игнор, 2 — не обработано")
        # Состояния, в которых событие упомянуто, получают свою ветку;
        # остальные ведут br_table сразу в $unhandled.
        handled = [s for s in m.states if (s, event) in m.table]
        labels = {s: self._label(f"in_{s}") for s in handled}
        unhandled = self._label("unhandled")

        f.emit("block", unhandled)
        for s in reversed(handled):
            f.emit("block", labels[s])
        f.emit("global.get", "$state")
        f.emit("br_table", [labels.get(s, unhandled) for s in m.states], unhandled)
        for s in handled:
            f.emit("end")
            f.emit("comment", f"{s} -- {event}")
            for t in m.table[(s, event)]:
                self._transition(f, t, names)
            if not f.body or f.body[-1][0] != "return":
                f.emit("br", unhandled)
        f.emit("end")
        f.emit("i32.const", UNHANDLED)
        return f

    def _transition(self, f: Func, t: A.Transition, params: list[str]) -> None:
        if t.guard is not None:
            self._expr(f, t.guard, params)
            f.emit("if", None)
        if t.ignore:
            f.emit("i32.const", IGNORED)
            f.emit("return")
        else:
            for call in t.actions:
                for arg in call.args:
                    self._expr(f, arg, params)
                f.emit("call", wat_id("act", call.name.text))
            if t.target is not None:
                f.emit("i32.const", self.m.state_index(t.target.text))
                f.emit("global.set", "$state")
            f.emit("i32.const", MOVED)
            f.emit("return")
        if t.guard is not None:
            f.emit("end")


def generate(model: Model) -> tuple[Module, dict]:
    return Generator(model).run()
