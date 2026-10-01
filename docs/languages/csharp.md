---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# C#

C# 12 — статически типизированный язык с классами, значимыми типами, обобщениями и асинхронными методами. Базовый профиль включает nullable-анализ; поведение управляемой памяти и библиотек отдельно привязано к .NET 8. Новшества C# 12 описываются официальными feature specifications в дополнение к основной спецификации.

*Карточка сравнительная: 35/85 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 2001 — [Wikidata P571](https://www.wikidata.org/wiki/Q2370) (получено 2026-09-24) |
| Авторы | [Андерс Хейлсберг](people.md#hejlsberg) |
| Организации | Microsoft |
| Сайт | <https://dotnet.microsoft.com/languages/csharp> |
| Спецификация | <https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/specifications> |
| Внешние каталоги | [Wikidata Q2370](https://www.wikidata.org/wiki/Q2370) |

## Люди { #people }

- [Андерс Хейлсберг](people.md#hejlsberg) — Автор Turbo Pascal; ведущий архитектор Delphi, C# и TypeScript.

## Публикации { #publications }

- Rui Pereira, Marco Couto, Francisco Ribeiro, Rui Rua, Jácome Cunha, João Paulo Fernandes, João Saraiva. [Energy Efficiency across Programming Languages: How Do Energy, Time, and Memory Relate?](https://greenlab.di.uminho.pt/wp-content/uploads/2017/10/sleFinal.pdf). SLE 2017, 2017. DOI: [10.1145/3136014.3136031](https://doi.org/10.1145/3136014.3136031). Измерения энергии, времени и памяти для 27 языков на задачах Benchmarks Game — материал к критерию «стоимость»; обсуждайте вместе с ограничениями методики. ([в источниках](sources.md#pereira-energy-2017))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **csharp12** — C# 12, nullable enable; базовый профиль языка. Nullable-анализ выдаёт предупреждения, если проект отдельно не повышает их до ошибок.
- **dotnet8** — .NET 8 / CLR и базовая библиотека при использовании C# 12; профиль реализации, а не утверждение о последнем выпуске.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

англ. *Binding introduction* (также *declaration*, *name binding*) · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: csharp12)** — Объявления локальных переменных, параметров и членов; var — объявление с выводом типа, а не динамическая переменная.
- **Связывание образцом (layer: language, profile: csharp12)** — Объявления при деконструкции и переменные в образцах.

#### Изменяемость связывания { #bindings-mutation }

англ. *Binding mutability* (также *rebinding*, *immutable binding*, *const qualification*) · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: csharp12, applies_to: обычные локальные переменные и поля)**
- **Неизменяемое (layer: language, profile: csharp12, applies_to: const и readonly-поля после разрешённой инициализации)** — readonly-ссылка на изменяемый объект не делает сам объект неизменяемым. init ограничивает время записи свойства, а не все эффекты объекта.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

англ. *Assignment and binding forms* (также *assignment*, *destructuring*, *unification*) · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: csharp12)**
- **Распаковка при присваивании (layer: language, profile: csharp12)** — Деконструирующее присваивание распределяет компоненты кортежа или результаты Deconstruct по переменным.

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

англ. *Name resolution* (также *name lookup*, *lexical scoping*, *dynamic scoping*) · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: csharp12)**

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

англ. *Name shadowing* (также *name hiding*, *variable shadowing*) · [в онтологии](concepts.md#scope-shadowing)

- **Запрет сокрытия локальных в охватывающем блоке (layer: language, profile: csharp12)** — Вложенная локальная переменная не может заново объявить имя локальной из охватывающего пространства объявлений. Локальная переменная при этом может скрыть член типа. ([C# specification: Declarations](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/basic-concepts#73-declarations))

### Типизация { #typing }

#### Проверка типов { #typing-checking }

англ. *Type checking* (также *static typing*, *dynamic typing*) · [в онтологии](concepts.md#typing-checking)

- **Статическая (layer: language, profile: csharp12)** — Основной режим проверки; var сохраняет статический тип.
- **Динамическая (layer: language, profile: csharp12, applies_to: операции с dynamic)** — Для dynamic связывание определённых операций переносится во время выполнения; это не поведение всех значений object. ([Using type dynamic](https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/interop/using-type-dynamic))

#### Аннотации типов { #typing-annotations }

англ. *Type annotations* (также *type declarations*, *type signatures*) · [в онтологии](concepts.md#typing-annotations)

- **Необязательны (layer: language, profile: csharp12, applies_to: локальные объявления с var и выводимые параметры лямбд)** — Типы обычных параметров методов и возвращаемых значений в сигнатурах по-прежнему задаются явно.

#### Вывод статических типов { #typing-inference }

англ. *Type inference* (также *type deduction*) · [в онтологии](concepts.md#typing-inference)

- **да (layer: language, profile: csharp12)** — var, вывод аргументов обобщённых методов, контекстная типизация лямбд.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

англ. *Type conversions* (также *type coercion*, *type casting*) · [в онтологии](concepts.md#typing-conversions)

- **Неявные (layer: language, profile: csharp12)** — Числовые, ссылочные, boxing и пользовательские преобразования; даже разрешённое неявное преобразование числа может терять точность.
- **Явные (layer: language, profile: csharp12)** — Cast и пользовательские explicit conversions; checked/unchecked влияет на определённые числовые преобразования. ([C# specification: Conversions](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/conversions))

#### Совместимость типов { #typing-compatibility }

англ. *Type compatibility* (также *type equivalence*, *nominal typing*, *structural typing*, *duck typing*) · [в онтологии](concepts.md#typing-compatibility)

- **Номинальная (layer: language, profile: csharp12, applies_to: классы, структуры и интерфейсы)** — Совпадения методов недостаточно для реализации интерфейса: требуется объявленная связь. Отдельные языковые протоколы, например foreach, также допускают pattern-based правила.

#### Типы-произведения { #typing-product-types }

англ. *Product types* (также *tuples*, *records*, *structs*) · [в онтологии](concepts.md#typing-product-types)

- **Записи и структуры (layer: language, profile: csharp12)** — struct, class, record class и record struct; record сам по себе не является типом-суммой.
- **Кортежи (layer: language, profile: csharp12)** — Кортежные типы с именованными или позиционными компонентами; имена элементов не определяют совместимость.

#### Представление отсутствия значения { #typing-nullability }

англ. *Nullability* (также *null reference*, *option type*) · [в онтологии](concepts.md#typing-nullability)

- **Явно nullable-типы (layer: language, profile: csharp12)** — T? для значимого T обозначает `Nullable<T>`. Для ссылочного T аннотация ? участвует в статическом анализе и не создаёт отдельный runtime-тип; нарушение обычно диагностируется предупреждением. ([Nullable reference types](https://learn.microsoft.com/en-us/dotnet/csharp/nullable-references); [Nullable value types](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/nullable-value-types))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

англ. *Conditional selection* (также *selection statement*, *conditional expression*) · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: csharp12)**
- **Условное выражение (layer: language, profile: csharp12)** — if/else, ?: и switch expression; обычное условие требует bool либо соответствующих пользовательских операторов истинности.

#### Выбор по значению switch/case { #control-switch }

англ. *Switch statement* (также *case statement*, *multiway branch*) · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: csharp12)** — switch поддерживает константы и образцы; неявный переход из непустой секции в следующую запрещён.

#### Сопоставление с образцом { #control-pattern-matching }

англ. *Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **да (layer: language, profile: csharp12)** — is и switch поддерживают типовые, константные, property, positional, relational и list patterns. ([C# patterns reference](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/patterns))

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

англ. *Iteration* (также *loops*, *for loop*, *foreach loop*, *range-based for loop*) · [в онтологии](concepts.md#control-iteration)

- **Инициализация / условие / шаг (layer: language, profile: csharp12)**
- **По последовательности или итератору (layer: language, profile: csharp12)** — foreach и await foreach; интерфейс или подходящий pattern определяет протокол перечисления.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

англ. *Function overloading* (также *overloading*, *operator overloading*) · [в онтологии](concepts.md#subprograms-overloading)

- **да (layer: language, profile: csharp12)** — Методы и операторы могут перегружаться по допустимым различиям сигнатур; один возвращаемый тип не различает перегрузки методов.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

англ. *Parameter passing* (также *call by value*, *call by reference*, *call by sharing*) · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: csharp12)** — По умолчанию копируется значение: у class это ссылка, у struct — значение структуры. Изменение объекта class видно вызывающему, перепривязка параметра — нет.
- **По ссылке на переменную (layer: language, profile: csharp12)** — ref, out, in и ref readonly задают ссылочные параметры с разными ограничениями. out — ссылка на хранилище вызывающего с требованиями definite assignment, а не copy-out при возврате. ([Method parameters and modifiers](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/method-parameters); [C# 12 feature specification: ref readonly parameters](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/proposals/csharp-12.0/ref-readonly-parameters))

#### Вложенные именованные подпрограммы { #subprograms-nesting }

англ. *Nested functions* (также *nested subprograms*) · [в онтологии](concepts.md#subprograms-nesting)

- **да (layer: language, profile: csharp12)** — Local functions могут быть объявлены в телах методов и других допустимых локальных контекстах.

#### Захват окружения { #subprograms-closures }

англ. *Closures* (также *lambda capture*, *captured variables*) · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: csharp12)** — Лямбды и локальные функции могут захватывать внешние переменные; static local functions и static lambdas запрещают такой захват.

#### Анонимные функции { #subprograms-lambda }

англ. *Anonymous functions* (также *lambda expressions*, *function literals*) · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: csharp12)**

#### Параметрический полиморфизм { #subprograms-generics }

англ. *Parametric polymorphism* (также *generics*, *templates*) · [в онтологии](concepts.md#subprograms-generics)

- **да (layer: language, profile: csharp12)** — Обобщённые типы и методы; where задаёт ограничения параметров типов.

#### Реализация параметрического полиморфизма { #subprograms-generic-mechanism }

англ. *Generic implementation mechanism* (также *monomorphization*, *type erasure*, *template instantiation*) · [в онтологии](concepts.md#subprograms-generic-mechanism)

- **Параметры типов во время выполнения (layer: implementation, profile: dotnet8, implementation: .NET 8 / CLR)** — Сведения об аргументах обобщённых типов доступны во время выполнения. Разделение либо специализация машинного кода — отдельное решение CLR/JIT. ([Generics in the runtime](https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/generics/generics-in-the-run-time))

### Полиморфизм и организация { #abstraction }

#### Контракты полиморфизма { #abstraction-contracts }

англ. *Polymorphic contracts* (также *interfaces*, *traits*, *type classes*, *protocols*) · [в онтологии](concepts.md#abstraction-contracts)

- **Интерфейсы (layer: language, profile: csharp12)** — Интерфейсы могут иметь default implementations и static abstract members; применимые правила различаются для экземплярных и статических членов.

#### Диспетчеризация вызовов { #abstraction-dispatch }

англ. *Method dispatch* (также *static dispatch*, *dynamic dispatch*, *virtual functions*, *multiple dispatch*) · [в онтологии](concepts.md#abstraction-dispatch)

- **Статическая (layer: language, profile: csharp12)** — Обычное разрешение перегрузок и невиртуальные вызовы.
- **По одному динамическому типу (layer: language, profile: csharp12, applies_to: виртуальные экземплярные методы)** — Переопределение выбирается по динамическому типу получателя. Операции dynamic используют отдельный runtime binder.

#### Наследование реализации { #abstraction-inheritance }

англ. *Implementation inheritance* (также *inheritance*, *subclassing*, *derived classes*) · [в онтологии](concepts.md#abstraction-inheritance)

- **Одиночное (layer: language, profile: csharp12)** — Класс имеет один непосредственный базовый класс и может реализовывать несколько интерфейсов; структуры не наследуются от пользовательских структур или классов.

#### Модульность { #abstraction-modules }

англ. *Modules* (также *module system*, *namespaces*, *packages*) · [в онтологии](concepts.md#abstraction-modules)

- **Пространства имён и пакеты (layer: language, profile: csharp12)** — namespace группирует имена; сборки и модификаторы доступности задают другие границы, пространство имён не равно сборке.

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

англ. *Evaluation strategy* (также *eager evaluation*, *lazy evaluation*) · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: csharp12)** — Обычные аргументы вычисляются слева направо; iterator methods откладывают обход тела, а не вычисление произвольных аргументов вызова.

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

англ. *Memory management* (также *memory reclamation*, *garbage collection*, *reference counting*) · [в онтологии](concepts.md#memory-management)

- **Трассирующая сборка мусора (layer: implementation, profile: dotnet8, implementation: .NET 8 / CLR)** — Сборщик освобождает недостижимые управляемые объекты; это не своевременное освобождение файлов, сокетов или иной неуправляемой памяти. ([Fundamentals of garbage collection](https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/fundamentals))

#### Передача и разделение владения { #memory-transfer }

англ. *Ownership transfer and sharing* (также *move semantics*, *copy semantics*, *borrowing*) · [в онтологии](concepts.md#memory-transfer)

- **Копирование значения (layer: language, profile: csharp12, applies_to: значимые типы при передаче и присваивании по значению)** — Ссылочные поля структуры продолжают обозначать те же объекты; глубокого копирования графа нет.
- **Разделяемая ссылка на объект (layer: language, profile: csharp12, applies_to: значения ссылочных типов)**

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

англ. *Error handling* (также *exceptions*, *result types*, *error codes*) · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: language, profile: csharp12)** — throw, try/catch, фильтры when и finally; общего требования объявлять throws нет.

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

англ. *Resource cleanup* (также *RAII*, *deterministic destruction*, *finally*, *defer*) · [в онтологии](concepts.md#resources-cleanup)

- **Блок finally / unwind-protect (layer: language, profile: csharp12)**
- **Конструкция управления ресурсом (layer: language, profile: csharp12)** — using statement/declaration организует Dispose при выходе, await using — DisposeAsync. Метод-деструктор C# является финализатором, а не детерминированным RAII-деструктором C++. ([The using statement](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/using))

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

англ. *Input/output* (также *I/O library*) · [в онтологии](concepts.md#resources-io)

- **API стандартной библиотеки (layer: standard_library, profile: dotnet8)** — System.Console и System.IO в библиотеках .NET; это API, а не ключевые слова C#.

#### Конкурентное выполнение { #resources-concurrency }

англ. *Concurrency* (также *threads*, *async/await*, *actors*) · [в онтологии](concepts.md#resources-concurrency)

- **Асинхронные корутины (layer: language, profile: csharp12)** — async/await — языковой протокол ожидаемых операций; он не гарантирует выделение отдельного потока для метода.

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

англ. *Syntactic grouping boundaries* (также *block delimiters*, *compound statement*, *off-side rule*) · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: csharp12)**
