---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Lua

Lua — компактный встраиваемый язык с динамической типизацией, в котором таблицы — единственный механизм структурирования данных, а метатаблицы позволяют переопределять операции и строить объекты и наследование. Функции первого класса с лексическими замыканиями, асимметричные корутины и гарантированные хвостовые вызовы входят в ядро языка. Описан срез по Lua 5.4 Reference Manual и эталонной реализации PUC-Rio Lua; LuaJIT и другие реализации не рассматриваются.

*Карточка сравнительная: 38/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1993 — [Wikidata P571](https://www.wikidata.org/wiki/Q207316) (получено 2026-09-25) |
| Авторы | [Роберту Иерузалимски](people.md#ierusalimschy) |
| Организации | PUC-Rio |
| Сайт | <https://www.lua.org/> |
| Спецификация | <https://www.lua.org/manual/5.4/manual.html> |
| Внешние каталоги | [Wikidata Q207316](https://www.wikidata.org/wiki/Q207316) |

## Версии { #versions }

Перечислены вехи, на которые ссылаются концепции ниже, а не все выпуски.

| Версия | Дата | Тип | Источник |
|---|---|---|---|
| Lua 1.1 — первый выпуск | 1994-07-08 | выпуск | [Lua — version history: first public release](https://www.lua.org/versions.html) (получено 2026-09-25) |
| Lua 5.3 | 2015-01-12 | выпуск | [Lua — version history](https://www.lua.org/versions.html) (получено 2026-09-25) |
| Lua 5.4 | 2020-06-29 | выпуск | [Lua — version history](https://www.lua.org/versions.html) (получено 2026-09-25) |
| Lua 5.5 — актуальная | 2025-12-22 | выпуск | [Lua — version history](https://www.lua.org/versions.html) (получено 2026-09-25) |

## Статьи { #articles }

- [Lua: метатаблицы, язык как конструктор](../garden/lua-metatables.md)

## Люди { #people }

- [Роберту Иерузалимски](people.md#ierusalimschy) — Ведущий архитектор Lua в PUC-Rio и автор книги «Programming in Lua».

## Публикации { #publications }

- Роберту Иерузалимски, Luiz Henrique de Figueiredo, Waldemar Celes. *The Evolution of Lua*. HOPL III, 2007. DOI: [10.1145/1238844.1238846](https://doi.org/10.1145/1238844.1238846). Авторы объясняют, почему таблицы и метатаблицы стали единственным механизмом структурирования в Lua. ([в источниках](sources.md#hopl-lua))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **lua54** — Lua 5.4 Reference Manual и стандартные библиотеки; эталонная реализация — PUC-Rio Lua 5.4. Отличия Lua 5.5 не рассматриваются; примеры статьи сада о метатаблицах проверены на Lua 5.5.1, где использованные механизмы совпадают с 5.4.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: lua54, applies_to: локальные переменные)** — `local x = 1` объявляет локальную переменную; параметры функций и переменные циклов `for` тоже локальны. ([Lua 5.4 manual §3.3.7 — Local Declarations](https://www.lua.org/manual/5.4/manual.html#3.3.7))
- **Связывание присваиванием (layer: language, profile: lua54, applies_to: глобальные переменные)** — Присваивание необъявленному имени создаёт поле в таблице окружения `_ENV`; чтение необъявленного имени даёт `nil`, а не ошибку. ([Lua 5.4 manual §2.2 — Environments and the Global Environment](https://www.lua.org/manual/5.4/manual.html#2.2); [Lua 5.4 manual §3.2 — Variables](https://www.lua.org/manual/5.4/manual.html#3.2))

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: lua54)** — Переменная может получить значение любого типа.
- **Неизменяемое (с Lua 5.4 включительно, layer: language, profile: lua54, applies_to: локальные с атрибутом `<const>` или `<close>`)** — Присваивание такой переменной после инициализации — ошибка компиляции; изменяемость таблицы, на которую она ссылается, не ограничивается. ([Lua 5.4 manual §3.3.7 — Local Declarations](https://www.lua.org/manual/5.4/manual.html#3.3.7))

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: lua54)**
- **Распаковка при присваивании (layer: language, profile: lua54)** — `a, b = b, a`: все выражения вычисляются до присваиваний; лишние значения отбрасываются, недостающие заполняются `nil`. Вызов в конце списка раскрывается во все свои результаты. ([Lua 5.4 manual §3.3.3 — Assignment](https://www.lua.org/manual/5.4/manual.html#3.3.3); [Lua 5.4 manual §3.4.12 — Lists of expressions, multiple results, and adjustment](https://www.lua.org/manual/5.4/manual.html#3.4.12))

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: lua54)** — Локальные переменные видны от объявления до конца самого внутреннего блока; вложенные функции обращаются к ним как к upvalue. ([Lua 5.4 manual §3.5 — Visibility Rules](https://www.lua.org/manual/5.4/manual.html#3.5))

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Блок (layer: language, profile: lua54)** — `do … end`, тела циклов, ветви `if`, тела функций; чанк (файл или строка кода) тоже блок. ([Lua 5.4 manual §3.3.1 — Blocks](https://www.lua.org/manual/5.4/manual.html#3.3.1))
- **Подпрограмма (layer: language, profile: lua54)**

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

*Top-level bindings* · [в онтологии](concepts.md#scope-globals)

- **Глобальные переменные (layer: language, profile: lua54)** — Глобальные переменные — поля таблицы `_ENV`, по умолчанию разделяемой глобальной таблицы `_G`; чанк может подменить `_ENV` и изолировать свои глобалы. ([Lua 5.4 manual §2.2 — Environments and the Global Environment](https://www.lua.org/manual/5.4/manual.html#2.2))

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

*Name shadowing* · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: lua54)**
- **Новое связывание в той же области (layer: language, profile: lua54)** — Повторный `local x` в том же блоке вводит новую переменную; замыкания, созданные ранее, продолжают ссылаться на прежнюю. ([Lua 5.4 manual §3.5 — Visibility Rules](https://www.lua.org/manual/5.4/manual.html#3.5))

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Динамическая (layer: language, profile: lua54)** — Типы имеют значения, а не переменные; восемь базовых типов: nil, boolean, number, string, function, userdata, thread, table. ([Lua 5.4 manual §2.1 — Values and Types](https://www.lua.org/manual/5.4/manual.html#2.1))

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Неявные (layer: language, profile: lua54)** — Строка приводится к числу в арифметике, число к строке при конкатенации `..`; целое и вещественное преобразуются друг в друга при смешанной арифметике. Сравнение `==` строки и числа всегда ложно. ([Lua 5.4 manual §3.4.3 — Coercions and Conversions](https://www.lua.org/manual/5.4/manual.html#3.4.3))
- **Явные (layer: standard_library, profile: lua54)** — `tonumber`, `tostring`, `math.tointeger`.

#### Совместимость типов { #typing-compatibility }

*Type compatibility* · [в онтологии](concepts.md#typing-compatibility)

- **По доступным операциям во время выполнения (layer: language, profile: lua54)** — Допустимость операции определяется во время выполнения типом значения или наличием метаметода (`__add`, `__index`, `__call` и др.). ([Lua 5.4 manual §2.4 — Metatables and Metamethods](https://www.lua.org/manual/5.4/manual.html#2.4))

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Записи и структуры (layer: language, profile: lua54)** — Записи — таблицы со строковыми ключами: `p.x` — синтаксический сахар для `p["x"]`. Отдельных типов struct или кортежей нет; массивы, множества и объекты тоже строятся из таблиц. ([Lua 5.4 manual §2.1 — Values and Types](https://www.lua.org/manual/5.4/manual.html#2.1); [Lua 5.4 manual §3.4.9 — Table Constructors](https://www.lua.org/manual/5.4/manual.html#3.4.9))

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Nullable-ссылки по умолчанию (layer: language, profile: lua54)** — Любая переменная или поле может содержать `nil`; отсутствующий ключ таблицы читается как `nil`, а присваивание `nil` удаляет поле. Ложны только `nil` и `false`, число 0 и пустая строка истинны. ([Lua 5.4 manual §2.1 — Values and Types](https://www.lua.org/manual/5.4/manual.html#2.1))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: lua54)** — `if … then … elseif … else … end`. Условного выражения нет; идиома `c and a or b` ошибается, если `a` ложно. ([Lua 5.4 manual §3.3.4 — Control Structures](https://www.lua.org/manual/5.4/manual.html#3.3.4))

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **нет (layer: language, profile: lua54)** — Выбор по значению выражают цепочкой `elseif` или таблицей обработчиков.

<a id="req-7-2-until"></a>

#### Цикл до истинности условия { #control-until }

*Until loop* · [в онтологии](concepts.md#control-until)

- **Проверка после тела (layer: language, profile: lua54)** — `repeat … until cond` проверяет условие после тела; в условии видны локальные переменные тела. ([Lua 5.4 manual §3.3.4 — Control Structures](https://www.lua.org/manual/5.4/manual.html#3.3.4))

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · [в онтологии](concepts.md#control-do-while)

- **нет (layer: language, profile: lua54)** — Цикл с постусловием есть только в форме `repeat … until` с обратной полярностью условия.

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **По последовательности или итератору (layer: language, profile: lua54)** — Общий `for k, v in explist do` вызывает функцию-итератор до получения `nil`; `pairs`/`ipairs` — библиотечные итераторы. Числовой `for i = a, b, step do` вычисляет границы один раз и не является C-подобным циклом с произвольными условием и шагом. ([Lua 5.4 manual §3.3.5 — For Statement](https://www.lua.org/manual/5.4/manual.html#3.3.5); [Lua 5.4 manual — pairs](https://www.lua.org/manual/5.4/manual.html#pdf-pairs))

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: lua54)** — Одно имя связано с одним значением-функцией; разбор аргументов по типу и числу выполняется в теле вручную.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **Разделение объекта (layer: language, profile: lua54)** — Таблицы, функции, корутины и full userdata передаются как ссылки без копирования; изменение таблицы видно вызывающему, но присваивание параметру — нет. Числа и строки неизменяемы. ([Lua 5.4 manual §2.1 — Values and Types](https://www.lua.org/manual/5.4/manual.html#2.1))

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: lua54)** — Вложенная функция захватывает внешние локальные переменные как upvalue: разделяет саму переменную, а не копию значения; каждое выполнение `local` создаёт новую переменную. ([Lua 5.4 manual §3.5 — Visibility Rules](https://www.lua.org/manual/5.4/manual.html#3.5))

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: lua54)** — `function (x) return x * 2 end` — выражение; все функции Lua анонимны, имя — лишь переменная.

#### Аргументы по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **нет (layer: language, profile: lua54)** — Недостающие аргументы получают `nil`; значение по умолчанию задают идиомой `x = x or default`. ([Lua 5.4 manual §3.4.11 — Function Definitions](https://www.lua.org/manual/5.4/manual.html#3.4.11))

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **нет (layer: language, profile: lua54)** — Имитируются передачей таблицы: `f{name = "x", size = 2}` — вызов с одним аргументом-таблицей.

### Полиморфизм и организация { #abstraction }

#### Диспетчеризация вызовов { #abstraction-dispatch }

*Call dispatch* · [в онтологии](concepts.md#abstraction-dispatch)

- **По одному динамическому типу (layer: language, profile: lua54)** — `obj:method(a)` — сахар для `obj.method(obj, a)`; метод ищется в самом объекте, затем через метаметод `__index`, то есть выбор зависит только от получателя. ([Lua 5.4 manual §3.4.10 — Function Calls](https://www.lua.org/manual/5.4/manual.html#3.4.10); [Lua 5.4 manual §2.4 — Metatables and Metamethods](https://www.lua.org/manual/5.4/manual.html#2.4))

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Одиночное (layer: language, profile: lua54, applies_to: соглашение через цепочку `__index` метатаблиц)** — Классов и наследования в синтаксисе нет: прототипное делегирование строят, задавая `__index` метатаблицы на таблицу-прототип. Множественное наследование возможно, если `__index` — функция, ищущая в нескольких родителях. ([Lua 5.4 manual §2.4 — Metatables and Metamethods](https://www.lua.org/manual/5.4/manual.html#2.4))

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Модули как объекты времени выполнения (layer: standard_library, profile: lua54)** — `require` загружает чанк один раз и кэширует возвращённое значение (обычно таблицу) в `package.loaded`; модуль — обычная таблица, экспорт — её поля. ([Lua 5.4 manual §6.3 — Modules](https://www.lua.org/manual/5.4/manual.html#6.3))

### Вычисление и эффекты { #evaluation }

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · [в онтологии](concepts.md#evaluation-tail-calls)

- **да (layer: language, profile: lua54)** — Вызов вида `return f(args)` — хвостовой: вызываемая функция переиспользует стековый кадр, число вложенных хвостовых вызовов не ограничено. `return (f(x))` и `return f(x) + 1` хвостовыми не являются. ([Lua 5.4 manual §3.4.10 — Function Calls](https://www.lua.org/manual/5.4/manual.html#3.4.10))

#### Протокол выдачи и возобновления результатов { #evaluation-result-protocol }

*Result and resumption protocol* · [в онтологии](concepts.md#evaluation-result-protocol)

- **Обычный возврат результата вызова (layer: language, profile: lua54)** — Функция может вернуть несколько значений одним `return`; это не поток альтернатив.
- **Явное возобновление генератора или корутины (layer: standard_library, profile: lua54)** — `coroutine.resume` продолжает корутину до следующего `coroutine.yield` или завершения; `coroutine.wrap` превращает корутину в функцию-итератор. Корутины асимметричные и не являются продолжениями первого класса. ([Lua 5.4 manual §2.6 — Coroutines](https://www.lua.org/manual/5.4/manual.html#2.6); [Lua 5.4 manual §6.2 — Coroutine Manipulation](https://www.lua.org/manual/5.4/manual.html#6.2))

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Трассирующая сборка мусора (layer: language, profile: lua54)** — Автоматическое управление памятью; в Lua 5.4 сборщик работает в инкрементальном или поколенческом режиме, переключаемом `collectgarbage`. Есть слабые таблицы и финализаторы `__gc`. ([Lua 5.4 manual §2.5 — Garbage Collection](https://www.lua.org/manual/5.4/manual.html#2.5))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: language, profile: lua54)** — `error(v)` возбуждает ошибку с произвольным значением, `pcall`/`xpcall` перехватывают её и возвращают `false, v`. Синтаксиса try/catch и иерархии типов исключений нет: это функции базовой библиотеки над механизмом раскрутки ядра. ([Lua 5.4 manual §2.3 — Error Handling](https://www.lua.org/manual/5.4/manual.html#2.3); [Lua 5.4 manual — pcall](https://www.lua.org/manual/5.4/manual.html#pdf-pcall))
- **Код ошибки (layer: standard_library, profile: lua54, applies_to: функции `io`, `os` и подобные)** — Соглашение библиотеки: при неудаче вернуть `nil` (или `fail`), сообщение и код ошибки вместо возбуждения ошибки. ([Lua 5.4 manual §6.8 — Input and Output Facilities](https://www.lua.org/manual/5.4/manual.html#6.8))

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Конструкция управления ресурсом (с Lua 5.4 включительно, layer: language, profile: lua54)** — Локальная переменная с атрибутом `<close>` вызывает метаметод `__close` значения при выходе из блока — обычном, через `break`/`goto`/`return` или по ошибке. ([Lua 5.4 manual §3.3.8 — To-be-closed Variables](https://www.lua.org/manual/5.4/manual.html#3.3.8))
- **Явное освобождение (layer: language, profile: lua54)** — Например, `file:close()`; финализатор `__gc` вызывается сборщиком в неопределённый момент и не заменяет детерминированную очистку.

#### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · [в онтологии](concepts.md#resources-concurrency)

- **неприменимо (n/a) (layer: language, profile: lua54)** — Ядро и стандартные библиотеки не дают вытесняющей многопоточности: тип `thread` — это корутина, выполняемая кооперативно в одном потоке ОС. Параллелизм предоставляет встраивающая программа или внешние библиотеки. ([Lua 5.4 manual §2.6 — Coroutines](https://www.lua.org/manual/5.4/manual.html#2.6))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: lua54)** — Ключевые слова `do … end`, `then … end`, `repeat … until`, `function … end`; отступы незначимы. ([Lua 5.4 manual §9 — The Complete Syntax of Lua](https://www.lua.org/manual/5.4/manual.html#9))

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Необязательная точка с запятой (layer: language, profile: lua54)** — Операторы разделяются по грамматике, перевод строки незначим; `;` допускается и почти никогда не нужна, кроме устранения неоднозначности, когда следующая строка начинается с `(`. ([Lua 5.4 manual §3.3 — Statements](https://www.lua.org/manual/5.4/manual.html#3.3))

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да (layer: language, profile: lua54)** ([Lua 5.4 manual §3.1 — Lexical Conventions](https://www.lua.org/manual/5.4/manual.html#3.1))

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Построение и выполнение кода (layer: standard_library, profile: lua54)** — `load` компилирует строку или результат функции в функцию-чанк с заданным окружением; `dofile`/`loadfile` — для файлов. ([Lua 5.4 manual — load](https://www.lua.org/manual/5.4/manual.html#pdf-load))
- **Рефлексия (layer: standard_library, profile: lua54)** — `type`, `getmetatable`/`setmetatable`, обход таблиц `pairs`; библиотека `debug` даёт доступ к локальным переменным, upvalue и стеку вызовов, но предназначена для отладки. ([Lua 5.4 manual §6.10 — The Debug Library](https://www.lua.org/manual/5.4/manual.html#6.10))

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: lua54)**
- **Процедурная (layer: language, profile: lua54)**
- **Функциональная (layer: language, profile: lua54)** — Функции первого класса, замыкания и хвостовые вызовы; неизменяемых структур данных нет.
- **Объектно-ориентированная (layer: language, profile: lua54)** — Объекты и классы строятся соглашениями на таблицах и метатаблицах, без встроенного синтаксиса классов. ([About Lua — procedural, object-oriented, functional and data-driven programming](https://www.lua.org/about.html))

### Семантика данных { #data }

#### Ограничение числовой точности { #data-numeric-precision }

*Numeric precision bound* · [в онтологии](concepts.md#data-numeric-precision)

- **Фиксированная разрядность типа или поля (с Lua 5.3 включительно, layer: language, profile: lua54)** — Тип number имеет подтипы integer и float; стандартная сборка использует 64-битные целые с заворачиванием при переполнении и двойную точность. До 5.3 все числа были вещественными. ([Lua 5.4 manual §2.1 — Values and Types](https://www.lua.org/manual/5.4/manual.html#2.1); [Lua 5.4 manual §3.4.1 — Arithmetic Operators](https://www.lua.org/manual/5.4/manual.html#3.4.1))
