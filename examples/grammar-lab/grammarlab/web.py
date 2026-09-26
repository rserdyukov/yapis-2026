"""JSON-мост для страницы самопроверки (Pyodide), как fsmc/web.py."""

from __future__ import annotations

import json

from .answer import parse_answer
from .check import check
from .grid import apply_grid, grid_model, layout


def check_json(text: str) -> str:
    """Проверить ответ; вернуть JSON-строку с отчётом.

    Все уровни подсказок возвращаются сразу: что и когда показывать,
    решает страница (это самопроверка, скрывать от студента нечего).
    """
    try:
        report = check(parse_answer(text))
        data = report.to_dict()
        data["ok"] = not report.parse or all(d.level != "error" for d in report.parse)
    except Exception as error:  # отчёт об ошибке программы, а не ответа
        data = {"ok": False, "internal_error": f"{type(error).__name__}: {error}",
                "parse": [], "findings": [], "checked": [], "interpretation": [], "verdict": ""}
    return json.dumps(data, ensure_ascii=False)


def grid_json(text: str) -> str:
    """Модель табличного редактора для текущего ответа (grid.grid_model)."""
    try:
        return json.dumps(grid_model(text), ensure_ascii=False)
    except Exception as error:
        return json.dumps({"ok": False, "internal_error": f"{type(error).__name__}: {error}"},
                          ensure_ascii=False)


def apply_grid_json(text: str, grid: str) -> str:
    """Записать сетку в текст ответа; вернуть {"ok", "text"}."""
    try:
        return json.dumps(apply_grid(text, json.loads(grid)), ensure_ascii=False)
    except Exception as error:
        return json.dumps({"ok": False, "text": text,
                           "internal_error": f"{type(error).__name__}: {error}"}, ensure_ascii=False)


def layout_json(text: str) -> str:
    """Разметка для редактора: секции, диагностика, сетка, трассы (grid.layout)."""
    try:
        return json.dumps(layout(text), ensure_ascii=False)
    except Exception as error:
        return json.dumps({"ok": False, "internal_error": f"{type(error).__name__}: {error}",
                           "diagnostics": [], "sections": [], "traces": []}, ensure_ascii=False)
