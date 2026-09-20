---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные index.md и concepts.md сохраняются при пересборке. -->

# Rust

Компилируемый язык со статической проверкой типов, управлением памятью через владение и заимствование без сборщика мусора и обработкой ошибок через значения `Result`. Компилируется через LLVM — одну из целевых платформ курса.

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 2010 — [PLDB appeared](https://pldb.io/concepts/rust.html) (получено 2026-09-18); [Wikidata P571 (2006 — начало разработки)](https://www.wikidata.org/wiki/Q575650) (получено 2026-09-18) |
| Авторы | Graydon Hoare |
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

## Публикации { #publications }

- Nicholas D. Matsakis, Felix S. Klock II. *[The Rust Language](https://doi.org/10.1145/2692956.2663188)*. ACM SIGAda Ada Letters 34(3), HILT '14, 2014.
- Ralf Jung, Jacques-Henri Jourdan, Robbert Krebbers, Derek Dreyer. *[RustBelt: Securing the Foundations of the Rust Programming Language](https://doi.org/10.1145/3158154)*. Proc. ACM Program. Lang. 2, POPL, 2018.
- Steve Klabnik, Carol Nichols. *[The Rust Programming Language](https://doc.rust-lang.org/book/)*. No Starch Press, 2018.

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

### Свойства проектируемого языка { #variants }

#### Объявление переменных { #variants-1 }

*Variable declaration* · [в онтологии](concepts.md#variants-1)

- **Явное** — ключевое слово `let`; тип указывается или выводится компилятором; без `mut` переменная неизменяема

```rust
--8<-- "examples/rust/showcase.rs:variants-1"
```

#### Преобразование типов { #variants-2 }

*Type conversion* · [в онтологии](concepts.md#variants-2)

- **Явное** — `as` для примитивов, `From`/`Into`, `parse`; арифметика между i32 и f64 без приведения — ошибка компиляции

```rust
--8<-- "examples/rust/showcase.rs:variants-2"
```

#### Оператор присваивания { #variants-3 }

*Assignment* · [в онтологии](concepts.md#variants-3)

- **Одиночный**
- **Множественный (Rust 1.59)** — деструктуризация кортежа: `(a, b) = (b, a)`; при объявлении `let (a, b) = …` — с 1.0

```rust
--8<-- "examples/rust/showcase.rs:variants-3"
```

#### Структуры, ограничивающие область видимости { #variants-4 }

*Scoping constructs* · [в онтологии](concepts.md#variants-4)

- **Подпрограммы и блочные операторы** — любой блок `{ }` — область видимости; блок — выражение

```rust
--8<-- "examples/rust/showcase.rs:variants-4"
```

#### Маркер блочного оператора { #variants-5 }

*Block delimiter* · [в онтологии](concepts.md#variants-5)

- **Явный** — фигурные скобки обязательны даже для одного оператора

```rust
--8<-- "examples/rust/showcase.rs:variants-5"
```

#### Условные операторы { #variants-6 }

*Conditional statements* · [в онтологии](concepts.md#variants-6)

- **Двухвариантный и многовариантный switch-case** — `if`/`else if`/`else` и `match` — сопоставление с образцом с проверкой полноты; оба — выражения

```rust
--8<-- "examples/rust/showcase.rs:variants-6"
```

#### Перегрузка подпрограмм { #variants-7 }

*Subprogram overloading* · [в онтологии](concepts.md#variants-7)

- **Отсутствует** — две `fn` с одним именем в одной области — ошибка; полиморфизм — через трейты и обобщения

```rust
--8<-- "examples/rust/showcase.rs:variants-7"
```

#### Передача параметров в подпрограмму { #variants-8 }

*Parameter passing* · [в онтологии](concepts.md#variants-8)

- **По значению** — для: типы с трейтом Copy (числа, bool, char, ссылки)
- **Перемещение** — для: остальные типы; после вызова исходная переменная недоступна — компилятор запрещает использование
- **Заимствование** — `&T` — разделяемая ссылка только на чтение; таких ссылок может быть несколько
- **Изменяемое заимствование** — `&mut T` — единственная ссылка с правом записи; проверяется компилятором (borrow checker)

```rust
--8<-- "examples/rust/showcase.rs:variants-8"
```

#### Допустимое место объявления подпрограмм { #variants-9 }

*Subprogram declaration placement* · [в онтологии](concepts.md#variants-9)

- **В любом месте** — вложенная `fn` не захватывает переменные внешней; для этого — замыкания `|x| …`

```rust
--8<-- "examples/rust/showcase.rs:variants-9"
```

### Обязательные требования к языку { #requirements }

#### Встроенный ввод-вывод { #req-4 }

*Built-in I/O* · [в онтологии](concepts.md#req-4)

- **Макросы** — для: вывод; `println!`, `print!`, `eprintln!` — макросы стандартной библиотеки
- **Функции стандартной библиотеки** — для: ввод; `std::io::stdin().read_line(&mut s)` и `parse`; встроенных функций ввода нет

```rust
--8<-- "examples/rust/showcase.rs:req-4"
```

#### Цикл с постусловием until { #req-7-2-until }

*until loop* · [в онтологии](concepts.md#req-7-2-until)

- **нет** — эквивалент — `while !cond`

```rust
--8<-- "examples/rust/showcase.rs:req-7-2-until"
```

#### Цикл do-while { #req-7-2-do-while }

*do-while loop* · [в онтологии](concepts.md#req-7-2-do-while)

- **нет** — эквивалент — `loop { …; if cond { break } }`

```rust
--8<-- "examples/rust/showcase.rs:req-7-2-do-while"
```

#### Оператор цикла с итерациями for { #req-7-3 }

*for loop form* · [в онтологии](concepts.md#req-7-3)

- **По коллекции (foreach)** — `for x in iter`; счётный цикл — диапазон `0..n`

```rust
--8<-- "examples/rust/showcase.rs:req-7-3"
```

#### Глобальная область видимости для переменных { #req-8-2 }

*Global variables* · [в онтологии](concepts.md#req-8-2)

- **Есть глобальные переменные** — `static`; изменение `static mut` требует `unsafe`, обычно используют атомики или `Mutex`

```rust
--8<-- "examples/rust/showcase.rs:req-8-2"
```

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Статическая**

#### Сильная и слабая типизация { #typing-strength }

*Type strength* · [в онтологии](concepts.md#typing-strength)

- **Сильная** — неявных приведений между числовыми типами нет

#### Вывод типов { #typing-inference }

*Type inference* · [в онтологии](concepts.md#typing-inference)

- **да** — локальный вывод (Hindley–Milner-подобный) внутри функции; сигнатуры функций аннотируются явно

#### Отсутствие значения (null) { #typing-nullability }

*Nullability* · [в онтологии](concepts.md#typing-nullability)

- **Отдельный тип-обёртка (Option/Optional)** — `Option<T>`; null-ссылок в безопасном коде нет

### Управление памятью { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Владение и время жизни** — владение, перемещение, заимствование и времена жизни проверяются компилятором; освобождение — при выходе владельца из области (`Drop`)
- **Подсчёт ссылок** — для: разделяемое владение; `Rc<T>` / `Arc<T>` — явно, по выбору программиста

### Парадигмы программирования { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная**
- **Процедурная**
- **Функциональная** — замыкания, итераторы, `map`/`filter`, алгебраические типы, сопоставление с образцом
- **Объектно-ориентированная** — структуры + трейты; наследования реализации нет — композиция и обобщения

### Обработка исключительных ситуаций { #errors }

#### Модель обработки ошибок { #errors-model }

*Error handling model* · [в онтологии](concepts.md#errors-model)

- **Значение-результат (Result / коды ошибок)** — `Result<T, E>` и `Option<T>`, оператор `?` для проброса; `panic!` — для невосстановимых ошибок, не для управления потоком

#### Блоки с гарантированным завершением { #errors-finally }

*Guaranteed cleanup blocks* · [в онтологии](concepts.md#errors-finally)

- **нет** — освобождение ресурсов — через `Drop` при выходе из области (RAII), отдельного `finally` нет

#### Проверяемые исключения в сигнатуре { #errors-checked }

*Checked exceptions* · [в онтологии](concepts.md#errors-checked)

- **да** — тип ошибки — часть сигнатуры `fn f() -> Result<T, E>`; игнорировать `Result` без `#[must_use]`-предупреждения нельзя

### Подпрограммы и абстракция { #subprograms }

#### Лямбда-функции { #subprograms-lambda }

*Lambda functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да** — замыкания `|x| x + 1`; три трейта `Fn`/`FnMut`/`FnOnce` по способу захвата

#### Обобщённые типы и подпрограммы { #subprograms-generics }

*Generics* · [в онтологии](concepts.md#subprograms-generics)

- **да** — мономорфизация во время компиляции; ограничения через трейты (`T: Display`)

#### Параметры по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **нет** — эквивалент — `Option<T>` в параметре или паттерн builder

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **нет** — эквивалент — структура-параметр

### Синтаксическая структура { #syntax }

#### Разделитель операторов { #syntax-statement-terminator }

*Statement terminator* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Точка с запятой обязательна** — `;` превращает выражение в оператор; последнее выражение блока без `;` — его значение

#### Чувствительность к регистру { #syntax-case-sensitive }

*Case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да**

#### Совмещение имён (shadowing) { #syntax-shadowing }

*Shadowing* · [в онтологии](concepts.md#syntax-shadowing)

- **Разрешено во вложенной области**
- **Разрешено даже в той же области** — повторный `let x` в той же области создаёт новую переменную (идиома для смены типа)

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

**Читабельность.** Синтаксис явный и единообразный (скобки, `let`, типы в сигнатурах), но аннотации времён жизни и обобщений с ограничениями трейтов делают сигнатуры длинными; для новичка — самый сложный из языков каталога. *([Объявление переменных](#variants-1), [Маркер блочного оператора](#variants-5), [Вывод типов](#typing-inference))*

**Лёгкость создания.** Вывод типов внутри функций и выражения-блоки сокращают код, но проверка заимствований заставляет заранее продумывать владение данными; высокая «входная цена». *([Передача параметров в подпрограмму](#variants-8), [Освобождение памяти](#memory-management))*

**Надёжность.** Статическая сильная типизация, отсутствие null, обязательная обработка `Result` и проверка владения исключают целые классы ошибок на этапе компиляции. *([Проверка типов](#typing-checking), [Отсутствие значения (null)](#typing-nullability), [Модель обработки ошибок](#errors-model), [Проверяемые исключения в сигнатуре](#errors-checked), [Освобождение памяти](#memory-management))*

**Стоимость.** Дольше учить и дольше компилировать; окупается там, где критичны производительность и безопасность памяти без сборщика мусора. *([Освобождение памяти](#memory-management))*
