# То, от чего Go отказался, в одном небольшом файле на Python.


class Animal:
    def __init__(self, name):
        self.name = name

    def title(self):
        return self.name

    def describe(self):
        # self.title() — виртуальный вызов: подкласс может его подменить
        return self.title() + " — животное"


class Dog(Animal):  # наследование реализации
    def title(self):
        return "пёс " + self.name


def greet(who, greeting="привет", *, loud=False):  # умолчание и именованный аргумент
    text = f"{greeting}, {who.title()}"
    return text.upper() if loud else text  # условное выражение


d = Dog("Шарик")
print(greet(d))
print(greet(d, loud=True))
print(d.describe())
print(isinstance(d, Animal))
