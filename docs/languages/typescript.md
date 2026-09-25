---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# TypeScript

TypeScript добавляет к JavaScript статическую проверку, структурную совместимость и стираемые типы. Базовый профиль — TypeScript 5.0 со strict; Handbook служит первичным описанием, а не отдельным стандартом ISO. Ввод-вывод зависит от JavaScript-хоста.

*Карточка сравнительная: 35/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 2012 — [Wikidata P571](https://www.wikidata.org/wiki/Q978185) (получено 2026-09-24) |
| Авторы | [Андерс Хейлсберг](people.md#hejlsberg) |
| Организации | Microsoft |
| Сайт | <https://www.typescriptlang.org/> |
| Спецификация | <https://www.typescriptlang.org/docs/handbook/> |
| Внешние каталоги | [Wikidata Q978185](https://www.wikidata.org/wiki/Q978185) |

## Люди { #people }

- [Андерс Хейлсберг](people.md#hejlsberg) — Автор Turbo Pascal; ведущий архитектор Delphi, C# и TypeScript.

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **ts5_strict** — TypeScript 5.0, strict: true (включая strictNullChecks и noImplicitAny), модули ES и target ES2022; базовый профиль всех записей. Более поздние возможности ветки 5.x не предполагаются.
- **javascript_runtime** — JavaScript после стирания типов TypeScript 5.0; семантика выполнения ECMAScript, без runtime-проверки интерфейсов и аннотаций.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: ts5_strict)**
- **Связывание образцом (layer: language, profile: ts5_strict)** — let/const/var и деструктуризация; аннотация типа не обязательна для каждого объявления.

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: ts5_strict, applies_to: let и var)**
- **Неизменяемое (layer: language, profile: ts5_strict, applies_to: const)** — const не замораживает объект; readonly — отдельное статическое ограничение, также не выполняющее Object.freeze.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: ts5_strict)**
- **Распаковка при присваивании (layer: language, profile: ts5_strict)**

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: ts5_strict)**

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Блок (layer: language, profile: ts5_strict)**
- **Подпрограмма (layer: language, profile: ts5_strict)**
- **Модуль (layer: language, profile: ts5_strict)**
- **Класс (layer: language, profile: ts5_strict)**

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Статическая (layer: language, profile: ts5_strict)** — Проверка выполняется компилятором; strict не делает систему типов полностью sound. Явный any и type assertions допускают обход части проверок. ([TSConfig: strict](https://www.typescriptlang.org/tsconfig/strict.html); [Type Compatibility: A Note on Soundness](https://www.typescriptlang.org/docs/handbook/type-compatibility.html))
- **Динамическая (layer: language, profile: javascript_runtime)** — Во время выполнения действуют проверки операций JavaScript; статические типы TypeScript не становятся runtime-контрактами.

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Необязательны (layer: language, profile: ts5_strict)** — Аннотации дополняют вывод типов; noImplicitAny требует устранить неявный any там, где тип вывести не удалось.

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **да (layer: language, profile: ts5_strict)** — Типы инициализаторов, контекстная типизация, вывод аргументов обобщённых функций и narrowing по потоку управления.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: javascript_runtime)** — Number/String/Boolean преобразуют значения. Type assertions через as и non-null assertion стираются: они не превращают строку в число и не проверяют значение. ([Everyday Types: Type Assertions](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions))
- **Неявные (layer: language, profile: javascript_runtime)** — Остаются преобразования ECMAScript; компилятор может отклонить часть выражений, которые JavaScript допускает.

#### Совместимость типов { #typing-compatibility }

*Type compatibility* · [в онтологии](concepts.md#typing-compatibility)

- **Структурная (layer: language, profile: ts5_strict)** — Совместимость объектов определяется членами. private/protected-члены классов и некоторые другие типы вводят дополнительные ограничения происхождения. ([TypeScript: Type Compatibility](https://www.typescriptlang.org/docs/handbook/type-compatibility.html))

#### Типы-суммы { #typing-sum-types }

*Sum types* · [в онтологии](concepts.md#typing-sum-types)

- **Объединения типов (layer: language, profile: ts5_strict)** — Объединения типов и discriminated unions проверяются статически; поле-дискриминант — обычное значение JavaScript, а не автоматически добавленная метка. ([Narrowing: Discriminated unions](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#discriminated-unions))

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Записи и структуры (layer: language, profile: ts5_strict)** — Объектные типы с именованными свойствами.
- **Кортежи (layer: language, profile: ts5_strict)** — Статически типизированные позиции и длина; runtime-представление — массив JavaScript.

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Явно nullable-типы (layer: language, profile: ts5_strict)** — При strictNullChecks null и undefined — отдельные типы; допустимость задаётся объединением. Утверждение ! не добавляет runtime-проверки. ([TSConfig: strictNullChecks](https://www.typescriptlang.org/tsconfig/strictNullChecks.html))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: ts5_strict)**
- **Условное выражение (layer: language, profile: ts5_strict)** — if/else и ?:; анализ условий может сужать статический тип.

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: ts5_strict)** — switch из JavaScript участвует в narrowing discriminated union.

#### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **нет (layer: language, profile: ts5_strict)** — Сужение типов и деструктуризация не вводят отдельную конструкцию match.

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **Инициализация / условие / шаг (layer: language, profile: ts5_strict)**
- **По последовательности или итератору (layer: language, profile: ts5_strict)** — for-of и for-in сохраняют различие значений iterable и перечислимых ключей.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **да (layer: language, profile: ts5_strict)** — Несколько видимых сигнатур с одним телом реализации. Компилятор выбирает сигнатуру, но не генерирует runtime-диспетчеризацию по типам. ([More on Functions: Function Overloads](https://www.typescriptlang.org/docs/handbook/2/functions.html#function-overloads))

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: ts5_strict)** — Переприсваивание параметра не изменяет переменную вызывающего.
- **Разделение объекта (layer: language, profile: ts5_strict, applies_to: объекты JavaScript)** — Мутация разделяемого объекта наблюдаема вызывающим; readonly ограничивает операции только статически.

#### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms* · [в онтологии](concepts.md#subprograms-nesting)

- **да (layer: language, profile: ts5_strict)**

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: ts5_strict)**

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: ts5_strict)**

#### Параметрический полиморфизм { #subprograms-generics }

*Parametric polymorphism* · [в онтологии](concepts.md#subprograms-generics)

- **да (layer: language, profile: ts5_strict)** — Параметры типов функций, интерфейсов и классов; ограничения extends проверяются статически.

#### Реализация параметрического полиморфизма { #subprograms-generic-mechanism }

*Generic implementation mechanism* · [в онтологии](concepts.md#subprograms-generic-mechanism)

- **Стирание типов (layer: language, profile: ts5_strict)** — Параметры типов и интерфейсы отсутствуют в JavaScript-результате. Это не означает стирания всех конструкций TS: например, обычные enum могут генерировать код. ([TypeScript: Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html); [The Basics: Erased Types](https://www.typescriptlang.org/docs/handbook/2/basic-types.html#erased-types))

### Полиморфизм и организация { #abstraction }

#### Контракты полиморфизма { #abstraction-contracts }

*Polymorphic contracts* · [в онтологии](concepts.md#abstraction-contracts)

- **Интерфейсы (layer: language, profile: ts5_strict)** — Структурные интерфейсы; implements проверяет класс, но не добавляет проверки во время выполнения.

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Одиночное (layer: language, profile: ts5_strict)** — Класс имеет один базовый класс; интерфейсы могут расширять несколько интерфейсов без наследования реализации.

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Явная граница экспорта (layer: language, profile: ts5_strict)** — import/export; import type и export type стираются. Разрешение и загрузка исполняемых модулей зависят от настроек и хоста.

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: ts5_strict)** — Обычные аргументы вычисляются по правилам JavaScript перед вызовом.

### Память и владение { #memory }

#### Передача и разделение владения { #memory-transfer }

*Ownership transfer and sharing* · [в онтологии](concepts.md#memory-transfer)

- **Разделяемая ссылка на объект (layer: language, profile: ts5_strict, applies_to: объектные значения)** — Статическая аннотация не меняет runtime-разделение объектов.

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: language, profile: ts5_strict)** — throw/try/catch из JavaScript; при strict переменная catch по умолчанию имеет тип unknown.

<a id="errors-checked"></a>

#### Проверяемые исключения { #errors-checked-exceptions }

*Checked exceptions* · [в онтологии](concepts.md#errors-checked-exceptions)

- **нет (layer: language, profile: ts5_strict)** — Тип функции не задаёт обязательный список throws; обработка исключения не проверяется как в Java.

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Блок finally / unwind-protect (layer: language, profile: ts5_strict)** — Базовый профиль 5.0 использует try/finally; explicit resource management из более поздних версий не включён.

#### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · [в онтологии](concepts.md#resources-concurrency)

- **Асинхронные корутины (layer: language, profile: ts5_strict)** — Статические типы `Promise<T>` описывают результаты; планирование и I/O остаются обязанностью JavaScript-хоста.

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: ts5_strict)**

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: ts5_strict)**
- **Объектно-ориентированная (layer: language, profile: ts5_strict)**
- **Функциональная (layer: language, profile: ts5_strict)**
