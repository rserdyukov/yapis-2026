"""Диаграмма автомата в Mermaid (stateDiagram-v2) — усложнение из карточки, п. 9.

Строится из той же модели, что и код, поэтому показывает автомат таким, каким
его понял компилятор. Состояния с ошибками E102/E103 подсвечиваются.
"""

from __future__ import annotations

from .ast import show_expr
from .semantic import Model


def _label(text: str) -> str:
    # В подписи перехода Mermaid ломается на `:`, `;`, `#` и угловых скобках
    # (сущности &lt; он тоже обрезает). Заменяем их похожими символами Unicode:
    # подпись читается так же, а разбор не ломается.
    for ascii_, uni in (("<=", "\u2264"), (">=", "\u2265"), ("!=", "\u2260"),
                        ("<", "\u2039"), (">", "\u203a"), (":", "\u2236"),
                        (";", ","), ("#", "\u266f")):
        text = text.replace(ascii_, uni)
    return text


def mermaid(model: Model) -> str:
    lines = ["stateDiagram-v2"]
    if model.initial:
        lines.append(f"    [*] --> {model.initial}")
    for term in model.terminal:
        lines.append(f"    {term} --> [*]")
    # Переходы с одинаковыми концами и подписью, но разными событиями
    # (`cancel | timeout`) сливаются в одну стрелку: `cancel | timeout / eject`.
    arrows: dict[tuple, list[str]] = {}
    for (state, event), ts in model.table.items():
        for t in ts:
            if t.ignore:
                continue
            target = t.target.text if t.target else state
            if target not in model.states:
                continue
            tail = ""
            if t.guard is not None:
                tail += f" [{show_expr(t.guard)}]"
            elif t.ordered:
                tail += " [else]"
            if t.actions:
                tail += " / " + ", ".join(c.name.text for c in t.actions)
            events = arrows.setdefault((state, target, id(t), tail), [])
            if event not in events:
                events.append(event)
    for (state, target, _, tail), events in arrows.items():
        lines.append(f"    {state} --> {target}: {_label(' | '.join(events) + tail)}")
    # Состояние без единой стрелки иначе не попало бы на диаграмму.
    drawn = {s for s, t, _, _ in arrows} | {t for _, t, _, _ in arrows}
    for s in model.states:
        if s not in drawn and s != model.initial and s not in model.terminal:
            lines.append(f"    {s}")
    bad = model.unreachable | model.trapped
    if bad:
        lines.append("    classDef bad fill:#fde2e1,stroke:#c0392b,color:#7b1d14")
        lines.append("    class " + ",".join(s for s in model.states if s in bad) + " bad")
    return "\n".join(lines) + "\n"
