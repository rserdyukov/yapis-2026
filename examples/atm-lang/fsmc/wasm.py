"""Минимальный построитель модуля WebAssembly: WAT-текст и двоичный .wasm.

Генератор кода (codegen.py) сам выбирает инструкции и складывает их сюда
списками кортежей ``(опкод, аргументы...)``. Этот модуль ничего не решает:
он только печатает те же инструкции двумя способами.

* ``Module.to_wat()`` — текст для человека (и для ``wat2wasm``);
* ``Module.to_wasm()`` — двоичный формат по спецификации WebAssembly 1.0.

Оба представления строятся из одного списка, поэтому разойтись не могут.
Тест test_wasm проверяет, что ``wat2wasm`` собирает из нашего WAT байт в байт
тот же модуль, что и наш кодировщик (без пользовательской секции fsm.meta:
в текстовом формате её не выразить).

Ссылки на функции, локальные и глобальные переменные и метки записываются
по имени (``"$state"``); кодировщик сам переводит их в индексы, а метки —
в глубину вложенности, как того требует двоичный формат.
"""

from __future__ import annotations

from dataclasses import dataclass, field

I32 = "i32"
_VALTYPE = {I32: 0x7F}

# Инструкции без непосредственных операндов.
_SIMPLE = {
    "unreachable": 0x00, "return": 0x0F, "drop": 0x1A, "select": 0x1B,
    "i32.eqz": 0x45, "i32.eq": 0x46, "i32.ne": 0x47, "i32.lt_s": 0x48,
    "i32.lt_u": 0x49, "i32.gt_s": 0x4A, "i32.gt_u": 0x4B, "i32.le_s": 0x4C,
    "i32.le_u": 0x4D, "i32.ge_s": 0x4E, "i32.ge_u": 0x4F,
    "i32.add": 0x6A, "i32.sub": 0x6B, "i32.mul": 0x6C, "i32.div_s": 0x6D,
    "i32.div_u": 0x6E, "i32.rem_s": 0x6F, "i32.rem_u": 0x70,
    "i32.and": 0x71, "i32.or": 0x72, "i32.xor": 0x73,
}
# Обращения к памяти: опкод и естественное выравнивание (log2 байт).
_MEMORY = {"i32.load": (0x28, 2), "i32.load8_u": (0x2D, 0),
           "i32.store": (0x36, 2), "i32.store8": (0x3A, 0)}
_BLOCKS = {"block": 0x02, "loop": 0x03, "if": 0x04}


# ------------------------------------------------------------------ LEB128


def uleb(n: int) -> bytes:
    out = bytearray()
    while True:
        byte = n & 0x7F
        n >>= 7
        if n:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return bytes(out)


def sleb(n: int) -> bytes:
    out = bytearray()
    while True:
        byte = n & 0x7F
        n >>= 7
        done = (n == 0 and not byte & 0x40) or (n == -1 and byte & 0x40)
        out.append(byte if done else byte | 0x80)
        if done:
            return bytes(out)


def _name(s: str) -> bytes:
    data = s.encode("utf-8")
    return uleb(len(data)) + data


def _vec(items: list[bytes]) -> bytes:
    return uleb(len(items)) + b"".join(items)


# ------------------------------------------------------------------ модель


@dataclass
class Func:
    name: str  # "$on_pin"
    params: list[tuple[str, str]]  # [("$p0", "i32")]
    results: list[str]
    body: list[tuple] = field(default_factory=list)
    locals: list[tuple[str, str]] = field(default_factory=list)
    comment: str = ""

    def emit(self, *instr) -> None:
        self.body.append(tuple(instr))

    def local(self, name: str, ty: str = I32) -> str:
        """Объявить локальную переменную в любой момент генерации тела:
        заголовок функции печатается в самом конце (HOWTO, § 2.3)."""
        if all(n != name for n, _ in self.params + self.locals):
            self.locals.append((name, ty))
        return name


@dataclass
class Import:
    module: str
    field: str
    name: str
    params: list[str]
    results: list[str]


@dataclass
class Global:
    name: str
    init: int
    mutable: bool = True
    comment: str = ""


@dataclass
class Data:
    offset: int
    payload: bytes
    comment: str = ""


