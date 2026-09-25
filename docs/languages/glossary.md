---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Понятия

Словарь онтологии. Определения описывают понятия, а не приписывают свойства всем языкам. У каждого понятия — отношения с другими понятиями и переходы к языкам, [различающим примерам](../concepts/examples/index.md), слайдам лекций, [людям](people.md) и [источникам](sources.md). [Сравнение языков](concepts.md) содержит конкретные контекстные утверждения; [проверочные вопросы](questions.md) показывают применение словаря и пробелы данных.

## Как читать связи { #relations }

- **Частный случай:** A → B означает, что механизм A рассматривается как частный случай B, не наоборот.
- **Полезный контраст:** два понятия сравниваются по явно указанному признаку; это не запрет их совместного использования.
- **Часто путают:** сходство слов или синтаксиса создаёт типичную ошибку; связь не означает тождества.
- **Сначала полезно изучить:** A → B рекомендует изучить B перед A. Это педагогическая рекомендация, не логическая необходимость.
- **Связано с:** содержательная связь без утверждения включения или зависимости.

Симметричные связи записаны один раз и показаны с обеих сторон. Обратная связь «частные случаи» и «помогает изучить» строится автоматически. Из связей не выводятся новые свойства языков и не вычисляются транзитивные рекомендации.

**74 определений · 73 связей · 15 вопросов.**

## Разделы

