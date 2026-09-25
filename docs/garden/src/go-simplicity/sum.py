def total(lines):
    # int() бросает ValueError; обработка — где-то выше по стеку
    return sum(int(line) for line in lines)


for lines in (["10", "20", "30"], ["10", "x", "30"]):
    try:
        print("сумма:", total(lines))
    except ValueError as e:
        print("ошибка:", e)