class Module:
    def __init__(self) -> None:
        self.types: list[tuple[tuple[str, ...], tuple[str, ...]]] = []
        self.imports: list[Import] = []
        self.funcs: list[Func] = []
        self.globals: list[Global] = []
        self.exports: list[tuple[str, str, str]] = []  # (имя, вид, ссылка)
        self.data: list[Data] = []
        self.memory_pages = 1
        self.custom: list[tuple[str, bytes]] = []
        self.header: list[str] = []  # комментарии в начале WAT

    # -------------------------------------------------------------- типы

    def type_index(self, params, results) -> int:
        sig = (tuple(params), tuple(results))
        if sig not in self.types:
            self.types.append(sig)
        return self.types.index(sig)

    def _collect_types(self) -> None:
        self.types = []
        for imp in self.imports:
            self.type_index(imp.params, imp.results)
        for f in self.funcs:
            self.type_index([t for _, t in f.params], f.results)

    # -------------------------------------------------------------- индексы

    def _func_index(self) -> dict[str, int]:
        names = [i.name for i in self.imports] + [f.name for f in self.funcs]
        return {n: i for i, n in enumerate(names)}

    def _global_index(self) -> dict[str, int]:
        return {g.name: i for i, g in enumerate(self.globals)}

    # ============================================================== WAT

    def to_wat(self) -> str:
        self._collect_types()
        out: list[str] = [f";; {line}" if line else ";;" for line in self.header]
        out.append("(module")
        for i, (params, results) in enumerate(self.types):
            out.append(f"  (type $t{i} (func{_sig(params, results)}))")
        for imp in self.imports:
            t = self.type_index(imp.params, imp.results)
            out.append(f'  (import "{imp.module}" "{imp.field}" '
                       f"(func {imp.name} (type $t{t})))")
        out.append(f"  (memory $memory {self.memory_pages})")
        for g in self.globals:
            ty = f"(mut {I32})" if g.mutable else I32
            comment = f"  ;; {g.comment}" if g.comment else ""
            out.append(f"  (global {g.name} {ty} (i32.const {g.init})){comment}")
        for f in self.funcs:
            out.append("")
            if f.comment:
                out.append(f"  ;; {f.comment}")
            out.extend(self._func_wat(f))
        out.append("")
        for name, kind, ref in self.exports:
            out.append(f'  (export "{name}" ({kind} {ref}))')
        for d in self.data:
            if d.comment:
                out.append(f"  ;; {d.comment}")
            out.append(f'  (data (i32.const {d.offset}) "{_wat_bytes(d.payload)}")')
        out.append(")")
        return "\n".join(out) + "\n"

    def _func_wat(self, f: Func) -> list[str]:
        t = self.type_index([ty for _, ty in f.params], f.results)
        head = f"  (func {f.name} (type $t{t})"
        head += "".join(f" (param {n} {ty})" for n, ty in f.params)
        head += "".join(f" (result {r})" for r in f.results)
        lines = [head]
        for n, ty in f.locals:
            lines.append(f"    (local {n} {ty})")
        depth = 2
        for ins in f.body:
            op = ins[0]
            if op in ("end", "else"):
                depth -= 1
            pad = "  " * depth
            if op == "comment":
                lines.append(f"{pad};; {ins[1]}")
            elif op in _BLOCKS:
                label = f" {ins[1]}" if ins[1] else ""
                result = f" (result {ins[2]})" if len(ins) > 2 and ins[2] else ""
                lines.append(f"{pad}{op}{label}{result}")
            elif op == "br_table":
                lines.append(f"{pad}br_table {' '.join(ins[1])} {ins[2]}")
            elif op in _MEMORY:
                offset = f" offset={ins[1]}" if len(ins) > 1 and ins[1] else ""
                lines.append(f"{pad}{op}{offset}")
            else:
                lines.append(pad + " ".join(str(a) for a in ins))
            if op in _BLOCKS or op == "else":
                depth += 1
        lines[-1] += ")"
        return lines

    # ============================================================== WASM

    def to_wasm(self, include_custom: bool = True) -> bytes:
        self._collect_types()
        funcs = self._func_index()
        globs = self._global_index()
        out = bytearray(b"\x00asm\x01\x00\x00\x00")

        def section(sid: int, payload: bytes) -> None:
            out.append(sid)
            out.extend(uleb(len(payload)))
            out.extend(payload)

        section(1, _vec([b"\x60" + _vec([bytes([_VALTYPE[p]]) for p in params])
                         + _vec([bytes([_VALTYPE[r]]) for r in results])
                         for params, results in self.types]))
        if self.imports:
            section(2, _vec([_name(i.module) + _name(i.field) + b"\x00"
                             + uleb(self.type_index(i.params, i.results))
                             for i in self.imports]))
        section(3, _vec([uleb(self.type_index([t for _, t in f.params], f.results))
                         for f in self.funcs]))
        section(5, _vec([b"\x00" + uleb(self.memory_pages)]))
        if self.globals:
            section(6, _vec([bytes([_VALTYPE[I32], 1 if g.mutable else 0])
                             + b"\x41" + sleb(g.init) + b"\x0b" for g in self.globals]))
        kinds = {"func": (0, funcs), "memory": (2, {"$memory": 0}),
                 "global": (3, globs)}
        exports = []
        for name, kind, ref in self.exports:
            code, table = kinds[kind]
            exports.append(_name(name) + bytes([code]) + uleb(table[ref]))
        section(7, _vec(exports))
        section(10, _vec([self._func_wasm(f, funcs, globs) for f in self.funcs]))
        if self.data:
            section(11, _vec([b"\x00\x41" + sleb(d.offset) + b"\x0b" + uleb(len(d.payload))
                              + d.payload for d in self.data]))
        if include_custom:
            for name, payload in self.custom:
                section(0, _name(name) + payload)
        return bytes(out)

    def _func_wasm(self, f: Func, funcs: dict, globs: dict) -> bytes:
        local_index = {n: i for i, (n, _) in enumerate(f.params + f.locals)}
        # Локальные одного типа подряд сжимаются в одну запись (count, type).
        groups: list[list] = []
        for _, ty in f.locals:
            if groups and groups[-1][1] == ty:
                groups[-1][0] += 1
            else:
                groups.append([1, ty])
        code = bytearray(_vec([uleb(n) + bytes([_VALTYPE[t]]) for n, t in groups]))
        labels: list[str] = []

        def depth(label: str) -> int:
            for d, name in enumerate(reversed(labels)):
                if name == label:
                    return d
            raise KeyError(f"{f.name}: метка {label} вне области видимости")

        for ins in f.body:
            op = ins[0]
            if op == "comment":
                continue
            if op in _SIMPLE:
                code.append(_SIMPLE[op])
            elif op in _BLOCKS:
                code.append(_BLOCKS[op])
                result = ins[2] if len(ins) > 2 else None
                code.append(_VALTYPE[result] if result else 0x40)
                labels.append(ins[1] or "")
            elif op == "else":
                code.append(0x05)
            elif op == "end":
                code.append(0x0B)
                labels.pop()
            elif op in ("br", "br_if"):
                code.append(0x0C if op == "br" else 0x0D)
                code.extend(uleb(depth(ins[1])))
            elif op == "br_table":
                code.append(0x0E)
                code.extend(_vec([uleb(depth(lbl)) for lbl in ins[1]]))
                code.extend(uleb(depth(ins[2])))
            elif op in ("memory.size", "memory.grow"):
                code.extend(b"\x3f\x00" if op == "memory.size" else b"\x40\x00")
            elif op == "call":
                code.append(0x10)
                code.extend(uleb(funcs[ins[1]]))
            elif op in ("local.get", "local.set", "local.tee"):
                code.append({"local.get": 0x20, "local.set": 0x21, "local.tee": 0x22}[op])
                code.extend(uleb(local_index[ins[1]]))
            elif op in ("global.get", "global.set"):
                code.append(0x23 if op == "global.get" else 0x24)
                code.extend(uleb(globs[ins[1]]))
            elif op == "i32.const":
                code.append(0x41)
                code.extend(sleb(ins[1]))
            elif op in _MEMORY:
                opcode, align = _MEMORY[op]
                code.append(opcode)
                code.extend(uleb(align) + uleb(ins[1] if len(ins) > 1 else 0))
            else:
                raise ValueError(f"неизвестная инструкция {op}")
        if labels:
            raise ValueError(f"{f.name}: незакрытый блок {labels[-1]}")
        code.append(0x0B)
        return uleb(len(code)) + bytes(code)


