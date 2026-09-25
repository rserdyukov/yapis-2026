"""Защитный стиль: ошибку перехватывают там, где она возникла."""


# --8<-- [start:defensive]
def safe_div(a, b):
    try:
        return a // b
    except ZeroDivisionError:
        return 0                     # «чтобы не упало» — но что на самом деле значит 0?


def average_rate(jobs):
    results = [safe_div(100, x) for x in jobs]
    return sum(results) / len(results)


print("results:", [safe_div(100, x) for x in [4, 1, 0, 5, 0, 2]])
print("average:", average_rate([4, 1, 0, 5, 0, 2]))   # два нуля тихо испортили среднее
# --8<-- [end:defensive]
