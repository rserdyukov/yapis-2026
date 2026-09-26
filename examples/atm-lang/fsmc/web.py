"""Мост для playground: компилятор, вызываемый из JavaScript через Pyodide.

Возвращает один JSON: так на границе Python/JS не нужно разбираться с
преобразованием PyProxy, а двоичный модуль передаётся в base64.
Этот же код проверяется обычными тестами в CPython (tests/test_web.py).
"""

from __future__ import annotations

import base64
import json
import time

from . import ast as A
from . import compile_source


def compile_json(source: str, frontend: str = "antlr") -> str:
    started = time.perf_counter()
    r = compile_source(source, frontend)
    elapsed = (time.perf_counter() - started) * 1000
    out = {
        "ok": r.ok,
        "frontend": frontend,
        "ms": round(elapsed, 1),
        "diagnostics": [d.to_dict() for d in r.diagnostics],
        "mermaid": r.mermaid,
        "wat": r.wat,
        "wasm": base64.b64encode(r.wasm).decode("ascii"),
        "meta": r.meta,
        "ast": dump_ast(r.program) if r.program is not None else "",
        "stats": _stats(r),
    }
    return json.dumps(out, ensure_ascii=False)


def _stats(r) -> dict:
    if r.model is None:
        return {}
    m = r.model
    return {"states": len(m.states), "events": len(m.events), "actions": len(m.actions),
            "transitions": len(r.program.transitions), "wat_lines": r.wat.count("\n"),
            "wasm_bytes": len(r.wasm)}


def dump_ast(node, indent: int = 0) -> str:
    """AST в виде дерева: имя узла и его поля без позиций и аннотаций."""
    pad = "  " * indent
    if isinstance(node, list):
        return "\n".join(dump_ast(x, indent) for x in node)
    if isinstance(node, (A.Name, A.TypeRef)):
        return f"{pad}{node.text if isinstance(node, A.Name) else node.name}"
    if isinstance(node, (A.IntLit, A.StrLit, A.BoolLit, A.Ref, A.Unary, A.Binary)):
        return f"{pad}{type(node).__name__}  {A.show_expr(node)}"
    lines = [f"{pad}{type(node).__name__}"]
    for name, value in vars(node).items():
        if name in ("line", "col", "ty", "ref") or value is None or value == []:
            continue
        if isinstance(value, (bool, str, int)):
            lines.append(f"{pad}  {name}: {value}")
            continue
        simple = isinstance(value, (A.Name, A.TypeRef))
        if simple:
            lines.append(f"{pad}  {name}: {dump_ast(value).strip()}")
        elif isinstance(value, list) and all(isinstance(x, A.Name) for x in value):
            lines.append(f"{pad}  {name}: " + ", ".join(x.text for x in value))
        else:
            lines.append(f"{pad}  {name}:")
            lines.append(dump_ast(value, indent + 2))
    return "\n".join(lines)
