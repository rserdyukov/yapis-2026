---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Smalltalk

Smalltalk — объектно-ориентированный язык, в котором любое значение является объектом, а любое вычисление — посылкой сообщения: даже условия и циклы выражаются сообщениями к логическим значениям и блокам-замыканиям. Программа живёт в образе (image) вместе со средой разработки, классы и метаклассы доступны для рефлексии и изменения во время работы. Основа — Smalltalk-80 по книге Goldberg и Robson (Blue Book, 1983); исключения ANSI-стиля, трейты и пакеты отмечены как свойства реализации Pharo.

*Карточка сравнительная: 38/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1972 — [Wikidata P571](https://www.wikidata.org/wiki/Q235086) (получено 2026-09-25) |
| Авторы | [Алан Кэй](people.md#kay), [Адель Голдберг](people.md#goldberg), [Дэн Ингаллс](people.md#ingalls) |
| Организации | Xerox PARC |
| Сайт | <https://pharo.org/> |
| Спецификация | <http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf> |
| Внешние каталоги | [Wikidata Q235086](https://www.wikidata.org/wiki/Q235086) |

## Статьи { #articles }

- [Smalltalk: всё есть сообщение](../garden/smalltalk-messages.md)

## Люди { #people }

- [Алан Кэй](people.md#kay) — Руководитель группы Xerox PARC, создавшей Smalltalk; ввёл термин «объектно-ориентированное программирование».
- [Адель Голдберг](people.md#goldberg) — Соразработчик Smalltalk-80 и соавтор его описания «Smalltalk-80: The Language and its Implementation».
- [Дэн Ингаллс](people.md#ingalls) — Главный реализатор виртуальных машин Smalltalk в Xerox PARC и соавтор Squeak.

## Публикации { #publications }

- Алан Кэй. *The Early History of Smalltalk*. HOPL II, 1993. DOI: [10.1145/155360.155364](https://doi.org/10.1145/155360.155364). Кэй о происхождении идеи «всё — объект, вычисление — посылка сообщения». ([в источниках](sources.md#hopl-smalltalk))
- Дэн Ингаллс. *The Evolution of Smalltalk: from Smalltalk-72 through Squeak*. Proc. ACM Program. Lang. 4, HOPL IV, 2020. DOI: [10.1145/3386335](https://doi.org/10.1145/3386335). Эволюция реализации Smalltalk — от интерпретатора сообщений до живой системы с образом. ([в источниках](sources.md#hopl-smalltalk-squeak))
- Адель Голдберг, David Robson. [Smalltalk-80: The Language and its Implementation](http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf). Addison-Wesley, 1983. «Синяя книга» — описание языка Smalltalk-80 и его виртуальной машины. ([в источниках](sources.md#smalltalk-80-blue-book))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **st80** — Smalltalk-80 по книге A. Goldberg, D. Robson «Smalltalk-80: The Language and its Implementation» (1983, Blue Book): синтаксис, классы ядра и виртуальная машина. Стандарт ANSI INCITS 319-1998 не используется — он недоступен открыто.
- **pharo** — Pharo — современная реализация, производная от Squeak, по книге «Pharo by Example 9» и Pharo wiki; слой реализации, выпуск не фиксируется.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: st80)** — Временные переменные объявляются между вертикальными чертами `| a b |` в начале метода или блока; параметры блока — `[:x | …]`, переменные экземпляра — в определении класса. ([Pharo by Example 9 — Local variable definitions](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/SyntaxNutshell/SyntaxNutshell.md))

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: st80)** — Переменной можно присвоить другой объект; аргументы метода и блока, а также псевдопеременные `self`, `super`, `nil`, `true`, `false`, `thisContext` присваиванию не подлежат.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: st80)** — Присваивание `x := expr` — выражение, возвращающее присвоенный объект; в Blue Book записывается стрелкой `←`. Распаковки при присваивании нет.

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: st80)** — Временные переменные и параметры видны во вложенных блоках по тексту; переменные экземпляра видны в методах класса и подклассов; имена с прописной буквы ищутся среди переменных класса, pool-словарей и глобалов.

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Подпрограмма (layer: language, profile: st80, applies_to: метод)**
- **Блок (layer: language, profile: st80)** — Блок `[ … ]` может объявлять собственные временные переменные и параметры.
- **Класс (layer: language, profile: st80)** — Переменные экземпляра и переменные класса доступны только методам класса (и подклассов); извне состояние объекта доступно только через сообщения.

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

*Top-level bindings* · [в онтологии](concepts.md#scope-globals)

- **Глобальные переменные (layer: language, profile: st80)** — Глобальные переменные, включая имена классов, хранятся в системном словаре `Smalltalk` — едином плоском пространстве имён образа. ([Goldberg, Robson — Smalltalk-80: global variables and the Smalltalk dictionary](http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf))

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Динамическая (layer: language, profile: st80)** — Переменные не имеют типов; пригодность объекта выясняется при посылке сообщения. Непонятое сообщение — не ошибка компиляции, а `doesNotUnderstand:` во время выполнения. ([Goldberg, Robson — Smalltalk-80, Part One](http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf))

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Отсутствуют (layer: language, profile: st80)** — Объявления `| a b |` вводят имена без типов; классы аргументов подсказывают только соглашения об именах вида `aNumber`.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Неявные (layer: language, profile: st80, applies_to: арифметика чисел)** — Операции над разными числовыми классами приводят операнды к более общему (generality/coercion), а `SmallInteger` при переполнении автоматически становится `LargePositiveInteger`/`LargeNegativeInteger`. ([Goldberg, Robson — Smalltalk-80, Ch. 8 Numerical Classes: coercion and generality](http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf); [Pharo by Example 9 — Basic classes: automatic Integer conversion](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/BasicClasses/BasicClasses.md))
- **Явные (layer: language, profile: st80, applies_to: сообщения as…)** — Прочие преобразования — обычные сообщения: `asString`, `asInteger`, `asFloat`, `asSet`, `asOrderedCollection`.

#### Совместимость типов { #typing-compatibility }

*Type compatibility* · [в онтологии](concepts.md#typing-compatibility)

- **По доступным операциям во время выполнения (layer: language, profile: st80)** — Любой объект, отвечающий на нужные селекторы, пригоден независимо от места в иерархии классов.

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Nullable-ссылки по умолчанию (layer: language, profile: st80)** — Любая переменная может ссылаться на `nil` — единственный экземпляр `UndefinedObject`; переменные по умолчанию инициализируются `nil`. Посылка `nil` сообщения, которого он не понимает, приводит к `doesNotUnderstand:`. ([Pharo by Example 9 — Syntax in a nutshell: pseudo-variables](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/SyntaxNutshell/SyntaxNutshell.md))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условное выражение (layer: language, profile: st80)** — `cond ifTrue: [ … ] ifFalse: [ … ]` — сообщение объекту `true` или `false`, возвращающее значение выбранного блока. Особой синтаксической конструкции нет; компилятор лишь встраивает эти сообщения ради скорости. ([Pharo by Example 9 — Conditionals and loops](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/SyntaxNutshell/SyntaxNutshell.md))

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **нет (layer: language, profile: st80)** — Конструкции switch/case нет; выбор по значению пишут цепочкой `ifTrue:ifFalse:`, словарём блоков или полиморфной посылкой сообщения.

<a id="req-7-2-until"></a>

#### Цикл до истинности условия { #control-until }

*Until loop* · [в онтологии](concepts.md#control-until)

- **Проверка перед телом (layer: language, profile: st80, applies_to: [ cond ] whileFalse: [ body ])** — `whileFalse:` — сообщение блоку-условию: условие вычисляется перед каждым выполнением тела. Постусловие выражают унарным `[ body. cond ] whileFalse`, где тело входит в сам блок-получатель. ([Pharo by Example 9 — Loops: whileTrue:, whileFalse:](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/SyntaxNutshell/SyntaxNutshell.md))

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **Функции обхода (layer: language, profile: st80)** — `do:`, `collect:`, `select:`, `inject:into:` посылаются коллекции, `to:do:` и `timesRepeat:` — числу, `whileTrue:` — блоку; тело цикла всегда передаётся как блок. ([Pharo by Example 9 — Conditionals and loops](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/SyntaxNutshell/SyntaxNutshell.md); [Pharo by Example 9 — Collections: iterators](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/Collections/Collections.md))

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: st80)** — Метод идентифицируется селектором; два метода одного класса с одним селектором невозможны. `at:` и `at:put:` — разные селекторы, а не перегрузка по числу или типам аргументов.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **Разделение объекта (layer: language, profile: st80)** — Аргумент — ссылка на объект: изменение состояния объекта видно вызывающему, присваивание параметру запрещено.

<a id="variants-9"></a>

#### Место определения подпрограмм { #subprograms-placement }

*Subprogram definition placement* · [в онтологии](concepts.md#subprograms-placement)

- **Член типа (layer: language, profile: st80)** — Метод принадлежит классу (или метаклассу — «методы класса»); свободных функций нет, роль функций играют блоки.

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: st80)** — Блоки захватывают переменные охватывающего метода и `self`. `^` внутри блока выполняет нелокальный возврат из метода, где блок создан. ([Pharo by Example 9 — Block syntax: lexical closures and ^](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/SyntaxNutshell/SyntaxNutshell.md))
- **да (layer: implementation, profile: pharo, implementation: Pharo)** — Реализация использует настоящие замыкания `BlockClosure` с собственными временными переменными; в Smalltalk-80 из Blue Book блоки (`BlockContext`) разделяли временные переменные с методом и не были полностью реентерабельными.

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: st80)** — Блок `[:x | x + 2]` — объект `BlockClosure`, вызываемый сообщением `value:`.

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **нет (layer: language, profile: st80)** — Ключевые сообщения вида `raisedTo: 6 modulo: 10` вплетают части имени в перечисление аргументов, но ключевые слова — часть селектора: порядок фиксирован, пропуск или перестановка дают другой селектор.

### Полиморфизм и организация { #abstraction }

#### Контракты полиморфизма { #abstraction-contracts }

*Polymorphic contracts* · [в онтологии](concepts.md#abstraction-contracts)

- **Трейты (layer: implementation, profile: pharo, implementation: Pharo)** — Трейт — набор методов (в Pharo также переменных экземпляра), композируемый в класс с явным разрешением конфликтов; служит повторному использованию поведения, а не статической проверке соответствия. В Smalltalk-80 протоколы — лишь категории методов в браузере. ([Pharo wiki — Traits](https://github.com/pharo-open-documentation/pharo-wiki/blob/master/General/Traits.md))

#### Диспетчеризация вызовов { #abstraction-dispatch }

*Call dispatch* · [в онтологии](concepts.md#abstraction-dispatch)

- **По одному динамическому типу (layer: language, profile: st80)** — Метод ищется по селектору в классе получателя и далее по цепочке суперклассов во время выполнения; классы аргументов на выбор не влияют. При неудаче поиска получателю посылается `doesNotUnderstand:`. ([Pharo by Example 9 — Understanding message syntax](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/UnderstandingMessage/UnderstandingMessage.md); [Pharo by Example 9 — The Pharo object model: method lookup](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/PharoObjectModel/PharoObjectModel.md))

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Одиночное (layer: language, profile: st80)** — У каждого класса ровно один суперкласс; `super` начинает поиск метода с суперкласса класса, где определён текущий метод. У каждого класса есть метакласс, параллельная иерархия которых повторяет иерархию классов. ([Pharo by Example 9 — single inheritance hierarchy rooted at ProtoObject](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/PharoObjectModel/PharoObjectModel.md); [Pharo by Example 9 — Classes and metaclasses](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/Metaclasses/Metaclasses.md))

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: st80)** — Получатель и аргументы вычисляются до посылки сообщения; отложенное вычисление явно выражается блоком (`and:`, `ifTrue:` принимают блоки).

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · [в онтологии](concepts.md#evaluation-tail-calls)

- **нет (layer: language, profile: st80)** — Ни Blue Book, ни Pharo не гарантируют устранение хвостовых вызовов: каждый вызов создаёт контекст, видимый через `thisContext`.

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Подсчёт ссылок (layer: implementation, profile: st80, implementation: Blue Book virtual machine)** — Спецификация памяти объектов в части IV Blue Book описывает подсчёт ссылок (циклы требуют дополнительной маркировки); сам язык способ освобождения не предписывает. ([Goldberg, Robson — Smalltalk-80, Part Four: Object Memory](http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf))
- **Трассирующая сборка мусора (layer: implementation, profile: pharo, implementation: Pharo VM)** — Виртуальная машина автоматически освобождает недостижимые объекты трассирующим сборщиком; явного освобождения нет.

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: implementation, profile: pharo, implementation: Pharo)** — `[ … ] on: ZeroDivide do: [:ex | … ]` перехватывает исключение по классу; `signal` его возбуждает. Механизм следует ANSI Smalltalk; в Blue Book его нет — ошибки там сводятся к `error:` и `doesNotUnderstand:`, открывающим отладчик. ([Pharo wiki — Exceptions](https://github.com/pharo-open-documentation/pharo-wiki/blob/master/General/Exceptions.md))
- **Условия и перезапуски (layer: implementation, profile: pharo, implementation: Pharo)** — Обработчик выполняется до раскрутки стека: он может `resume:` — продолжить выполнение после `signal` с заданным значением, `retry` — повторить защищённый блок, `return:`, `pass` или `outer`. Именованных перезапусков, как в Common Lisp, нет. ([Pharo wiki — Exceptions: retry, resume, pass, outer](https://github.com/pharo-open-documentation/pharo-wiki/blob/master/General/Exceptions.md))

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Блок finally / unwind-protect (layer: implementation, profile: pharo, implementation: Pharo)** — `aBlock ensure: [ … ]` выполняет второй блок при любом выходе, `ifCurtailed:` — только при аварийном. Это сообщения блоку, а не синтаксис. ([Pharo wiki — Exceptions: ensure and ifCurtailed](https://github.com/pharo-open-documentation/pharo-wiki/blob/master/General/Exceptions.md))

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

*I/O interface* · [в онтологии](concepts.md#resources-io)

- **API стандартной библиотеки (layer: language, profile: st80)** — Ввод-вывод — сообщения объектам классов потоков и `Transcript`; в языке нет операторов ввода-вывода.

#### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · [в онтологии](concepts.md#resources-concurrency)

- **Потоки (layer: language, profile: st80)** — `[ … ] fork` создаёт `Process` — лёгкий процесс внутри одной виртуальной машины с планированием по приоритетам; синхронизация — `Semaphore`. Процессы разделяют память образа. ([Goldberg, Robson — Smalltalk-80, Ch. 15 Multiple Independent Processes](http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: st80)** — Квадратные скобки ограничивают блок, круглые — группируют выражения; тело метода ограничено средой браузера или форматом файла, а не ключевыми словами.

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Точка в конце клаузы (layer: language, profile: st80)** — Точка разделяет (а не завершает) выражения метода или блока; `;` образует каскад сообщений тому же получателю. ([Pharo by Example 9 — Sequences and cascades](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/SyntaxNutshell/SyntaxNutshell.md))

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да (layer: language, profile: st80)** — Регистр значим; по соглашению имена глобалов и классов начинаются с прописной буквы, временных переменных и селекторов — со строчной.

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Рефлексия (layer: language, profile: st80)** — Классы, методы, метаклассы и стек исполнения (`thisContext`) — объекты, доступные для чтения и изменения из программы; сами средства разработки написаны на Smalltalk. ([Pharo by Example 9 — Reflection](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/Reflection/Reflection.md); [Pharo — A simple reflective object kernel](https://books.pharo.org/booklet-ReflectiveCore/))
- **Построение и выполнение кода (layer: language, profile: st80)** — Компилятор — объект образа: методы компилируются и добавляются в классы во время работы, классы создаются сообщением суперклассу. ([Pharo by Example 9 — Reflection](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/Reflection/Reflection.md))

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Объектно-ориентированная (layer: language, profile: st80)** — Числа, классы, блоки и контексты исполнения — объекты; вычисление — посылка сообщения получателю, который сам выбирает метод. ([Goldberg, Robson — Smalltalk-80, Part One: objects and messages](http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf))
- **Императивная (layer: language, profile: st80)** — Методы — последовательности выражений с присваиванием переменным и изменением состояния объектов.

### Семантика данных { #data }

#### Кратность элементов коллекции { #data-collection-multiplicity }

*Collection multiplicity* · [в онтологии](concepts.md#data-collection-multiplicity)

- **Множество без дубликатов (layer: standard_library, profile: st80, applies_to: Set)**
- **Мультимножество с кратностями (layer: standard_library, profile: st80, applies_to: Bag)** — `Bag` хранит число вхождений элемента (`occurrencesOf:`).
- **Последовательность позиционных вхождений (layer: standard_library, profile: st80, applies_to: Array, OrderedCollection, SortedCollection)** ([Pharo by Example 9 — Collections: sequenceable vs Set, Bag, Dictionary](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/Collections/Collections.md))

#### Ограничение числовой точности { #data-numeric-precision }

*Numeric precision bound* · [в онтологии](concepts.md#data-numeric-precision)

- **Нефиксированная заранее разрядность (layer: language, profile: st80, applies_to: Integer, Fraction)** — Целые не переполняются: `100 factorial` вычисляется точно благодаря автоматическому переходу к `LargePositiveInteger`. ([Pharo by Example 9 — Basic classes: SmallInteger and LargePositiveInteger](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/BasicClasses/BasicClasses.md))
- **Фиксированная разрядность типа или поля (layer: language, profile: st80, applies_to: Float)**