- [Имена и связывание](#bindings)
- [Области видимости](#scope)
- [Типизация](#typing)
- [Управление потоком](#control)
- [Подпрограммы и абстракция](#subprograms)
- [Полиморфизм и организация](#abstraction)
- [Вычисление и эффекты](#evaluation)
- [Память и владение](#memory)
- [Каналы ошибок](#errors)
- [Ресурсы и взаимодействие](#resources)
- [Синтаксис и метапрограммирование](#syntax)
- [Парадигмы](#paradigm)
- [Семантика данных](#data)
- [Правила вычисления и модели времени](#computation)
- [Проверяемые свойства программ](#verification)

## Имена и связывание { #bindings }

### Введение связывания { #bindings-introduction }

*Binding introduction* · `bindings.introduction` · [Введение связывания](concepts.md#bindings-introduction)

Установление связи между именем и сущностью программы — значением, местом хранения, функцией или логической переменной. Конструкция введения имени не определяет, нужно ли писать его тип.

**Пример.** В Java `var x = 1` явно вводит имя x, хотя тип вычисляет компилятор.

**Граница понятия.** Присваивание уже существующей переменной может менять её содержимое, не вводя нового имени.

**Связи:**

- Часто путают: [Вывод статических типов](glossary.md#typing-inference) — Введение имени и определение его статического типа — разные действия; Java var делает оба.
- Связано с: [Ожидание доступности данных](glossary.md#evaluation-data-availability) — Ожидание в Oz связано с ещё не определённой информацией логического связывания.
- Помогает изучить: [Сокрытие имён](glossary.md#scope-shadowing) — Чтобы понять сокрытие, сначала различите новое и существующее связывание.

**В языках:** [C](c.md#bindings-introduction), [Prolog](prolog.md#bindings-introduction), [C++](cpp.md#bindings-introduction), [Common Lisp](common-lisp.md#bindings-introduction), [Haskell](haskell.md#bindings-introduction), [Python](python.md#bindings-introduction), [Java](java.md#bindings-introduction), [JavaScript](javascript.md#bindings-introduction), [C#](csharp.md#bindings-introduction), [Rust](rust.md#bindings-introduction), [TypeScript](typescript.md#bindings-introduction)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html), [08. Обработка ошибок](../lectures/html/08-obrabotka-oshibok.html)

**Проверить понимание:** [Отсутствие аннотации означает динамическую типизацию?](questions.md#q02); [Чем перепривязка отличается от сокрытия имени?](questions.md#q03)

### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · `bindings.mutation` · [Изменяемость связывания](concepts.md#bindings-mutation)

Правила, определяющие, можно ли после введения связывания менять обозначаемое им значение или содержимое соответствующей переменной. Эти правила задаются отдельно от изменяемости достижимого объекта.

**Пример.** JavaScript `const xs = []; xs.push(1)` сохраняет связывание xs, изменяя массив.

**Граница понятия.** Неизменяемая привязка не гарантирует глубокой неизменяемости объекта; однократное связывание логической переменной — ещё один механизм.

**Связи:**

- Часто путают: [Права ссылок и ограничения алиасов](glossary.md#memory-reference-permissions) — Запрет перепривязки имени не определяет права изменения объекта через ссылку.

**В языках:** [C](c.md#bindings-mutation), [Prolog](prolog.md#bindings-mutation), [C++](cpp.md#bindings-mutation), [Common Lisp](common-lisp.md#bindings-mutation), [Haskell](haskell.md#bindings-mutation), [Python](python.md#bindings-mutation), [Java](java.md#bindings-mutation), [JavaScript](javascript.md#bindings-mutation), [C#](csharp.md#bindings-mutation), [Rust](rust.md#bindings-mutation), [TypeScript](typescript.md#bindings-mutation)

**Различающие примеры:** [Oz: значение появится позже](../concepts/examples/index.md#oz)

**Проверить понимание:** [Можно ли менять объект через неизменяемое имя?](questions.md#q01)

### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · `bindings.assignment` · [Формы присваивания и связывания](concepts.md#bindings-assignment)

Семейство операций обновления мест хранения и установления связей со значениями. Для сравнения различаются присваивание одной цели, распаковка, неизменяемое определение и унификация, а не объявляются одной операцией.

**Пример.** Python `a, b = b, a` обновляет две цели; Prolog `X = 1` пытается унифицировать термы.

**Граница понятия.** Haskell `x = 1` задаёт определение, а не команду последующего изменения x. Цепочка присваиваний не равна одновременной распаковке.

**Связи:**

- Часто путают: [Сокрытие имён](glossary.md#scope-shadowing) — Обновление существующего имени нельзя автоматически считать введением нового скрывающего связывания.
- Полезный контраст: [Сопоставление с образцом](glossary.md#control-pattern-matching) — Сопоставление с образцом сравнивается здесь с унификацией и присваиванием из семейства форм связывания; это не полные синонимы.
- Часто путают: [Направленность уравнений и присваиваний](glossary.md#computation-equation-causality) — Равенство в уравнении не означает последовательное изменение переменной.
- Связано с: [Планирование обновлений в HDL-симуляции](glossary.md#computation-update-scheduling) — Планирование уточняет, когда наблюдается эффект присваивания; не заменяет его синтаксическую форму.

**В языках:** [C](c.md#bindings-assignment), [Prolog](prolog.md#bindings-assignment), [C++](cpp.md#bindings-assignment), [Common Lisp](common-lisp.md#bindings-assignment), [Haskell](haskell.md#bindings-assignment), [Python](python.md#bindings-assignment), [Java](java.md#bindings-assignment), [JavaScript](javascript.md#bindings-assignment), [C#](csharp.md#bindings-assignment), [Rust](rust.md#bindings-assignment), [TypeScript](typescript.md#bindings-assignment)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html), [08. Обработка ошибок](../lectures/html/08-obrabotka-oshibok.html)

**Проверить понимание:** [Чем перепривязка отличается от сокрытия имени?](questions.md#q03); [Копия ссылки — это передача по ссылке на переменную?](questions.md#q05); [Сопоставление с образцом — это унификация?](questions.md#q11); [Как отличить присваивание, уравнение и отложенное обновление?](questions.md#q15)

**Источники:** [Can Programming Be Liberated from the von Neumann Style?](sources.md#backus-1978)


## Области видимости { #scope }

### Правило разрешения имён { #scope-resolution }

*Name resolution* · `scope.resolution` · [Правило разрешения имён](concepts.md#scope-resolution)

Правило выбора связывания для конкретного вхождения имени. Лексическое разрешение использует структуру программы, динамическое — активные связывания в ходе выполнения.

**Пример.** Обычная переменная Common Lisp в let лексическая; объявленная special может разрешаться динамически.

**Граница понятия.** Динамическая область видимости не означает динамическую типизацию; время жизни объекта не равно области видимости имени.

**Связи:**

- Часто путают: [Проверка типов](glossary.md#typing-checking) — Слово dynamic в разрешении имён и в проверке типов обозначает разные механизмы.
- Связано с: [Чувствительность имён к регистру](glossary.md#syntax-case-sensitive) — Правила чтения и различения имён определяют, какой идентификатор передаётся разрешению связываний.
- Связано с: [Гигиена макросов](glossary.md#syntax-macro-hygiene) — Гарантия гигиены сформулирована через сохранение связываний при раскрытии.
- Помогает изучить: [Захват окружения](glossary.md#subprograms-closures) — Разбор захвата окружения проще после лексического разрешения имён.

**В языках:** [C](c.md#scope-resolution), [Prolog](prolog.md#scope-resolution), [C++](cpp.md#scope-resolution), [Common Lisp](common-lisp.md#scope-resolution), [Haskell](haskell.md#scope-resolution), [Python](python.md#scope-resolution), [Java](java.md#scope-resolution), [JavaScript](javascript.md#scope-resolution), [C#](csharp.md#scope-resolution), [Rust](rust.md#scope-resolution), [TypeScript](typescript.md#scope-resolution)

**Проверить понимание:** [Чем перепривязка отличается от сокрытия имени?](questions.md#q03); [Замыкание и продолжение сохраняют одно и то же?](questions.md#q08)

**Источники:** [Основные концепции языков программирования, 5-е изд.](sources.md#sebesta)

### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · `scope.constructs` · [Конструкции областей видимости](concepts.md#scope-constructs)

Синтаксические конструкции, создающие области, внутри которых действуют определённые связывания имён и правила их видимости.

**Пример.** Блок JavaScript создаёт область для let, но не отдельную функциональную область для var.

**Граница понятия.** Скобки могут группировать операторы без создания области имён; блок if в Python не вводит отдельной области локальных переменных.

**Связи:**

- Часто путают: [Границы синтаксических групп](glossary.md#syntax-blocks) — Границы синтаксической группы и границы области имён не обязаны совпадать.

**В языках:** [C](c.md#scope-constructs), [Prolog](prolog.md#scope-constructs), [C++](cpp.md#scope-constructs), [Common Lisp](common-lisp.md#scope-constructs), [Haskell](haskell.md#scope-constructs), [Python](python.md#scope-constructs), [Java](java.md#scope-constructs), [JavaScript](javascript.md#scope-constructs), [Rust](rust.md#scope-constructs), [TypeScript](typescript.md#scope-constructs)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html), [08. Обработка ошибок](../lectures/html/08-obrabotka-oshibok.html)

**Проверить понимание:** [Может ли блок иметь границы, но не создавать область имён?](questions.md#q04)

### Связывания верхнего уровня { #scope-globals }

*Top-level bindings* · `scope.globals` · [Связывания верхнего уровня](concepts.md#scope-globals)

Формы доступности и организации связываний вне локального вызова — глобальная среда, пространство модуля или статические члены типа.

**Пример.** Python global обращается к пространству текущего модуля, а Java использует статические поля классов.

**Граница понятия.** Верхнеуровневое имя не обязательно доступно из любого модуля и не обязательно обозначает изменяемую переменную.

**Связи:**

- Связано с: [Модульность](glossary.md#abstraction-modules) — Доступность имени верхнего уровня зависит от модульных границ и экспорта; оно не обязано быть глобально видимым.

**В языках:** [C](c.md#scope-globals), [Prolog](prolog.md#scope-globals), [Common Lisp](common-lisp.md#scope-globals), [Haskell](haskell.md#scope-globals), [Python](python.md#scope-globals), [Java](java.md#scope-globals), [JavaScript](javascript.md#scope-globals), [Rust](rust.md#scope-globals)

### Сокрытие имён { #scope-shadowing }

*Name shadowing* · `scope.shadowing` · [Сокрытие имён](concepts.md#scope-shadowing)

Введение нового связывания с тем же именем, из-за которого часть вхождений перестаёт обозначать прежнее связывание.

**Пример.** Rust `let x = 1; let x = "one";` вводит новое связывание во второй декларации.

**Граница понятия.** Python `x = 1; x = 2` обычно перепривязывает одно имя, а не создаёт новую скрывающую декларацию.

**Связи:**

- Часто путают: [Формы присваивания и связывания](glossary.md#bindings-assignment) — Обновление существующего имени нельзя автоматически считать введением нового скрывающего связывания.
- Сначала полезно изучить: [Введение связывания](glossary.md#bindings-introduction) — Чтобы понять сокрытие, сначала различите новое и существующее связывание.
- Помогает изучить: [Гигиена макросов](glossary.md#syntax-macro-hygiene) — Контрпример захвата имени понятнее после различения связывания и сокрытия.

**В языках:** [C](c.md#scope-shadowing), [Common Lisp](common-lisp.md#scope-shadowing), [Haskell](haskell.md#scope-shadowing), [Python](python.md#scope-shadowing), [Java](java.md#scope-shadowing), [JavaScript](javascript.md#scope-shadowing), [C#](csharp.md#scope-shadowing), [Rust](rust.md#scope-shadowing)

**Слайды лекций:** [20. Критерии оценки языков программирования](../lectures/html/20-kriterii-ocenki-yazykov-programmirovaniya.html)

**Проверить понимание:** [Чем перепривязка отличается от сокрытия имени?](questions.md#q03)


## Типизация { #typing }

### Проверка типов { #typing-checking }

*Type checking* · `typing.checking` · [Проверка типов](concepts.md#typing-checking)

Проверка допустимости операций и сочетаний значений по правилам типов. Статическая выполняется до соответствующего выполнения программы, динамическая — при выполнении; gradual-система описывает взаимодействие статически и динамически типизированных частей.

**Пример.** Java проверяет совместимость аргумента статически; Python может выдать TypeError при выполнении операции.

**Граница понятия.** Статическая проверка не гарантирует отсутствия всех ошибок и не требует явных аннотаций у каждого выражения.

**Связи:**

- Часто путают: [Правило разрешения имён](glossary.md#scope-resolution) — Слово dynamic в разрешении имён и в проверке типов обозначает разные механизмы.
- Часто путают: [Аннотации типов](glossary.md#typing-annotations) — Наличие записи типа не доказывает, кто и когда её проверяет.
- Часто путают: [Вывод статических типов](glossary.md#typing-inference) — Вывод статического типа не является runtime-определением типа объекта.
- Помогает изучить: [Вывод статических типов](glossary.md#typing-inference) — Учебная рекомендация: сначала разобраться, что такое статическая проверка, затем как типы выводятся.

**В языках:** [C](c.md#typing-checking), [Prolog](prolog.md#typing-checking), [C++](cpp.md#typing-checking), [Common Lisp](common-lisp.md#typing-checking), [Haskell](haskell.md#typing-checking), [Python](python.md#typing-checking), [Java](java.md#typing-checking), [JavaScript](javascript.md#typing-checking), [C#](csharp.md#typing-checking), [Rust](rust.md#typing-checking), [TypeScript](typescript.md#typing-checking)

**Слайды лекций:** [20. Критерии оценки языков программирования](../lectures/html/20-kriterii-ocenki-yazykov-programmirovaniya.html)

**Проверить понимание:** [Отсутствие аннотации означает динамическую типизацию?](questions.md#q02)

**Источники:** [Основные концепции языков программирования, 5-е изд.](sources.md#sebesta)

### Аннотации типов { #typing-annotations }

*Type annotations* · `typing.annotations` · [Аннотации типов](concepts.md#typing-annotations)

Записанная автором программы информация о типе выражения, связывания, параметра или результата. Роль аннотации зависит от языка и проверяющего инструмента.

**Пример.** Python `x: int` сообщает тип статическому анализатору, но само по себе не включает runtime-проверку присваиваний.

**Граница понятия.** Наличие аннотации не доказывает её проверку, а отсутствие аннотации не доказывает динамическую типизацию.

**Связи:**

- Часто путают: [Проверка типов](glossary.md#typing-checking) — Наличие записи типа не доказывает, кто и когда её проверяет.

**В языках:** [C](c.md#typing-annotations), [Prolog](prolog.md#typing-annotations), [C++](cpp.md#typing-annotations), [Common Lisp](common-lisp.md#typing-annotations), [Haskell](haskell.md#typing-annotations), [Python](python.md#typing-annotations), [Java](java.md#typing-annotations), [JavaScript](javascript.md#typing-annotations), [C#](csharp.md#typing-annotations), [Rust](rust.md#typing-annotations), [TypeScript](typescript.md#typing-annotations)

**Проверить понимание:** [Отсутствие аннотации означает динамическую типизацию?](questions.md#q02)

### Вывод статических типов { #typing-inference }

*Static type inference* · `typing.inference` · [Вывод статических типов](concepts.md#typing-inference)

Выведение статического типа из структуры программы, ограничений и контекста без полной записи типа программистом.

**Пример.** Компилятор выводит тип Java `var x = 1`; анализатор Python может вывести тип локального имени из использования.

**Граница понятия.** Определение типа уже вычисленного объекта во время исполнения не является выводом статических типов.

**Связи:**

- Часто путают: [Введение связывания](glossary.md#bindings-introduction) — Введение имени и определение его статического типа — разные действия; Java var делает оба.
- Часто путают: [Проверка типов](glossary.md#typing-checking) — Вывод статического типа не является runtime-определением типа объекта.
- Сначала полезно изучить: [Проверка типов](glossary.md#typing-checking) — Учебная рекомендация: сначала разобраться, что такое статическая проверка, затем как типы выводятся.

**В языках:** [C](c.md#typing-inference), [Prolog](prolog.md#typing-inference), [C++](cpp.md#typing-inference), [Haskell](haskell.md#typing-inference), [Python](python.md#typing-inference), [Java](java.md#typing-inference), [C#](csharp.md#typing-inference), [Rust](rust.md#typing-inference), [TypeScript](typescript.md#typing-inference)

**Проверить понимание:** [Отсутствие аннотации означает динамическую типизацию?](questions.md#q02)

### Преобразования типов { #typing-conversions }

*Type conversions* · `typing.conversions` · [Преобразования типов](concepts.md#typing-conversions)

Правила перехода от значения или представления одного типа к другому, явно запрошенного или вставленного неявно. Преобразование может требовать вычисления, проверки и сопровождаться потерей информации.

**Пример.** Java допускает неявное int → float, при котором некоторые целые теряют точность.

**Граница понятия.** TypeScript `x as T` обычно является стираемым утверждением о типе, а не преобразованием значения во время исполнения.

**Связи:**

- Полезный контраст: [Совместимость типов](glossary.md#typing-compatibility) — Допустимость использования и изменение представления — разные вопросы; совместимость может не требовать преобразования.
- Связано с: [Ограничение числовой точности](glossary.md#data-numeric-precision) — Преобразование числового типа может округлять значение или терять разряды.

**В языках:** [C](c.md#typing-conversions), [Prolog](prolog.md#typing-conversions), [C++](cpp.md#typing-conversions), [Common Lisp](common-lisp.md#typing-conversions), [Haskell](haskell.md#typing-conversions), [Python](python.md#typing-conversions), [Java](java.md#typing-conversions), [JavaScript](javascript.md#typing-conversions), [C#](csharp.md#typing-conversions), [Rust](rust.md#typing-conversions), [TypeScript](typescript.md#typing-conversions)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html), [08. Обработка ошибок](../lectures/html/08-obrabotka-oshibok.html), [20. Критерии оценки языков программирования](../lectures/html/20-kriterii-ocenki-yazykov-programmirovaniya.html)

### Совместимость типов { #typing-compatibility }

*Type compatibility* · `typing.compatibility` · [Совместимость типов](concepts.md#typing-compatibility)

Условия, при которых значение или выражение допустимо использовать там, где требуется определённый тип или набор операций. Основанием могут быть имена типов, структура или фактически поддержанные операции.

**Пример.** TypeScript сопоставляет структуру интерфейса; Java требует заявленного номинального отношения реализации интерфейса.

**Граница понятия.** Совместимость не обязательно означает преобразование представления; наличие одинаковых полей не всегда делает два типа одинаковыми.

**Связи:**

- Полезный контраст: [Преобразования типов](glossary.md#typing-conversions) — Допустимость использования и изменение представления — разные вопросы; совместимость может не требовать преобразования.
- Часто путают: [Наследование реализации](glossary.md#abstraction-inheritance) — Подтипизация не всегда требует наследования реализации, а наследование не автоматически гарантирует все поведенческие свойства подтипа.

**В языках:** [C++](cpp.md#typing-compatibility), [Haskell](haskell.md#typing-compatibility), [Python](python.md#typing-compatibility), [Java](java.md#typing-compatibility), [JavaScript](javascript.md#typing-compatibility), [C#](csharp.md#typing-compatibility), [Rust](rust.md#typing-compatibility), [TypeScript](typescript.md#typing-compatibility)

### Типы-суммы { #typing-sum-types }

*Sum types* · `typing.sum_types` · [Типы-суммы](concepts.md#typing-sum-types)

Описание значения как одной из альтернатив типов или вариантов. Конкретная система определяет, как альтернативы различаются, пересекаются и проверяются при использовании.

**Пример.** Rust `Result<T, E>` имеет варианты Ok и Err; TypeScript union допускает значения объединённых типов.

**Граница понятия.** Неразмеченная C union делит представление памяти и не обеспечивает автоматически безопасный выбор активного варианта.

**Связи:**

- Полезный контраст: [Типы-произведения](glossary.md#typing-product-types) — Альтернатива компонентов противопоставляется их одновременному наличию; это не взаимоисключающие возможности языка.
- Связано с: [Представление отсутствия значения](glossary.md#typing-nullability) — Option/Maybe моделирует отсутствие размеченной альтернативой; не все null-механизмы устроены так.

**В языках:** [C++](cpp.md#typing-sum-types), [Haskell](haskell.md#typing-sum-types), [Python](python.md#typing-sum-types), [Java](java.md#typing-sum-types), [Rust](rust.md#typing-sum-types), [TypeScript](typescript.md#typing-sum-types)

### Типы-произведения { #typing-product-types }

*Product types* · `typing.product_types` · [Типы-произведения](concepts.md#typing-product-types)

Составной тип, значение которого содержит компоненты всех заданных типов одновременно; позиции или имена различают компоненты.

**Пример.** Пара `(Int, Bool)` содержит и число, и булево значение; запись связывает компоненты с именами полей.

**Граница понятия.** Тип-сумма выбирает альтернативу, тип-произведение объединяет компоненты. Поле класса ещё может иметь ограничения сверх простого произведения.

**Связи:**

- Полезный контраст: [Типы-суммы](glossary.md#typing-sum-types) — Альтернатива компонентов противопоставляется их одновременному наличию; это не взаимоисключающие возможности языка.
- Помогает изучить: [Зависимость типа от значения](glossary.md#typing-value-dependency) — Зависимую пару удобно вводить после обычной пары; это порядок объяснения, не требование реализации языка.

**В языках:** [C](c.md#typing-product-types), [C++](cpp.md#typing-product-types), [Common Lisp](common-lisp.md#typing-product-types), [Haskell](haskell.md#typing-product-types), [Python](python.md#typing-product-types), [Java](java.md#typing-product-types), [C#](csharp.md#typing-product-types), [Rust](rust.md#typing-product-types), [TypeScript](typescript.md#typing-product-types)

### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · `typing.nullability` · [Представление отсутствия значения](concepts.md#typing-nullability)

Способ выразить отсутствие полезного значения и ограничить места, где такое отсутствие допустимо: специальное значение, nullable-тип либо явная обёртка с вариантами.

**Пример.** `Option<T>` отличает Some от None; nullable-ссылка допускает null вместо ссылки на объект.

**Граница понятия.** Неинициализированность и расходимость вычисления не равны отсутствию значения; Haskell bottom не является Nothing.

**Связи:**

- Связано с: [Типы-суммы](glossary.md#typing-sum-types) — Option/Maybe моделирует отсутствие размеченной альтернативой; не все null-механизмы устроены так.

**В языках:** [C](c.md#typing-nullability), [C++](cpp.md#typing-nullability), [Common Lisp](common-lisp.md#typing-nullability), [Haskell](haskell.md#typing-nullability), [Python](python.md#typing-nullability), [Java](java.md#typing-nullability), [JavaScript](javascript.md#typing-nullability), [C#](csharp.md#typing-nullability), [Rust](rust.md#typing-nullability), [TypeScript](typescript.md#typing-nullability)

### Зависимость типа от значения { #typing-value-dependency }

*Value-dependent types* · `typing.value_dependency` · [Зависимость типа от значения](concepts.md#typing-value-dependency)

Зависимость структуры типа от значения параметра, позволяющая выражать отношения между данными в типе функции или семейства типов.

**Пример.** Idris `Fin n -> Vect n a -> a` связывает допустимый индекс с длиной вектора.

**Граница понятия.** Параметризация только типом элемента не является зависимостью от длины-значения. Зависимые типы сами по себе не требуют завершения каждой программы.

**Связи:**

- Часто путают: [Режим гарантии тотальности](glossary.md#verification-totality) — Зависимость типа от значения не гарантирует завершения любой программы.
- Сначала полезно изучить: [Типы-произведения](glossary.md#typing-product-types) — Зависимую пару удобно вводить после обычной пары; это порядок объяснения, не требование реализации языка.

**Различающие примеры:** [Idris 2: длина связана с допустимым индексом](../concepts/examples/index.md#idris)

**Источники:** [Idris 2 — Types and Functions: Vect, Fin, dependent pairs](https://idris2.readthedocs.io/en/latest/tutorial/typesfuns.html)

### Идентичность абстрактных типов модулей { #typing-abstract-type-identity }

*Abstract module type identity* · `typing.abstract_type_identity` · [Идентичность абстрактных типов модулей](concepts.md#typing-abstract-type-identity)

Правила сохранения или создания идентичности типового компонента при абстракции модулей и скрытии его представления.

**Пример.** Два применения SML-функтора с opaque result signature создают различные абстрактные типы, даже если внутри оба представлены int.

**Граница понятия.** Скрытие представления не тождественно имени типа или модульному пространству имён; прозрачная сигнатура может сохранять равенство с представлением.

**Связи:**

- Связано с: [Модульность](glossary.md#abstraction-modules) — Скрытие представления и генерация свежего типа проявляются при согласовании модулей и сигнатур.
- Сначала полезно изучить: [Модульность](glossary.md#abstraction-modules) — Свежие типы результата функтора проще изучать после структуры и сигнатуры модуля.

**Различающие примеры:** [Standard ML: одинаковое представление, разные типы](../concepts/examples/index.md#sml)

**Источники:** [SML '97 Modules — signatures and §1.3.9 opaque result signatures](https://www.smlnj.org/doc/Conversion/modules.html)


## Управление потоком { #control }

### Условный выбор { #control-selection }

*Conditional selection* · `control.selection` · [Условный выбор](concepts.md#control-selection)

Выбор ветви вычисления по условию или условиям. Выбор может быть оператором, выражением со значением или набором охранных условий.

**Пример.** Haskell if возвращает значение выбранной ветви; обычный Java if управляет выполнением операторов.

**Граница понятия.** Наличие выбора не требует конкретного ключевого слова if; библиотечный протокол тоже может предоставлять условное выполнение.

**Связи:**

- Частные случаи: [Выбор по значению switch/case](glossary.md#control-switch) — Выбор по значению — частный механизм условного выбора; это не утверждение о синтаксисе каждого языка.

**В языках:** [C](c.md#control-selection), [C++](cpp.md#control-selection), [Common Lisp](common-lisp.md#control-selection), [Haskell](haskell.md#control-selection), [Python](python.md#control-selection), [Java](java.md#control-selection), [JavaScript](javascript.md#control-selection), [C#](csharp.md#control-selection), [Rust](rust.md#control-selection), [TypeScript](typescript.md#control-selection)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html), [08. Обработка ошибок](../lectures/html/08-obrabotka-oshibok.html)

### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · `control.switch` · [Выбор по значению switch/case](concepts.md#control-switch)

Специализированный многовариантный выбор по проверяемому значению и меткам вариантов, с правилами совпадения и переходов конкретного языка.

**Пример.** C switch сравнивает значение с case-метками; Java расширяет switch сопоставлением по типам в новых редакциях.

**Граница понятия.** Имя switch не гарантирует только сравнение констант. Полноценное сопоставление с образцом может дополнительно разбирать структуру и связывать имена.

**Связи:**

- Частный случай понятия: [Условный выбор](glossary.md#control-selection) — Выбор по значению — частный механизм условного выбора; это не утверждение о синтаксисе каждого языка.
- Часто путают: [Сопоставление с образцом](glossary.md#control-pattern-matching) — Конкретный switch может поддерживать patterns, но совпадение ключевого слова не делает все switch полноценным pattern matching.

**В языках:** [C](c.md#control-switch), [Prolog](prolog.md#control-switch), [C++](cpp.md#control-switch), [Common Lisp](common-lisp.md#control-switch), [Haskell](haskell.md#control-switch), [Python](python.md#control-switch), [Java](java.md#control-switch), [JavaScript](javascript.md#control-switch), [C#](csharp.md#control-switch), [Rust](rust.md#control-switch), [TypeScript](typescript.md#control-switch)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html), [20. Критерии оценки языков программирования](../lectures/html/20-kriterii-ocenki-yazykov-programmirovaniya.html)

### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching* · `control.pattern_matching` · [Сопоставление с образцом](concepts.md#control-pattern-matching)

Сопоставление значения с описанием допустимой формы, литерала или конструктора с возможным извлечением частей и связыванием имён.

**Пример.** Rust `Some(x)` проверяет вариант и связывает его содержимое с x.

**Граница понятия.** Сопоставление обычно направлено от известного значения к образцу; унификация ищет согласование двух термов, которые оба могут содержать переменные.

**Связи:**

- Полезный контраст: [Формы присваивания и связывания](glossary.md#bindings-assignment) — Сопоставление с образцом сравнивается здесь с унификацией и присваиванием из семейства форм связывания; это не полные синонимы.
- Часто путают: [Выбор по значению switch/case](glossary.md#control-switch) — Конкретный switch может поддерживать patterns, но совпадение ключевого слова не делает все switch полноценным pattern matching.

**В языках:** [C](c.md#control-pattern-matching), [Haskell](haskell.md#control-pattern-matching), [Python](python.md#control-pattern-matching), [Java](java.md#control-pattern-matching), [JavaScript](javascript.md#control-pattern-matching), [C#](csharp.md#control-pattern-matching), [Rust](rust.md#control-pattern-matching), [TypeScript](typescript.md#control-pattern-matching)

**Проверить понимание:** [Сопоставление с образцом — это унификация?](questions.md#q11)

### Цикл до истинности условия { #control-until }

*Until loop* · `control.until` · [Цикл до истинности условия](concepts.md#control-until)

Повторение до истинности условия остановки. Проверка перед телом допускает ноль выполнений, после тела — требует хотя бы одного.

**Пример.** Постусловное repeat-until можно выразить через do-while с отрицанием условия.

**Граница понятия.** Предусловное `while not cond` не эквивалентно постусловному циклу, когда cond истинно с самого начала.

**Связи:**

- Частный случай понятия: [Формы итерации](glossary.md#control-iteration) — Цикл с условием остановки — форма итерации независимо от места проверки.
- Полезный контраст: [Цикл do-while с постусловием](glossary.md#control-do-while) — Для одинакового момента проверки отличаются условие остановки и условие продолжения.

**В языках:** [Common Lisp](common-lisp.md#control-until), [Haskell](haskell.md#control-until), [Python](python.md#control-until), [Java](java.md#control-until), [Rust](rust.md#control-until)

### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · `control.do_while` · [Цикл do-while с постусловием](concepts.md#control-do-while)

Конструкция цикла, сначала выполняющая тело и затем проверяющая условие продолжения для следующей итерации.

**Пример.** C `do { body; } while (cond);` исполняет body хотя бы раз.

**Граница понятия.** В until условие обычно задаёт остановку, а не продолжение. Совпадение момента проверки не означает совпадения полярности условия.

**Связи:**

- Частный случай понятия: [Формы итерации](glossary.md#control-iteration) — Постусловный цикл — частный способ повторения вычисления.
- Полезный контраст: [Цикл до истинности условия](glossary.md#control-until) — Для одинакового момента проверки отличаются условие остановки и условие продолжения.

**В языках:** [C](c.md#control-do-while), [Prolog](prolog.md#control-do-while), [Python](python.md#control-do-while), [Java](java.md#control-do-while), [JavaScript](javascript.md#control-do-while), [Rust](rust.md#control-do-while)

### Формы итерации { #control-iteration }

*Iteration forms* · `control.iteration` · [Формы итерации](concepts.md#control-iteration)

Способ систематически повторять вычисление — по условию и шагу, элементам последовательности, через генераторную конструкцию или функцию обхода.

**Пример.** Python for получает элементы итератора; C-style for отдельно задаёт инициализацию, условие и шаг.

**Граница понятия.** Обход можно выразить рекурсией без наличия синтаксического for; не всякая итерация является счётным циклом.

**Связи:**

- Частные случаи: [Цикл do-while с постусловием](glossary.md#control-do-while) — Постусловный цикл — частный способ повторения вычисления.
- Частные случаи: [Цикл до истинности условия](glossary.md#control-until) — Цикл с условием остановки — форма итерации независимо от места проверки.
- Связано с: [Гарантированное устранение хвостовых вызовов](glossary.md#evaluation-tail-calls) — Гарантия хвостовых вызовов позволяет выражать некоторые циклы рекурсией без накопления контекста возврата.
- Полезный контраст: [Поднятие операций по рангу массива](glossary.md#evaluation-rank-lifting) — Неявное применение операции к ячейкам массива сравнивается с явным обходом; возможность выразить одно через другое не делает механизмы одинаковыми.

**В языках:** [C](c.md#control-iteration), [C++](cpp.md#control-iteration), [Common Lisp](common-lisp.md#control-iteration), [Haskell](haskell.md#control-iteration), [Python](python.md#control-iteration), [Java](java.md#control-iteration), [JavaScript](javascript.md#control-iteration), [C#](csharp.md#control-iteration), [Rust](rust.md#control-iteration), [TypeScript](typescript.md#control-iteration)

**Слайды лекций:** [20. Критерии оценки языков программирования](../lectures/html/20-kriterii-ocenki-yazykov-programmirovaniya.html)

**Проверить понимание:** [Почему одинаковая операция даёт разные результаты для коллекций?](questions.md#q13)

### Логический поиск решений { #control-logic-search }

*Logic search* · `control.logic_search` · [Логический поиск решений](concepts.md#control-logic-search)

Механизмы построения решений логических целей — перебор альтернатив с возвратом, сохранение результатов подцелей или распространение ограничений.

**Пример.** Prolog может вернуться к выбору альтернативной клаузы; tabling сохраняет ответы подцелей.

**Граница понятия.** Стратегия поиска и определение множества правильных ответов — разные уровни; распространение ограничений не обязательно перебирает решения.

**Связи:**

- Связано с: [Смысл применения правил](glossary.md#computation-rule-semantics) — Механизм поиска реализует получение решений, а семантика правил определяет, что считается результатом.

**В языках:** [Prolog](prolog.md#control-logic-search)

**Проверить понимание:** [Генератор делает язык нестрогим?](questions.md#q09); [Сопоставление с образцом — это унификация?](questions.md#q11)

**Люди:** [Ален Колмероэ](people.md#colmerauer), [Роберт Ковальский](people.md#kowalski)

**Источники:** [The Birth of Prolog](sources.md#hopl-prolog)

### Граница захвата продолжения { #control-continuation-extent }

*Continuation capture boundary* · `control.continuation_extent` · [Граница захвата продолжения](concepts.md#control-continuation-extent)

Граница контекста вычисления, представленного захваченным продолжением: весь текущий остаток вычисления либо его часть до ограничителя.

**Пример.** Scheme call/cc предоставляет продолжение, к которому можно вернуться; delimited continuation ограничено prompt.

**Граница понятия.** Окружение замыкания хранит доступные связывания, продолжение — что делать дальше. Граница захвата не задаёт число разрешённых возобновлений.

**Связи:**

- Часто путают: [Захват окружения](glossary.md#subprograms-closures) — Оставшийся контекст вычисления отличается от сохранённого окружения функции.
- Связано с: [Протокол выдачи и возобновления результатов](glossary.md#evaluation-result-protocol) — Продолжения позволяют реализовывать возобновление; не всякий генератор предоставляет first-class continuation.
- Сначала полезно изучить: [Протокол выдачи и возобновления результатов](glossary.md#evaluation-result-protocol) — Перед продолжениями полезно проследить обычный вызов, возврат и возобновление.

**Различающие примеры:** [Scheme: вернуться в вычисление](../concepts/examples/index.md#scheme)

**Проверить понимание:** [Замыкание и продолжение сохраняют одно и то же?](questions.md#q08)

**Люди:** [Гай Стил](people.md#steele)

**Источники:** [Scheme R7RS-small §6.10 — call-with-current-continuation](https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-8.html); [Racket Reference §10.4 — prompts and delimited continuations](https://docs.racket-lang.org/reference/cont.html)


## Подпрограммы и абстракция { #subprograms }

### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · `subprograms.overloading` · [Перегрузка по сигнатуре](concepts.md#subprograms-overloading)

Использование одного имени для нескольких сигнатур подпрограмм с выбором применимой сигнатуры по правилам языка и контексту вызова.

**Пример.** Java выбирает перегрузку по статическим типам аргументов; TypeScript допускает несколько сигнатур над одной реализацией.

**Граница понятия.** Перегрузка не равна выбору переопределённого метода по динамическому типу получателя и не требует нескольких runtime-реализаций.

**Связи:**

- Часто путают: [Диспетчеризация вызовов](glossary.md#abstraction-dispatch) — Перегрузка по сигнатуре отличается от выбора реализации по динамическим типам; они могут сочетаться.

**В языках:** [C](c.md#subprograms-overloading), [Prolog](prolog.md#subprograms-overloading), [C++](cpp.md#subprograms-overloading), [Common Lisp](common-lisp.md#subprograms-overloading), [Haskell](haskell.md#subprograms-overloading), [Python](python.md#subprograms-overloading), [Java](java.md#subprograms-overloading), [JavaScript](javascript.md#subprograms-overloading), [C#](csharp.md#subprograms-overloading), [Rust](rust.md#subprograms-overloading), [TypeScript](typescript.md#subprograms-overloading)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html), [08. Обработка ошибок](../lectures/html/08-obrabotka-oshibok.html)

**Проверить понимание:** [Перегрузка, type class и виртуальный вызов — один механизм?](questions.md#q10)

**Люди:** [Филип Уодлер](people.md#wadler)

**Источники:** [Дизайн и эволюция C++](sources.md#stroustrup-de); [How to Make Ad-hoc Polymorphism Less Ad Hoc](sources.md#wadler-blott-1989)

### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · `subprograms.parameter_passing` · [Связывание параметров](concepts.md#subprograms-parameter-passing)

Правила связывания фактических аргументов с формальными параметрами, определяющие доступ к значениям, переменным вызывающей стороны или отложенным вычислениям.

**Пример.** Копия ссылки в Java — передача значения; C# ref может обозначать переменную вызывающего кода.

**Граница понятия.** Копирование ссылки не копирует сам объект. Передача параметра не определяет сама по себе перенос владения ресурсом.

**Связи:**

- Часто путают: [Передача и разделение владения](glossary.md#memory-transfer) — Способ связать параметр и передача ответственности за объект — независимые измерения вызова.
- Связано с: [Именованные аргументы](glossary.md#subprograms-named-args) — Выбор параметра по имени и способ связать с ним аргумент — разные стадии протокола вызова.
- Часто путают: [Режимы связанности аргументов](glossary.md#computation-instantiation-modes) — Входная связанность не задаёт физический или семантический способ передачи параметра.

**В языках:** [C](c.md#subprograms-parameter-passing), [Prolog](prolog.md#subprograms-parameter-passing), [C++](cpp.md#subprograms-parameter-passing), [Common Lisp](common-lisp.md#subprograms-parameter-passing), [Haskell](haskell.md#subprograms-parameter-passing), [Python](python.md#subprograms-parameter-passing), [Java](java.md#subprograms-parameter-passing), [JavaScript](javascript.md#subprograms-parameter-passing), [C#](csharp.md#subprograms-parameter-passing), [Rust](rust.md#subprograms-parameter-passing), [TypeScript](typescript.md#subprograms-parameter-passing)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html), [08. Обработка ошибок](../lectures/html/08-obrabotka-oshibok.html)

**Проверить понимание:** [Копия ссылки — это передача по ссылке на переменную?](questions.md#q05)

**Источники:** [Основные концепции языков программирования, 5-е изд.](sources.md#sebesta)

### Место определения подпрограмм { #subprograms-placement }

*Subprogram definition placement* · `subprograms.placement` · [Место определения подпрограмм](concepts.md#subprograms-placement)

Допустимые структурные места определения подпрограммы в программе: верхний уровень, выделенная область объявлений, член типа или локальная область.

**Пример.** Стандарт C допускает определения функций на уровне файла, но не вложенные определения функций.

**Граница понятия.** Разрешение вложенного определения не означает автоматического захвата окружения; Rust local fn и замыкание различаются.

**Связи:**

- Связано с: [Вложенные именованные подпрограммы](glossary.md#subprograms-nesting) — Допустимость локального определения включает вопрос вложенных именованных подпрограмм.

**В языках:** [C](c.md#subprograms-placement), [Prolog](prolog.md#subprograms-placement), [Common Lisp](common-lisp.md#subprograms-placement), [Python](python.md#subprograms-placement), [Java](java.md#subprograms-placement), [Rust](rust.md#subprograms-placement)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html)

### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms* · `subprograms.nesting` · [Вложенные именованные подпрограммы](concepts.md#subprograms-nesting)

Возможность определять именованную подпрограмму внутри области другой подпрограммы или локальной связывающей конструкции.

**Пример.** Python def внутри def создаёт локальную именованную функцию.

**Граница понятия.** Анонимная лямбда и вложенная именованная функция — разные синтаксические возможности; захват внешних переменных проверяется отдельно.

**Связи:**

- Связано с: [Место определения подпрограмм](glossary.md#subprograms-placement) — Допустимость локального определения включает вопрос вложенных именованных подпрограмм.
- Часто путают: [Захват окружения](glossary.md#subprograms-closures) — Вложенная функция не обязана захватывать окружение: пример — Rust fn внутри функции.

**В языках:** [C](c.md#subprograms-nesting), [Prolog](prolog.md#subprograms-nesting), [C++](cpp.md#subprograms-nesting), [Common Lisp](common-lisp.md#subprograms-nesting), [Haskell](haskell.md#subprograms-nesting), [Python](python.md#subprograms-nesting), [Java](java.md#subprograms-nesting), [JavaScript](javascript.md#subprograms-nesting), [C#](csharp.md#subprograms-nesting), [Rust](rust.md#subprograms-nesting), [TypeScript](typescript.md#subprograms-nesting)

### Захват окружения { #subprograms-closures }

*Closure capture* · `subprograms.closures` · [Захват окружения](concepts.md#subprograms-closures)

Сохранение функции вместе с доступом к необходимым связываниям окружающей лексической среды. Способ захвата значений, переменных и владения определяется языком.

**Пример.** Возвращённая Python-функция может читать переменную внешнего вызова после его завершения.

**Граница понятия.** Захват окружения не равен захвату стека управления; функция без свободных переменных не демонстрирует необходимость окружения.

**Связи:**

- Часто путают: [Граница захвата продолжения](glossary.md#control-continuation-extent) — Оставшийся контекст вычисления отличается от сохранённого окружения функции.
- Часто путают: [Вложенные именованные подпрограммы](glossary.md#subprograms-nesting) — Вложенная функция не обязана захватывать окружение: пример — Rust fn внутри функции.
- Часто путают: [Анонимные функции](glossary.md#subprograms-lambda) — Анонимность функции и захват окружения — разные свойства; именованные функции также бывают замыканиями.
- Сначала полезно изучить: [Правило разрешения имён](glossary.md#scope-resolution) — Разбор захвата окружения проще после лексического разрешения имён.

**В языках:** [C](c.md#subprograms-closures), [C++](cpp.md#subprograms-closures), [Common Lisp](common-lisp.md#subprograms-closures), [Haskell](haskell.md#subprograms-closures), [Python](python.md#subprograms-closures), [Java](java.md#subprograms-closures), [JavaScript](javascript.md#subprograms-closures), [C#](csharp.md#subprograms-closures), [Rust](rust.md#subprograms-closures), [TypeScript](typescript.md#subprograms-closures)

**Проверить понимание:** [Замыкание и продолжение сохраняют одно и то же?](questions.md#q08)

### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · `subprograms.lambda` · [Анонимные функции](concepts.md#subprograms-lambda)

Конструкция создания функции как выражения без обязательного отдельного именованного определения.

**Пример.** Python `lambda x: x + 1` создаёт функцию, которую можно передать как аргумент.

**Граница понятия.** Анонимность — свойство записи, захват окружения — семантический механизм. Именованная функция тоже может быть замыканием.

**Связи:**

- Часто путают: [Захват окружения](glossary.md#subprograms-closures) — Анонимность функции и захват окружения — разные свойства; именованные функции также бывают замыканиями.

**В языках:** [C](c.md#subprograms-lambda), [Prolog](prolog.md#subprograms-lambda), [C++](cpp.md#subprograms-lambda), [Common Lisp](common-lisp.md#subprograms-lambda), [Haskell](haskell.md#subprograms-lambda), [Python](python.md#subprograms-lambda), [Java](java.md#subprograms-lambda), [JavaScript](javascript.md#subprograms-lambda), [C#](csharp.md#subprograms-lambda), [Rust](rust.md#subprograms-lambda), [TypeScript](typescript.md#subprograms-lambda)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html)

### Параметрический полиморфизм { #subprograms-generics }

*Parametric polymorphism* · `subprograms.generics` · [Параметрический полиморфизм](concepts.md#subprograms-generics)

Параметризация типов или подпрограмм типовыми параметрами, позволяющая описать семейство применений без отдельной ручной реализации для каждого конкретного типа.

**Пример.** Одна функция над списком T применима к спискам разных типов элементов при соблюдении ограничений на T.

**Граница понятия.** CLOS generic function относится прежде всего к диспетчеризации методов. Параметризация не гарантирует полную независимость поведения от конкретного типа.

**Связи:**

- Связано с: [Реализация параметрического полиморфизма](glossary.md#subprograms-generic-mechanism) — Языковая возможность обобщения отделена от способа её реализации; один механизм не обязателен для всех generics.
- Часто путают: [Диспетчеризация вызовов](glossary.md#abstraction-dispatch) — CLOS generic function относится к выбору методов, а не обязательно к параметризации типом.

**В языках:** [C++](cpp.md#subprograms-generics), [Haskell](haskell.md#subprograms-generics), [Python](python.md#subprograms-generics), [Java](java.md#subprograms-generics), [C#](csharp.md#subprograms-generics), [Rust](rust.md#subprograms-generics), [TypeScript](typescript.md#subprograms-generics)

**Проверить понимание:** [Перегрузка, type class и виртуальный вызов — один механизм?](questions.md#q10)

### Реализация параметрического полиморфизма { #subprograms-generic-mechanism }

*Generic implementation mechanism* · `subprograms.generic_mechanism` · [Реализация параметрического полиморфизма](concepts.md#subprograms-generic-mechanism)

Механизмы реализации обобщённого кода и его ограничений — специализированные экземпляры, стирание параметров, их сохранение во время исполнения или передача наборов операций.

**Пример.** Мономорфизация создаёт специализации; словарь может передавать реализации операций type class.

**Граница понятия.** Эти механизмы могут сочетаться; передача словаря реализует ограниченный полиморфизм и не является обязательным устройством любых generics.

**Связи:**

- Связано с: [Параметрический полиморфизм](glossary.md#subprograms-generics) — Языковая возможность обобщения отделена от способа её реализации; один механизм не обязателен для всех generics.

**В языках:** [Java](java.md#subprograms-generic-mechanism), [C#](csharp.md#subprograms-generic-mechanism), [Rust](rust.md#subprograms-generic-mechanism), [TypeScript](typescript.md#subprograms-generic-mechanism)

### Аргументы по умолчанию { #subprograms-default-args }

*Default arguments* · `subprograms.default_args` · [Аргументы по умолчанию](concepts.md#subprograms-default-args)

Правила получения аргумента, который вызывающий код не передал явно, из заданного определения или выражения по умолчанию.

**Пример.** Python вычисляет default-значение при определении функции, что заметно для изменяемого списка.

**Граница понятия.** Аргумент по умолчанию не обязательно вычисляется заново при каждом вызове; перегрузка с меньшим числом параметров — иной механизм.

**Связи:**

- Связано с: [Стратегия вычисления](glossary.md#evaluation-strategy) — Для default-выражения важно отдельно знать момент вычисления; общая строгость вызова его не определяет.

**В языках:** [Common Lisp](common-lisp.md#subprograms-default-args), [Python](python.md#subprograms-default-args), [Java](java.md#subprograms-default-args), [JavaScript](javascript.md#subprograms-default-args), [Rust](rust.md#subprograms-default-args)

### Именованные аргументы { #subprograms-named-args }

*Named arguments* · `subprograms.named_args` · [Именованные аргументы](concepts.md#subprograms-named-args)

Сопоставление фактического аргумента с параметром по имени, а не только по позиции в списке вызова.

**Пример.** Python `sorted(xs, reverse=True)` выбирает параметр reverse по имени.

**Граница понятия.** Передача объекта с именованными полями не означает поддержку именованных аргументов самим протоколом вызова.

**Связи:**

- Связано с: [Связывание параметров](glossary.md#subprograms-parameter-passing) — Выбор параметра по имени и способ связать с ним аргумент — разные стадии протокола вызова.

**В языках:** [Common Lisp](common-lisp.md#subprograms-named-args), [Python](python.md#subprograms-named-args), [Java](java.md#subprograms-named-args), [Rust](rust.md#subprograms-named-args)


## Полиморфизм и организация { #abstraction }

### Контракты полиморфизма { #abstraction-contracts }

*Polymorphic contracts* · `abstraction.contracts` · [Контракты полиморфизма](concepts.md#abstraction-contracts)

Требования к доступным операциям типа или значения, через которые код использует разные реализации единообразно: интерфейсы, traits, type classes или протоколы.

**Пример.** Ограничение Rust `T: Display` требует доступности определённого поведения форматирования.

**Граница понятия.** Наличие метода deposit в интерфейсе не выражает постусловие об увеличении баланса; поведенческие контракты описываются отдельно.

**Связи:**

- Часто путают: [Поведенческие контракты](glossary.md#verification-behavioral-contracts) — Набор доступных операций не равен предикатам их поведения.

**В языках:** [Haskell](haskell.md#abstraction-contracts), [Python](python.md#abstraction-contracts), [Java](java.md#abstraction-contracts), [C#](csharp.md#abstraction-contracts), [Rust](rust.md#abstraction-contracts), [TypeScript](typescript.md#abstraction-contracts)

**Проверить понимание:** [Перегрузка, type class и виртуальный вызов — один механизм?](questions.md#q10)

**Люди:** [Филип Уодлер](people.md#wadler)

**Источники:** [How to Make Ad-hoc Polymorphism Less Ad Hoc](sources.md#wadler-blott-1989); [A History of Haskell — Being Lazy with Class](sources.md#hopl-haskell)

### Диспетчеризация вызовов { #abstraction-dispatch }

*Call dispatch* · `abstraction.dispatch` · [Диспетчеризация вызовов](concepts.md#abstraction-dispatch)

Выбор реализации вызываемой операции по статической информации или динамическим характеристикам одного либо нескольких аргументов.

**Пример.** Виртуальный метод выбирается по получателю; CLOS может выбирать применимые методы по нескольким обязательным аргументам.

**Граница понятия.** Статический выбор перегрузки и последующая динамическая диспетчеризация могут участвовать в одном вызове последовательно.

**Связи:**

- Часто путают: [Перегрузка по сигнатуре](glossary.md#subprograms-overloading) — Перегрузка по сигнатуре отличается от выбора реализации по динамическим типам; они могут сочетаться.
- Часто путают: [Параметрический полиморфизм](glossary.md#subprograms-generics) — CLOS generic function относится к выбору методов, а не обязательно к параметризации типом.
- Связано с: [Наследование реализации](glossary.md#abstraction-inheritance) — Наследование и переопределение дают кандидатов для вызова, но диспетчеризация возможна и без наследования реализации.

**В языках:** [C++](cpp.md#abstraction-dispatch), [Common Lisp](common-lisp.md#abstraction-dispatch), [Python](python.md#abstraction-dispatch), [Java](java.md#abstraction-dispatch), [C#](csharp.md#abstraction-dispatch), [Rust](rust.md#abstraction-dispatch)

**Проверить понимание:** [Перегрузка, type class и виртуальный вызов — один механизм?](questions.md#q10)

**Люди:** [Ричард Гэбриел](people.md#gabriel), [Дэвид Мун](people.md#moon)

### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · `abstraction.inheritance` · [Наследование реализации](concepts.md#abstraction-inheritance)

Получение реализации или состояния типа из одного либо нескольких родительских типов с правилами дополнения и переопределения.

**Пример.** Класс может наследовать реализацию метода и заменить её своей.

**Граница понятия.** Подтипизация, реализация интерфейса и композиция не обязательно требуют наследования реализации.

**Связи:**

- Связано с: [Диспетчеризация вызовов](glossary.md#abstraction-dispatch) — Наследование и переопределение дают кандидатов для вызова, но диспетчеризация возможна и без наследования реализации.
- Часто путают: [Совместимость типов](glossary.md#typing-compatibility) — Подтипизация не всегда требует наследования реализации, а наследование не автоматически гарантирует все поведенческие свойства подтипа.

**В языках:** [C++](cpp.md#abstraction-inheritance), [Common Lisp](common-lisp.md#abstraction-inheritance), [Python](python.md#abstraction-inheritance), [Java](java.md#abstraction-inheritance), [JavaScript](javascript.md#abstraction-inheritance), [C#](csharp.md#abstraction-inheritance), [Rust](rust.md#abstraction-inheritance), [TypeScript](typescript.md#abstraction-inheritance)

### Модульность { #abstraction-modules }

*Modules* · `abstraction.modules` · [Модульность](concepts.md#abstraction-modules)

Организация программы в единицы с контролируемыми именами, зависимостями и границами использования; конкретный механизм определяет импорт, экспорт и параметризацию.

**Пример.** SML functor принимает модуль по сигнатуре и строит модуль-результат.

**Граница понятия.** Текстовый include, namespace и модуль со скрытыми типами дают разные гарантии, хотя все участвуют в организации кода.

**Связи:**

- Связано с: [Связывания верхнего уровня](glossary.md#scope-globals) — Доступность имени верхнего уровня зависит от модульных границ и экспорта; оно не обязано быть глобально видимым.
- Связано с: [Идентичность абстрактных типов модулей](glossary.md#typing-abstract-type-identity) — Скрытие представления и генерация свежего типа проявляются при согласовании модулей и сигнатур.
- Помогает изучить: [Идентичность абстрактных типов модулей](glossary.md#typing-abstract-type-identity) — Свежие типы результата функтора проще изучать после структуры и сигнатуры модуля.

**В языках:** [C](c.md#abstraction-modules), [Prolog](prolog.md#abstraction-modules), [C++](cpp.md#abstraction-modules), [Common Lisp](common-lisp.md#abstraction-modules), [Haskell](haskell.md#abstraction-modules), [Python](python.md#abstraction-modules), [Java](java.md#abstraction-modules), [JavaScript](javascript.md#abstraction-modules), [C#](csharp.md#abstraction-modules), [Rust](rust.md#abstraction-modules), [TypeScript](typescript.md#abstraction-modules)

**Различающие примеры:** [Standard ML: одинаковое представление, разные типы](../concepts/examples/index.md#sml)


## Вычисление и эффекты { #evaluation }

### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · `evaluation.strategy` · [Стратегия вычисления](concepts.md#evaluation-strategy)

Правила востребованности вычислений: требует ли операция значения аргумента до своего выполнения или может получить результат без вычисления некоторых аргументов.

**Пример.** Нестрогая функция может вернуть константу, не вычисляя расходящийся аргумент.

**Граница понятия.** Нестрогость не задаёт порядок вычисления всех операндов и не обещает мемоизацию каждого вызова функции.

**Связи:**

- Связано с: [Аргументы по умолчанию](glossary.md#subprograms-default-args) — Для default-выражения важно отдельно знать момент вычисления; общая строгость вызова его не определяет.
- Часто путают: [Протокол выдачи и возобновления результатов](glossary.md#evaluation-result-protocol) — Приостановка генератора не превращает обычное вычисление аргументов языка в нестрогое.

**В языках:** [C](c.md#evaluation-strategy), [C++](cpp.md#evaluation-strategy), [Common Lisp](common-lisp.md#evaluation-strategy), [Haskell](haskell.md#evaluation-strategy), [Python](python.md#evaluation-strategy), [Java](java.md#evaluation-strategy), [JavaScript](javascript.md#evaluation-strategy), [C#](csharp.md#evaluation-strategy), [Rust](rust.md#evaluation-strategy), [TypeScript](typescript.md#evaluation-strategy)

**Проверить понимание:** [Генератор делает язык нестрогим?](questions.md#q09)

**Люди:** [Пол Худак](people.md#hudak), [Саймон Пейтон-Джонс](people.md#peyton-jones)

**Источники:** [A History of Haskell — Being Lazy with Class](sources.md#hopl-haskell)

### Контроль эффектов { #evaluation-effects }

*Effect control* · `evaluation.effects` · [Контроль эффектов](concepts.md#evaluation-effects)

Способы выражения и контроля наблюдаемых действий помимо получения обычного значения — изменения состояния, ввода-вывода и других эффектов.

**Пример.** Haskell IO отмечает действия в типе; обработчики эффектов задают интерпретацию операций эффекта.

**Граница понятия.** Типизированный эффект и его обработчик — разные механизмы. Чистая функция может расходиться, поэтому чистота не равна тотальности.

**Связи:**

- Часто путают: [Режим гарантии тотальности](glossary.md#verification-totality) — Чистое вычисление может расходиться, а завершающееся — иметь побочные эффекты.
- Связано с: [Интерфейс ввода-вывода](glossary.md#resources-io) — Ввод-вывод — пример наблюдаемого эффекта, но способ предоставления API не определяет статический контроль эффекта.

**В языках:** [Prolog](prolog.md#evaluation-effects), [Haskell](haskell.md#evaluation-effects), [Python](python.md#evaluation-effects), [Java](java.md#evaluation-effects), [Rust](rust.md#evaluation-effects)

**Люди:** [Саймон Пейтон-Джонс](people.md#peyton-jones)

**Источники:** [Can Programming Be Liberated from the von Neumann Style?](sources.md#backus-1978); [A History of Haskell — Being Lazy with Class](sources.md#hopl-haskell)

### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · `evaluation.tail_calls` · [Гарантированное устранение хвостовых вызовов](concepts.md#evaluation-tail-calls)

Гарантия, что хвостовой вызов не требует сохранения дополнительного контекста возврата и не вызывает неограниченного роста такого контекста в цепочке хвостовых вызовов.

**Пример.** Хвостовая рекурсия может выражать цикл без накопления кадров возврата.

**Граница понятия.** Оптимизация, иногда выполняемая компилятором, слабее гарантии языка; память под данные при этом всё ещё может расти.

**Связи:**

- Связано с: [Формы итерации](glossary.md#control-iteration) — Гарантия хвостовых вызовов позволяет выражать некоторые циклы рекурсией без накопления контекста возврата.

**В языках:** [Python](python.md#evaluation-tail-calls), [Java](java.md#evaluation-tail-calls), [JavaScript](javascript.md#evaluation-tail-calls), [Rust](rust.md#evaluation-tail-calls)

### Поднятие операций по рангу массива { #evaluation-rank-lifting }

*Array rank lifting* · `evaluation.rank_lifting` · [Поднятие операций по рангу массива](concepts.md#evaluation-rank-lifting)

Автоматическое применение операции к ячейкам массива выбранной размерности с правилами объединения результатов и согласования аргументов.

**Пример.** В J одна редукция с рангом 1 суммирует строки, с рангом 2 действует на всю матрицу.

**Граница понятия.** Наличие массивов или явного map не означает встроенной семантики ранга; rank — число осей, shape — их размеры.

**Связи:**

- Полезный контраст: [Формы итерации](glossary.md#control-iteration) — Неявное применение операции к ячейкам массива сравнивается с явным обходом; возможность выразить одно через другое не делает механизмы одинаковыми.

**Различающие примеры:** [J: та же операция, другой ранг](../concepts/examples/index.md#j)

**Проверить понимание:** [Почему одинаковая операция даёт разные результаты для коллекций?](questions.md#q13)

**Люди:** [Кеннет Айверсон](people.md#iverson)

**Источники:** [Notation as a Tool of Thought](sources.md#iverson-notation); [J Dictionary — Nouns: shape, rank and cells](https://www.jsoftware.com/help/dictionary/dicta.htm); [J Dictionary — Verbs: rank and agreement](https://www.jsoftware.com/help/dictionary/dictb.htm); [Dyalog APL 19.0 — Rank operator](https://help.dyalog.com/19.0/Content/Language/Primitive%20Operators/Rank.htm)

### Протокол выдачи и возобновления результатов { #evaluation-result-protocol }

*Result and resumption protocol* · `evaluation.result_protocol` · [Протокол выдачи и возобновления результатов](concepts.md#evaluation-result-protocol)

Правила выдачи результатов и инициирования следующего результата: обычный возврат, явное возобновление или автоматический поиск альтернатив при неудаче.

**Пример.** Icon возобновляет find после неудачи внешнего сравнения, тогда как потребитель Python-генератора явно запрашивает следующий элемент.

**Граница понятия.** Несколько значений одного возврата не равны нескольким альтернативным решениям; генератор не обязан выполняться параллельно.

**Связи:**

- Связано с: [Граница захвата продолжения](glossary.md#control-continuation-extent) — Продолжения позволяют реализовывать возобновление; не всякий генератор предоставляет first-class continuation.
- Часто путают: [Стратегия вычисления](glossary.md#evaluation-strategy) — Приостановка генератора не превращает обычное вычисление аргументов языка в нестрогое.
- Помогает изучить: [Граница захвата продолжения](glossary.md#control-continuation-extent) — Перед продолжениями полезно проследить обычный вызов, возврат и возобновление.

**Различающие примеры:** [Icon: неудача запускает следующую альтернативу](../concepts/examples/index.md#icon)

**Проверить понимание:** [Замыкание и продолжение сохраняют одно и то же?](questions.md#q08); [Генератор делает язык нестрогим?](questions.md#q09)

**Источники:** [Griswold — Icon overview §§2–3: generators and goal-directed evaluation](https://www2.cs.arizona.edu/icon/docs/ipd266.htm); [Python 3 — Iterator and Generator Types](https://docs.python.org/3/library/stdtypes.html#iterator-types); [Lua 5.4 Reference Manual §2.6 — Coroutines](https://www.lua.org/manual/5.4/manual.html#2.6)

### Ожидание доступности данных { #evaluation-data-availability }

*Data availability suspension* · `evaluation.data_availability` · [Ожидание доступности данных](concepts.md#evaluation-data-availability)

Приостановка или запуск вычисления в зависимости от наличия необходимой информации на входах или в логических переменных.

**Пример.** Oz приостанавливает вычисление `X + 1`, если X ещё не связан с числом.

**Граница понятия.** Ожидание информации не является чтением нуля и не следует автоматически из наличия унификации или нестрогости.

**Связи:**

- Связано с: [Введение связывания](glossary.md#bindings-introduction) — Ожидание в Oz связано с ещё не определённой информацией логического связывания.
- Часто путают: [Синхронизация отправки и приёма](glossary.md#resources-communication-coupling) — Ожидание значения и встреча отправителя с получателем не одно и то же событие.
- Часто путают: [Нотация исходной программы](glossary.md#syntax-program-representation) — Графическая запись не доказывает правило готовности по данным.

**Различающие примеры:** [Oz: значение появится позже](../concepts/examples/index.md#oz)

**Проверить понимание:** [Синхронный канал и синхронные такты означают одно и то же?](questions.md#q14)

**Источники:** [Mozart 1.4.0 tutorial — Oz 3 dataflow threads](https://mozart.github.io/mozart-v1/doc-1.4.0/tutorial/node1.html); [NI — G dataflow and node readiness in LabVIEW](https://www.ni.com/en/shop/labview/benefits-of-programming-graphically-in-ni-labview.html)


## Память и владение { #memory }

### Освобождение памяти { #memory-management }

*Memory reclamation* · `memory.management` · [Освобождение памяти](concepts.md#memory-management)

Политика определения момента и ответственного за освобождение памяти объектов: явный вызов, анализ достижимости, подсчёт ссылок или правила владения и времени жизни.

**Пример.** Подсчёт ссылок может немедленно освободить объект без ссылок, но цикл требует отдельного решения.

**Граница понятия.** Освобождение памяти не гарантирует своевременного закрытия файла; GC не означает отсутствие всех утечек ресурсов.

**Связи:**

- Часто путают: [Освобождение ресурсов](glossary.md#resources-cleanup) — Освобождение памяти объекта и закрытие внешнего ресурса имеют разные условия и сроки.

**В языках:** [C](c.md#memory-management), [Prolog](prolog.md#memory-management), [C++](cpp.md#memory-management), [Haskell](haskell.md#memory-management), [Python](python.md#memory-management), [Java](java.md#memory-management), [C#](csharp.md#memory-management), [Rust](rust.md#memory-management)

**Проверить понимание:** [Сборщик мусора гарантирует закрытие файла?](questions.md#q07)

### Передача и разделение владения { #memory-transfer }

*Ownership transfer and sharing* · `memory.transfer` · [Передача и разделение владения](concepts.md#memory-transfer)

Правила копирования значений, перемещения владения и разделения доступа к объектам, включая заимствования с ограниченным временем использования.

**Пример.** После перемещения String в Rust прежнее связывание нельзя использовать как владельца этого значения.

**Граница понятия.** Перемещение не обязательно физически переносит байты и не тождественно передаче параметра по ссылке.

**Связи:**

- Часто путают: [Связывание параметров](glossary.md#subprograms-parameter-passing) — Способ связать параметр и передача ответственности за объект — независимые измерения вызова.
- Связано с: [Права ссылок и ограничения алиасов](glossary.md#memory-reference-permissions) — Перемещение и заимствование изменяют допустимые способы доступа, но модель прав не сводится к перемещению.

**В языках:** [C](c.md#memory-transfer), [C++](cpp.md#memory-transfer), [Python](python.md#memory-transfer), [Java](java.md#memory-transfer), [JavaScript](javascript.md#memory-transfer), [C#](csharp.md#memory-transfer), [Rust](rust.md#memory-transfer), [TypeScript](typescript.md#memory-transfer)

**Различающие примеры:** [Pony: read-only не означает immutable](../concepts/examples/index.md#pony)

**Проверить понимание:** [Можно ли менять объект через неизменяемое имя?](questions.md#q01); [Копия ссылки — это передача по ссылке на переменную?](questions.md#q05)

### Права ссылок и ограничения алиасов { #memory-reference-permissions }

*Reference permissions and alias restrictions* · `memory.reference_permissions` · [Права ссылок и ограничения алиасов](concepts.md#memory-reference-permissions)

Права конкретной ссылки на чтение и изменение объекта и ограничения на одновременное существование других ссылок к нему.

**Пример.** Pony box даёт представление для чтения, хотя другая ref-ссылка в том же акторе может менять объект.

**Граница понятия.** Read-only view не означает неизменяемость всего объекта; изоляция алиасов не равна требованию использовать значение ровно один раз.

**Связи:**

- Часто путают: [Изменяемость связывания](glossary.md#bindings-mutation) — Запрет перепривязки имени не определяет права изменения объекта через ссылку.
- Связано с: [Передача и разделение владения](glossary.md#memory-transfer) — Перемещение и заимствование изменяют допустимые способы доступа, но модель прав не сводится к перемещению.

**Различающие примеры:** [Pony: read-only не означает immutable](../concepts/examples/index.md#pony)

**Проверить понимание:** [Можно ли менять объект через неизменяемое имя?](questions.md#q01)

**Источники:** [Pony Tutorial — Reference Capabilities: iso, ref, val, box, tag](https://tutorial.ponylang.io/reference-capabilities/reference-capabilities.html)


## Каналы ошибок { #errors }

### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · `errors.model` · [Представление и передача ошибок](concepts.md#errors-model)

Каналы представления и передачи неуспешного исхода или исключительной ситуации: значение, исключение, condition/restart, логическая неудача или аварийный механизм.

**Пример.** Rust Result возвращает данные; Prolog failure предлагает искать другие решения; condition Common Lisp может быть обработано с продолжением.

**Граница понятия.** Не всякий failure является ошибкой, не всякое condition требует раскрутки стека, а сигнал ОС не является общей моделью ошибок языка.

**Связи:**

- Связано с: [Проверяемые исключения](glossary.md#errors-checked-exceptions) — Статическая обязанность catch/throws относится к исключительному каналу, а не ко всем видам неуспеха.
- Связано с: [Освобождение ресурсов](glossary.md#resources-cleanup) — Нелокальный выход требует определить очистку ресурсов; возврат значения-ошибки сам по себе не создаёт такой выход.

**В языках:** [C](c.md#errors-model), [Prolog](prolog.md#errors-model), [C++](cpp.md#errors-model), [Common Lisp](common-lisp.md#errors-model), [Haskell](haskell.md#errors-model), [Python](python.md#errors-model), [Java](java.md#errors-model), [JavaScript](javascript.md#errors-model), [C#](csharp.md#errors-model), [Rust](rust.md#errors-model), [TypeScript](typescript.md#errors-model)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html), [20. Критерии оценки языков программирования](../lectures/html/20-kriterii-ocenki-yazykov-programmirovaniya.html)

**Проверить понимание:** [Чем checked exception отличается от Result и must-use?](questions.md#q06); [Сборщик мусора гарантирует закрытие файла?](questions.md#q07)

### Проверяемые исключения { #errors-checked-exceptions }

*Checked exceptions* · `errors.checked_exceptions` · [Проверяемые исключения](concepts.md#errors-checked-exceptions)

Статическое требование обработать определённые классы исключений или объявить возможность их распространения в контракте подпрограммы.

**Пример.** Java требует catch или throws для проверяемых исключений, с установленными языком исключениями из этого правила.

**Граница понятия.** Наличие типа ошибки в Result не превращает его в checked exception; непроверяемые исключения могут сосуществовать с проверяемыми.

**Связи:**

- Связано с: [Представление и передача ошибок](glossary.md#errors-model) — Статическая обязанность catch/throws относится к исключительному каналу, а не ко всем видам неуспеха.
- Часто путают: [Диагностика неиспользованного результата](glossary.md#errors-must-use) — Проверка распространения исключения и диагностика отброшенного значения проверяют разные события.

**В языках:** [Python](python.md#errors-checked-exceptions), [Java](java.md#errors-checked-exceptions), [Rust](rust.md#errors-checked-exceptions), [TypeScript](typescript.md#errors-checked-exceptions)

**Проверить понимание:** [Чем checked exception отличается от Result и must-use?](questions.md#q06)

### Диагностика неиспользованного результата { #errors-must-use }

*Unused-result diagnostics* · `errors.must_use` · [Диагностика неиспользованного результата](concepts.md#errors-must-use)

Диагностика отбрасывания результата, который помечен как требующий внимания вызывающего кода. Уровень диагностики и допустимые способы отбрасывания зависят от профиля.

**Пример.** Rust предупреждает о некоторых неиспользованных Result, но допускает явное `let _ = ...`.

**Граница понятия.** Использовать значение не обязательно означает корректно обработать ошибку; предупреждение не равно запрету компиляции.

**Связи:**

- Часто путают: [Проверяемые исключения](glossary.md#errors-checked-exceptions) — Проверка распространения исключения и диагностика отброшенного значения проверяют разные события.

**В языках:** [Python](python.md#errors-must-use), [Java](java.md#errors-must-use), [Rust](rust.md#errors-must-use)

**Проверить понимание:** [Чем checked exception отличается от Result и must-use?](questions.md#q06)


## Ресурсы и взаимодействие { #resources }

### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · `resources.cleanup` · [Освобождение ресурсов](concepts.md#resources-cleanup)

Правила выполнения освобождающих действий при завершении работы с ресурсом или выходе из области, включая обычные и исключительные пути.

**Пример.** Деструктор RAII, Python with и Java try-with-resources ограничивают время использования ресурсов разными механизмами.

**Граница понятия.** Ни одна такая запись без уточнений не обещает очистку при аварийном завершении процесса; очистка не тождественна сборке мусора.

**Связи:**

- Часто путают: [Освобождение памяти](glossary.md#memory-management) — Освобождение памяти объекта и закрытие внешнего ресурса имеют разные условия и сроки.
- Связано с: [Представление и передача ошибок](glossary.md#errors-model) — Нелокальный выход требует определить очистку ресурсов; возврат значения-ошибки сам по себе не создаёт такой выход.

**В языках:** [C](c.md#resources-cleanup), [C++](cpp.md#resources-cleanup), [Common Lisp](common-lisp.md#resources-cleanup), [Python](python.md#resources-cleanup), [Java](java.md#resources-cleanup), [JavaScript](javascript.md#resources-cleanup), [C#](csharp.md#resources-cleanup), [Rust](rust.md#resources-cleanup), [TypeScript](typescript.md#resources-cleanup)

**Слайды лекций:** [20. Критерии оценки языков программирования](../lectures/html/20-kriterii-ocenki-yazykov-programmirovaniya.html)

**Проверить понимание:** [Сборщик мусора гарантирует закрытие файла?](questions.md#q07)

**Люди:** [Бьёрн Страуструп](people.md#stroustrup)

**Источники:** [Дизайн и эволюция C++](sources.md#stroustrup-de)

### Интерфейс ввода-вывода { #resources-io }

*I/O interface* · `resources.io` · [Интерфейс ввода-вывода](concepts.md#resources-io)

Уровень и форма предоставления операций обмена с внешним окружением — встроенная операция, стандартная библиотека, макрос или API конкретной среды.

**Пример.** Python print встроен, а Java System.out — библиотечный API.

**Граница понятия.** Доступность console.log в хосте не делает файловый или консольный ввод-вывод универсальной гарантией ECMAScript.

**Связи:**

- Связано с: [Контроль эффектов](glossary.md#evaluation-effects) — Ввод-вывод — пример наблюдаемого эффекта, но способ предоставления API не определяет статический контроль эффекта.

**В языках:** [C](c.md#resources-io), [Prolog](prolog.md#resources-io), [C++](cpp.md#resources-io), [Common Lisp](common-lisp.md#resources-io), [Haskell](haskell.md#resources-io), [Python](python.md#resources-io), [Java](java.md#resources-io), [C#](csharp.md#resources-io), [Rust](rust.md#resources-io)

### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · `resources.concurrency` · [Конкурентное выполнение](concepts.md#resources-concurrency)

Возможность организовать несколько вычислений с перекрывающимся временем жизни и правила их продвижения и взаимодействия.

**Пример.** Акторы обмениваются сообщениями; async-функции могут приостанавливаться без выделения отдельного потока каждой функции.

**Граница понятия.** Конкурентность не гарантирует одновременное выполнение на нескольких ядрах; наличие await не определяет политику планировщика.

**Связи:**

- Связано с: [Синхронизация отправки и приёма](glossary.md#resources-communication-coupling) — Взаимодействующим вычислениям нужен определённый протокол отправки и приёма.

**В языках:** [Python](python.md#resources-concurrency), [Java](java.md#resources-concurrency), [JavaScript](javascript.md#resources-concurrency), [C#](csharp.md#resources-concurrency), [Rust](rust.md#resources-concurrency), [TypeScript](typescript.md#resources-concurrency)

### Синхронизация отправки и приёма { #resources-communication-coupling }

*Send and receive coupling* · `resources.communication_coupling` · [Синхронизация отправки и приёма](concepts.md#resources-communication-coupling)

Степень зависимости завершения отправки от готовности получателя: независимое помещение сообщения в очередь или согласованная встреча отправителя и получателя.

**Пример.** Erlang отправляет в mailbox; occam использует синхронное рандеву по каналу.

**Граница понятия.** Синхронная коммуникация не означает синхронную реактивную модель времени или гарантию доставки при отказах.

**Связи:**

- Часто путают: [Ожидание доступности данных](glossary.md#evaluation-data-availability) — Ожидание значения и встреча отправителя с получателем не одно и то же событие.
- Связано с: [Конкурентное выполнение](glossary.md#resources-concurrency) — Взаимодействующим вычислениям нужен определённый протокол отправки и приёма.
- Полезный контраст: [Выбор сообщения из очереди](glossary.md#resources-receive-selection) — Когда завершится отправка и какое сообщение получатель выберет — разные вопросы.
- Часто путают: [Временная область модели](glossary.md#computation-time-domain) — Синхронные логические такты и синхронное рандеву — разные значения слова synchronous.

**Проверить понимание:** [Синхронный канал и синхронные такты означают одно и то же?](questions.md#q14)

**Источники:** [Erlang/OTP — Concurrent Programming: send and receive](https://www.erlang.org/doc/system/conc_prog.html); [INMOS occam Run-time Model Specification SW-0064-4 §3 — synchronized unbuffered channels](https://www.transputer.net/obooks/sw-0064-4/sw-0064-4.html)

### Выбор сообщения из очереди { #resources-receive-selection }

*Message selection from a queue* · `resources.receive_selection` · [Выбор сообщения из очереди](concepts.md#resources-receive-selection)

Правило выбора доступного сообщения из очереди получателя — например, только голова либо первое сообщение, подходящее под образец.

**Пример.** Erlang receive может оставить раннее неподходящее сообщение и обработать более позднее подходящее.

**Граница понятия.** Mailbox сам по себе не задаёт selective receive; к небуферизованному каналу без очереди это сравнение напрямую неприменимо.

**Связи:**

- Полезный контраст: [Синхронизация отправки и приёма](glossary.md#resources-communication-coupling) — Когда завершится отправка и какое сообщение получатель выберет — разные вопросы.

**Проверить понимание:** [Синхронный канал и синхронные такты означают одно и то же?](questions.md#q14)

**Источники:** [Erlang/OTP — Concurrent Programming: selective receive and retained messages](https://www.erlang.org/doc/system/conc_prog.html)


## Синтаксис и метапрограммирование { #syntax }

### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · `syntax.blocks` · [Границы синтаксических групп](concepts.md#syntax-blocks)

Способ обозначения границ синтаксических групп — разделителями, значимыми отступами или структурой читаемых форм.

**Пример.** Haskell допускает как layout, так и явные фигурные скобки для соответствующих групп.

**Граница понятия.** Синтаксическая группа не обязана создавать область видимости, а поддержанные способы не всегда взаимоисключающие.

**Связи:**

- Часто путают: [Конструкции областей видимости](glossary.md#scope-constructs) — Границы синтаксической группы и границы области имён не обязаны совпадать.
- Связано с: [Границы операторов и определений](glossary.md#syntax-statement-terminator) — Границы групп и границы отдельных операторов совместно определяют разбор, но могут задаваться разными средствами.

**В языках:** [C](c.md#syntax-blocks), [Prolog](prolog.md#syntax-blocks), [C++](cpp.md#syntax-blocks), [Common Lisp](common-lisp.md#syntax-blocks), [Haskell](haskell.md#syntax-blocks), [Python](python.md#syntax-blocks), [Java](java.md#syntax-blocks), [JavaScript](javascript.md#syntax-blocks), [C#](csharp.md#syntax-blocks), [Rust](rust.md#syntax-blocks), [TypeScript](typescript.md#syntax-blocks)

**Слайды лекций:** [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html)

**Проверить понимание:** [Может ли блок иметь границы, но не создавать область имён?](questions.md#q04)

### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · `syntax.statement_terminator` · [Границы операторов и определений](concepts.md#syntax-statement-terminator)

Правила распознавания границ операторов и определений: терминатор, разделитель, перевод строки либо структура формы.

**Пример.** Prolog завершает клаузу точкой; в Lisp граница формы задаётся её структурой.

**Граница понятия.** Терминатор и разделитель — разные роли; автоматическая вставка точки с запятой не означает, что любой перенос строки завершает оператор.

**Связи:**

- Связано с: [Границы синтаксических групп](glossary.md#syntax-blocks) — Границы групп и границы отдельных операторов совместно определяют разбор, но могут задаваться разными средствами.

**В языках:** [Prolog](prolog.md#syntax-statement-terminator), [Common Lisp](common-lisp.md#syntax-statement-terminator), [Python](python.md#syntax-statement-terminator), [Java](java.md#syntax-statement-terminator), [JavaScript](javascript.md#syntax-statement-terminator), [Rust](rust.md#syntax-statement-terminator)

**Проверить понимание:** [Может ли блок иметь границы, но не создавать область имён?](questions.md#q04)

### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · `syntax.case_sensitive` · [Чувствительность имён к регистру](concepts.md#syntax-case-sensitive)

Правило различения идентификаторов по регистру после предусмотренных языком шагов чтения и нормализации.

**Пример.** Python различает name и Name; Common Lisp reader по умолчанию преобразует регистр неэкранированных символов.

**Граница понятия.** Политику чтения символов нельзя без уточнений приравнивать к сравнению строк или объявлять одинаковой для всех Lisp-диалектов.

**Связи:**

- Связано с: [Правило разрешения имён](glossary.md#scope-resolution) — Правила чтения и различения имён определяют, какой идентификатор передаётся разрешению связываний.

**В языках:** [Prolog](prolog.md#syntax-case-sensitive), [Python](python.md#syntax-case-sensitive), [Java](java.md#syntax-case-sensitive), [Rust](rust.md#syntax-case-sensitive)

### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · `syntax.metaprogramming` · [Метапрограммирование](concepts.md#syntax-metaprogramming)

Средства, с помощью которых программа анализирует, создаёт или преобразует код либо его представление на определённой стадии обработки.

**Пример.** Препроцессор C преобразует токены; Lisp defmacro преобразует формы; рефлексия исследует доступные сведения о программе.

**Граница понятия.** Вычисление при компиляции не обязательно меняет синтаксис, а возможность eval не означает лексический захват окружения вызывающего кода.

**Связи:**

- Связано с: [Гигиена макросов](glossary.md#syntax-macro-hygiene) — Гигиена уточняет один аспект преобразования синтаксиса, но не любого метапрограммирования.

**В языках:** [C](c.md#syntax-metaprogramming), [Prolog](prolog.md#syntax-metaprogramming), [C++](cpp.md#syntax-metaprogramming), [Common Lisp](common-lisp.md#syntax-metaprogramming), [Python](python.md#syntax-metaprogramming), [Java](java.md#syntax-metaprogramming), [Rust](rust.md#syntax-metaprogramming)

### Гигиена макросов { #syntax-macro-hygiene }

*Macro hygiene* · `syntax.macro_hygiene` · [Гигиена макросов](concepts.md#syntax-macro-hygiene)

Сохранение корректных связей имён при раскрытии макроса, предотвращающее непреднамеренный захват между введёнными именами и контекстом использования.

**Пример.** syntax-rules Scheme позволяет макросу ввести tmp без захвата одноимённой переменной пользователя.

**Граница понятия.** Уникальные имена, выбранные вручную, являются техникой предотвращения захвата, а не автоматической гарантией любого макромеханизма.

**Связи:**

- Связано с: [Метапрограммирование](glossary.md#syntax-metaprogramming) — Гигиена уточняет один аспект преобразования синтаксиса, но не любого метапрограммирования.
- Связано с: [Правило разрешения имён](glossary.md#scope-resolution) — Гарантия гигиены сформулирована через сохранение связываний при раскрытии.
- Сначала полезно изучить: [Сокрытие имён](glossary.md#scope-shadowing) — Контрпример захвата имени понятнее после различения связывания и сокрытия.

**Различающие примеры:** [Scheme: вернуться в вычисление](../concepts/examples/index.md#scheme)

**Источники:** [Scheme R7RS-small §4.3 — hygienic macros](https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-6.html)

### Нотация исходной программы { #syntax-program-representation }

*Source program notation* · `syntax.program_representation` · [Нотация исходной программы](concepts.md#syntax-program-representation)

Форма, в которой автор задаёт исходную программу для исполнения или трансляции: текст либо структурный граф с узлами и связями.

**Пример.** Граф G в LabVIEW является программой; граф AST в отладчике текстового языка — её производным представлением.

**Граница понятия.** Графическая запись сама по себе не доказывает dataflow-семантику или параллельное выполнение.

**Связи:**

- Часто путают: [Ожидание доступности данных](glossary.md#evaluation-data-availability) — Графическая запись не доказывает правило готовности по данным.

**Источники:** [NI — G graphical programming in LabVIEW](https://www.ni.com/en/shop/labview/benefits-of-programming-graphically-in-ni-labview.html); [Marten 1.6 — Prograph cases, operations and links (notation only)](https://www.andescotia.com/products/marten/)


## Парадигмы { #paradigm }

### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · `paradigm.supported` · [Поддерживаемые парадигмы](concepts.md#paradigm-supported)

Устойчивые способы организации вычислений и программных абстракций, поддержанные механизмами языка и его практикой использования.

**Пример.** Один язык может поддерживать императивный, функциональный и объектный стили.

**Граница понятия.** Название парадигмы не заменяет перечень конкретных гарантий; функциональные возможности Python не делают его нестрогим Haskell.

**Связи:**

- Связано с: [Смысл применения правил](glossary.md#computation-rule-semantics) — Логическая и декларативная традиции включают разные семантики правил; метка парадигмы не выбирает одну автоматически.

**В языках:** [C](c.md#paradigm-supported), [Prolog](prolog.md#paradigm-supported), [C++](cpp.md#paradigm-supported), [Common Lisp](common-lisp.md#paradigm-supported), [Haskell](haskell.md#paradigm-supported), [Python](python.md#paradigm-supported), [Java](java.md#paradigm-supported), [JavaScript](javascript.md#paradigm-supported), [Rust](rust.md#paradigm-supported), [TypeScript](typescript.md#paradigm-supported)

**Слайды лекций:** [02. Понятие языка](../lectures/html/02-ponyatie-yazyka.html)

**Источники:** [Стили и методы программирования](sources.md#nepeivoda)


## Семантика данных { #data }

### Кратность элементов коллекции { #data-collection-multiplicity }

*Collection multiplicity* · `data.collection_multiplicity` · [Кратность элементов коллекции](concepts.md#data-collection-multiplicity)

Правила учёта повторных элементов и их позиций в конкретной коллекции или результате операции: присутствие, число вхождений либо позиционные вхождения.

**Пример.** SQL SELECT ALL сохраняет дубликаты, SELECT DISTINCT устраняет их.

**Граница понятия.** Кратность и порядок независимы; наблюдаемый порядок строк без ORDER BY не является гарантией последовательности.

**Связи:**

- Связано с: [Смысл применения правил](glossary.md#computation-rule-semantics) — Замыкание Datalog работает с отношениями как множествами; SQL bag-семантика показывает другой выбор кратности.

**Различающие примеры:** [Datalog: цикл в графе, конечное замыкание](../concepts/examples/index.md#datalog), [SQL: одинаковые строки не исчезают сами](../concepts/examples/index.md#sql)

**Проверить понимание:** [Почему одинаковая операция даёт разные результаты для коллекций?](questions.md#q13)

**Источники:** [Soufflé — Relations as sets of tuples](https://souffle-lang.github.io/relations); [PostgreSQL 18 — Select Lists: ALL and DISTINCT](https://www.postgresql.org/docs/18/queries-select-lists.html); [Python 3 — Sequence Types](https://docs.python.org/3/library/stdtypes.html#sequence-types-list-tuple-range)

### Основание числового представления { #data-numeric-radix }

*Numeric representation radix* · `data.numeric_radix` · [Основание числового представления](concepts.md#data-numeric-radix)

Основание представления и арифметики числового типа или поля, например двоичное либо десятичное.

**Пример.** Десятичное поле COBOL и двоичный float представляют дробные значения по разным правилам.

**Граница понятия.** Литерал 0x10 меняет запись числа, но сам по себе не определяет арифметическую модель типа.

**Связи:**

- Часто путают: [Ограничение числовой точности](glossary.md#data-numeric-precision) — Основание представления и ограничение числа разрядов независимы.

**Различающие примеры:** [COBOL: позиции, а не двоичная дробь](../concepts/examples/index.md#cobol)

**Источники:** [GnuCOBOL 3.1 RC-1 Programmer's Guide §6.9.33 — PICTURE and V scale](https://gnucobol.sourceforge.io/HTML/gnucobpg.html); [Python 3 — binary float representation and hex conversion](https://docs.python.org/3/library/stdtypes.html#additional-methods-on-float)

### Ограничение числовой точности { #data-numeric-precision }

*Numeric precision bound* · `data.numeric_precision` · [Ограничение числовой точности](concepts.md#data-numeric-precision)

Ограничение количества значащих разрядов, задаваемое типом, полем или настраиваемым контекстом вычисления.

**Пример.** Python int не имеет заранее фиксированной разрядности, а PIC-поле COBOL имеет заданное число позиций.

**Граница понятия.** Точность не равна масштабу или положению точки; произвольная точность ограничена ресурсами и не означает точное представление любого вещественного числа.

**Связи:**

- Часто путают: [Основание числового представления](glossary.md#data-numeric-radix) — Основание представления и ограничение числа разрядов независимы.
- Связано с: [Преобразования типов](glossary.md#typing-conversions) — Преобразование числового типа может округлять значение или терять разряды.

**Различающие примеры:** [COBOL: позиции, а не двоичная дробь](../concepts/examples/index.md#cobol)

**Источники:** [Python 3 — unlimited-precision integers and user-definable Decimal precision](https://docs.python.org/3/library/stdtypes.html#numeric-types-int-float-complex); [GnuCOBOL 3.1 RC-1 Programmer's Guide §6.9.33 — numeric PICTURE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html)


## Правила вычисления и модели времени { #computation }

### Смысл применения правил { #computation-rule-semantics }

*Rule application semantics* · `computation.rule_semantics` · [Смысл применения правил](concepts.md#computation-rule-semantics)

Смысл применения правил к состоянию задачи: поиск ответа на цель, построение замыкания фактов либо преобразование хранилища с фиксацией выбора.

**Пример.** Положительный конечный Datalog задаёт наименьшую неподвижную точку отношений; CHR переписывает хранилище ограничений.

**Граница понятия.** Семантика результата не предписывает единственный алгоритм реализации; top-down и bottom-up — стратегии, не универсальные названия языковых семантик.

**Связи:**

- Связано с: [Логический поиск решений](glossary.md#control-logic-search) — Механизм поиска реализует получение решений, а семантика правил определяет, что считается результатом.
- Связано с: [Поддерживаемые парадигмы](glossary.md#paradigm-supported) — Логическая и декларативная традиции включают разные семантики правил; метка парадигмы не выбирает одну автоматически.
- Связано с: [Кратность элементов коллекции](glossary.md#data-collection-multiplicity) — Замыкание Datalog работает с отношениями как множествами; SQL bag-семантика показывает другой выбор кратности.

**Различающие примеры:** [Datalog: цикл в графе, конечное замыкание](../concepts/examples/index.md#datalog)

**Источники:** [Mercury Reference Manual — goal solutions and determinism](https://www.mercurylang.org/information/doc-release/mercury_ref/Determinism-categories.html); [Z3 Guide — Basic Datalog fixed-point engine](https://microsoft.github.io/z3guide/docs/fixedpoints/basicdatalog/); [Soufflé Tutorial — recursive relations and arithmetic extension limits](https://souffle-lang.github.io/tutorial); [SWI-Prolog CHR — simplification, propagation and simpagation](https://www.swi-prolog.org/pldoc/man?section=chr-syntaxandsemantics)

### Режимы связанности аргументов { #computation-instantiation-modes }

*Argument instantiation modes* · `computation.instantiation_modes` · [Режимы связанности аргументов](concepts.md#computation-instantiation-modes)

Описание требуемой связанности аргументов до вызова и гарантируемой связанности после него, отдельно от типов значений.

**Пример.** Mercury in обычно задаёт ground → ground, out — free → ground.

**Граница понятия.** Режим out логического аргумента не равен C# out и не определяет механизм передачи по ссылке или число решений.

**Связи:**

- Полезный контраст: [Объявленная кратность решений](glossary.md#computation-solution-cardinality) — Состояние аргументов и число решений описываются отдельно для одного режима вызова.
- Часто путают: [Связывание параметров](glossary.md#subprograms-parameter-passing) — Входная связанность не задаёт физический или семантический способ передачи параметра.

**Различающие примеры:** [Mercury: один предикат, два режима](../concepts/examples/index.md#mercury)

**Проверить понимание:** [Сопоставление с образцом — это унификация?](questions.md#q11); [det означает, что функция обязательно завершится?](questions.md#q12)

**Источники:** [Mercury Reference Manual — Insts, modes and mode definitions](https://www.mercurylang.org/information/doc-release/mercury_ref/Insts-modes-and-mode-definitions.html)

### Объявленная кратность решений { #computation-solution-cardinality }

*Declared solution cardinality* · `computation.solution_cardinality` · [Объявленная кратность решений](concepts.md#computation-solution-cardinality)

Контракт количества успешных решений и допустимости неудачи для определённого режима вызова при его возврате.

**Пример.** Mercury det означает одно решение, semidet — ноль или одно, multi — одно или больше, nondet — ноль или больше.

**Граница понятия.** det не доказывает завершение и не описывает порядок планирования потоков; несколько решений не равны нескольким возвращаемым компонентам одного результата.

**Связи:**

- Полезный контраст: [Режимы связанности аргументов](glossary.md#computation-instantiation-modes) — Состояние аргументов и число решений описываются отдельно для одного режима вызова.
- Часто путают: [Режим гарантии тотальности](glossary.md#verification-totality) — Ровно одно решение при возврате не является гарантией возврата.

**Различающие примеры:** [Mercury: один предикат, два режима](../concepts/examples/index.md#mercury)

**Проверить понимание:** [det означает, что функция обязательно завершится?](questions.md#q12)

**Источники:** [Mercury Reference Manual — Determinism categories and returning-call qualification](https://www.mercurylang.org/information/doc-release/mercury_ref/Determinism-categories.html)

### Временная область модели { #computation-time-domain }

*Model time domain* · `computation.time_domain` · [Временная область модели](concepts.md#computation-time-domain)

Встроенный смысл времени, относительно которого определены значения и изменения модели: логические такты, дискретные события, непрерывное время или их сочетание.

**Пример.** Поток Lustre задаёт значение на логических тактах; Modelica может описывать непрерывную динамику с дискретными событиями.

**Граница понятия.** Логический такт не задаёт длительность выполнения на процессоре и сам по себе не гарантирует real-time deadline.

**Связи:**

- Часто путают: [Синхронизация отправки и приёма](glossary.md#resources-communication-coupling) — Синхронные логические такты и синхронное рандеву — разные значения слова synchronous.
- Связано с: [Планирование обновлений в HDL-симуляции](glossary.md#computation-update-scheduling) — Внутри одного момента модельного времени могут существовать разные фазы применения обновлений.
- Помогает изучить: [Планирование обновлений в HDL-симуляции](glossary.md#computation-update-scheduling) — Сначала разделите модельное время и время исполнения, затем фазы одного шага симуляции.

**Различающие примеры:** [Lustre: значение — поток](../concepts/examples/index.md#lustre)

**Проверить понимание:** [Синхронный канал и синхронные такты означают одно и то же?](questions.md#q14); [Как отличить присваивание, уравнение и отложенное обновление?](questions.md#q15)

**Источники:** [Verimag — Lustre clocked streams](https://www-verimag.imag.fr/The-Lustre-Programming-Language-and.html); [Modelica Specification 3.6 §8 — continuous integration and events](https://specification.modelica.org/maint/3.6/equations.html); [Icarus Verilog — discrete-event simulation](https://steveicarus.github.io/iverilog/usage/simulation.html)

### Направленность уравнений и присваиваний { #computation-equation-causality }

*Equation and assignment causality* · `computation.equation_causality` · [Направленность уравнений и присваиваний](concepts.md#computation-equation-causality)

Различие между направленным обновлением цели, определением выходного потока и ненаправленным отношением величин, решаемым совместно с другими уравнениями.

**Пример.** Modelica `v = R*i` позволяет решать относительно i или v в зависимости от остальных уравнений.

**Граница понятия.** Знак равенства не всегда означает присваивание; система уравнений может не иметь решения или иметь несколько решений.

**Связи:**

- Часто путают: [Формы присваивания и связывания](glossary.md#bindings-assignment) — Равенство в уравнении не означает последовательное изменение переменной.

**Различающие примеры:** [Lustre: значение — поток](../concepts/examples/index.md#lustre), [Modelica: неизвестная может быть с любой стороны](../concepts/examples/index.md#modelica)

**Проверить понимание:** [Как отличить присваивание, уравнение и отложенное обновление?](questions.md#q15)

**Источники:** [Verimag — Lustre unordered stream equations](https://www-verimag.imag.fr/The-Lustre-Programming-Language-and.html); [Modelica Specification 3.6 §8 — equations versus assignments](https://specification.modelica.org/maint/3.6/equations.html)

### Планирование обновлений в HDL-симуляции { #computation-update-scheduling }

*HDL simulation update scheduling* · `computation.update_scheduling` · [Планирование обновлений в HDL-симуляции](concepts.md#computation-update-scheduling)

Момент применения изменения состояния относительно вычисления правой части и других событий в модели аппаратной симуляции.

**Пример.** Verilog nonblocking assignment вычисляет RHS сейчас, а применение значения помещает в очередь обновлений.

**Граница понятия.** Неблокирующее присваивание не равно многопоточному атомарному обмену; наблюдение результата зависит от фазы симуляционного шага.

**Связи:**

- Связано с: [Временная область модели](glossary.md#computation-time-domain) — Внутри одного момента модельного времени могут существовать разные фазы применения обновлений.
- Связано с: [Формы присваивания и связывания](glossary.md#bindings-assignment) — Планирование уточняет, когда наблюдается эффект присваивания; не заменяет его синтаксическую форму.
- Сначала полезно изучить: [Временная область модели](glossary.md#computation-time-domain) — Сначала разделите модельное время и время исполнения, затем фазы одного шага симуляции.

**Различающие примеры:** [Verilog: вычислить сейчас, обновить позже](../concepts/examples/index.md#verilog)

**Проверить понимание:** [Как отличить присваивание, уравнение и отложенное обновление?](questions.md#q15)

**Источники:** [Icarus Verilog — Simulation](https://steveicarus.github.io/iverilog/usage/simulation.html); [Icarus VVP Simulation Engine — blocking and nonblocking assignment events](https://steveicarus.github.io/iverilog/developer/guide/vvp/vvp.html)


## Проверяемые свойства программ { #verification }

### Режим гарантии тотальности { #verification-totality }

*Totality guarantee policy* · `verification.totality` · [Режим гарантии тотальности](concepts.md#verification-totality)

Политика проверки того, что определение покрывает допустимые входы и завершается либо продуктивно выдаёт результат в принятой модели вычислений.

**Пример.** Idris total требует больше, чем покрытие всех образцов; partial явно ослабляет обязательства.

**Граница понятия.** Типизация и чистота не доказывают тотальность, а успешная проверка через непроверенное допущение не является доказательством.

**Связи:**

- Часто путают: [Зависимость типа от значения](glossary.md#typing-value-dependency) — Зависимость типа от значения не гарантирует завершения любой программы.
- Часто путают: [Контроль эффектов](glossary.md#evaluation-effects) — Чистое вычисление может расходиться, а завершающееся — иметь побочные эффекты.
- Часто путают: [Объявленная кратность решений](glossary.md#computation-solution-cardinality) — Ровно одно решение при возврате не является гарантией возврата.
- Связано с: [Поведенческие контракты](glossary.md#verification-behavioral-contracts) — Постусловие обычно говорит о нормальном возврате; завершение требует отдельного обязательства.

**Различающие примеры:** [Idris 2: длина связана с допустимым индексом](../concepts/examples/index.md#idris)

**Проверить понимание:** [det означает, что функция обязательно завершится?](questions.md#q12)

**Источники:** [Idris 2 — covering, total, partial and Totality](https://idris2.readthedocs.io/en/latest/tutorial/typesfuns.html); [Agda — Termination Checking, TERMINATING, NON_TERMINATING and --safe](https://agda.readthedocs.io/en/latest/language/termination-checking.html)

### Поведенческие контракты { #verification-behavioral-contracts }

*Behavioral contracts* · `verification.behavioral_contracts` · [Поведенческие контракты](concepts.md#verification-behavioral-contracts)

Предикаты допустимого входа, результата, изменения состояния и инвариантов, которыми описывается наблюдаемое поведение программного компонента.

**Пример.** Eiffel ensure может потребовать `balance = old balance + amount` после deposit.

**Граница понятия.** Контракт можно проверять при выполнении или доказывать инструментом; его наличие в тексте ещё не означает доказанность.

**Связи:**

- Часто путают: [Контракты полиморфизма](glossary.md#abstraction-contracts) — Набор доступных операций не равен предикатам их поведения.
- Связано с: [Режим гарантии тотальности](glossary.md#verification-totality) — Постусловие обычно говорит о нормальном возврате; завершение требует отдельного обязательства.

**Различающие примеры:** [Eiffel: контракт сильнее сигнатуры](../concepts/examples/index.md#eiffel)

**Источники:** [Eiffel — Design by Contract: assertions, old and monitoring](https://www.eiffel.org/doc/eiffel/ET-_Design_by_Contract_(tm),_Assertions_and_Exceptions); [Ada 2012 RM §6.1.1 — preconditions, postconditions and assertion policy](https://www.adaic.org/resources/add_content/standards/12rm/html/RM-6-1-1.html); [SPARK User's Guide — language subset, contracts and GNATprove boundaries](https://docs.adacore.com/spark2014-docs/html/ug/en/spark_2014.html)
