---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Zig

Zig — императивный системный язык без сборщика мусора, скрытого потока управления и скрытых выделений памяти: аллокатор передаётся явно, ошибки возвращаются как значения типа `!T`, а очистка задаётся `defer`/`errdefer`. Обобщённость и метапрограммирование строятся на одном механизме — вычислении `comptime` с типами как значениями, без макросов и препроцессора. Язык ещё не достиг 1.0 и не имеет стабильной спецификации: записи опираются на Language Reference выпуска 0.16.0 и могут устареть в следующих выпусках.

*Карточка сравнительная: 39/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 2015 — [Wikidata P571](https://www.wikidata.org/wiki/Q51885456) (получено 2026-09-25) |
| Авторы | [Эндрю Келли](people.md#andrew-kelley) |
| Организации | Zig Software Foundation |
| Сайт | <https://ziglang.org/> |
| Спецификация | <https://ziglang.org/documentation/master/> |
| Внешние каталоги | [Wikidata Q51885456](https://www.wikidata.org/wiki/Q51885456) |

## Статьи { #articles }

- [Zig: comptime вместо макросов](../garden/zig-comptime.md)

## Люди { #people }

- [Эндрю Келли](people.md#andrew-kelley) — Создатель языка Zig и президент Zig Software Foundation.

## Публикации { #publications }

- [Zig 0.16.0 Language Reference](https://ziglang.org/documentation/0.16.0/). Нормативное описание Zig, привязанное к выпуску: язык до версии 1.0 меняется между выпусками. ([в источниках](sources.md#zig-langref))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **zig016** — Zig 0.16, Language Reference выпуска 0.16.0 и стандартная библиотека этого выпуска; язык до 1.0 и меняется между выпусками, формальной спецификации нет.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: zig016)** — Имя вводится объявлением `const` или `var`; инициализация обязательна, а `undefined` явно оставляет значение неопределённым. ([Zig 0.16.0 Language Reference — Assignment](https://ziglang.org/documentation/0.16.0/#Assignment))

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Неизменяемое (layer: language, profile: zig016, applies_to: объявления `const`)** — После инициализации `const`-имя нельзя изменить; `const` относится к байтам, которые имя адресует непосредственно, у указателей собственная константность. ([Zig 0.16.0 Language Reference — Assignment](https://ziglang.org/documentation/0.16.0/#Assignment))
- **Перепривязываемое (layer: language, profile: zig016, applies_to: объявления `var`)** — `var` допускает последующее присваивание значения того же типа.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: zig016)**
- **Распаковка при присваивании (layer: language, profile: zig016, applies_to: кортежи, массивы и векторы)** — Деструктурирующее присваивание `x, y, z = tuple;` разрешено только внутри блока. ([Zig 0.16.0 Language Reference — Destructuring](https://ziglang.org/documentation/0.16.0/#Destructuring))

### Области видимости { #scope }

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Блок (layer: language, profile: zig016)** — Блок ограничивает область локальных объявлений и сам является выражением; помеченный блок возвращает значение через `break :label value`. ([Zig 0.16.0 Language Reference — Blocks](https://ziglang.org/documentation/0.16.0/#Blocks))
- **Модуль (layer: language, profile: zig016)** — Каждый исходный файл неявно является объявлением структуры и задаёт пространство имён своих объявлений.

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

*Name shadowing* · [в онтологии](concepts.md#scope-shadowing)

- **Запрет сокрытия локальных в охватывающем блоке (layer: language, profile: zig016)** — Запрет шире локального: идентификатор не может скрыть никакой видимый идентификатор внешней области, включая объявления уровня файла (`local variable shadows declaration`). ([Zig 0.16.0 Language Reference — Shadowing](https://ziglang.org/documentation/0.16.0/#Shadowing))

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Статическая (layer: language, profile: zig016)** — Типы проверяются при семантическом анализе; часть проверок (переполнение, выход за границы) выполняется при выполнении в режимах Debug и ReleaseSafe.

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Необязательны (layer: language, profile: zig016, applies_to: локальные объявления)** — Тип локального `const`/`var` можно вывести из инициализатора; типы параметров (или `anytype`) и тип результата функции записываются явно.

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **да (layer: language, profile: zig016, applies_to: локальные объявления и параметры `anytype`)** — Локальный вывод из инициализатора и вывод типа `anytype`-параметра в месте вызова; глобального вывода типов функций нет. ([Zig 0.16.0 Language Reference — Function Parameter Type Inference](https://ziglang.org/documentation/0.16.0/#Function-Parameter-Type-Inference))

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: zig016)** — Сужающие и меняющие представление преобразования выполняются встроенными функциями `@intCast`, `@floatFromInt`, `@bitCast`, `@ptrCast` и др.; часть из них добавляет проверки безопасности. ([Zig 0.16.0 Language Reference — Explicit Casts](https://ziglang.org/documentation/0.16.0/#Explicit-Casts))
- **Неявные (layer: language, profile: zig016, applies_to: однозначные и безопасные приведения типов)** — Неявная коэрсия допускается только когда преобразование однозначно и гарантированно безопасно: расширение целых, `T` → `?T`, `T` → `E!T`, усиление квалификаторов. Исключение — C-указатели. ([Zig 0.16.0 Language Reference — Type Coercion](https://ziglang.org/documentation/0.16.0/#Type-Coercion))

#### Типы-суммы { #typing-sum-types }

*Sum types* · [в онтологии](concepts.md#typing-sum-types)

- **Размеченные варианты (layer: language, profile: zig016)** — `union(enum)` или `union(Tag)` хранит активный вариант; `switch` по размеченному объединению даёт доступ к полезной нагрузке через захват. ([Zig 0.16.0 Language Reference — Tagged union](https://ziglang.org/documentation/0.16.0/#Tagged-union))

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Записи и структуры (layer: language, profile: zig016)** — `struct` с именованными полями и значениями по умолчанию; порядок полей в памяти не гарантирован, кроме `extern` и `packed`. ([Zig 0.16.0 Language Reference — struct](https://ziglang.org/documentation/0.16.0/#struct))
- **Кортежи (layer: language, profile: zig016)** — Кортеж — анонимная структура без имён полей, `.{ 1, 2, 3 }`. ([Zig 0.16.0 Language Reference — Tuples](https://ziglang.org/documentation/0.16.0/#Tuples))

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Тип Option/Optional (layer: language, profile: zig016)** — Обычные указатели `*T` не могут быть null; отсутствие значения выражается типом `?T` и распаковывается через `orelse`, `if` или `.?`. Исключения — `allowzero` и C-указатели `[*c]T`. ([Zig 0.16.0 Language Reference — Optionals](https://ziglang.org/documentation/0.16.0/#Optionals))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условное выражение (layer: language, profile: zig016)** — `if` — выражение и заменяет тернарный оператор; оно также распаковывает `?T` и `E!T` с захватом значения. ([Zig 0.16.0 Language Reference — if](https://ziglang.org/documentation/0.16.0/#if))

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: zig016)** — `switch` — выражение; без ветви `else` оно обязано перечислить все значения, иначе ошибка компиляции. ([Zig 0.16.0 Language Reference — switch](https://ziglang.org/documentation/0.16.0/#switch); [Zig 0.16.0 Language Reference — Exhaustive Switching](https://ziglang.org/documentation/0.16.0/#Exhaustive-Switching))

#### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **нет (layer: language, profile: zig016)** — `switch` сравнивает значения, диапазоны и варианты размеченного объединения и захватывает полезную нагрузку одного уровня, но вложенных структурных образцов нет.

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · [в онтологии](concepts.md#control-do-while)

- **нет (layer: language, profile: zig016)** — Постусловие выражается `while (true)` с явным `break`.

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **По последовательности или итератору (layer: language, profile: zig016)** — `for` обходит массивы, срезы и диапазоны `0..n`, в том числе несколько последовательностей одинаковой длины одновременно; произвольный итератор обходится через `while` с опционалом. ([Zig 0.16.0 Language Reference — for](https://ziglang.org/documentation/0.16.0/#for))
- **Инициализация / условие / шаг (layer: language, profile: zig016, applies_to: `while (cond) : (step)`)** — `while` принимает continue-выражение, выполняемое при каждом продолжении цикла; инициализация записывается до цикла отдельным объявлением. ([Zig 0.16.0 Language Reference — while](https://ziglang.org/documentation/0.16.0/#while))

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: zig016)** — Имя в контейнере обозначает одно объявление; вариативность по типам выражается `comptime`-параметрами или `anytype`.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: zig016)** — Параметры неизменяемы; для структур, объединений и массивов компилятор может передавать ссылку, так как копия ненаблюдаема. Изменяемый аргумент передаётся явным указателем. ([Zig 0.16.0 Language Reference — Pass-by-value Parameters](https://ziglang.org/documentation/0.16.0/#Pass-by-value-Parameters))

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **нет (layer: language, profile: zig016)** — Нет функций, захватывающих окружение во время выполнения; состояние передаётся явно, например структурой-контекстом.

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **нет (layer: language, profile: zig016)** — Анонимных функциональных выражений нет; функцию объявляют в контейнере, в том числе в анонимной структуре внутри выражения.

#### Параметрический полиморфизм { #subprograms-generics }

*Parametric polymorphism* · [в онтологии](concepts.md#subprograms-generics)

- **да (layer: language, profile: zig016)** — Обобщённость реализуется параметрами времени компиляции: тип — значение первого класса, передаваемое как `comptime T: type`; ограничения проверяются при инстанцировании (compile-time duck typing). ([Zig 0.16.0 Language Reference — Compile-Time Parameters](https://ziglang.org/documentation/0.16.0/#Compile-Time-Parameters); [Zig 0.16.0 Language Reference — Generic Data Structures](https://ziglang.org/documentation/0.16.0/#Generic-Data-Structures))

#### Реализация параметрического полиморфизма { #subprograms-generic-mechanism }

*Generic implementation mechanism* · [в онтологии](concepts.md#subprograms-generic-mechanism)

- **Мономорфизация (layer: language, profile: zig016)** — Отдельного механизма шаблонов нет: вызов с новыми `comptime`-аргументами вычисляется при компиляции и порождает специализированный код; функция, возвращающая `type`, строит обобщённую структуру данных.

### Полиморфизм и организация { #abstraction }

#### Диспетчеризация вызовов { #abstraction-dispatch }

*Call dispatch* · [в онтологии](concepts.md#abstraction-dispatch)

- **Статическая (layer: language, profile: zig016)** — Вызовы разрешаются статически; динамический полиморфизм строится вручную через указатели на функции, например `std.mem.Allocator` хранит указатель на объект и таблицу функций.

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Отсутствует (layer: language, profile: zig016)**

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Явная граница экспорта (layer: language, profile: zig016)** — `@import` возвращает структуру-тип файла; извне видны только объявления с `pub`. ([Zig 0.16.0 Language Reference — @import](https://ziglang.org/documentation/0.16.0/#import); [Zig 0.16.0 Language Reference — Source File Structs](https://ziglang.org/documentation/0.16.0/#Source-File-Structs))

### Вычисление и эффекты { #evaluation }

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · [в онтологии](concepts.md#evaluation-tail-calls)

- **нет (layer: language, profile: zig016)** — Для обычного вызова устранение не гарантировано; `@call(.always_tail, f, args)` требует хвостового вызова и даёт ошибку компиляции, если он невозможен. ([Zig 0.16.0 Language Reference — @call](https://ziglang.org/documentation/0.16.0/#call))

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Ручное (layer: language, profile: zig016)** — Язык не управляет памятью за программиста и не имеет среды выполнения со сборщиком; по соглашению аллокатора по умолчанию нет — функции, которым нужна куча, принимают параметр `Allocator`, реализации (`FixedBufferAllocator`, `ArenaAllocator` и др.) даёт стандартная библиотека. ([Zig 0.16.0 Language Reference — Memory](https://ziglang.org/documentation/0.16.0/#Memory); [Zig 0.16.0 Language Reference — Choosing an Allocator](https://ziglang.org/documentation/0.16.0/#Choosing-an-Allocator))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Размеченный результат (layer: language, profile: zig016)** — Ошибка — значение из множества ошибок; тип `E!T` объединяет его с результатом. `try` возвращает ошибку вызывающему, `catch` подставляет значение или обрабатывает её; раскрутки стека нет. ([Zig 0.16.0 Language Reference — Errors](https://ziglang.org/documentation/0.16.0/#Errors); [Zig 0.16.0 Language Reference — Error Union Type](https://ziglang.org/documentation/0.16.0/#Error-Union-Type))
- **Паника (layer: language, profile: zig016)** — `@panic` и достижение `unreachable` в режимах Debug/ReleaseSafe вызывают обработчик паники; в ReleaseFast/ReleaseSmall `unreachable` становится предположением оптимизатора. ([Zig 0.16.0 Language Reference — unreachable](https://ziglang.org/documentation/0.16.0/#unreachable))

#### Диагностика неиспользованного результата { #errors-must-use }

*Unused-result diagnostics* · [в онтологии](concepts.md#errors-must-use)

- **Ошибка (layer: language, profile: zig016)** — Игнорирование любого выражения не-`void` типа — ошибка компиляции (`value of type … ignored`), поэтому ошибку нельзя молча потерять; явное отбрасывание — `_ = expr`. ([Zig 0.16.0 Language Reference — void](https://ziglang.org/documentation/0.16.0/#void))

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Отложенный вызов при выходе (layer: language, profile: zig016)** — `defer` выполняет выражение при любом выходе из области в обратном порядке; `errdefer` — только при выходе с ошибкой. Внутри `defer` запрещён `return`. ([Zig 0.16.0 Language Reference — defer](https://ziglang.org/documentation/0.16.0/#defer); [Zig 0.16.0 Language Reference — errdefer](https://ziglang.org/documentation/0.16.0/#errdefer))

#### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · [в онтологии](concepts.md#resources-concurrency)

- **Потоки (layer: standard_library, profile: zig016)** — `std.Thread.spawn` и `threadlocal`-переменные. Языковые async-функции не поддерживаются начиная с 0.11.0; `async_await` поэтому не указан. ([Zig 0.16.0 Language Reference — Thread Local Variables](https://ziglang.org/documentation/0.16.0/#Thread-Local-Variables); [Zig 0.16.0 Language Reference — Async Functions](https://ziglang.org/documentation/0.16.0/#Async-Functions))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: zig016)**

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Точка с запятой (layer: language, profile: zig016)**

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да (layer: language, profile: zig016)**

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Вычисление при компиляции (layer: language, profile: zig016)** — `comptime`-блоки, параметры и переменные вычисляются при семантическом анализе; типы — значения времени компиляции. Макросов и препроцессора нет; C-макросы доступны только через трансляцию C-заголовков. ([Zig 0.16.0 Language Reference — comptime](https://ziglang.org/documentation/0.16.0/#comptime))
- **Рефлексия (layer: language, profile: zig016, applies_to: время компиляции)** — `@typeInfo`, `@TypeOf`, `@hasField` дают сведения о типах при компиляции; встроенные функции `@Struct`, `@Int`, `@Enum` и др. строят новые типы. Отражения типов во время выполнения нет. ([Zig 0.16.0 Language Reference — @typeInfo](https://ziglang.org/documentation/0.16.0/#typeInfo))

#### Гигиена макросов { #syntax-macro-hygiene }

*Macro hygiene* · [в онтологии](concepts.md#syntax-macro-hygiene)

- **неприменимо (n/a) (layer: language, profile: zig016)** — В Zig нет макросов и препроцессора: код времени компиляции — обычные функции и блоки comptime с лексической областью видимости, поэтому вопрос о захвате имён при подстановке не возникает. ([Zig 0.16.0 Language Reference, comptime](https://ziglang.org/documentation/0.16.0/#comptime))

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: zig016)**
- **Процедурная (layer: language, profile: zig016)**

### Семантика данных { #data }

#### Ограничение числовой точности { #data-numeric-precision }

*Numeric precision bound* · [в онтологии](concepts.md#data-numeric-precision)

- **Фиксированная разрядность типа или поля (layer: language, profile: zig016, applies_to: целые `iN`/`uN` и числа с плавающей точкой)** — Разрядность целого задаётся типом, в том числе произвольной шириной вроде `u7`; переполнение обычных операторов — Illegal Behavior (проверяется в Debug/ReleaseSafe), для оборачивания есть отдельные операторы вроде `+%`. ([Zig 0.16.0 Language Reference — Integer Overflow](https://ziglang.org/documentation/0.16.0/#Integer-Overflow))
- **Нефиксированная заранее разрядность (layer: language, profile: zig016, applies_to: `comptime_int` при компиляции)** — Целые литералы и значения `comptime_int` не ограничены по размеру, но существуют только при компиляции.
