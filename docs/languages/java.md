---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные index.md и concepts.md сохраняются при пересборке. -->

# Java

Объектно-ориентированный язык со статической проверкой типов, сборкой мусора и структурными исключениями, компилируемый в байт-код JVM — одну из целевых платформ курса. Второй по частоте язык реализации компиляторов в практикуме.

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1995 — [Wikidata P571](https://www.wikidata.org/wiki/Q251) (получено 2026-09-18) |
| Авторы | James Gosling |
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
| Java SE 8 | 2014-03-18 | выпуск | [Wikidata P348 Java SE 8](https://www.wikidata.org/wiki/Q251) (получено 2026-09-18) |
| Java SE 10 | 2018-03-20 | выпуск | [JEP 286: Local-Variable Type Inference](https://openjdk.org/jeps/286) (получено 2026-09-18) |
| Java SE 26 — актуальная | 2026-03-17 | выпуск | [Wikidata P348 Java SE 26](https://www.wikidata.org/wiki/Q251) (получено 2026-09-18) |

## Публикации { #publications }

- James Gosling, Henry McGilton. *[The Java Language Environment: A White Paper](https://www.oracle.com/java/technologies/language-environment.html)*. Sun Microsystems, 1996.
- James Gosling, Bill Joy, Guy Steele, Gilad Bracha, Alex Buckley, Daniel Smith, Gavin Bierman. *[The Java Language Specification, Java SE 21 Edition](https://docs.oracle.com/javase/specs/jls/se21/html/index.html)*. Oracle, 2023.
- Joshua Bloch. *Effective Java, 3rd Edition*. Addison-Wesley, 2018.

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

### Свойства проектируемого языка { #variants }

#### Объявление переменных { #variants-1 }

*Variable declaration* · [в онтологии](concepts.md#variants-1)

- **Явное** — тип перед именем: `int x = 1;`
- **Неявное (Java SE 10)** — для: локальные переменные с инициализатором; `var x = 1;` — тип выводится, но объявление остаётся явным (JEP 286); поля и параметры — только с типом

```java
--8<-- "examples/java/Showcase.java:variants-1"
```

#### Преобразование типов { #variants-2 }

*Type conversion* · [в онтологии](concepts.md#variants-2)

- **Явное** — оператор приведения `(int) x` — буквально пример из вариантов заданий
- **Неявное** — для: расширяющие преобразования и boxing; int → long → double без потери (JLS 5.1.2); int ↔ Integer с версии 5; сужающие — только явно

```java
--8<-- "examples/java/Showcase.java:variants-2"
```

#### Оператор присваивания { #variants-3 }

*Assignment* · [в онтологии](concepts.md#variants-3)

- **Одиночный** — `a = b = 0` — цепочка одиночных присваиваний; множественного `a, b = c, d` нет

```java
--8<-- "examples/java/Showcase.java:variants-3"
```

#### Структуры, ограничивающие область видимости { #variants-4 }

*Scoping constructs* · [в онтологии](concepts.md#variants-4)

- **Подпрограммы и блочные операторы** — любой блок `{ }`; повторное объявление имени во вложенном блоке — ошибка

```java
--8<-- "examples/java/Showcase.java:variants-4"
```

#### Маркер блочного оператора { #variants-5 }

*Block delimiter* · [в онтологии](concepts.md#variants-5)

- **Явный** — фигурные скобки; для одного оператора их можно опустить, но это не блок

```java
--8<-- "examples/java/Showcase.java:variants-5"
```

#### Условные операторы { #variants-6 }

*Conditional statements* · [в онтологии](concepts.md#variants-6)

- **Двухвариантный и многовариантный switch-case** — `switch` по константам с 1.0; выражение `switch` со стрелками — с 14 (JEP 361); сопоставление по типам — с 21 (JEP 441)

```java
--8<-- "examples/java/Showcase.java:variants-6"
```

#### Перегрузка подпрограмм { #variants-7 }

*Subprogram overloading* · [в онтологии](concepts.md#variants-7)

- **Присутствует** — выбор по статическим типам аргументов на этапе компиляции

```java
--8<-- "examples/java/Showcase.java:variants-7"
```

#### Передача параметров в подпрограмму { #variants-8 }

*Parameter passing* · [в онтологии](concepts.md#variants-8)

- **По значению** — для: примитивные типы; копия значения
- **По ссылке на объект** — для: ссылочные типы; JLS 8.4.1 формально называет это передачей по значению — копируется ссылка; изменение объекта видно вызывающему, перепривязка параметра — нет ([JLS 8.4.1 Formal Parameters](https://docs.oracle.com/javase/specs/jls/se21/html/jls-8.html#jls-8.4.1) (получено 2026-09-18))

```java
--8<-- "examples/java/Showcase.java:variants-8"
```

#### Допустимое место объявления подпрограмм { #variants-9 }

*Subprogram declaration placement* · [в онтологии](concepts.md#variants-9)

- **Только как члены класса** — вложенных методов нет; обход — лямбды (с 8) и локальные классы внутри метода

```java
--8<-- "examples/java/Showcase.java:variants-9"
```

### Обязательные требования к языку { #requirements }

#### Встроенный ввод-вывод { #req-4 }

*Built-in I/O* · [в онтологии](concepts.md#req-4)

- **Функции стандартной библиотеки** — `System.out.println`, `Scanner`, `BufferedReader` — классы стандартной библиотеки

```java
--8<-- "examples/java/Showcase.java:req-4"
```

#### Цикл с постусловием until { #req-7-2-until }

*until loop* · [в онтологии](concepts.md#req-7-2-until)

- **нет** — эквивалент — `while (!cond)`

```java
--8<-- "examples/java/Showcase.java:req-7-2-until"
```

#### Цикл do-while { #req-7-2-do-while }

*do-while loop* · [в онтологии](concepts.md#req-7-2-do-while)

- **да**

```java
--8<-- "examples/java/Showcase.java:req-7-2-do-while"
```

#### Оператор цикла с итерациями for { #req-7-3 }

*for loop form* · [в онтологии](concepts.md#req-7-3)

- **Счётный (в стиле C)** — `for (int i = 0; i < n; i++)`
- **По коллекции (foreach) (Java SE 5)** — `for (T x : iterable)`

```java
--8<-- "examples/java/Showcase.java:req-7-3"
```

#### Глобальная область видимости для переменных { #req-8-2 }

*Global variables* · [в онтологии](concepts.md#req-8-2)

- **Глобальных переменных нет** — любая переменная — член класса или локальная; эквивалент глобальной — `static`-поле

```java
--8<-- "examples/java/Showcase.java:req-8-2"
```

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Статическая**

#### Сильная и слабая типизация { #typing-strength }

*Type strength* · [в онтологии](concepts.md#typing-strength)

- **Сильная** — `"1" + 2` даёт строку `"12"` — единственное заметное неявное приведение (конкатенация)

#### Вывод типов { #typing-inference }

*Type inference* · [в онтологии](concepts.md#typing-inference)

- **да (Java SE 10)** — для: локальные переменные (`var`), лямбды, обобщённые вызовы (diamond с 7)

#### Отсутствие значения (null) { #typing-nullability }

*Nullability* · [в онтологии](concepts.md#typing-nullability)

- **null допустим в любом ссылочном типе** — любая ссылка может быть `null`; `Optional<T>` (с 8) — библиотечная обёртка, не часть системы типов

### Управление памятью { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Сборка мусора** — трассирующие сборщики JVM (G1, ZGC, Shenandoah); освобождение недетерминировано

### Парадигмы программирования { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная**
- **Процедурная** — статические методы; свободных функций нет
- **Объектно-ориентированная** — классы, одиночное наследование реализации, интерфейсы
- **Функциональная (Java SE 8)** — лямбды, функциональные интерфейсы, Stream API; без функций первого класса вне интерфейсов

### Обработка исключительных ситуаций { #errors }

#### Модель обработки ошибок { #errors-model }

*Error handling model* · [в онтологии](concepts.md#errors-model)

- **Структурная (try-throw-catch)** — try / catch / finally; иерархия от Throwable

#### Блоки с гарантированным завершением { #errors-finally }

*Guaranteed cleanup blocks* · [в онтологии](concepts.md#errors-finally)

- **да** — `finally` и try-with-resources (с 7)

#### Проверяемые исключения в сигнатуре { #errors-checked }

*Checked exceptions* · [в онтологии](concepts.md#errors-checked)

- **да** — проверяемые исключения объявляются в `throws`; непроверяемые (RuntimeException) — нет

### Подпрограммы и абстракция { #subprograms }

#### Лямбда-функции { #subprograms-lambda }

*Lambda functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (Java SE 8)** — лямбда — реализация функционального интерфейса; захватываемые переменные должны быть effectively final

#### Обобщённые типы и подпрограммы { #subprograms-generics }

*Generics* · [в онтологии](concepts.md#subprograms-generics)

- **да (Java SE 5)** — стирание типов: во время выполнения параметры типов недоступны

#### Параметры по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **нет** — эквивалент — перегрузка

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **нет** — эквивалент — паттерн builder

### Синтаксическая структура { #syntax }

#### Разделитель операторов { #syntax-statement-terminator }

*Statement terminator* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Точка с запятой обязательна**

#### Чувствительность к регистру { #syntax-case-sensitive }

*Case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да**

#### Совмещение имён (shadowing) { #syntax-shadowing }

*Shadowing* · [в онтологии](concepts.md#syntax-shadowing)

- **Запрещено внутри одной подпрограммы** — для: локальные переменные; локальная переменная не может повторить имя другой локальной в охватывающем блоке того же метода
- **Разрешено во вложенной области** — для: поля и параметры; локальная переменная или параметр может скрыть поле класса; доступ к полю — через `this`

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

**Читабельность.** Явные типы в объявлениях и сигнатурах делают код самодокументируемым, но многословным: обвязка классов и обязательные скобки увеличивают объём по сравнению с Python и Kotlin. *([Объявление переменных](#variants-1), [Маркер блочного оператора](#variants-5), [Допустимое место объявления подпрограмм](#variants-9))*

**Лёгкость создания.** Перегрузка, `var`, лямбды и Stream API сократили код по сравнению с ранними версиями; отсутствие свободных функций, параметров по умолчанию и множественного присваивания остаётся. *([Перегрузка подпрограмм](#variants-7), [Оператор присваивания](#variants-3), [Параметры по умолчанию](#subprograms-default-args))*

**Надёжность.** Статическая типизация и проверяемые исключения ловят ошибки на этапе компиляции; `null` допустим в любой ссылке и остаётся главным источником ошибок времени выполнения. *([Проверка типов](#typing-checking), [Проверяемые исключения в сигнатуре](#errors-checked), [Отсутствие значения (null)](#typing-nullability))*

**Стоимость.** Зрелая экосистема JVM и инструменты; цена — многословность, время старта JVM и потребление памяти. *([Освобождение памяти](#memory-management))*
