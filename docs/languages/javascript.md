---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# JavaScript

JavaScript описан здесь как ECMAScript 2024 с динамическими типами, прототипными объектами и функциями первого класса. Ввод-вывод предоставляется хостом (например, браузером или Node.js), а не самим ECMAScript.

*Карточка сравнительная: 34/85 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1995 — [Wikidata P571](https://www.wikidata.org/wiki/Q2005) (получено 2026-09-24) |
| Авторы | [Брендан Эйх](people.md#eich) |
| Организации | Netscape, Ecma International TC39 |
| Сайт | <https://tc39.es/> |
| Спецификация | <https://262.ecma-international.org/15.0/> |
| Внешние каталоги | [Wikidata Q2005](https://www.wikidata.org/wiki/Q2005) |

## Люди { #people }

- [Брендан Эйх](people.md#eich) — Создал первую реализацию JavaScript в Netscape в 1995 году и участвовал в стандартизации ECMAScript.

## Публикации { #publications }

- Брендан Эйх, Allen Wirfs-Brock. *JavaScript: The First 20 Years*. Proc. ACM Program. Lang. 4, HOPL IV, 2020. DOI: [10.1145/3386327](https://doi.org/10.1145/3386327). Создание JavaScript и развитие стандарта ECMAScript. ([в источниках](sources.md#hopl-javascript))
- Rui Pereira, Marco Couto, Francisco Ribeiro, Rui Rua, Jácome Cunha, João Paulo Fernandes, João Saraiva. [Energy Efficiency across Programming Languages: How Do Energy, Time, and Memory Relate?](https://greenlab.di.uminho.pt/wp-content/uploads/2017/10/sleFinal.pdf). SLE 2017, 2017. DOI: [10.1145/3136014.3136031](https://doi.org/10.1145/3136014.3136031). Измерения энергии, времени и памяти для 27 языков на задачах Benchmarks Game — материал к критерию «стоимость»; обсуждайте вместе с ограничениями методики. ([в источниках](sources.md#pereira-energy-2017))
- Russ Cox. [Programming Language Memory Models](https://research.swtch.com/plmm). 2021. Как Java, C++, JavaScript, Rust и Go определяют семантику разделяемой памяти и атомарных операций и почему это трудно. ([в источниках](sources.md#cox-memory-models))
- Stefan Marr. [An Introduction to Efficient and Safe Implementations of Dynamic Languages](https://stefan-marr.de/2020/06/efficient-and-safe-implementations-of-dynamic-languages/). 2020. Обзор техник реализации динамических языков: AST- и байткод-интерпретаторы, inline caches, hidden classes, JIT. ([в источниках](sources.md#marr-dynamic-languages))
- Daejun Park, Andrei Ştefănescu, Grigore Roşu. *KJS: A Complete Formal Semantics of JavaScript*. PLDI '15, 2015. DOI: [10.1145/2737924.2737991](https://doi.org/10.1145/2737924.2737991). Полная исполняемая семантика ECMAScript 5.1 в K-framework, проверенная на тестах test262. ([в источниках](sources.md#kjs-2015))
- Darius Mercadier. [Land ahoy: leaving the Sea of Nodes](https://v8.dev/blog/leaving-the-sea-of-nodes). V8 blog, 2025. Почему оптимизирующий компилятор V8 ушёл от IR «море узлов» к графу потока управления Turboshaft: промахи кэша, сложность, время компиляции. ([в источниках](sources.md#v8-leaving-son))
- [Ohm](https://ohmjs.org/). PEG-библиотека для JavaScript и TypeScript: грамматика без семантических действий, семантика задаётся отдельно; левая рекурсия и онлайн-редактор с визуализацией разбора. ([в источниках](sources.md#ohm))
- [Peggy](https://peggyjs.org/). PEG-генератор для JavaScript, наследник PEG.js; семантические действия в грамматике, генерация типов TypeScript. ([в источниках](sources.md#peggy))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **es2024** — ECMA-262, 15-я редакция (ECMAScript 2024); общий базовый профиль, если не указан strict или sloppy.
- **strict** — ECMAScript 2024, strict mode: модули и тела классов всегда строгие, скрипты/функции могут включить use strict.
- **sloppy** — ECMAScript 2024, нестрогий код Script/функций; не применяется к модулям и телам классов.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

англ. *Binding introduction* (также *declaration*, *name binding*) · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: es2024)** — let, const, var, объявления функций и классов.
- **Связывание образцом (layer: language, profile: es2024)** — Деструктурирующие объявления и параметры.
- **Связывание присваиванием (layer: language, profile: sloppy, applies_to: присваивание неразрешимому имени)** — В обычном хосте может создать свойство глобального объекта, а не лексическое let-связывание. В strict mode такое присваивание вызывает ReferenceError. ([ECMA-262 2024, PutValue](https://262.ecma-international.org/15.0/#sec-putvalue))

#### Изменяемость связывания { #bindings-mutation }

англ. *Binding mutability* (также *rebinding*, *immutable binding*, *const qualification*) · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: es2024, applies_to: let и var)**
- **Неизменяемое (layer: language, profile: es2024, applies_to: const)** — const запрещает перепривязку; объект, на который ссылается значение, может быть изменяемым.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

англ. *Assignment and binding forms* (также *assignment*, *destructuring*, *unification*) · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: es2024)**
- **Распаковка при присваивании (layer: language, profile: es2024)** — Деструктуризация массивов и объектов; это также возможно при присваивании существующим переменным.

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

англ. *Name resolution* (также *name lookup*, *lexical scoping*, *dynamic scoping*) · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: strict)** — with запрещён; direct eval не добавляет var-связывания в окружение вызывающего.
- **Лексическое (layer: language, profile: sloppy)** — Лексическая основа с исключениями: with добавляет объектное окружение, а direct eval может вводить var в окружение вызывающего. Это не общая динамическая область переменных по стеку вызовов. ([ECMA-262 2024, Strict Mode Code](https://262.ecma-international.org/15.0/#sec-strict-mode-code))

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

англ. *Scoping constructs* (также *scope*, *block scope*) · [в онтологии](concepts.md#scope-constructs)

- **Подпрограмма (layer: language, profile: es2024)**
- **Блок (layer: language, profile: es2024)** — let/const имеют область блока; var — область функции либо скрипта.
- **Модуль (layer: language, profile: es2024)**
- **Класс (layer: language, profile: es2024)** — Именование класса и приватные имена; обычное поле не становится лексической переменной метода.

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

англ. *Top-level bindings* (также *global variables*, *file scope*, *namespace scope*) · [в онтологии](concepts.md#scope-globals)

- **Глобальные переменные (layer: language, profile: es2024)** — В Script глобальные var и глобальные лексические let/const представлены разными частями окружения.
- **Имена модуля (layer: language, profile: es2024)** — Имена верхнего уровня модуля не становятся свойствами глобального объекта.

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

англ. *Name shadowing* (также *name hiding*, *variable shadowing*) · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: es2024)** — Вложенное let может скрывать внешнее имя; повторное лексическое объявление в одной области запрещено.

### Типизация { #typing }

#### Проверка типов { #typing-checking }

англ. *Type checking* (также *static typing*, *dynamic typing*) · [в онтологии](concepts.md#typing-checking)

- **Динамическая (layer: language, profile: es2024)**

#### Аннотации типов { #typing-annotations }

англ. *Type annotations* (также *type declarations*, *type signatures*) · [в онтологии](concepts.md#typing-annotations)

- **Отсутствуют (layer: language, profile: es2024)** — Аннотации TypeScript не входят в ECMAScript 2024.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

англ. *Type conversions* (также *type coercion*, *type casting*) · [в онтологии](concepts.md#typing-conversions)

- **Неявные (layer: language, profile: es2024)** — Операторы применяют ToPrimitive/ToNumber/ToString/ToBoolean по своим правилам; смешанная арифметика Number и BigInt обычно вызывает TypeError.
- **Явные (layer: language, profile: es2024)** — Number, String, Boolean и BigInt выполняют преобразования значений. ([ECMA-262 2024, Type Conversion](https://262.ecma-international.org/15.0/#sec-type-conversion))

#### Совместимость типов { #typing-compatibility }

англ. *Type compatibility* (также *type equivalence*, *nominal typing*, *structural typing*, *duck typing*) · [в онтологии](concepts.md#typing-compatibility)

- **По доступным операциям во время выполнения (layer: language, profile: es2024)** — Пользовательские протоколы часто зависят от свойств и вызываемых методов; встроенные операции могут дополнительно проверять внутренние слоты и brand объекта.

#### Представление отсутствия значения { #typing-nullability }

англ. *Nullability* (также *null reference*, *option type*) · [в онтологии](concepts.md#typing-nullability)

- **Специальное значение (layer: language, profile: es2024)** — null и undefined — разные значения; большинство обращений к их свойствам вызывает TypeError.

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

англ. *Conditional selection* (также *selection statement*, *conditional expression*) · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: es2024)**
- **Условное выражение (layer: language, profile: es2024)** — if/else и ?: используют проверку истинности, а не требование значения типа Boolean.

#### Выбор по значению switch/case { #control-switch }

англ. *Switch statement* (также *case statement*, *multiway branch*) · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: es2024)** — Сравнение case использует строгое равенство; возможен fall-through.

#### Сопоставление с образцом { #control-pattern-matching }

англ. *Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **нет (layer: language, profile: es2024)** — Деструктуризация есть, но отдельной конструкции match в этой редакции нет.

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

англ. *Do-while loop* (также *post-test loop*) · [в онтологии](concepts.md#control-do-while)

- **да (layer: language, profile: es2024)**

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

англ. *Iteration* (также *loops*, *for loop*, *foreach loop*, *range-based for loop*) · [в онтологии](concepts.md#control-iteration)

- **Инициализация / условие / шаг (layer: language, profile: es2024)**
- **По последовательности или итератору (layer: language, profile: es2024)** — for-of обходит iterable; for-in перечисляет перечислимые строковые ключи, включая унаследованные.
- **Функции обхода (layer: standard_library, profile: es2024)** — Методы Array.prototype.map/filter/forEach.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

англ. *Function overloading* (также *overloading*, *operator overloading*) · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: es2024)** — Нет выбора перегрузки по статическим типам сигнатур; функция может сама анализировать аргументы.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

англ. *Parameter passing* (также *call by value*, *call by reference*, *call by sharing*) · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: es2024, applies_to: значения аргументов)** — Присваивание параметру не изменяет переменную вызывающего.
- **Разделение объекта (layer: language, profile: es2024, applies_to: объектные значения)** — Вызывающий и параметр могут обозначать один объект; изменение его свойств наблюдаемо с обеих сторон. ([ECMA-262 2024, FunctionDeclarationInstantiation](https://262.ecma-international.org/15.0/#sec-functiondeclarationinstantiation))

#### Вложенные именованные подпрограммы { #subprograms-nesting }

англ. *Nested functions* (также *nested subprograms*) · [в онтологии](concepts.md#subprograms-nesting)

- **да (layer: language, profile: es2024)**

#### Захват окружения { #subprograms-closures }

англ. *Closures* (также *lambda capture*, *captured variables*) · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: es2024)** — Функция сохраняет лексическое окружение; стрелочная функция также использует лексический this. ([ECMA-262 2024, OrdinaryFunctionCreate](https://262.ecma-international.org/15.0/#sec-ordinaryfunctioncreate))

#### Анонимные функции { #subprograms-lambda }

англ. *Anonymous functions* (также *lambda expressions*, *function literals*) · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: es2024)** — Function expressions и arrow functions.

#### Аргументы по умолчанию { #subprograms-default-args }

англ. *Default arguments* (также *optional parameters*) · [в онтологии](concepts.md#subprograms-default-args)

- **да (layer: language, profile: es2024)** — Инициализатор параметра вычисляется при вызове, если аргумент отсутствует или равен undefined.

### Полиморфизм и организация { #abstraction }

#### Наследование реализации { #abstraction-inheritance }

англ. *Implementation inheritance* (также *inheritance*, *subclassing*, *derived classes*) · [в онтологии](concepts.md#abstraction-inheritance)

- **Одиночное (layer: language, profile: es2024)** — Обычный объект имеет одну цепочку [[Prototype]]; class extends использует прототипное наследование.

#### Модульность { #abstraction-modules }

англ. *Modules* (также *module system*, *namespaces*, *packages*) · [в онтологии](concepts.md#abstraction-modules)

- **Явная граница экспорта (layer: language, profile: es2024)** — import/export и live bindings; разрешение спецификатора модуля и его загрузка зависят от хоста.

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

англ. *Evaluation strategy* (также *eager evaluation*, *lazy evaluation*) · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: es2024)** — Обычные аргументы вычисляются слева направо перед вызовом; генераторы откладывают выполнение тела, а не произвольных аргументов.

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

англ. *Tail-call elimination* (также *proper tail calls*, *tail-call optimization*) · [в онтологии](concepts.md#evaluation-tail-calls)

- **да (layer: language, profile: strict)** — Спецификация требует proper tail calls для определённых хвостовых позиций; это не утверждение о поддержке всеми движками. ([ECMA-262 2024, Tail Position Calls](https://262.ecma-international.org/15.0/#sec-tail-position-calls))
- **нет (layer: language, profile: sloppy)** — Нестрогий код не получает этой гарантии спецификации.

### Память и владение { #memory }

#### Передача и разделение владения { #memory-transfer }

англ. *Ownership transfer and sharing* (также *move semantics*, *copy semantics*, *borrowing*) · [в онтологии](concepts.md#memory-transfer)

- **Разделяемая ссылка на объект (layer: language, profile: es2024, applies_to: объекты)** — Присваивание не копирует граф объекта.

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

англ. *Error handling* (также *exceptions*, *result types*, *error codes*) · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: language, profile: es2024)** — throw принимает любое значение; try/catch перехватывает исключительное завершение.

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

англ. *Resource cleanup* (также *RAII*, *deterministic destruction*, *finally*, *defer*) · [в онтологии](concepts.md#resources-cleanup)

- **Блок finally / unwind-protect (layer: language, profile: es2024)** — try/finally выполняет очистку при обычном и исключительном выходе; возврат или throw из finally может заменить исходный результат.

#### Конкурентное выполнение { #resources-concurrency }

англ. *Concurrency* (также *threads*, *async/await*, *actors*) · [в онтологии](concepts.md#resources-concurrency)

- **Асинхронные корутины (layer: language, profile: es2024)** — async/await и Promise координируют асинхронные вычисления; источники событий, I/O и запуск workers задаёт хост. ([ECMA-262 2024, Async Function Definitions](https://262.ecma-international.org/15.0/#sec-async-function-definitions))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

англ. *Syntactic grouping boundaries* (также *block delimiters*, *compound statement*, *off-side rule*) · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: es2024)**

#### Границы операторов и определений { #syntax-statement-terminator }

англ. *Statement terminators* (также *statement separators*, *automatic semicolon insertion*) · [в онтологии](concepts.md#syntax-statement-terminator)

- **Необязательная точка с запятой (layer: language, profile: es2024)** — Automatic Semicolon Insertion действует по формальным правилам; перенос строки не всегда эквивалентен точке с запятой.

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

англ. *Programming paradigms* (также *supported paradigms*) · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: es2024)**
- **Объектно-ориентированная (layer: language, profile: es2024)**
- **Функциональная (layer: language, profile: es2024)**
