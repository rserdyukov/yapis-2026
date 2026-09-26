"""Диагностика компилятора: коды, уровни, форматирование.

Код ошибки — часть контракта: негативные тесты проверяют именно коды, а не
текст сообщения, поэтому текст можно улучшать, не ломая тесты. Полный список
кодов — в README.md, раздел «Семантические проверки».
"""

from __future__ import annotations

from dataclasses import dataclass, field

ERROR = "error"
WARNING = "warning"

_LEVEL_RU = {ERROR: "ошибка", WARNING: "предупреждение"}


@dataclass
class Diagnostic:
    level: str
    code: str
    message: str
    line: int = 0
    col: int = 0

    def format(self, filename: str = "<input>") -> str:
        where = f"{filename}:{self.line}:{self.col}" if self.line else filename
        return f"{where}: {_LEVEL_RU[self.level]} {self.code}: {self.message}"

    def to_dict(self) -> dict:
        return {"level": self.level, "code": self.code, "message": self.message,
                "line": self.line, "col": self.col}


@dataclass
class Diagnostics:
    items: list[Diagnostic] = field(default_factory=list)

    def error(self, code: str, message: str, line: int = 0, col: int = 0) -> None:
        self.items.append(Diagnostic(ERROR, code, message, line, col))

    def warning(self, code: str, message: str, line: int = 0, col: int = 0) -> None:
        self.items.append(Diagnostic(WARNING, code, message, line, col))

    @property
    def has_errors(self) -> bool:
        return any(d.level == ERROR for d in self.items)

    def sorted(self) -> list[Diagnostic]:
        return sorted(self.items, key=lambda d: (d.line, d.col, d.code))

    def codes(self) -> set[str]:
        return {d.code for d in self.items}


class SyntaxFailure(Exception):
    """Фронтенд не смог построить дерево. Диагностика уже записана."""
