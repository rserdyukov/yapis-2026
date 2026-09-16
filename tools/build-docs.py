#!/usr/bin/env python3
"""Сборка производных документов из общих партиалов.

Единый источник правды для текста задания — файлы в docs/_partials/.
Из них собираются два потребителя с разной аудиторией:

  docs/labs/index.md       — страница сайта (читают студенты в браузере)
  admin/template-TASK.md   — уезжает в репозиторий студента как TASK.md

Тексты различаются только обвязкой и способом ссылаться на документы
студента: на сайте README.md/GUIDE.md студента не существует, поэтому
в партиалах стоят токены {{README}} и {{GUIDE}}, а подстановка зависит
от цели сборки.

Запуск:
    python3 tools/build-docs.py           # собрать
    python3 tools/build-docs.py --check   # проверить, что пересборка
                                          # не меняет файлы (для CI)
"""

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PARTIALS = ROOT / "docs" / "_partials"

GENERATED_NOTICE = (
    "<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-docs.py\n"
    "     Правки вносите в docs/_partials/, иначе они будут затёрты. -->"
)

# Подстановки для токенов {{README}} и {{GUIDE}} в партиалах.
#
# template — студент читает файл в своём репозитории, рядом лежат
#            README.md и GUIDE.md, поэтому ссылки относительные.
# site     — этих файлов на сайте нет; ссылка вела бы в никуда,
#            поэтому остаётся только имя файла без ссылки.
LINKS = {
    "template": {
        "README": "[`README.md`](README.md)",
        "GUIDE": "[`GUIDE.md`](GUIDE.md)",
    },
    "site": {
        "README": "`README.md` своего репозитория",
        "GUIDE": "`GUIDE.md` своего репозитория",
    },
}


def load_partial(name: str, target: str) -> str:
    """Прочитать партиал и подставить ссылки под конкретного потребителя."""
    text = (PARTIALS / f"{name}.md").read_text(encoding="utf-8").rstrip("\n")
    for token, replacement in LINKS[target].items():
        text = text.replace("{{" + token + "}}", replacement)
    if "{{" in text:
        raise SystemExit(f"В партиале {name}.md остались неподставленные токены")
    return text


def renumber(sections: list[str]) -> list[str]:
    """Пронумеровать заголовки второго уровня подряд.

    Партиалы не знают своего порядка в документе, поэтому номер разделу
    проставляется при сборке — так один и тот же партиал можно включать
    в разные документы с разной нумерацией.
    """
    out = []
    for i, text in enumerate(sections, start=1):
        lines = text.split("\n")
        for j, line in enumerate(lines):
            if line.startswith("## "):
                lines[j] = f"## {i}. {line[3:]}"
                break
        out.append("\n".join(lines))
    return out


def build_template_task() -> str:
    """admin/template-TASK.md — документ студента, plain CommonMark."""
    body = renumber(
        [
            load_partial("labs-sequence", "template"),
            load_partial("report-structure", "template"),
            load_partial("language-requirements", "template"),
        ]
    )
    header = f"""{GENERATED_NOTICE}

# Задание лабораторного практикума

Курс «Языковые процессоры интеллектуальных систем».

Здесь описано, **что нужно сделать** и **каким требованиям** должен
удовлетворять разрабатываемый язык. Конкретный вариант задания (язык,
набор свойств, целевой код) выдаёт преподаватель — опишите его в
[`README.md`](README.md) своего репозитория.

Порядок работы с репозиторием, правила оформления PR и информация об
автоматическом ИИ-ревью — в [`GUIDE.md`](GUIDE.md).

Полный список вариантов и таблица распределения — на сайте курса:
<https://rserdyukov.github.io/yapis-2026/labs/variants/>"""
    footer = """## Свойства языка по варианту

Помимо общих требований выше, ваш вариант задаёт конкретные свойства языка:

- способ объявления переменных (явное / неявное);
- преобразование типов (явное / неявное);
- оператор присваивания (одиночный / множественный);
- маркер блочного оператора;
- вид условного оператора и оператора цикла;
- способ передачи параметров в подпрограммы;
- наличие перегрузки подпрограмм;
- область видимости имён;
- целевой код компилятора (JVM, .NET CIL, LLVM IR, CPython, WAT).

Точные значения для вашего варианта выдаёт преподаватель.
**Выпишите их в [`README.md`](README.md)** — на этот файл опирается и
преподаватель при проверке, и автоматическое ИИ-ревью."""

    parts = [header, *body, f"## 4. {footer[3:]}"]
    return "\n\n---\n\n".join(parts) + "\n"


def build_site_labs() -> str:
    """docs/labs/index.md — страница сайта."""
    body = renumber(
        [
            load_partial("labs-sequence", "site"),
            load_partial("report-structure", "site"),
            load_partial("language-requirements", "site"),
        ]
    )
    header = f"""{GENERATED_NOTICE}

# Лабораторный практикум

Здесь описано, **что нужно сделать** и **каким требованиям** должен
удовлетворять разрабатываемый язык. Требования одинаковы для всех вариантов.

Конкретный вариант задания — язык, набор свойств и целевой код — выдаёт
преподаватель. Списки вариантов и таблица распределения: [Варианты
заданий](variants.md).

Порядок работы с репозиторием, ветки, Pull Request и правила ИИ-ревью
описаны в `GUIDE.md` вашего репозитория."""

    return "\n\n".join([header, *body]) + "\n"


TARGETS = {
    ROOT / "admin" / "template-TASK.md": build_template_task,
    ROOT / "docs" / "labs" / "index.md": build_site_labs,
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="не записывать файлы, а проверить, что они уже актуальны",
    )
    args = parser.parse_args()

    stale = []
    for path, builder in TARGETS.items():
        expected = builder()
        rel = path.relative_to(ROOT)
        if args.check:
            current = path.read_text(encoding="utf-8") if path.exists() else None
            if current != expected:
                stale.append(rel)
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.exists() and path.read_text(encoding="utf-8") == expected:
            print(f"  без изменений: {rel}")
        else:
            path.write_text(expected, encoding="utf-8")
            print(f"  обновлён:      {rel}")

    if stale:
        print("Файлы разошлись с источником в docs/_partials/:", file=sys.stderr)
        for rel in stale:
            print(f"  {rel}", file=sys.stderr)
        print("\nЗапустите: python3 tools/build-docs.py", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
