---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Rust

Компилируемый язык со статической проверкой типов, управлением памятью через владение и заимствование без сборщика мусора и обработкой ошибок через значения `Result`. Компилируется через LLVM — одну из целевых платформ курса.

*Карточка полная: 51/74 понятий; пример, грамматика, оценка* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 2010 — [PLDB appeared](https://pldb.io/concepts/rust.html) (получено 2026-09-18); [Wikidata P571 (2006 — начало разработки)](https://www.wikidata.org/wiki/Q575650) (получено 2026-09-18) |
| Авторы | [Грэйдон Хор](people.md#graydon-hoare) |
| Организации | Mozilla Research, Rust Foundation |
| Сайт | <https://www.rust-lang.org/> |
| Спецификация | <https://doc.rust-lang.org/reference/> |
| Внешние каталоги | [Wikidata Q575650](https://www.wikidata.org/wiki/Q575650), [PLDB](https://pldb.io/concepts/rust.html), [Rosetta Code](https://rosettacode.org/wiki/Category:Rust) |

## Версии { #versions }

Перечислены вехи, на которые ссылаются концепции ниже, а не все выпуски.

| Версия | Дата | Тип | Источник |
|---|---|---|---|
| Rust 1.0 — первый выпуск | 2015-05-15 | выпуск | [Wikidata P348 1.0.0](https://www.wikidata.org/wiki/Q575650) (получено 2026-09-18) |
| Rust 1.59 | 2022-02-24 | выпуск | [Announcing Rust 1.59.0](https://blog.rust-lang.org/2022/02/24/Rust-1.59.0.html) (получено 2026-09-18) |
| Rust 1.98 — актуальная | 2026-09-01 | выпуск | [Wikidata P348 1.98.0](https://www.wikidata.org/wiki/Q575650) (получено 2026-09-18) |

## Люди { #people }

- [Грэйдон Хор](people.md#graydon-hoare) — Начал Rust как личный проект; затем язык развивался в Mozilla Research.

## Публикации { #publications }

- Nicholas D. Matsakis, Felix S. Klock II. *[The Rust Language](https://doi.org/10.1145/2692956.2663188)*. ACM SIGAda Ada Letters 34(3), HILT '14, 2014.
- Ralf Jung, Jacques-Henri Jourdan, Robbert Krebbers, Derek Dreyer. *[RustBelt: Securing the Foundations of the Rust Programming Language](https://doi.org/10.1145/3158154)*. Proc. ACM Program. Lang. 2, POPL, 2018.
- Steve Klabnik, Carol Nichols. *[The Rust Programming Language](https://doc.rust-lang.org/book/)*. No Starch Press, 2018.

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **rust2024** — Rust, edition 2024; базовый профиль языка и стандартной библиотеки. Редакция языка не равна номеру выпуска rustc; исторические границы и контексты safe/locals/signatures отмечены отдельно.
- **safe** — Безопасный Rust без unsafe-операций.
- **locals** — Локальные связывания и замыкания с выводом типов.
- **signatures** — Сигнатуры именованных функций.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: rust2024)** — ключевое слово `let`; тип указывается или выводится компилятором; без `mut` переменная неизменяема
- **Связывание образцом (layer: language, profile: rust2024, applies_to: let и образцы match)**

```rust
--8<-- "examples/rust/showcase.rs:variants-1"
```

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Неизменяемое (layer: language, profile: rust2024)** — по умолчанию; внутренняя изменяемость объекта не равна перепривязке имени
- **Перепривязываемое (layer: language, profile: rust2024, applies_to: let mut)**

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: rust2024)**
- **Распаковка при присваивании (с Rust 1.59 включительно, layer: language, profile: rust2024)** — деструктуризация кортежа: `(a, b) = (b, a)`; при объявлении `let (a, b) = …` — с 1.0

```rust
--8<-- "examples/rust/showcase.rs:variants-3"
```

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: rust2024)**

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Подпрограмма (layer: language, profile: rust2024)**
- **Модуль (layer: language, profile: rust2024)**
- **Блок (layer: language, profile: rust2024)** — любой блок `{ }` — область видимости; блок — выражение

```rust
--8<-- "examples/rust/showcase.rs:variants-4"
```

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

*Top-level bindings* · [в онтологии](concepts.md#scope-globals)

- **Имена модуля (layer: language, profile: rust2024)** — `static`; изменение `static mut` требует `unsafe`, обычно используют атомики или `Mutex`

```rust
--8<-- "examples/rust/showcase.rs:req-8-2"
```

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

*Name shadowing* · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: rust2024)**
- **Новое связывание в той же области (layer: language, profile: rust2024)** — повторный `let x` в той же области создаёт новую переменную (идиома для смены типа)

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Статическая (layer: language, profile: rust2024)**

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Необязательны (layer: language, profile: locals)**
- **Обязательны (layer: language, profile: signatures)**

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **да (layer: language, profile: locals)** — локальный вывод (Hindley–Milner-подобный) внутри функции; сигнатуры функций аннотируются явно

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: rust2024)** — `as` для примитивов, `From`/`Into`, `parse`; арифметика между i32 и f64 без приведения — ошибка компиляции
- **Неявные (layer: language, profile: rust2024, applies_to: разрешённые позиции coercion)** — ограниченные coercions, например &mut T → &T, &[T; N] → &[T], deref coercion; не произвольное числовое расширение

```rust
--8<-- "examples/rust/showcase.rs:variants-2"
```

#### Совместимость типов { #typing-compatibility }

*Type compatibility* · [в онтологии](concepts.md#typing-compatibility)

- **Номинальная (layer: language, profile: rust2024, applies_to: struct, enum и явные реализации trait)**
- **Структурная (layer: language, profile: rust2024, applies_to: кортежи и типы указателей на функции)**

#### Типы-суммы { #typing-sum-types }

*Sum types* · [в онтологии](concepts.md#typing-sum-types)

- **Размеченные варианты (layer: language, profile: rust2024)** — enum с данными вариантов

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Кортежи (layer: language, profile: rust2024)**
- **Записи и структуры (layer: language, profile: rust2024)**

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Тип Option/Optional (layer: standard_library, profile: safe)** — `Option<T>`; null-ссылок в безопасном коде нет

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условное выражение (layer: language, profile: rust2024)** — `if`/`else if`/`else` и `match` — сопоставление с образцом с проверкой полноты; оба — выражения

```rust
--8<-- "examples/rust/showcase.rs:variants-6"
```

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **нет (layer: language, profile: rust2024)**

#### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **да (layer: language, profile: rust2024)**

<a id="req-7-2-until"></a>

#### Цикл до истинности условия { #control-until }

*Until loop* · [в онтологии](concepts.md#control-until)

- **Отдельная конструкция отсутствует (layer: language, profile: rust2024)** — Предусловие: `while !cond`; постусловие: `loop { ...; if cond { break } }`.

```rust
--8<-- "examples/rust/showcase.rs:req-7-2-until"
```

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · [в онтологии](concepts.md#control-do-while)

- **нет (layer: language, profile: rust2024)** — do-while(cond) имитируется `loop { ...; if !cond { break } }`

```rust
--8<-- "examples/rust/showcase.rs:req-7-2-do-while"
```

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **По последовательности или итератору (layer: language, profile: rust2024)** — `for x in iter`; счётный цикл — диапазон `0..n`

```rust
--8<-- "examples/rust/showcase.rs:req-7-3"
```

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: rust2024)** — две `fn` с одним именем в одной области — ошибка; полиморфизм — через трейты и обобщения

```rust
--8<-- "examples/rust/showcase.rs:variants-7"
```

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: rust2024)** — аргумент передаёт значение; это относится и к значениям ссылок. Копирование, перемещение и заимствование — отдельная ось.

```rust
--8<-- "examples/rust/showcase.rs:variants-8"
```

<a id="variants-9"></a>

#### Место определения подпрограмм { #subprograms-placement }

*Subprogram definition placement* · [в онтологии](concepts.md#subprograms-placement)

- **Верхний уровень модуля (layer: language, profile: rust2024)**
- **Член типа (layer: language, profile: rust2024)**
- **Локальное определение (layer: language, profile: rust2024)** — вложенная `fn` не захватывает переменные внешней; для этого — замыкания `|x| …`

```rust
--8<-- "examples/rust/showcase.rs:variants-9"
```

#### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms* · [в онтологии](concepts.md#subprograms-nesting)

- **да (layer: language, profile: rust2024)**

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: rust2024)**

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: rust2024)** — замыкания `|x| x + 1`; три трейта `Fn`/`FnMut`/`FnOnce` по способу захвата

#### Параметрический полиморфизм { #subprograms-generics }

*Parametric polymorphism* · [в онтологии](concepts.md#subprograms-generics)

- **да (layer: language, profile: rust2024)** — мономорфизация во время компиляции; ограничения через трейты (`T: Display`)

#### Реализация параметрического полиморфизма { #subprograms-generic-mechanism }

*Generic implementation mechanism* · [в онтологии](concepts.md#subprograms-generic-mechanism)

- **Мономорфизация (layer: implementation, profile: rust2024, implementation: rustc)**

#### Аргументы по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **нет (layer: language, profile: rust2024)** — эквивалент — `Option<T>` в параметре или паттерн builder

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **нет (layer: language, profile: rust2024)** — эквивалент — структура-параметр

### Полиморфизм и организация { #abstraction }

#### Контракты полиморфизма { #abstraction-contracts }

*Polymorphic contracts* · [в онтологии](concepts.md#abstraction-contracts)

- **Трейты (layer: language, profile: rust2024)**

#### Диспетчеризация вызовов { #abstraction-dispatch }

*Call dispatch* · [в онтологии](concepts.md#abstraction-dispatch)

- **Статическая (layer: language, profile: rust2024, applies_to: обобщённые функции с ограничениями trait)**
- **По одному динамическому типу (layer: language, profile: rust2024, applies_to: вызовы через dyn Trait)**

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Отсутствует (layer: language, profile: rust2024)** — supertraits выражают ограничения, а не наследование полей и реализации класса

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Пространства имён и пакеты (layer: language, profile: rust2024)**
- **Явная граница экспорта (layer: language, profile: rust2024)** — mod, pub и pub use

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: rust2024)**

#### Контроль эффектов { #evaluation-effects }

*Effect control* · [в онтологии](concepts.md#evaluation-effects)

- **Без общего статического разделения эффектов (layer: language, profile: rust2024)** — владение и Send/Sync ограничивают отдельные операции, но общей системы чистых и эффектных функций нет

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · [в онтологии](concepts.md#evaluation-tail-calls)

- **нет (layer: language, profile: rust2024)**

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Владение и время жизни (layer: language, profile: safe)** — владение, перемещение, заимствование и времена жизни проверяются компилятором; освобождение — при выходе владельца из области (`Drop`)
- **Подсчёт ссылок (layer: standard_library, profile: rust2024, applies_to: разделяемое владение)** — `Rc<T>` / `Arc<T>` — явно, по выбору программиста

#### Передача и разделение владения { #memory-transfer }

*Ownership transfer and sharing* · [в онтологии](concepts.md#memory-transfer)

- **Копирование значения (layer: language, profile: rust2024, applies_to: типы Copy, включая &T, но не &mut T)**
- **Перемещение владения (layer: language, profile: rust2024, applies_to: передача принадлежащего вызывающему значения не-Copy типа)** — после вызова исходная переменная недоступна — компилятор запрещает использование
- **Разделяемое заимствование (layer: language, profile: safe)** — &T допускает разделяемый доступ; изменение через внутреннюю изменяемость (например Cell/Mutex) возможно
- **Исключительное заимствование (layer: language, profile: safe)** — &mut T даёт исключительный доступ на время активного заимствования; возможны временные reborrow

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Размеченный результат (layer: standard_library, profile: rust2024)** — `Result<T, E>` представляет успех или ошибку; оператор ? распространяет ошибку. `Option<T>` представляет отсутствие значения, а не отдельный тип ошибки.
- **Паника (layer: language, profile: rust2024)** — panic! запускает unwinding либо abort в зависимости от конфигурации; это отдельный от Result канал

<a id="errors-checked"></a>

#### Проверяемые исключения { #errors-checked-exceptions }

*Checked exceptions* · [в онтологии](concepts.md#errors-checked-exceptions)

- **нет (layer: language, profile: rust2024)** — Result — возвращаемое значение, не checked exception; требований catch/throws нет

#### Диагностика неиспользованного результата { #errors-must-use }

*Unused-result diagnostics* · [в онтологии](concepts.md#errors-must-use)

- **Предупреждение (layer: language, profile: rust2024, applies_to: значения типов и функций с #[must_use], в частности Result)** — unused_must_use по умолчанию предупреждение; `let _ = result;` явно отбрасывает результат. Уровень lint настраивается.

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Деструктор при выходе из области (layer: language, profile: rust2024)** — Drop при обычном выходе из области и unwinding; abort, утечка или mem::forget могут пропустить деструктор

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

*I/O interface* · [в онтологии](concepts.md#resources-io)

- **Макросы (layer: standard_library, profile: rust2024, applies_to: вывод)** — `println!`, `print!`, `eprintln!` — макросы стандартной библиотеки
- **API стандартной библиотеки (layer: standard_library, profile: rust2024, applies_to: ввод)** — `std::io::stdin().read_line(&mut s)` и `parse`; встроенных функций ввода нет

```rust
--8<-- "examples/rust/showcase.rs:req-4"
```

#### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · [в онтологии](concepts.md#resources-concurrency)

- **Потоки (layer: standard_library, profile: rust2024)**
- **Передача сообщений (layer: standard_library, profile: rust2024)**
- **Асинхронные корутины (layer: language, profile: rust2024)** — синтаксис языка; исполнитель Future выбирается отдельно

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: rust2024)** — фигурные скобки обязательны даже для одного оператора

```rust
--8<-- "examples/rust/showcase.rs:variants-5"
```

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Точка с запятой (layer: language, profile: rust2024)** — `;` превращает выражение в оператор; последнее выражение блока без `;` — его значение

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да (layer: language, profile: rust2024)**

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Синтаксические макросы (layer: language, profile: rust2024)** — macro_rules!
- **Процедурные макросы (layer: language, profile: rust2024)**
- **Вычисление при компиляции (layer: language, profile: rust2024)** — const-выражения и const fn с ограничениями

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: rust2024)**
- **Процедурная (layer: language, profile: rust2024)**
- **Функциональная (layer: language, profile: rust2024)** — замыкания, итераторы, `map`/`filter`, алгебраические типы, сопоставление с образцом
- **Объектно-ориентированная (layer: language, profile: rust2024)** — структуры + трейты; наследования реализации нет — композиция и обобщения

## Грамматика { #grammar }

Официальная грамматика: <https://doc.rust-lang.org/reference/>.

Фрагменты ниже взяты из сообщества grammars-v4 и **не являются нормативными**: они иллюстрируют, как правила записываются в нотации ANTLR4, которую вы используете в лабораторной работе 2. Нетерминалы, упомянутые в правиле, перечислены под ним со ссылкой на полный файл.

### `letStatement` { #rule-letstatement }

```antlr
--8<-- "grammar/rust/RustParser.fragments.g4:letStatement"
```

Источник: [`rust/RustParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4#L430), MIT. Нетерминалы: [`outerAttribute`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`patternNoTopAlt`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`type_`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4).

### `blockExpression` { #rule-blockexpression }

```antlr
--8<-- "grammar/rust/RustParser.fragments.g4:blockExpression"
```

Источник: [`rust/RustParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4#L537), MIT. Нетерминалы: [`innerAttribute`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`statements`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4).

### `ifExpression` { #rule-ifexpression }

```antlr
--8<-- "grammar/rust/RustParser.fragments.g4:ifExpression"
```

Источник: [`rust/RustParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4#L677), MIT. Нетерминалы: [`expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`blockExpression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`ifLetExpression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4).

### `matchExpression` { #rule-matchexpression }

```antlr
--8<-- "grammar/rust/RustParser.fragments.g4:matchExpression"
```

Источник: [`rust/RustParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4#L688), MIT. Нетерминалы: [`expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`innerAttribute`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`matchArms`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4).

### `loopExpression` { #rule-loopexpression }

```antlr
--8<-- "grammar/rust/RustParser.fragments.g4:loopExpression"
```

Источник: [`rust/RustParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4#L647), MIT. Нетерминалы: [`loopLabel`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`infiniteLoopExpression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`predicateLoopExpression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`predicatePatternLoopExpression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`iteratorLoopExpression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4).

### `function_` { #rule-function_ }

```antlr
--8<-- "grammar/rust/RustParser.fragments.g4:function_"
```

Источник: [`rust/RustParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4#L195), MIT. Нетерминалы: [`functionQualifiers`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`identifier`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`genericParams`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`functionParameters`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`functionReturnType`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`whereClause`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`blockExpression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4).

### `functionParamPattern` { #rule-functionparampattern }

```antlr
--8<-- "grammar/rust/RustParser.fragments.g4:functionParamPattern"
```

Источник: [`rust/RustParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4#L232), MIT. Нетерминалы: [`pattern`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4), [`type_`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/rust/RustParser.g4).

### Лицензия источника { #grammar-license }

`antlr/grammars-v4` / `rust/RustParser.g4` @ `20efa5375866` — MIT:

```text
--8<-- "grammar/rust/RustParser.fragments.g4:notice"
```

Другие грамматики и материалы:

- [Нотация грамматики в The Rust Reference](https://doc.rust-lang.org/reference/notation.html)
- [Rosetta Code: Rust](https://rosettacode.org/wiki/Category:Rust)

## Пример-витрина { #showcase }

Одна программа, в которой прокомментированы конструкции, соответствующие концепциям каталога — тот же формат, что у второго примера в лабораторной работе 1. Фрагменты этого файла показаны выше у каждой концепции.

```rust
--8<-- "examples/rust/showcase.rs"
```

## Оценка по критериям лекции 20 { #assessment }

Критерии — читабельность, лёгкость создания, надёжность, стоимость. Это оценки, а не свойства: они выводятся из концепций, на которые ссылается каждый пункт.

**Читабельность.** Синтаксис явный и единообразный (скобки, `let`, типы в сигнатурах), но аннотации времён жизни и обобщений с ограничениями трейтов делают сигнатуры длинными и требуют изучения дополнительных понятий. *([Введение связывания](#bindings-introduction), [Границы синтаксических групп](#syntax-blocks), [Вывод статических типов](#typing-inference))*

**Лёгкость создания.** Вывод типов внутри функций и выражения-блоки сокращают код, но проверка заимствований заставляет заранее продумывать владение данными; высокая «входная цена». *([Связывание параметров](#subprograms-parameter-passing), [Передача и разделение владения](#memory-transfer), [Освобождение памяти](#memory-management))*

**Надёжность.** Статическая проверка типов, ненулевые ссылки и проверка владения предотвращают многие ошибки памяти в безопасном коде. Result явно представляет ошибку; предупреждение о неиспользованном результате допускает явное отбрасывание и не гарантирует обработку ошибки. *([Проверка типов](#typing-checking), [Представление отсутствия значения](#typing-nullability), [Представление и передача ошибок](#errors-model), [Диагностика неиспользованного результата](#errors-must-use), [Освобождение памяти](#memory-management))*

**Стоимость.** Дольше учить и дольше компилировать; окупается там, где критичны производительность и безопасность памяти без сборщика мусора. *([Освобождение памяти](#memory-management))*
