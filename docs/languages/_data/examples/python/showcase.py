"""Пример-витрина: Python 3.

Одна программа, в которой прокомментированы конструкции, соответствующие
независимым концепциям каталога. Старые маркеры `--8<--` приняты через
legacy_slugs; они размечают секции для сайта и не влияют на выполнение.
"""

from __future__ import annotations

import sys


# --8<-- [start:req-8-2]
# 8.2. Глобальная область видимости: имена уровня модуля видны во всех
# функциях; для записи в них внутри функции нужно объявление `global`.
COUNTER = 0


def bump() -> None:
    global COUNTER
    COUNTER += 1
# --8<-- [end:req-8-2]


# --8<-- [start:variants-9]
# 9. Подпрограмму можно объявить в любом месте модуля, а также внутри
# другой подпрограммы — вложенная функция видит переменные внешней.
def outer(x: int) -> int:
    def inner(y: int) -> int:
        return x + y

    return inner(1)
# --8<-- [end:variants-9]


# --8<-- [start:variants-7]
# 7. Перегрузки по сигнатуре нет: второе `def` с тем же именем заменяет
# первое. Разное поведение для разных типов достигается проверкой типа
# внутри функции или functools.singledispatch.
def describe(value: object) -> str:
    if isinstance(value, int):
        return f"целое {value}"
    return f"объект {value!r}"
# --8<-- [end:variants-7]


# --8<-- [start:variants-8]
# 8. Передача параметров — по ссылке на объект (call by sharing):
# внутрь передаётся ссылка, изменение изменяемого объекта видно вызывающему,
# а перепривязка имени параметра — нет.
def append_and_rebind(items: list[int], n: int) -> None:
    items.append(n)   # видно снаружи: тот же объект list
    n = n + 1         # не видно снаружи: имя перепривязано локально
    items = []        # не видно снаружи: локальное имя указывает на новый list
# --8<-- [end:variants-8]


# --8<-- [start:req-4]
# 4. Ввод-вывод — встроенные функции input() и print(), импорт не нужен.
def read_int(prompt: str) -> int:
    return int(input(prompt))
# --8<-- [end:req-4]


def main() -> None:
    # --8<-- [start:variants-1]
    # 1. Объявление переменных неявное: переменная появляется при первом
    # присваивании. Аннотация типа (с 3.6) необязательна и не проверяется
    # интерпретатором.
    total = 0
    name: str = "ЯПИС"
    # --8<-- [end:variants-1]

    # --8<-- [start:variants-2]
    # 2. Преобразование типов — явное вызовом типа-конструктора; неявное
    # числовое преобразование есть в смешанной арифметике.
    # Проверка истинности использует отдельный протокол __bool__/__len__.
    count = int("42")
    ratio = count / 5.0        # смешанная арифметика int и float
    if count:                  # проверка истинности, count остаётся int
        total += count
    # --8<-- [end:variants-2]

    # --8<-- [start:variants-3]
    # 3. Присваивание одиночное и множественное (распаковка кортежа).
    a = 1
    a, b = b_first(), a        # правая часть вычисляется целиком до присваивания
    a = a + 1                 # перепривязка того же имени, не новое shadowing
    a = a - 1
    # --8<-- [end:variants-3]

    # --8<-- [start:variants-4]
    # 4. Области создают функции, классы, модули и comprehension в Python 3.
    # if/for/while новой области не создают; имя доступно после присваивания.
    if total > 0:
        inside_block = "видна ниже"
    print(inside_block)
    # --8<-- [end:variants-4]

    # --8<-- [start:variants-5]
    # 5. Маркер блока неявный: двоеточие и отступ, закрывающего символа нет.
    for i in range(3):
        total += i
        if i == 2:
            print("конец блока по отступу")
    # --8<-- [end:variants-5]

    # --8<-- [start:variants-6]
    # 6. Двухвариантный if / elif / else и, с версии 3.10, многовариантный
    # match — сопоставление с образцом, а не switch по константам.
    if total > 100:
        print("много")
    elif total > 10:
        print("средне")
    else:
        print("мало")

    match (a, b):
        case (1, _):
            print("первый элемент — единица")
        case (_, 1):
            print("второй элемент — единица")
        case _:
            print("что-то другое")
    # --8<-- [end:variants-6]

    # --8<-- [start:req-7-3]
    # 7.3. Цикл for — только по коллекции (foreach); счётный цикл — это
    # итерация по range().
    for ch in name:
        print(ch, end=" ")
    for i in range(0, 10, 2):
        print(i, end=" ")
    print()
    # --8<-- [end:req-7-3]

    # --8<-- [start:req-7-2-until]
    # 7.2. Отдельного until нет. Предусловие допускает ноль итераций;
    # постусловие repeat-until проверяется после тела, выполненного хотя бы раз.
    n = 0
    while not n >= 3:
        n += 1
    n = 0
    while True:
        n += 1
        if n >= 3:
            break
    # --8<-- [end:req-7-2-until]

    # --8<-- [start:req-7-2-do-while]
    # Цикла do-while нет; тело выполняется хотя бы раз через while True + break.
    while True:
        n -= 1
        if n <= 0:
            break
    # --8<-- [end:req-7-2-do-while]

    print(describe(count), describe(ratio), outer(41))
    items: list[int] = []
    append_and_rebind(items, 5)
    print(items)               # [5]
    bump()
    print(COUNTER)             # 1

    if len(sys.argv) > 1:
        print(read_int("число: "))


def b_first() -> int:
    return 2


if __name__ == "__main__":
    main()
