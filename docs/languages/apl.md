---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# APL

APL — язык массивов: единственная структура данных — прямоугольный массив произвольного ранга, а примитивные функции записываются специальными глифами и применяются к целым массивам без явных циклов. Выражение вычисляется справа налево без приоритета операций; операторы вроде `/` и `¨` строят из функций новые функции. Базовый профиль — общее ядро по ISO/IEC 13751 (Extended APL), стандарт не свободно доступен, поэтому ссылки для ядра даны на документацию Dyalog; dfns, поезда, оператор ранга `⍤` и управляющие структуры отнесены к профилю Dyalog APL.

*Карточка сравнительная: 36/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1966 — [Wikidata P571](https://www.wikidata.org/wiki/Q296187) (получено 2026-09-25) |
| Авторы | [Кеннет Айверсон](people.md#iverson) |
| Организации | IBM |
| Сайт | <https://aplwiki.com/> |
| Спецификация | <https://docs.dyalog.com/> |
| Внешние каталоги | [Wikidata Q296187](https://www.wikidata.org/wiki/Q296187) |

## Статьи { #articles }

- [APL: нотация как инструмент мышления](../garden/apl-arrays.md)

## Люди { #people }

- [Кеннет Айверсон](people.md#iverson) — Создатель APL; тьюринговская лекция «Notation as a Tool of Thought».

## Публикации { #publications }

- Кеннет Айверсон, Adin D. Falkoff. *The Evolution of APL*. HOPL I, 1978. DOI: [10.1145/800025.808372](https://doi.org/10.1145/800025.808372). Как математическая нотация Айверсона стала языком программирования и почему в нём нет приоритетов операций. ([в источниках](sources.md#hopl-apl))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **iso13751** — Общее ядро APL по ISO/IEC 13751:2001 (Extended APL): массивы, скалярные функции, операторы, традиционные функции с динамической областью видимости. Текст стандарта платный; утверждения проверены по совпадающим разделам Dyalog APL 19.0 Language Reference.
- **dyalog** — Dyalog APL 19.0 по Language Reference Guide: диалект и реализация Dyalog Ltd., включая dfns, поезда, оператор ранга, управляющие структуры и классы. Не распространяется на APL2, GNU APL и другие диалекты.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Связывание присваиванием (layer: language, profile: iso13751)** — Переменная появляется при первом присваивании `←`; объявления для глобальных имён нет. Локальные имена традиционной функции перечисляются в заголовке через `;`. ([Dyalog 19.0 — Specification of Variables](https://help.dyalog.com/19.0/Content/Language/Introduction/Variables/Specification%20of%20Variables.htm))

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: iso13751)** — Имя можно заново присвоить; массивы — значения, изменение части массива через индексное присваивание не затрагивает другие имена.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: iso13751)** — `A←⍳3` связывает имя со значением выражения справа. ([Dyalog 19.0 — Assignment](https://help.dyalog.com/19.0/Content/Language/Primitive%20Functions/Assignment.htm))
- **Распаковка при присваивании (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — Стрендовое присваивание `year month day←2017 05 24` раскладывает элементы вектора по именам; скаляр присваивается всем именам. Происходит от APL2, но в ядре ISO не проверено. ([Dyalog 19.0 — Assignment: multiple assignment](https://help.dyalog.com/19.0/Content/Language/Primitive%20Functions/Assignment.htm))

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Динамическое (layer: language, profile: iso13751, applies_to: традиционные функции (tradfns))** — Локальное имя затеняет одноимённый объект на время выполнения функции, и вызванные ею функции видят это локальное значение — поиск идёт вниз по state indicator. ([Dyalog 19.0 — Global & Local Names](https://help.dyalog.com/19.0/Content/Language/Defined%20Functions%20and%20Operators/TradFns/Global%20Local%20Names.htm))
- **Лексическое (layer: implementation, profile: dyalog, implementation: Dyalog APL, applies_to: dfns)** — Вложенная dfn ищет имя во внешних dfn по тексту, а не по цепочке вызовов; документация противопоставляет это «обычной для APL» динамической области. ([Dyalog 19.0 — Lexical Name Scope](https://help.dyalog.com/19.0/Content/Language/Defined%20Functions%20and%20Operators/DynamicFunctions/Static%20Name%20Scope.htm))

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Подпрограмма (layer: language, profile: iso13751)** — Локализация действует на время вызова определённой функции или оператора; блочных областей нет. ([Dyalog 19.0 — Global & Local Names](https://help.dyalog.com/19.0/Content/Language/Defined%20Functions%20and%20Operators/TradFns/Global%20Local%20Names.htm))
- **Модуль (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — Пространства имён (класс 9) — вложенные «рабочие области» с собственными именами. ([Dyalog 19.0 — Namespaces](https://help.dyalog.com/19.0/Content/Language/Introduction/Namespaces/Namespaces.htm))

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

*Top-level bindings* · [в онтологии](concepts.md#scope-globals)

- **Глобальные переменные (layer: language, profile: iso13751)** — Имена рабочей области (workspace) доступны любой функции, если не затенены локальными. ([Dyalog 19.0 — Workspaces](https://help.dyalog.com/19.0/Content/Language/Introduction/Workspaces.htm))

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

*Name shadowing* · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: iso13751)** — Локальное имя функции временно исключает объект с тем же именем из внешнего окружения (localisation/shadowing). ([Dyalog 19.0 — Global & Local Names](https://help.dyalog.com/19.0/Content/Language/Defined%20Functions%20and%20Operators/TradFns/Global%20Local%20Names.htm))

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Динамическая (layer: language, profile: iso13751)** — Тип элементов (числа, символы, вложенные массивы) и согласованность форм проверяются примитивами при выполнении: `DOMAIN ERROR`, `LENGTH ERROR`, `RANK ERROR`.

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Отсутствуют (layer: language, profile: iso13751)** — Заголовок функции задаёт имена аргументов и результата, но не их типы или ранги.

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **нет (layer: language, profile: iso13751)** — Статического вывода типов в языке нет; оптимизации интерпретатора по типу данных — свойство реализации.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Неявные (layer: language, profile: iso13751)** — Числовые представления (булево, целое, вещественное, комплексное) взаимно преобразуются неявно; программа видит просто числа. Число и символ неявно не смешиваются. ([Dyalog 19.0 — Numbers](https://help.dyalog.com/19.0/Content/Language/Introduction/Variables/Numbers.htm))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Охранные условия (layer: implementation, profile: dyalog, implementation: Dyalog APL, applies_to: dfns)** — `условие: выражение` — охранные выражения проверяются по порядку; первое истинное задаёт результат dfn. ([Dyalog 19.0 — Guards](https://help.dyalog.com/19.0/Content/Language/Defined%20Functions%20and%20Operators/DynamicFunctions/Guards.htm))
- **Условный оператор (layer: implementation, profile: dyalog, implementation: Dyalog APL, applies_to: традиционные функции)** — `:If … :Else … :EndIf`; в dfns управляющие структуры не допускаются. В классическом APL ветвление выражается переходом `→`. ([Dyalog 19.0 — If Statement](https://help.dyalog.com/19.0/Content/Language/Control%20Structures/if.htm))

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **да (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — `:Select … :Case … :CaseList … :Else … :EndSelect`; сравнение через `≡`. ([Dyalog 19.0 — Select Statement](https://help.dyalog.com/19.0/Content/Language/Control%20Structures/select.htm))

<a id="req-7-2-until"></a>

#### Цикл до истинности условия { #control-until }

*Until loop* · [в онтологии](concepts.md#control-until)

- **Проверка после тела (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — `:Repeat … :Until условие` выполняет тело хотя бы один раз. ([Dyalog 19.0 — Repeat Statement](https://help.dyalog.com/19.0/Content/Language/Control%20Structures/repeat.htm))

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **Функции обхода (layer: language, profile: iso13751)** — Обход выражается операторами над функциями: редукция `f/`, `¨` (each), внешнее произведение `∘.f`, а также неявным поэлементным применением скалярных функций. ([Dyalog 19.0 — Reduce](https://help.dyalog.com/19.0/Content/Language/Primitive%20Operators/Reduce.htm); [Dyalog 19.0 — Each](https://help.dyalog.com/19.0/Content/Language/Primitive%20Operators/Each%20with%20Monadic%20Operand.htm); [Dyalog 19.0 — Outer Product](https://help.dyalog.com/19.0/Content/Language/Primitive%20Operators/Outer%20Product.htm))
- **По последовательности или итератору (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — `:For I :In массив` перебирает элементы в порядке ravel. ([Dyalog 19.0 — For Statement](https://help.dyalog.com/19.0/Content/Language/Control%20Structures/for.htm))

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: iso13751)** — Одна функция может быть вызвана монадически и диадически (валентность), но это не перегрузка по типам: тело само проверяет наличие левого аргумента.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: iso13751)** — Аргументы `⍺`/`⍵` — массивы-значения; изменение локальной копии не видно вызывающему. Ссылки на пространства имён Dyalog передаются как значения-ссылки.

#### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms* · [в онтологии](concepts.md#subprograms-nesting)

- **да (layer: implementation, profile: dyalog, implementation: Dyalog APL, applies_to: dfns)** — Именованная dfn может быть определена внутри другой dfn как локальная функция. ([Dyalog 19.0 — Dfns & Dops](https://help.dyalog.com/19.0/Content/Language/Defined%20Functions%20and%20Operators/DynamicFunctions/Dynamic%20Functions%20and%20Operators.htm))

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — Dfn `{(+/⍵)÷≢⍵}` — анонимная функция, которую можно применить сразу, передать операнду оператора или назвать присваиванием. Поезда `(f g h)` дают неявные (tacit) функции без имён аргументов. ([Dyalog 19.0 — Dfns & Dops](https://help.dyalog.com/19.0/Content/Language/Defined%20Functions%20and%20Operators/DynamicFunctions/Dynamic%20Functions%20and%20Operators.htm); [Dyalog 19.0 — Function Trains](https://help.dyalog.com/19.0/Content/Language/Introduction/Trains.htm))

#### Аргументы по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **да (layer: implementation, profile: dyalog, implementation: Dyalog APL, applies_to: левый аргумент dfn)** — `⍺←выражение` задаёт левый аргумент, если dfn вызвана монадически. ([Dyalog 19.0 — Default Left Argument](https://help.dyalog.com/19.0/Content/Language/Defined%20Functions%20and%20Operators/DynamicFunctions/Default%20Left%20Argument.htm))

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **нет (layer: language, profile: iso13751)** — Функция имеет не более двух аргументов-массивов, `⍺` и `⍵`; несколько значений передаются вложенным массивом.

### Полиморфизм и организация { #abstraction }

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Одиночное (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — `:Class CLASS2: CLASS1` — класс наследует публичные члены одного базового класса. ([Dyalog 19.0 — Inheritance](https://help.dyalog.com/19.0/Content/Language/Object%20Oriented%20Programming/Classes/Class%20Inheritance.htm))

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: iso13751)** — Аргумент вычисляется до применения функции; выражение разбирается справа налево без приоритета операций, так `2×3-1` равно 4. ([Dyalog 19.0 — Expressions](https://help.dyalog.com/19.0/Content/Language/Introduction/Expressions.htm))

#### Контроль эффектов { #evaluation-effects }

*Effect control* · [в онтологии](concepts.md#evaluation-effects)

- **Без общего статического разделения эффектов (layer: language, profile: iso13751)** — Функции могут присваивать глобальные имена и выполнять ввод-вывод; статического контроля эффектов нет.

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · [в онтологии](concepts.md#evaluation-tail-calls)

- **да (layer: implementation, profile: dyalog, implementation: Dyalog APL, applies_to: dfns)** — Интерпретатор переиспользует кадр стека для хвостовых вызовов dfn; для традиционных функций такое утверждение не делается. ([Dyalog 19.0 — Tail Calls](https://help.dyalog.com/19.0/Content/Language/Defined%20Functions%20and%20Operators/DynamicFunctions/Tail%20Calls.htm))

#### Поднятие операций по рангу массива { #evaluation-rank-lifting }

*Array rank lifting* · [в онтологии](concepts.md#evaluation-rank-lifting)

- **Распространение скаляра на элементы массива (layer: language, profile: iso13751)** — Скалярные функции применяются к каждому простому скаляру на любой глубине вложенности; скаляр в диадическом вызове размножается до формы другого аргумента: `1 2 3+10` даёт `11 12 13`. ([Dyalog 19.0 — Scalar Functions: scalar extension](https://help.dyalog.com/19.0/Content/Language/Primitive%20Functions/Scalar%20Functions.htm))
- **Применение к ячейкам выбранного ранга (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — Оператор ранга `f⍤k` применяет `f` к k-ячейкам аргументов; отрицательный k отсчитывается от ранга аргумента. В Classic Edition вместо глифа — `⎕U2364`. Наличие этого оператора в других диалектах (APL2 его не имеет) здесь не утверждается. ([Dyalog 19.0 — Rank operator](https://help.dyalog.com/19.0/Content/Language/Primitive%20Operators/Rank.htm))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — `⎕SIGNAL` порождает событие с номером; `:Trap коды … :EndTrap` и error-guard dfn `коды::выражение` перехватывают его, разматывая стек до места перехвата. ([Dyalog 19.0 — ⎕SIGNAL](https://help.dyalog.com/19.0/Content/Language/System%20Functions/signal.htm); [Dyalog 19.0 — Trap Statement](https://help.dyalog.com/19.0/Content/Language/Control%20Structures/trap.htm); [Dyalog 19.0 — Error-Guards](https://help.dyalog.com/19.0/Content/Language/Defined%20Functions%20and%20Operators/DynamicFunctions/Error%20Guards.htm))

### Ресурсы и взаимодействие { #resources }

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

*I/O interface* · [в онтологии](concepts.md#resources-io)

- **Встроенные функции (layer: language, profile: iso13751)** — Системные переменные `⎕` и `⍞` — ввод и вывод через терминал; неприсвоенный результат выражения выводится автоматически. ([Dyalog 19.0 — Character Input/Output](https://help.dyalog.com/19.0/Content/Language/System%20Functions/Character%20Input%20Output.htm))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: iso13751)** — Группировка — круглые скобки; тело dfn ограничено `{ }`, традиционная функция — строками определения `∇ … ∇` или редактором, управляющие структуры Dyalog — парами `:If … :EndIf`.

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Перевод строки (layer: language, profile: iso13751)** — Строка — одно выражение; Dyalog дополнительно разделяет выражения в одной строке символом `⋄` (diamond). ([Dyalog 19.0 — Execute: sub-expressions separated by ⋄](https://help.dyalog.com/19.0/Content/Language/Primitive%20Functions/Execute.htm))

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — Прописные и строчные латинские буквы — разные символы имён; ранние системы с одним регистром это различие не наблюдали. ([Dyalog 19.0 — Legal Names](https://help.dyalog.com/19.0/Content/Language/Introduction/Variables/Names.htm))

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Построение и выполнение кода (layer: language, profile: iso13751)** — `⍎` выполняет строку как выражение APL; `⎕FX` создаёт функцию из её текстового представления, `⎕CR` возвращает текст существующей. ([Dyalog 19.0 — Execute](https://help.dyalog.com/19.0/Content/Language/Primitive%20Functions/Execute.htm); [Dyalog 19.0 — ⎕FX](https://help.dyalog.com/19.0/Content/Language/System%20Functions/fx.htm))

#### Нотация исходной программы { #syntax-program-representation }

*Source program notation* · [в онтологии](concepts.md#syntax-program-representation)

- **Текстовая нотация (layer: language, profile: iso13751)** — Программа — текст, но из специального набора символов: примитивы записываются одиночными глифами (`⍴`, `⍳`, `∘.`, `⍤`), что исторически требовало особой клавиатуры.

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Функциональная (layer: language, profile: iso13751)** — Композиция функций и операторов высшего порядка над целыми массивами; «программирование массивами» в перечислении онтологии отдельного значения не имеет.
- **Императивная (layer: language, profile: iso13751)** — Присваивание, переход `→` и глобальное состояние рабочей области.
- **Объектно-ориентированная (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — Классы, экземпляры и наследование Dyalog.

### Семантика данных { #data }

#### Кратность элементов коллекции { #data-collection-multiplicity }

*Collection multiplicity* · [в онтологии](concepts.md#data-collection-multiplicity)

- **Последовательность позиционных вхождений (layer: language, profile: iso13751)** — Массив упорядочен по осям и хранит повторяющиеся элементы в отдельных позициях; множества моделируются функциями вроде `∪`, а не отдельной коллекцией. ([Dyalog 19.0 — Arrays](https://help.dyalog.com/19.0/Content/Language/Introduction/Variables/Arrays.htm))

#### Основание числового представления { #data-numeric-radix }

*Numeric representation radix* · [в онтологии](concepts.md#data-numeric-radix)

- **Двоичное (layer: implementation, profile: dyalog, implementation: Dyalog APL)** — Вещественные числа по умолчанию — IEEE-754 64-bit binary. ([Dyalog 19.0 — 128 Bit Decimal Floating-Point](https://help.dyalog.com/19.0/Content/Language/Introduction/128%20Bit%20Decimal%20Floating%20Point.htm))
- **Десятичное (layer: implementation, profile: dyalog, implementation: Dyalog APL, applies_to: `⎕FR←1287`)** — Альтернативное 128-битное десятичное представление IEEE-754-2008 выбирается системной переменной. ([Dyalog 19.0 — 128 Bit Decimal Floating-Point](https://help.dyalog.com/19.0/Content/Language/Introduction/128%20Bit%20Decimal%20Floating%20Point.htm))
