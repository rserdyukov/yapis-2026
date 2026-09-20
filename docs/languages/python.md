---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные index.md и concepts.md сохраняются при пересборке. -->

# Python

Интерпретируемый язык с динамической проверкой типов и неявным маркером блока (отступы). Самый частый язык реализации компиляторов в практикуме курса и одна из целевых платформ (байт-код CPython).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1991 — [Wikidata P571](https://www.wikidata.org/wiki/Q28865) (получено 2026-09-18) |
| Авторы | Guido van Rossum |
| Организации | Python Software Foundation |
| Сайт | <https://www.python.org/> |
| Спецификация | <https://docs.python.org/3/reference/> |
| Внешние каталоги | [Wikidata Q28865](https://www.wikidata.org/wiki/Q28865), [PLDB](https://pldb.io/concepts/python.html), [HOPL 2126](https://hopl.info/showlanguage.prx?exp=2126), [Rosetta Code](https://rosettacode.org/wiki/Category:Python) |

## Версии { #versions }

Перечислены вехи, на которые ссылаются концепции ниже, а не все выпуски.

| Версия | Дата | Тип | Источник |
|---|---|---|---|
| Python 1.0 — первый выпуск | 1994-01-26 | выпуск | [Python documentation by version](https://www.python.org/doc/versions/) (получено 2026-09-18) |
| Python 3.5 | 2015-09-13 | выпуск | [Wikidata P348 3.5.0](https://www.wikidata.org/wiki/Q28865) (получено 2026-09-18) |
| Python 3.10 | 2021-10-04 | выпуск | [What's New In Python 3.10](https://docs.python.org/3/whatsnew/3.10.html) (получено 2026-09-18) |
| Python 3.14 — актуальная | 2025-10-07 | выпуск | [Wikidata P348 3.14.0](https://www.wikidata.org/wiki/Q28865) (получено 2026-09-18) |

## Публикации { #publications }

- Guido van Rossum. *[Python Reference Manual](https://ir.cwi.nl/pub/5008)*. CWI Report CS-R9525, Centrum voor Wiskunde en Informatica, Amsterdam, 1995.
- Guido van Rossum. *[PEP 8 — Style Guide for Python Code](https://peps.python.org/pep-0008/)*. Python Enhancement Proposals, 2001.
- Guido van Rossum, Jukka Lehtosalo, Łukasz Langa. *[PEP 484 — Type Hints](https://peps.python.org/pep-0484/)*. Python Enhancement Proposals, 2014.
- Brandt Bucher, Guido van Rossum. *[PEP 634 — Structural Pattern Matching: Specification](https://peps.python.org/pep-0634/)*. Python Enhancement Proposals, 2020.

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

### Свойства проектируемого языка { #variants }

#### Объявление переменных { #variants-1 }

*Variable declaration* · [в онтологии](concepts.md#variants-1)

- **Неявное** — переменная появляется при первом присваивании; аннотация типа (с 3.6) необязательна и интерпретатором не проверяется

```python
--8<-- "examples/python/showcase.py:variants-1"
```

#### Преобразование типов { #variants-2 }

*Type conversion* · [в онтологии](concepts.md#variants-2)

- **Явное** — вызов типа-конструктора: `int(s)`, `str(n)`
- **Неявное** — для: числовая башня и логический контекст; int → float в арифметике, любое значение → bool в условии; между строками и числами неявного приведения нет

```python
--8<-- "examples/python/showcase.py:variants-2"
```

#### Оператор присваивания { #variants-3 }

*Assignment* · [в онтологии](concepts.md#variants-3)

- **Одиночный**
- **Множественный** — распаковка кортежа: `a, b = b, a`; правая часть вычисляется целиком до присваивания

```python
--8<-- "examples/python/showcase.py:variants-3"
```

#### Структуры, ограничивающие область видимости { #variants-4 }

*Scoping constructs* · [в онтологии](concepts.md#variants-4)

- **Подпрограммы** — блоки if/for/while новую область не создают; область создают функции, классы и comprehension

```python
--8<-- "examples/python/showcase.py:variants-4"
```

#### Маркер блочного оператора { #variants-5 }

*Block delimiter* · [в онтологии](concepts.md#variants-5)

- **Неявный** — двоеточие и отступ; закрывающего символа нет

```python
--8<-- "examples/python/showcase.py:variants-5"
```

#### Условные операторы { #variants-6 }

*Conditional statements* · [в онтологии](concepts.md#variants-6)

- **Только двухвариантный if-then-else (до Python 3.10)** — до 3.10 — только if/elif/else; многовариантный выбор через словарь или цепочку elif
- **Двухвариантный и многовариантный switch-case (Python 3.10)** — `match` — сопоставление с образцом (PEP 634), а не switch по константам

```python
--8<-- "examples/python/showcase.py:variants-6"
```

#### Перегрузка подпрограмм { #variants-7 }

*Subprogram overloading* · [в онтологии](concepts.md#variants-7)

- **Отсутствует** — повторное `def` заменяет предыдущее; диспетчеризация по типу — `functools.singledispatch`

```python
--8<-- "examples/python/showcase.py:variants-7"
```

#### Передача параметров в подпрограмму { #variants-8 }

*Parameter passing* · [в онтологии](concepts.md#variants-8)

- **По ссылке на объект** — передаётся ссылка на объект: изменение изменяемого объекта видно вызывающему, перепривязка имени параметра — нет

```python
--8<-- "examples/python/showcase.py:variants-8"
```

#### Допустимое место объявления подпрограмм { #variants-9 }

*Subprogram declaration placement* · [в онтологии](concepts.md#variants-9)

- **В любом месте** — вложенные функции образуют замыкания над переменными внешней

```python
--8<-- "examples/python/showcase.py:variants-9"
```

### Обязательные требования к языку { #requirements }

#### Встроенный ввод-вывод { #req-4 }

*Built-in I/O* · [в онтологии](concepts.md#req-4)

- **Встроенные функции** — `input()` и `print()` — встроенные функции, импорт не нужен

```python
--8<-- "examples/python/showcase.py:req-4"
```

#### Цикл с постусловием until { #req-7-2-until }

*until loop* · [в онтологии](concepts.md#req-7-2-until)

- **нет** — эквивалент — `while not cond` или `while True` с `break`

```python
--8<-- "examples/python/showcase.py:req-7-2-until"
```

#### Цикл do-while { #req-7-2-do-while }

*do-while loop* · [в онтологии](concepts.md#req-7-2-do-while)

- **нет** — эквивалент — `while True` с `break` в конце тела

```python
--8<-- "examples/python/showcase.py:req-7-2-do-while"
```

#### Оператор цикла с итерациями for { #req-7-3 }

*for loop form* · [в онтологии](concepts.md#req-7-3)

- **По коллекции (foreach)** — счётный цикл — итерация по `range()`

```python
--8<-- "examples/python/showcase.py:req-7-3"
```

#### Глобальная область видимости для переменных { #req-8-2 }

*Global variables* · [в онтологии](concepts.md#req-8-2)

- **Есть глобальные переменные** — имена уровня модуля; для записи внутри функции — `global`

```python
--8<-- "examples/python/showcase.py:req-8-2"
```

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Динамическая**
- **Постепенная (Python 3.5)** — аннотации типов (PEP 484) проверяются внешними инструментами (mypy, pyright), не интерпретатором

#### Сильная и слабая типизация { #typing-strength }

*Type strength* · [в онтологии](concepts.md#typing-strength)

- **Сильная** — `'1' + 2` — TypeError; неявного приведения между строками и числами нет

#### Вывод типов { #typing-inference }

*Type inference* · [в онтологии](concepts.md#typing-inference)

- **нет** — у переменных нет статических типов, выводить нечего; статические анализаторы выводят типы из аннотаций

#### Отсутствие значения (null) { #typing-nullability }

*Nullability* · [в онтологии](concepts.md#typing-nullability)

- **null допустим в любом ссылочном типе** — `None` — обычный объект, допустим где угодно; `Optional[T]` — только аннотация

### Управление памятью { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Подсчёт ссылок** — подсчёт ссылок в CPython; объект освобождается при обнулении счётчика
- **Сборка мусора** — дополнительный сборщик для циклических ссылок (модуль `gc`)

### Парадигмы программирования { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная**
- **Процедурная**
- **Объектно-ориентированная**
- **Функциональная** — функции первого класса, замыкания, `map`/`filter`, генераторы; без хвостовой рекурсии и неизменяемости по умолчанию

### Обработка исключительных ситуаций { #errors }

#### Модель обработки ошибок { #errors-model }

*Error handling model* · [в онтологии](concepts.md#errors-model)

- **Структурная (try-throw-catch)** — try / except / else / finally; исключения — классы, иерархия от BaseException

#### Блоки с гарантированным завершением { #errors-finally }

*Guaranteed cleanup blocks* · [в онтологии](concepts.md#errors-finally)

- **да** — `finally`, а также контекстные менеджеры `with`

#### Проверяемые исключения в сигнатуре { #errors-checked }

*Checked exceptions* · [в онтологии](concepts.md#errors-checked)

- **нет**

### Подпрограммы и абстракция { #subprograms }

#### Лямбда-функции { #subprograms-lambda }

*Lambda functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да** — `lambda` — только одно выражение; многострочные замыкания — вложенный `def`

#### Обобщённые типы и подпрограммы { #subprograms-generics }

*Generics* · [в онтологии](concepts.md#subprograms-generics)

- **да (Python 3.5)** — `typing.Generic`, `TypeVar`; с 3.12 — синтаксис `def f[T](x: T)`; во время выполнения не проверяются

#### Параметры по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **да** — значение по умолчанию вычисляется один раз при определении функции

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **да**

### Синтаксическая структура { #syntax }

#### Разделитель операторов { #syntax-statement-terminator }

*Statement terminator* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Перевод строки** — `;` допустима для нескольких операторов в одной строке

#### Чувствительность к регистру { #syntax-case-sensitive }

*Case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да**

#### Совмещение имён (shadowing) { #syntax-shadowing }

*Shadowing* · [в онтологии](concepts.md#syntax-shadowing)

- **Разрешено во вложенной области** — вложенная функция может переопределить имя внешней; предупреждений нет
- **Разрешено даже в той же области** — повторное присваивание — это перепривязка того же имени, а не новое объявление

## Грамматика { #grammar }

Официальная грамматика: <https://docs.python.org/3/reference/grammar.html>.

Фрагменты ниже взяты из сообщества grammars-v4 и **не являются нормативными**: они иллюстрируют, как правила записываются в нотации ANTLR4, которую вы используете в лабораторной работе 2. Нетерминалы, упомянутые в правиле, перечислены под ним со ссылкой на полный файл.

### `tokens` { #rule-tokens }

```antlr
--8<-- "grammar/python/PythonParser.fragments.g4:tokens"
```

Источник: [`python/python3_14/PythonLexer.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonLexer.g4#L35), MIT.

### `block` { #rule-block }

```antlr
--8<-- "grammar/python/PythonParser.fragments.g4:block"
```

Источник: [`python/python3_14/PythonParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4#L185), MIT. Нетерминалы: [`statements`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`simple_stmts`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4).

### `assignment` { #rule-assignment }

```antlr
--8<-- "grammar/python/PythonParser.fragments.g4:assignment"
```

Источник: [`python/python3_14/PythonParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4#L98), MIT. Нетерминалы: [`name`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`annotated_rhs`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`single_target`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`single_subscript_attribute_target`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`star_targets`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`augassign`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4).

### `if_stmt` { #rule-if_stmt }

```antlr
--8<-- "grammar/python/PythonParser.fragments.g4:if_stmt"
```

Источник: [`python/python3_14/PythonParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4#L278), MIT. Нетерминалы: [`named_expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`block`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`elif_stmt`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`else_block`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4).

### `match_stmt` { #rule-match_stmt }

```antlr
--8<-- "grammar/python/PythonParser.fragments.g4:match_stmt"
```

Источник: [`python/python3_14/PythonParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4#L340), MIT. Нетерминалы: [`subject_expr`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`case_block`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4).

### `while_stmt` { #rule-while_stmt }

```antlr
--8<-- "grammar/python/PythonParser.fragments.g4:while_stmt"
```

Источник: [`python/python3_14/PythonParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4#L290), MIT. Нетерминалы: [`named_expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`block`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`else_block`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4).

### `for_stmt` { #rule-for_stmt }

```antlr
--8<-- "grammar/python/PythonParser.fragments.g4:for_stmt"
```

Источник: [`python/python3_14/PythonParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4#L296), MIT. Нетерминалы: [`star_targets`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`star_expressions`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`block`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`else_block`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4).

### `function_def_raw` { #rule-function_def_raw }

```antlr
--8<-- "grammar/python/PythonParser.fragments.g4:function_def_raw"
```

Источник: [`python/python3_14/PythonParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4#L208), MIT. Нетерминалы: [`name`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`type_params`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`params`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`func_type_comment`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4), [`block`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/python/python3_14/PythonParser.g4).

### Лицензия источника { #grammar-license }

`antlr/grammars-v4` / `python/python3_14/PythonLexer.g4` @ `20efa5375866` — MIT:

```text
--8<-- "grammar/python/PythonParser.fragments.g4:notice"
```

Другие грамматики и материалы:

- [Официальная PEG-грамматика (Grammar/python.gram)](https://github.com/python/cpython/blob/main/Grammar/python.gram)
- [Grammar Zoo: Python](https://slebok.github.io/zoo/index.html#python)
- [Rosetta Code: Python](https://rosettacode.org/wiki/Category:Python)

## Пример-витрина { #showcase }

Одна программа, в которой прокомментированы конструкции, соответствующие концепциям каталога — тот же формат, что у второго примера в лабораторной работе 1. Фрагменты этого файла показаны выше у каждой концепции.

```python
--8<-- "examples/python/showcase.py"
```

## Оценка по критериям лекции 20 { #assessment }

Критерии — читабельность, лёгкость создания, надёжность, стоимость. Это оценки, а не свойства: они выводятся из концепций, на которые ссылается каждый пункт.

**Читабельность.** Отступы вместо скобок и минимум служебных слов делают код коротким и единообразным; отсутствие типов в сигнатурах затрудняет чтение больших программ, аннотации частично это компенсируют. *([Маркер блочного оператора](#variants-5), [Объявление переменных](#variants-1), [Проверка типов](#typing-checking))*

**Лёгкость создания.** Неявное объявление, множественное присваивание, встроенные коллекции и ввод-вывод без импорта — программа пишется быстро; ошибки типов откладываются до запуска. *([Объявление переменных](#variants-1), [Оператор присваивания](#variants-3), [Встроенный ввод-вывод](#req-4))*

**Надёжность.** Сильная типизация ловит смешение строк и чисел, но только во время выполнения; надёжность держится на тестах и внешних проверках аннотаций. Исключения структурные, с `finally` и `with`. *([Проверка типов](#typing-checking), [Сильная и слабая типизация](#typing-strength), [Модель обработки ошибок](#errors-model), [Блоки с гарантированным завершением](#errors-finally))*

**Стоимость.** Низкий порог входа, огромная экосистема; цена — скорость выполнения и расходы на тесты вместо компилятора. *([Освобождение памяти](#memory-management))*
