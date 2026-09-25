# Те же приёмы в Python: специальные («dunder») методы класса.

class V:
    def __init__(self, x, y):
        self.x, self.y = x, y

    def __add__(self, o):          # v + o
        return V(self.x + o.x, self.y + o.y)

    def __eq__(self, o):
        return (self.x, self.y) == (o.x, o.y)

    def __repr__(self):
        return f"({self.x}, {self.y})"


class Defaults:
    def __getattr__(self, name):   # как __index-функция: только для отсутствующих
        return 0


p = V(1, 2)
print(p + V(3, 4), p == V(1, 2), p is V(1, 2))
d = Defaults()
d.a = 5
print(d.a, d.missing)

# Специальные методы ищутся в типе, а не в экземпляре
p.__add__ = lambda o: "instance"
print(p + V(0, 0))
