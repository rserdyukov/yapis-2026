---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Python

Интерпретируемый язык с динамической проверкой типов и неявным маркером блока (отступы). Самый частый язык реализации компиляторов в практикуме курса и одна из целевых платформ (байт-код CPython).

*Карточка полная: 50/74 понятий; пример, грамматика, оценка* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1991 — [Wikidata P571](https://www.wikidata.org/wiki/Q28865) (получено 2026-09-18) |
| Авторы | [Гвидо ван Россум](people.md#van-rossum) |
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

## Статьи { #articles }

- [Lua: метатаблицы, язык как конструктор](../garden/lua-metatables.md)
- [Smalltalk: всё есть сообщение](../garden/smalltalk-messages.md)

## Люди { #people }

- [Гвидо ван Россум](people.md#van-rossum) — Автор Python; руководил развитием языка до 2018 года.

## Публикации { #publications }

- Guido van Rossum. *[Python Reference Manual](https://ir.cwi.nl/pub/5008)*. CWI Report CS-R9525, Centrum voor Wiskunde en Informatica, Amsterdam, 1995.
- Guido van Rossum. *[PEP 8 — Style Guide for Python Code](https://peps.python.org/pep-0008/)*. Python Enhancement Proposals, 2001.
- Guido van Rossum, Jukka Lehtosalo, Łukasz Langa. *[PEP 484 — Type Hints](https://peps.python.org/pep-0484/)*. Python Enhancement Proposals, 2014.
- Brandt Bucher, Guido van Rossum. *[PEP 634 — Structural Pattern Matching: Specification](https://peps.python.org/pep-0634/)*. Python Enhancement Proposals, 2020.
- [Модуль dis](https://docs.python.org/3/library/dis.html). Инструкции байт-кода CPython и дизассемблер. ([в источниках](sources.md#python-dis))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **python314** — Python 3.14; базовый профиль языка и стандартной библиотеки. Исторические границы и контексты runtime/static_analysis отмечены отдельно.
- **runtime** — Семантика выполнения Python без внешней статической проверки.
- **static_analysis** — Аннотированный Python при проверке mypy или Pyright.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Связывание присваиванием (layer: language, profile: python314)** — переменная появляется при первом присваивании; аннотация типа (с 3.6) необязательна и интерпретатором не проверяется
- **Связывание образцом (с Python 3.10 включительно, layer: language, profile: python314, applies_to: захватывающие образцы match)**

```python
--8<-- "examples/python/showcase.py:variants-1"
```

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: python314)** — повторное присваивание связывает то же имя с новым объектом, не создавая same-scope shadowing

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: python314)**
- **Распаковка при присваивании (layer: language, profile: python314)** — распаковка кортежа: `a, b = b, a`; правая часть вычисляется целиком до присваивания

```python
--8<-- "examples/python/showcase.py:variants-3"
```

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: python314)** — область класса имеет особые правила и не служит замыкающим окружением методов

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Подпрограмма (layer: language, profile: python314)**
- **Модуль (layer: language, profile: python314)**
- **Класс (layer: language, profile: python314)**
- **Генераторная конструкция (layer: language, profile: python314)** — в Python 3 переменная обхода comprehension локальна; if/for/while отдельной области не создают

```python
--8<-- "examples/python/showcase.py:variants-4"
```

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

*Top-level bindings* · [в онтологии](concepts.md#scope-globals)

- **Имена модуля (layer: language, profile: python314)** — имена уровня модуля; для записи внутри функции — `global`

```python
--8<-- "examples/python/showcase.py:req-8-2"
```

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

*Name shadowing* · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: python314)** — локальное имя вложенной функции может скрыть внешнее; повторное присваивание в одной области — перепривязка

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Динамическая (layer: language, profile: runtime)**
- **Постепенная (с Python 3.5 включительно, layer: tooling, profile: static_analysis)** — аннотации типов (PEP 484) проверяются внешними инструментами (mypy, pyright), не интерпретатором

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Необязательны (layer: language, profile: python314)** — аннотации не обеспечивают проверку типов во время выполнения

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **нет (layer: language, profile: runtime)** — интерпретатор не выводит статические типы имён
- **да (layer: tooling, profile: static_analysis)** — анализатор выводит типы из выражений и потока управления, учитывая аннотации

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: python314)** — вызов типа-конструктора: `int(s)`, `str(n)`
- **Неявные (layer: language, profile: python314, applies_to: смешанная числовая арифметика)** — int → float при смешанной арифметике может терять точность или вызывать OverflowError. Проверка истинности — отдельный протокол, не перепривязка объекта к bool; строки и числа автоматически не складываются.

```python
--8<-- "examples/python/showcase.py:variants-2"
```

#### Совместимость типов { #typing-compatibility }

*Type compatibility* · [в онтологии](concepts.md#typing-compatibility)

- **По доступным операциям во время выполнения (layer: language, profile: runtime)**
- **Номинальная (layer: tooling, profile: static_analysis, applies_to: обычные классы)**
- **Структурная (layer: tooling, profile: static_analysis, applies_to: typing.Protocol)**

#### Типы-суммы { #typing-sum-types }

*Sum types* · [в онтологии](concepts.md#typing-sum-types)

- **Объединения типов (layer: tooling, profile: static_analysis)** — Union[T, U] или T | U описывают тип для анализатора, не проверяют значение при присваивании

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Кортежи (layer: language, profile: python314)**

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Специальное значение (layer: language, profile: runtime)** — имя может быть связано с None, но операции над None могут быть недопустимы
- **Явно nullable-типы (layer: tooling, profile: static_analysis)** — T | None / Optional[T] явно допускает None; при строгой проверке T сам по себе его не допускает

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: python314)**
- **Условное выражение (layer: language, profile: python314)** — `a if condition else b`

```python
--8<-- "examples/python/showcase.py:variants-6"
```

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **нет (layer: language, profile: python314)**

#### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **нет (до Python 3.10 исключительно, layer: language, profile: python314)**
- **да (с Python 3.10 включительно, layer: language, profile: python314)** — `match` — сопоставление с образцом (PEP 634), а не switch по константам

<a id="req-7-2-until"></a>

#### Цикл до истинности условия { #control-until }

*Until loop* · [в онтологии](concepts.md#control-until)

- **Отдельная конструкция отсутствует (layer: language, profile: python314)** — Предусловие: `while not cond`; постусловие: `while True` с `if cond: break` после тела.

```python
--8<-- "examples/python/showcase.py:req-7-2-until"
```

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · [в онтологии](concepts.md#control-do-while)

- **нет (layer: language, profile: python314)** — эквивалент — `while True` с `break` в конце тела

```python
--8<-- "examples/python/showcase.py:req-7-2-do-while"
```

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **По последовательности или итератору (layer: language, profile: python314)** — счётный цикл — итерация по `range()`
- **Генераторная конструкция (layer: language, profile: python314)**

```python
--8<-- "examples/python/showcase.py:req-7-3"
```

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: python314)** — повторное `def` заменяет предыдущее; диспетчеризация по типу — `functools.singledispatch`

```python
--8<-- "examples/python/showcase.py:variants-7"
```

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **Разделение объекта (layer: language, profile: python314)** — передаётся ссылка на объект: изменение изменяемого объекта видно вызывающему, перепривязка имени параметра — нет

```python
--8<-- "examples/python/showcase.py:variants-8"
```

<a id="variants-9"></a>

#### Место определения подпрограмм { #subprograms-placement }

*Subprogram definition placement* · [в онтологии](concepts.md#subprograms-placement)

- **Верхний уровень модуля (layer: language, profile: python314)**
- **Член типа (layer: language, profile: python314)**
- **Локальное определение (layer: language, profile: python314)** — вложенные функции образуют замыкания над переменными внешней

```python
--8<-- "examples/python/showcase.py:variants-9"
```

#### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms* · [в онтологии](concepts.md#subprograms-nesting)

- **да (layer: language, profile: python314)**

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: python314)**

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: python314)** — `lambda` — только одно выражение; многострочные замыкания — вложенный `def`

#### Параметрический полиморфизм { #subprograms-generics }

*Parametric polymorphism* · [в онтологии](concepts.md#subprograms-generics)

- **да (с Python 3.5 включительно, layer: tooling, profile: static_analysis)** — `typing.Generic`, `TypeVar`; с 3.12 — синтаксис `def f[T](x: T)`; во время выполнения не проверяются

#### Аргументы по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **да (layer: language, profile: python314)** — значение по умолчанию вычисляется один раз при определении функции

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **да (layer: language, profile: python314)**

### Полиморфизм и организация { #abstraction }

#### Контракты полиморфизма { #abstraction-contracts }

*Polymorphic contracts* · [в онтологии](concepts.md#abstraction-contracts)

- **Структурные протоколы (layer: tooling, profile: static_analysis, applies_to: typing.Protocol)**

#### Диспетчеризация вызовов { #abstraction-dispatch }

*Call dispatch* · [в онтологии](concepts.md#abstraction-dispatch)

- **По одному динамическому типу (layer: language, profile: python314, applies_to: поиск метода по классу получателя)**
- **По одному динамическому типу (layer: standard_library, profile: python314, applies_to: functools.singledispatch по первому аргументу)**

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Множественное (layer: language, profile: python314)**

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Пространства имён и пакеты (layer: language, profile: python314)**
- **Модули как объекты времени выполнения (layer: language, profile: python314)**

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: python314)** — аргументы функции вычисляются перед вызовом; генераторы откладывают выполнение собственного тела

#### Контроль эффектов { #evaluation-effects }

*Effect control* · [в онтологии](concepts.md#evaluation-effects)

- **Без общего статического разделения эффектов (layer: language, profile: python314)**

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · [в онтологии](concepts.md#evaluation-tail-calls)

- **нет (layer: language, profile: python314)**

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Подсчёт ссылок (layer: implementation, profile: python314, implementation: CPython)** — подсчёт ссылок; детали отложенного освобождения и бессмертных объектов зависят от версии и сборки, это не гарантия языка Python
- **Трассирующая сборка мусора (layer: implementation, profile: python314, implementation: CPython)** — дополнительный сборщик для циклических ссылок (модуль `gc`)

#### Передача и разделение владения { #memory-transfer }

*Ownership transfer and sharing* · [в онтологии](concepts.md#memory-transfer)

- **Разделяемая ссылка на объект (layer: language, profile: python314)**

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: language, profile: python314)** — try / except / else / finally; исключения — классы, иерархия от BaseException

<a id="errors-checked"></a>

#### Проверяемые исключения { #errors-checked-exceptions }

*Checked exceptions* · [в онтологии](concepts.md#errors-checked-exceptions)

- **нет (layer: language, profile: python314)**

#### Диагностика неиспользованного результата { #errors-must-use }

*Unused-result diagnostics* · [в онтологии](concepts.md#errors-must-use)

- **Нет специальной диагностики (layer: language, profile: runtime)**

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Блок finally / unwind-protect (layer: language, profile: python314)**
- **Контекстный менеджер (layer: language, profile: python314)** — with вызывает __exit__ при обычном выходе и исключении; аварийное завершение процесса может пропустить очистку

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

*I/O interface* · [в онтологии](concepts.md#resources-io)

- **Встроенные функции (layer: standard_library, profile: python314)** — `input()` и `print()` — встроенные функции, импорт не нужен

```python
--8<-- "examples/python/showcase.py:req-4"
```

#### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · [в онтологии](concepts.md#resources-concurrency)

- **Асинхронные корутины (с Python 3.5 включительно, layer: language, profile: python314)**
- **Потоки (layer: standard_library, profile: python314)**
- **Процессы (layer: standard_library, profile: python314)**

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Значимые отступы (layer: language, profile: python314)** — двоеточие и отступ; закрывающего символа нет

```python
--8<-- "examples/python/showcase.py:variants-5"
```

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Перевод строки (layer: language, profile: python314)** — `;` допустима для нескольких операторов в одной строке

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да (layer: language, profile: python314)**

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Рефлексия (layer: language, profile: python314)**
- **Построение и выполнение кода (layer: language, profile: python314)** — eval, exec, создание классов и метаклассы

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: python314)**
- **Процедурная (layer: language, profile: python314)**
- **Объектно-ориентированная (layer: language, profile: python314)**
- **Функциональная (layer: language, profile: python314)** — функции первого класса, замыкания, `map`/`filter`, генераторы; без гарантированного устранения хвостовых вызовов

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

**Читабельность.** Отступы вместо скобок и минимум служебных слов делают код коротким и единообразным; отсутствие типов в сигнатурах затрудняет чтение больших программ, аннотации частично это компенсируют. *([Границы синтаксических групп](#syntax-blocks), [Введение связывания](#bindings-introduction), [Аннотации типов](#typing-annotations))*

**Лёгкость создания.** Неявное объявление, множественное присваивание, встроенные коллекции и ввод-вывод без импорта — программа пишется быстро; ошибки типов откладываются до запуска. *([Введение связывания](#bindings-introduction), [Формы присваивания и связывания](#bindings-assignment), [Интерфейс ввода-вывода](#resources-io))*

**Надёжность.** Попытка сложения строки и числа вызывает TypeError во время выполнения; надёжность держится на тестах и внешних проверках аннотаций. Исключения структурные, с `finally` и `with`. *([Проверка типов](#typing-checking), [Преобразования типов](#typing-conversions), [Представление и передача ошибок](#errors-model), [Освобождение ресурсов](#resources-cleanup))*

**Стоимость.** Низкий порог входа, огромная экосистема; цена — скорость выполнения и расходы на тесты вместо компилятора. *([Освобождение памяти](#memory-management))*
