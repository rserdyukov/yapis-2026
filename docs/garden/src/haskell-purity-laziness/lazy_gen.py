# Python: строгие аргументы, лень — только явная, через генераторы.
from itertools import count, islice


def trace(name, value):
    print(f"  вычисляю {name}")
    return value


def const_one(_):
    return 1


# Аргумент вычисляется до вызова, даже если функции он не нужен.
print("const_one:", const_one(trace("аргумент", 42)))


def boom():
    raise RuntimeError("аргумент вычислен")


try:
    const_one(boom())
except RuntimeError as e:
    print("строгость:", e)


# Генератор — явно отложенная последовательность.
def fibs():
    a, b = 0, 1
    while True:
        yield a
        a, b = b, a + b


def primes():
    found = []
    for n in count(2):
        if all(n % p for p in found):
            found.append(n)
            yield n


print(list(islice(fibs(), 10)))
print(list(islice(primes(), 10)))

# Список вычисляется целиком сразу, генераторное выражение — по требованию.
squares_list = [trace(f"{x}^2", x * x) for x in range(3)]
print("список построен")
squares_gen = (trace(f"{x}^2", x * x) for x in range(3))
print("генератор создан")
print(next(squares_gen))

# Генератор одноразовый: в отличие от ленивого списка Haskell, он не мемоизирует.
g = (x for x in range(3))
print(list(g), list(g))
