# Аналог doesNotUnderstand: в Python: __getattr__ вызывается,
# только когда обычный поиск атрибута не нашёл имя.


class LoggingProxy:
    def __init__(self, subject):
        # пишем в __dict__ напрямую, чтобы не зациклиться на собственных полях
        self.__dict__["_subject"] = subject
        self.__dict__["invocation_count"] = 0

    def __getattr__(self, name):          # «сообщение не понято»
        attr = getattr(self._subject, name)
        if not callable(attr):
            return attr

        def forward(*args):
            self.__dict__["invocation_count"] += 1
            print(f"performing {name}({', '.join(map(repr, args))})")
            return attr(*args)            # aMessage sendTo: subject
        return forward


p = LoggingProxy([])
p.append(3)
p.append(4)
print("count(3) =", p.count(3))
print("invocation_count =", p.invocation_count)   # найден обычным поиском

# Ограничение: неявные вызовы спецметодов ищутся в классе, а не через __getattr__
try:
    print(len(p))
except TypeError as e:
    print("len(p):", e)
