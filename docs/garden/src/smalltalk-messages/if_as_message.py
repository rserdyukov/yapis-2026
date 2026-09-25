# Условный оператор как посылка сообщения: без if в «языке пользователя».
# Выбор ветви делает не синтаксис, а диспетчеризация по классу получателя,
# как в классах True и False Smalltalk-80.


class Boolean_:
    def if_true_if_false(self, then_block, else_block):
        raise NotImplementedError("subclassResponsibility")

    def and_(self, block):
        raise NotImplementedError("subclassResponsibility")

    def not_(self):
        raise NotImplementedError("subclassResponsibility")


class True_(Boolean_):
    def if_true_if_false(self, then_block, else_block):
        return then_block()          # ^ trueAlternativeBlock value

    def and_(self, block):
        return block()               # вычисляем аргумент

    def not_(self):
        return FALSE

    def __repr__(self):
        return "true"


class False_(Boolean_):
    def if_true_if_false(self, then_block, else_block):
        return else_block()          # ^ falseAlternativeBlock value

    def and_(self, block):
        return self                  # аргумент не вычисляется: короткое замыкание

    def not_(self):
        return TRUE

    def __repr__(self):
        return "false"


TRUE, FALSE = True_(), False_()


class Num:
    """Число, которое на сравнение отвечает нашими TRUE/FALSE."""

    def __init__(self, v):
        self.v = v

    def gt(self, other):
        return TRUE if self.v > other.v else FALSE

    def __repr__(self):
        return str(self.v)


def abs_value(x):
    # x < 0 ifTrue: [x negated] ifFalse: [x]
    return Num(0).gt(x).if_true_if_false(lambda: Num(-x.v), lambda: x)


def noisy(name, value):
    def block():
        print(f"  вычислен блок {name}")
        return value
    return block


print("abs(-5) =", abs_value(Num(-5)))
print("abs(7)  =", abs_value(Num(7)))

print("(17 * 13 > 220) ifTrue: ... ifFalse: ...")
print(" ->", Num(17 * 13).gt(Num(220)).if_true_if_false(
    noisy("then", "bigger"), noisy("else", "smaller")))

print("false and: [...]  — блок не вычисляется:")
print(" ->", FALSE.and_(noisy("arg", TRUE)))
print("true and: [...]:")
print(" ->", TRUE.and_(noisy("arg", FALSE)))
print("true not not =", TRUE.not_().not_())