def _sig(params, results) -> str:
    s = "".join(f" (param {p})" for p in params)
    return s + "".join(f" (result {r})" for r in results)


def _wat_bytes(data: bytes) -> str:
    """Строка data-сегмента: печатный ASCII и целые UTF-8 символы как есть
    (кириллица в WAT остаётся читаемой), всё прочее — ``\\xx``."""
    out = []
    i = 0
    while i < len(data):
        b = data[i]
        if 0x20 <= b < 0x7F and b not in (0x22, 0x5C):
            out.append(chr(b))
            i += 1
            continue
        if b >= 0xC2:
            n = 2 if b < 0xE0 else 3 if b < 0xF0 else 4
            try:
                out.append(data[i:i + n].decode("utf-8"))
                i += n
                continue
            except UnicodeDecodeError:
                pass
        out.append(f"\\{b:02x}")
        i += 1
    return "".join(out)


def strip_custom_sections(binary: bytes) -> bytes:
    """Удалить пользовательские секции (id 0) — для сравнения с wat2wasm."""
    out = bytearray(binary[:8])
    i = 8
    while i < len(binary):
        sid = binary[i]
        size, shift, j = 0, 0, i + 1
        while True:
            b = binary[j]
            size |= (b & 0x7F) << shift
            shift += 7
            j += 1
            if not b & 0x80:
                break
        if sid != 0:
            out.extend(binary[i:j + size])
        i = j + size
    return bytes(out)
