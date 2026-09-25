---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Java

Объектно-ориентированный язык со статической проверкой типов, сборкой мусора и структурными исключениями, компилируемый в байт-код JVM — одну из целевых платформ курса. Второй по частоте язык реализации компиляторов в практикуме. Текущий срез свойств карточки — Java SE 21 без preview-возможностей; Java SE 26 в истории выпусков не означает проверки этих свойств для 26.

*Карточка полная: 51/74 понятий; пример, грамматика, оценка* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1995 — [Wikidata P571](https://www.wikidata.org/wiki/Q251) (получено 2026-09-18) |
| Авторы | [Джеймс Гослинг](people.md#gosling) |
| Организации | Sun Microsystems, Oracle |
| Сайт | <https://www.oracle.com/java/> |
| Спецификация | <https://docs.oracle.com/javase/specs/> |
| Внешние каталоги | [Wikidata Q251](https://www.wikidata.org/wiki/Q251), [PLDB](https://pldb.io/concepts/java.html), [HOPL 2131](https://hopl.info/showlanguage.prx?exp=2131), [Rosetta Code](https://rosettacode.org/wiki/Category:Java) |

## Версии { #versions }

Перечислены вехи, на которые ссылаются концепции ниже, а не все выпуски.

| Версия | Дата | Тип | Источник |
|---|---|---|---|
| Java 1.0 — первый выпуск | 1996-01-23 | выпуск | [Wikidata P571/P348](https://www.wikidata.org/wiki/Q251) (получено 2026-09-18) |
| Java SE 5 | 2004-09-30 | выпуск | [JDK 5.0 Release Notes](https://www.oracle.com/java/technologies/javase/jdk5-relnotes.html) (получено 2026-09-18) |
| Java SE 7 | 2011-07-28 | выпуск | [OpenJDK: JDK 7 General Availability](https://openjdk.org/projects/jdk7/) (получено 2026-09-20) |
| Java SE 8 | 2014-03-18 | выпуск | [Wikidata P348 Java SE 8](https://www.wikidata.org/wiki/Q251) (получено 2026-09-18) |
| Java SE 9 | 2017-09-21 | выпуск | [OpenJDK: JDK 9 General Availability](https://openjdk.org/projects/jdk9/) (получено 2026-09-20) |
| Java SE 10 | 2018-03-20 | выпуск | [JEP 286: Local-Variable Type Inference](https://openjdk.org/jeps/286) (получено 2026-09-18) |
| Java SE 17 | 2021-09-14 | выпуск | [OpenJDK: JDK 17 General Availability](https://openjdk.org/projects/jdk/17/) (получено 2026-09-20) |
| Java SE 21 | 2023-09-19 | выпуск | [OpenJDK: JDK 21 General Availability](https://openjdk.org/projects/jdk/21/) (получено 2026-09-20) |
| Java SE 26 — актуальная | 2026-03-17 | выпуск | [Wikidata P348 Java SE 26](https://www.wikidata.org/wiki/Q251) (получено 2026-09-18) |

## Люди { #people }

- [Джеймс Гослинг](people.md#gosling) — Ведущий разработчик Java в Sun Microsystems и соавтор спецификации языка.
- [Гай Стил](people.md#steele) — Автор «Common Lisp the Language», соавтор Scheme и спецификации Java.

## Публикации { #publications }

- James Gosling, Henry McGilton. *[The Java Language Environment: A White Paper](https://www.oracle.com/java/technologies/language-environment.html)*. Sun Microsystems, 1996.
- James Gosling, Bill Joy, Guy Steele, Gilad Bracha, Alex Buckley, Daniel Smith, Gavin Bierman. *[The Java Language Specification, Java SE 21 Edition](https://docs.oracle.com/javase/specs/jls/se21/html/index.html)*. Oracle, 2023.
- Joshua Bloch. *Effective Java, 3rd Edition*. Addison-Wesley, 2018.

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **java21** — Java SE 21, JLS 21 и стандартная библиотека, без preview-возможностей; базовый срез карточки. Исторические границы и локальные контексты отмечены отдельно.
- **local_variables** — Локальные переменные с инициализатором.
- **signatures** — Параметры и результаты методов, поля классов.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: java21)** — `int x = 1;` и `var x = 1;` — явные объявления; var опускает только аннотацию типа

```java
--8<-- "examples/java/Showcase.java:variants-1"
```

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: java21)**
- **Неизменяемое (layer: language, profile: java21, applies_to: final-переменные)** — final запрещает перепривязку, но не изменение объекта по ссылке.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: java21)** — `a = b = 0` — цепочка одиночных присваиваний; множественного `a, b = c, d` нет

```java
--8<-- "examples/java/Showcase.java:variants-3"
```

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: java21)**

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Подпрограмма (layer: language, profile: java21)**
- **Блок (layer: language, profile: java21)**
- **Класс (layer: language, profile: java21)**

```java
--8<-- "examples/java/Showcase.java:variants-4"
```

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

*Top-level bindings* · [в онтологии](concepts.md#scope-globals)

- **Статические члены типов (layer: language, profile: java21)** — любая переменная — член класса или локальная; эквивалент глобальной — `static`-поле

```java
--8<-- "examples/java/Showcase.java:req-8-2"
```

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

*Name shadowing* · [в онтологии](concepts.md#scope-shadowing)

- **Запрет сокрытия локальных в охватывающем блоке (layer: language, profile: java21, applies_to: локальные переменные)** — локальная переменная не может повторить имя другой локальной в охватывающем блоке того же метода
- **Во вложенной области (layer: language, profile: java21, applies_to: поля и параметры)** — локальная переменная или параметр может скрыть поле класса; доступ к полю — через `this`

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Статическая (layer: language, profile: java21)**

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Обязательны (layer: language, profile: signatures)**
- **Необязательны (с Java SE 10 включительно, layer: language, profile: local_variables, applies_to: локальные переменные с инициализатором)** — `var x = 1;` — тип выводится, но объявление остаётся явным (JEP 286); поля и параметры именованных методов требуют типа

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **да (с Java SE 10 включительно, layer: language, profile: local_variables, applies_to: локальные переменные с var)**
- **да (с Java SE 5 включительно, layer: language, profile: java21, applies_to: аргументы типов при вызове обобщённых методов)**
- **да (с Java SE 8 включительно, layer: language, profile: java21, applies_to: типы параметров лямбды из целевого функционального интерфейса)**

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: java21)** — оператор приведения `(int) x`; сужение может терять информацию
- **Неявные (layer: language, profile: java21, applies_to: расширяющие преобразования и boxing)** — Расширение int → float и long → float/double может терять точность (JLS 5.1.2). Есть boxing/unboxing и расширение ссылок; некоторые сужения констант допустимы без cast.

```java
--8<-- "examples/java/Showcase.java:variants-2"
```

#### Совместимость типов { #typing-compatibility }

*Type compatibility* · [в онтологии](concepts.md#typing-compatibility)

- **Номинальная (layer: language, profile: java21)**

#### Типы-суммы { #typing-sum-types }

*Sum types* · [в онтологии](concepts.md#typing-sum-types)

- **Закрытая иерархия (с Java SE 17 включительно, layer: language, profile: java21, applies_to: sealed-иерархии)** ([JEP 409: Sealed Classes](https://openjdk.org/jeps/409) (получено 2026-09-20))

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Записи и структуры (layer: language, profile: java21, applies_to: классы с полями; record-классы в Java 16 и новее)**

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Nullable-ссылки по умолчанию (layer: language, profile: java21)** — любая ссылка может быть `null`; `Optional<T>` (с 8) — библиотечная обёртка, не часть системы типов
- **Тип Option/Optional (с Java SE 8 включительно, layer: standard_library, profile: java21)** — `Optional<T>` представляет отсутствие значения, но сама ссылка Optional тоже может быть null.

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: java21)**
- **Условное выражение (layer: language, profile: java21)** — тернарное условное выражение `cond ? a : b`

```java
--8<-- "examples/java/Showcase.java:variants-6"
```

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: java21)** — `switch` по константам с 1.0; выражение `switch` со стрелками — с 14 (JEP 361); сопоставление по типам — с 21 (JEP 441)

#### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **да (с Java SE 21 включительно, layer: language, profile: java21, applies_to: record patterns)** — Деконструкция record-значений, включая вложенные образцы; граница относится к финализации record patterns, а не ко всем формам pattern matching. ([JEP 440: Record Patterns](https://openjdk.org/jeps/440) (получено 2026-09-20))

<a id="req-7-2-until"></a>

#### Цикл до истинности условия { #control-until }

*Until loop* · [в онтологии](concepts.md#control-until)

- **Отдельная конструкция отсутствует (layer: language, profile: java21)** — Предусловие имитируется `while (!cond)`, постусловие — `do { ... } while (!cond)`.

```java
--8<-- "examples/java/Showcase.java:req-7-2-until"
```

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · [в онтологии](concepts.md#control-do-while)

- **да (layer: language, profile: java21)**

```java
--8<-- "examples/java/Showcase.java:req-7-2-do-while"
```

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **Инициализация / условие / шаг (layer: language, profile: java21)** — `for (int i = 0; i < n; i++)`
- **По последовательности или итератору (с Java SE 5 включительно, layer: language, profile: java21)** — `for (T x : iterable)`

```java
--8<-- "examples/java/Showcase.java:req-7-3"
```

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **да (layer: language, profile: java21)** — выбор по статическим типам аргументов на этапе компиляции

```java
--8<-- "examples/java/Showcase.java:variants-7"
```

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: java21, applies_to: примитивные и ссылочные типы)** — JLS 8.4.1 формально называет это передачей по значению — копируется ссылка; изменение объекта видно вызывающему, перепривязка параметра — нет ([JLS 8.4.1 Formal Parameters](https://docs.oracle.com/javase/specs/jls/se21/html/jls-8.html#jls-8.4.1) (получено 2026-09-18))

```java
--8<-- "examples/java/Showcase.java:variants-8"
```

<a id="variants-9"></a>

#### Место определения подпрограмм { #subprograms-placement }

*Subprogram definition placement* · [в онтологии](concepts.md#subprograms-placement)

- **Член типа (layer: language, profile: java21)** — вложенных методов нет; обход — лямбды (с 8) и локальные классы внутри метода

```java
--8<-- "examples/java/Showcase.java:variants-9"
```

#### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms* · [в онтологии](concepts.md#subprograms-nesting)

- **нет (layer: language, profile: java21)**

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **да (с Java SE 8 включительно, layer: language, profile: java21, applies_to: лямбды)** — Лямбды захватывают final/effectively final локальные переменные. До лямбд локальные и анонимные внутренние классы уже могли захватывать final-локальные переменные.

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (с Java SE 8 включительно, layer: language, profile: java21)** — лямбда — реализация функционального интерфейса; захватываемые переменные должны быть effectively final

#### Параметрический полиморфизм { #subprograms-generics }

*Parametric polymorphism* · [в онтологии](concepts.md#subprograms-generics)

- **да (с Java SE 5 включительно, layer: language, profile: java21)** — стирание типов: во время выполнения параметры типов недоступны

#### Реализация параметрического полиморфизма { #subprograms-generic-mechanism }

*Generic implementation mechanism* · [в онтологии](concepts.md#subprograms-generic-mechanism)

- **Стирание типов (с Java SE 5 включительно, layer: language, profile: java21)**

#### Аргументы по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **нет (layer: language, profile: java21)** — эквивалент — перегрузка

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **нет (layer: language, profile: java21)** — эквивалент — паттерн builder

### Полиморфизм и организация { #abstraction }

#### Контракты полиморфизма { #abstraction-contracts }

*Polymorphic contracts* · [в онтологии](concepts.md#abstraction-contracts)

- **Интерфейсы (layer: language, profile: java21)**

#### Диспетчеризация вызовов { #abstraction-dispatch }

*Call dispatch* · [в онтологии](concepts.md#abstraction-dispatch)

- **Статическая (layer: language, profile: java21, applies_to: статические методы и выбор перегрузки)**
- **По одному динамическому типу (layer: language, profile: java21, applies_to: переопределяемые методы экземпляра)**

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Одиночное (layer: language, profile: java21)** — один суперкласс; интерфейсов может быть несколько, включая default-методы

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Пространства имён и пакеты (layer: language, profile: java21)**
- **Явная граница экспорта (с Java SE 9 включительно, layer: language, profile: java21, applies_to: модульная система Java)** ([JEP 261: Module System](https://openjdk.org/jeps/261) (получено 2026-09-20))

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: java21)**

#### Контроль эффектов { #evaluation-effects }

*Effect control* · [в онтологии](concepts.md#evaluation-effects)

- **Без общего статического разделения эффектов (layer: language, profile: java21)** — checked exceptions отслеживают часть ошибок, но общей системы эффектов нет

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · [в онтологии](concepts.md#evaluation-tail-calls)

- **нет (layer: language, profile: java21)**

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Трассирующая сборка мусора (layer: language, profile: java21)** — автоматическое освобождение памяти; конкретный сборщик выбирает реализация JVM, момент освобождения не гарантирован

#### Передача и разделение владения { #memory-transfer }

*Ownership transfer and sharing* · [в онтологии](concepts.md#memory-transfer)

- **Копирование значения (layer: language, profile: java21)** — копируется значение примитива или ссылки
- **Разделяемая ссылка на объект (layer: language, profile: java21, applies_to: объекты ссылочных типов)**

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: language, profile: java21)** — try / catch / finally; иерархия от Throwable

<a id="errors-checked"></a>

#### Проверяемые исключения { #errors-checked-exceptions }

*Checked exceptions* · [в онтологии](concepts.md#errors-checked-exceptions)

- **да (layer: language, profile: java21)** — проверяемые исключения объявляются в `throws`; непроверяемые (RuntimeException) — нет

#### Диагностика неиспользованного результата { #errors-must-use }

*Unused-result diagnostics* · [в онтологии](concepts.md#errors-must-use)

- **Нет специальной диагностики (layer: language, profile: java21)** — язык не требует использовать возвращённое значение метода

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Блок finally / unwind-protect (layer: language, profile: java21)**
- **Конструкция управления ресурсом (с Java SE 7 включительно, layer: language, profile: java21, applies_to: try-with-resources)** — вызывает close для AutoCloseable; прекращение процесса может пропустить очистку ([OpenJDK: JDK 7 — Project Coin (try-with-resources)](https://openjdk.org/projects/jdk7/features#f618) (получено 2026-09-20))

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

*I/O interface* · [в онтологии](concepts.md#resources-io)

- **API стандартной библиотеки (layer: standard_library, profile: java21)** — `System.out.println`, `Scanner`, `BufferedReader` — классы стандартной библиотеки

```java
--8<-- "examples/java/Showcase.java:req-4"
```

#### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · [в онтологии](concepts.md#resources-concurrency)

- **Потоки (layer: standard_library, profile: java21)**

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: java21)** — фигурные скобки; для одного оператора их можно опустить, но это не блок

```java
--8<-- "examples/java/Showcase.java:variants-5"
```

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Точка с запятой (layer: language, profile: java21)**

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да (layer: language, profile: java21)**

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Рефлексия (layer: standard_library, profile: java21)**

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: java21)**
- **Процедурная (layer: language, profile: java21)** — статические методы; свободных функций нет
- **Объектно-ориентированная (layer: language, profile: java21)** — классы, одиночное наследование реализации, интерфейсы
- **Функциональная (с Java SE 8 включительно, layer: language, profile: java21)** — лямбды, функциональные интерфейсы, Stream API; без функций первого класса вне интерфейсов

## Грамматика { #grammar }

Официальная грамматика: <https://docs.oracle.com/javase/specs/jls/se21/html/jls-19.html>.

Фрагменты ниже взяты из сообщества grammars-v4 и **не являются нормативными**: они иллюстрируют, как правила записываются в нотации ANTLR4, которую вы используете в лабораторной работе 2. Нетерминалы, упомянутые в правиле, перечислены под ним со ссылкой на полный файл.

### `localVariableDeclaration` { #rule-localvariabledeclaration }

```antlr
--8<-- "grammar/java/JavaParser.fragments.g4:localVariableDeclaration"
```

Источник: [`java/java/JavaParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4#L478), BSD-3-Clause. Нетерминалы: [`variableModifier`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`identifier`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`typeType`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`variableDeclarators`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4).

### `block` { #rule-block }

```antlr
--8<-- "grammar/java/JavaParser.fragments.g4:block"
```

Источник: [`java/java/JavaParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4#L468), BSD-3-Clause. Нетерминалы: [`blockStatement`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4).

### `statement` { #rule-statement }

```antlr
--8<-- "grammar/java/JavaParser.fragments.g4:statement"
```

Источник: [`java/java/JavaParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4#L521), BSD-3-Clause. Нетерминалы: [`block`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`forControl`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`catchClause`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`finallyBlock`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`resourceSpecification`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`switchBlockStatementGroup`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`switchLabel`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4).

### `switchExpression` { #rule-switchexpression }

```antlr
--8<-- "grammar/java/JavaParser.fragments.g4:switchExpression"
```

Источник: [`java/java/JavaParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4#L722), BSD-3-Clause. Нетерминалы: [`expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`switchLabeledRule`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4).

### `forControl` { #rule-forcontrol }

```antlr
--8<-- "grammar/java/JavaParser.fragments.g4:forControl"
```

Источник: [`java/java/JavaParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4#L584), BSD-3-Clause. Нетерминалы: [`enhancedForControl`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`forInit`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`expression`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`expressionList`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4).

### `methodDeclaration` { #rule-methoddeclaration }

```antlr
--8<-- "grammar/java/JavaParser.fragments.g4:methodDeclaration"
```

Источник: [`java/java/JavaParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4#L168), BSD-3-Clause. Нетерминалы: [`typeTypeOrVoid`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`identifier`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`formalParameters`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`qualifiedNameList`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`methodBody`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4).

### `formalParameter` { #rule-formalparameter }

```antlr
--8<-- "grammar/java/JavaParser.fragments.g4:formalParameter"
```

Источник: [`java/java/JavaParser.g4`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4#L305), BSD-3-Clause. Нетерминалы: [`variableModifier`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`typeType`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`annotation`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4), [`variableDeclaratorId`](https://github.com/antlr/grammars-v4/blob/20efa537586610f5aebd584429ac1b5993a30381/java/java/JavaParser.g4).

### Лицензия источника { #grammar-license }

`antlr/grammars-v4` / `java/java/JavaParser.g4` @ `20efa5375866` — BSD-3-Clause:

```text
--8<-- "grammar/java/JavaParser.fragments.g4:notice"
```

Другие грамматики и материалы:

- [Grammar Zoo: Java](https://slebok.github.io/zoo/index.html#java)
- [Rosetta Code: Java](https://rosettacode.org/wiki/Category:Java)

## Пример-витрина { #showcase }

Одна программа, в которой прокомментированы конструкции, соответствующие концепциям каталога — тот же формат, что у второго примера в лабораторной работе 1. Фрагменты этого файла показаны выше у каждой концепции.

```java
--8<-- "examples/java/Showcase.java"
```

## Оценка по критериям лекции 20 { #assessment }

Критерии — читабельность, лёгкость создания, надёжность, стоимость. Это оценки, а не свойства: они выводятся из концепций, на которые ссылается каждый пункт.

**Читабельность.** Явные объявления и типы в сигнатурах помогают читать код, но обвязка классов и скобки увеличивают объём по сравнению с Python и Kotlin. *([Введение связывания](#bindings-introduction), [Аннотации типов](#typing-annotations), [Границы синтаксических групп](#syntax-blocks), [Место определения подпрограмм](#subprograms-placement))*

**Лёгкость создания.** Перегрузка, `var`, лямбды и Stream API сократили код по сравнению с ранними версиями; отсутствие свободных функций, параметров по умолчанию и множественного присваивания остаётся. *([Перегрузка по сигнатуре](#subprograms-overloading), [Формы присваивания и связывания](#bindings-assignment), [Аргументы по умолчанию](#subprograms-default-args))*

**Надёжность.** Статическая типизация и проверяемые исключения ловят ошибки на этапе компиляции; `null` допустим в ссылочных типах и остаётся одним из источников ошибок времени выполнения. *([Проверка типов](#typing-checking), [Проверяемые исключения](#errors-checked-exceptions), [Представление отсутствия значения](#typing-nullability))*

**Стоимость.** Зрелая экосистема JVM и инструменты; цена — многословность, время старта JVM и потребление памяти. *([Освобождение памяти](#memory-management))*
