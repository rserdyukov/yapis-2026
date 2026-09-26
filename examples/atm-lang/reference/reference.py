# reference.py — эталон из карточки задачи «Диалог банкомата», раздел 2.
#
# Оракул для тестов: tests/test_scenarios.py прогоняет каждый сценарий из
# scenarios/ здесь и в скомпилированном WASM и требует совпадения вывода.
# Логика ниже перенесена из карточки без изменений; добавлены только чтение
# сценария и печать.
#
#   python3 reference/reference.py scenarios/01_success.events

import sys

CORRECT_PIN = "4321"
MAX_ATTEMPTS = 3
START_BALANCE = 5000

# =====================================================================
# B: ПОСТАНОВКА — это должно стать читаемой программой на вашем языке
# =====================================================================

INITIAL_STATE = "Idle"
TERMINAL_STATE = "Idle"

TRANSITIONS = [
    # состояние     событие        guard                                            действие         новое состояние
    ("Idle",       "insert_card", lambda c, p: True,                                "prompt_pin",    "PinWait"),
    ("PinWait",    "pin",         lambda c, p: p == CORRECT_PIN,                    "greet",         "Menu"),
    ("PinWait",    "pin",         lambda c, p: c["attempts"] + 1 >= MAX_ATTEMPTS,   "capture_card",  "Captured"),
    ("PinWait",    "pin",         lambda c, p: True,                                "count_attempt", "PinWait"),
    ("PinWait",    "cancel",      lambda c, p: True,                                "eject_card",    "Ejecting"),
    ("PinWait",    "timeout",     lambda c, p: True,                                "eject_card",    "Ejecting"),
    ("Menu",       "withdraw",    lambda c, p: p <= c["balance"],                   "dispense",      "Dispensing"),
    ("Menu",       "withdraw",    lambda c, p: True,                                "refuse",        "Menu"),
    ("Menu",       "cancel",      lambda c, p: True,                                "eject_card",    "Ejecting"),
    ("Menu",       "timeout",     lambda c, p: True,                                "eject_card",    "Ejecting"),
    ("Dispensing", "cash_taken",  lambda c, p: True,                                "eject_card",    "Ejecting"),
    ("Dispensing", "timeout",     lambda c, p: True,                                "retract_cash",  "Ejecting"),
    ("Ejecting",   "card_taken",  lambda c, p: True,                                "reset",         "Idle"),
    ("Ejecting",   "timeout",     lambda c, p: True,                                "capture_card",  "Captured"),
    ("Captured",   "service",     lambda c, p: True,                                "reset",         "Idle"),
]

# =====================================================================
# A: АЛГОРИТМ — это должно уехать внутрь вашего языка
# =====================================================================

def new_context():
    return {"attempts": 0, "balance": START_BALANCE, "log": []}


def do_action(name, ctx, payload):
    log = ctx["log"].append
    if name == "prompt_pin":
        ctx["attempts"] = 0
        log("Введите PIN")
    elif name == "count_attempt":
        ctx["attempts"] += 1
        log("Неверный PIN. Осталось попыток: %d" % (MAX_ATTEMPTS - ctx["attempts"]))
    elif name == "greet":
        log("Здравствуйте! Выберите операцию")
    elif name == "capture_card":
        log("Карта изъята")
    elif name == "eject_card":
        log("Заберите карту")
    elif name == "dispense":
        ctx["balance"] -= payload
        log("Выдано %d руб. Остаток %d руб." % (payload, ctx["balance"]))
    elif name == "refuse":
        log("Недостаточно средств")
    elif name == "retract_cash":
        log("Наличные забраны обратно")
    elif name == "reset":
        ctx["attempts"] = 0
        log("Готов к работе")
    else:
        raise RuntimeError("неизвестное действие: " + name)


def step(state, event, payload, ctx):
    for (s, e, guard, action, nxt) in TRANSITIONS:
        if s == state and e == event and guard(ctx, payload):
            do_action(action, ctx, payload)
            return nxt
    ctx["log"].append("[игнор] %s в состоянии %s" % (event, state))
    return state


def run(events):
    ctx = new_context()
    state = INITIAL_STATE
    for event, payload in events:
        state = step(state, event, payload, ctx)
    return state, ctx


# =====================================================================
# Обвязка: чтение сценария
# =====================================================================

def parse_scenario(text):
    """Строка сценария: `событие [аргумент]`; `#` — комментарий.
    Числовой аргумент — int, остальное — строка (PIN всегда строка)."""
    events = []
    for line in text.splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        name, _, arg = line.partition(" ")
        arg = arg.strip()
        if name == "withdraw":
            events.append((name, int(arg)))
        else:
            events.append((name, arg or None))
    return events


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as f:
        final, ctx = run(parse_scenario(f.read()))
    for line in ctx["log"]:
        # Игнорируемые события эталон пишет в протокол; язык FSM
        # игнорирует их молча (явный `ignore`), поэтому в сравнении их нет.
        if not line.startswith("[игнор]"):
            print(line)
    print("Итоговое состояние: " + final)
