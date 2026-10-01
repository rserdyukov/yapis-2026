---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Haskell

Haskell 2010 — нестрогий чисто функциональный язык со статическими полиморфными типами, алгебраическими данными и классами типов. Вычисление по необходимости, сборщик памяти и дополнительные библиотеки GHC выделены в слой реализации, а не приписаны нормативной семантике языка.

*Карточка сравнительная: 37/85 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1990 — [Wikidata P571](https://www.wikidata.org/wiki/Q34010) (получено 2026-09-24) |
| Авторы | [Пол Худак](people.md#hudak), [Джон Хьюз](people.md#hughes), [Саймон Пейтон-Джонс](people.md#peyton-jones), [Филип Уодлер](people.md#wadler) |
| Организации | Haskell Committee |
| Сайт | <https://www.haskell.org/> |
| Спецификация | <https://www.haskell.org/onlinereport/haskell2010/> |
| Внешние каталоги | [Wikidata Q34010](https://www.wikidata.org/wiki/Q34010) |

## Люди { #people }

- [Пол Худак](people.md#hudak) — Один из редакторов первого отчёта о языке Haskell.
- [Саймон Пейтон-Джонс](people.md#peyton-jones) — Участник комитета Haskell и один из ведущих разработчиков компилятора GHC.
- [Филип Уодлер](people.md#wadler) — Участник комитета Haskell; вместе со Стивеном Блоттом предложил классы типов.
- [Джон Хьюз](people.md#hughes) — Участник комитета Haskell, автор статьи «Why Functional Programming Matters».

## Публикации { #publications }

- Филип Уодлер, Stephen Blott. *How to Make Ad-hoc Polymorphism Less Ad Hoc*. POPL '89, 1989. DOI: [10.1145/75277.75283](https://doi.org/10.1145/75277.75283). Статья, в которой предложены классы типов Haskell. ([в источниках](sources.md#wadler-blott-1989))
- Пол Худак, Джон Хьюз, Саймон Пейтон-Джонс, Филип Уодлер. *A History of Haskell — Being Lazy with Class*. HOPL III, 2007. DOI: [10.1145/1238844.1238856](https://doi.org/10.1145/1238844.1238856). Решения комитета Haskell о нестрогости, классах типов и монадическом вводе-выводе. ([в источниках](sources.md#hopl-haskell))
- Джон Хьюз. *Why Functional Programming Matters*. The Computer Journal 32(2), 1989. DOI: [10.1093/comjnl/32.2.98](https://doi.org/10.1093/comjnl/32.2.98). Почему функции высшего порядка и ленивые вычисления улучшают модульность программ. ([в источниках](sources.md#hughes-why-fp))
- Peter J. Landin. [The Next 700 Programming Languages](https://www.cs.cmu.edu/~crary/819-f09/Landin66.pdf). Communications of the ACM 9(3), 1966. DOI: [10.1145/365230.365257](https://doi.org/10.1145/365230.365257). Язык как общее ядро плюс предметная часть и синтаксический сахар; семейство ISWIM и правило отступов, повлиявшие на ML, Haskell и Python. ([в источниках](sources.md#landin-1966))
- Rui Pereira, Marco Couto, Francisco Ribeiro, Rui Rua, Jácome Cunha, João Paulo Fernandes, João Saraiva. [Energy Efficiency across Programming Languages: How Do Energy, Time, and Memory Relate?](https://greenlab.di.uminho.pt/wp-content/uploads/2017/10/sleFinal.pdf). SLE 2017, 2017. DOI: [10.1145/3136014.3136031](https://doi.org/10.1145/3136014.3136031). Измерения энергии, времени и памяти для 27 языков на задачах Benchmarks Game — материал к критерию «стоимость»; обсуждайте вместе с ограничениями методики. ([в источниках](sources.md#pereira-energy-2017))
- Frederick J. Ross. [The seven programming ur-languages](https://madhadron.com/programming/seven_ur_languages.html). 2022. Семь семейств-«праязыков» (ALGOL, Lisp, ML, Self, Forth, APL, Prolog) с характерными приёмами мышления — рамка для каталога языков. ([в источниках](sources.md#ross-ur-languages))
- Tristan Hume. [Comparing the Same Project in Rust, Haskell, C++, Python, Scala and OCaml](https://thume.ca/2019/04/29/comparing-compilers-in-rust-haskell-c-and-python/). 2019. Один и тот же учебный компилятор, написанный командами на шести языках: объём кода, генераторы парсеров, представление AST. К выбору языка и архитектуры в ЛР. ([в источниках](sources.md#hume-comparing-compilers))
- Саймон Пейтон-Джонс, Simon Marlow. [The Glasgow Haskell Compiler](https://aosabook.org/en/v2/ghc.html). The Architecture of Open Source Applications, Vol. 2, 2012. Архитектура промышленного компилятора от его авторов: фазы, промежуточный язык Core, оптимизации и рантайм. ([в источниках](sources.md#aosa-ghc))
- Graham Hutton, Erik Meijer. [Monadic Parsing in Haskell](https://people.cs.nott.ac.uk/pszgmh/pearl.pdf). Journal of Functional Programming 8(4), 1998. DOI: [10.1017/S0956796898003050](https://doi.org/10.1017/S0956796898003050). Короткое введение в парсер-комбинаторы: анализатор как функция, из которой операторами собираются большие анализаторы. ([в источниках](sources.md#hutton-meijer-1998))
- [Megaparsec](https://hackage.haskell.org/package/megaparsec). Промышленная библиотека монадических парсер-комбинаторов для Haskell с восстановлением после ошибок. ([в источниках](sources.md#megaparsec))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **haskell2010** — Haskell 2010 Language Report; базовый профиль языка и его стандартных библиотек, без расширений GHC.
- **ghc** — GHC с базовым языковым режимом Haskell2010 и библиотекой base; свойства реализации отмечены отдельно. Конкретный выпуск и latest не заявляются.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

англ. *Binding introduction* (также *declaration*, *name binding*) · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: haskell2010)** — Имена вводятся определениями и параметрами; сигнатура типа — отдельное, часто необязательное объявление.
- **Связывание образцом (layer: language, profile: haskell2010)** — Образцы связывают переменные в уравнениях функций, case, let и генераторах списков. ([Haskell 2010, Declarations and Bindings](https://www.haskell.org/onlinereport/haskell2010/haskellch4.html))

#### Изменяемость связывания { #bindings-mutation }

англ. *Binding mutability* (также *rebinding*, *immutable binding*, *const qualification*) · [в онтологии](concepts.md#bindings-mutation)

- **Неизменяемое (layer: language, profile: haskell2010)** — Связывания неизменяемы. Повторное имя во внутренней области создаёт новое связывание, а IORef изменяет содержимое ячейки через IO, не перепривязывая чистую переменную. ([Haskell 2010, Let Expressions and Pattern Matching](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); [GHC base: Data.IORef (reference snapshot)](https://hackage.haskell.org/package/base-4.19.1.0/docs/Data-IORef.html))

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

англ. *Assignment and binding forms* (также *assignment*, *destructuring*, *unification*) · [в онтологии](concepts.md#bindings-assignment)

- **Неизменяемое определение (layer: language, profile: haskell2010)** — Знак = вводит уравнение определения; <- в do связывает результат монадического действия. Ни то ни другое не является обычным изменяемым присваиванием.

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

англ. *Name resolution* (также *name lookup*, *lexical scoping*, *dynamic scoping*) · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: haskell2010)**

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

англ. *Scoping constructs* (также *scope*, *block scope*) · [в онтологии](concepts.md#scope-constructs)

- **Модуль (layer: language, profile: haskell2010)**
- **Форма связывания let/where (layer: language, profile: haskell2010)** — let и where задают лексические, в общем случае взаимно рекурсивные связывания.
- **Генераторная конструкция (layer: language, profile: haskell2010)**
- **Подпрограмма (layer: language, profile: haskell2010, applies_to: параметры и образцы уравнений функций)**

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

англ. *Top-level bindings* (также *global variables*, *file scope*, *namespace scope*) · [в онтологии](concepts.md#scope-globals)

- **Имена модуля (layer: language, profile: haskell2010)** — Определения модуля неизменяемы; экспорт управляет видимостью для импортирующих модулей.

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

англ. *Name shadowing* (также *name hiding*, *variable shadowing*) · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: haskell2010)** — Вложенные связывания могут скрывать внешние; повторные уравнения функции описывают одно определение, а не мутацию имени.

### Типизация { #typing }

#### Проверка типов { #typing-checking }

англ. *Type checking* (также *static typing*, *dynamic typing*) · [в онтологии](concepts.md#typing-checking)

- **Статическая (layer: language, profile: haskell2010)** — Выражения проверяются до выполнения; полиморфизм и ограничения классов типов входят в статическую систему. ([Haskell 2010, Overview of Types and Classes](https://www.haskell.org/onlinereport/haskell2010/haskellch4.html))

#### Аннотации типов { #typing-annotations }

англ. *Type annotations* (также *type declarations*, *type signatures*) · [в онтологии](concepts.md#typing-annotations)

- **Необязательны (layer: language, profile: haskell2010)** — Сигнатуры функций часто выводятся; объявления data/newtype и классов задают структуру типов явно.

#### Вывод статических типов { #typing-inference }

англ. *Type inference* (также *type deduction*) · [в онтологии](concepts.md#typing-inference)

- **да (layer: language, profile: haskell2010)** — Вывод полиморфных типов с ограничениями классов; monomorphism restriction и defaulting влияют на итоговый тип. ([Haskell 2010, Static Semantics of Function and Pattern Bindings](https://www.haskell.org/onlinereport/haskell2010/haskellch4.html))

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

англ. *Type conversions* (также *type coercion*, *type casting*) · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: haskell2010)** — fromIntegral, realToFrac и другие функции меняют числовое представление. Перегруженные литералы и defaulting не означают общего неявного приведения уже типизированных числовых значений. ([Haskell 2010, Numbers and Numeric Conversions](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html))

#### Совместимость типов { #typing-compatibility }

англ. *Type compatibility* (также *type equivalence*, *nominal typing*, *structural typing*, *duck typing*) · [в онтологии](concepts.md#typing-compatibility)

- **Номинальная (layer: language, profile: haskell2010, applies_to: объявленные data/newtype)** — Одинаковый набор полей не делает независимо объявленные типы совместимыми; type вводит синоним, newtype — отдельный тип.

#### Типы-суммы { #typing-sum-types }

англ. *Sum types* (также *tagged unions*, *variant types*, *discriminated unions*) · [в онтологии](concepts.md#typing-sum-types)

- **Размеченные варианты (layer: language, profile: haskell2010)** — data может объявить несколько конструкторов; образцы различают альтернативы. ([Haskell 2010, Algebraic Datatype Declarations](https://www.haskell.org/onlinereport/haskell2010/haskellch4.html))

#### Типы-произведения { #typing-product-types }

англ. *Product types* (также *tuples*, *records*, *structs*) · [в онтологии](concepts.md#typing-product-types)

- **Кортежи (layer: language, profile: haskell2010)**
- **Записи и структуры (layer: language, profile: haskell2010)** — Кортежи и конструкторы с несколькими полями, в том числе именованными; record update создаёт новое значение.

#### Представление отсутствия значения { #typing-nullability }

англ. *Nullability* (также *null reference*, *option type*) · [в онтологии](concepts.md#typing-nullability)

- **Тип Option/Optional (layer: standard_library, profile: haskell2010)** — Maybe a различает Nothing и Just. undefined/bottom может встретиться в любом типе, но означает ошибку или расходимость вычисления, а не обычное отсутствие значения. ([Haskell 2010, The Maybe Type](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html); [Haskell 2010, §3.1 Errors](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

англ. *Conditional selection* (также *selection statement*, *conditional expression*) · [в онтологии](concepts.md#control-selection)

- **Условное выражение (layer: language, profile: haskell2010)** — if/then/else возвращает значение; обе ветви имеют один тип.
- **Охранные условия (layer: language, profile: haskell2010)** — Охранные условия в уравнениях функций и альтернативах case.

#### Выбор по значению switch/case { #control-switch }

англ. *Switch statement* (также *case statement*, *multiway branch*) · [в онтологии](concepts.md#control-switch)

- **нет (layer: language, profile: haskell2010)** — case — сопоставление с образцом; отдельного switch только по значению нет.

#### Сопоставление с образцом { #control-pattern-matching }

англ. *Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **да (layer: language, profile: haskell2010)** — Сопоставление по конструкторам, литералам и структуре; оно может потребовать вычисления значения, а ленивые образцы откладывают эту проверку. ([Haskell 2010, §3.17 Pattern Matching](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html))

<a id="req-7-2-until"></a>

#### Цикл до истинности условия { #control-until }

англ. *Until loop* (также *repeat-until loop*) · [в онтологии](concepts.md#control-until)

- **Отдельная конструкция отсутствует (layer: language, profile: haskell2010)** — Prelude.until — функция высшего порядка, а не отдельная синтаксическая конструкция цикла.

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

англ. *Iteration* (также *loops*, *for loop*, *foreach loop*, *range-based for loop*) · [в онтологии](concepts.md#control-iteration)

- **Генераторная конструкция (layer: language, profile: haskell2010)** — Генераторы списков; ключевого слова for и обычного императивного цикла в Haskell 2010 нет.
- **Функции обхода (layer: standard_library, profile: haskell2010)** — map, foldr и mapM/sequence выражают обходы; рекурсия — общий механизм повторения.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

англ. *Function overloading* (также *overloading*, *operator overloading*) · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: haskell2010, applies_to: перегрузка отдельных функций по сигнатурам)** — Одно имя функции не образует Java-подобный набор перегрузок. Ad-hoc полиморфизм операций выражается классами типов и экземплярами.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

англ. *Parameter passing* (также *call by value*, *call by reference*, *call by sharing*) · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По необходимости с мемоизацией (layer: implementation, profile: ghc, implementation: GHC)** — Обычный механизм — разделяемые отложенные вычисления с обновлением thunk после вычисления. Анализ строгости может вычислить аргумент заранее, сохраняя семантику; Report требует нестрогость, а не конкретное представление thunk. ([GHC Commentary: Heap Objects (thunks and indirections)](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/rts/storage/heap-objects))

#### Вложенные именованные подпрограммы { #subprograms-nesting }

англ. *Nested functions* (также *nested subprograms*) · [в онтологии](concepts.md#subprograms-nesting)

- **да (layer: language, profile: haskell2010)** — Локальные именованные функции в let/where.

#### Захват окружения { #subprograms-closures }

англ. *Closures* (также *lambda capture*, *captured variables*) · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: haskell2010)** — Функции первого класса захватывают лексические связывания; частичное применение создаёт функции с оставшимися параметрами.

#### Анонимные функции { #subprograms-lambda }

англ. *Anonymous functions* (также *lambda expressions*, *function literals*) · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: haskell2010)**

#### Параметрический полиморфизм { #subprograms-generics }

англ. *Parametric polymorphism* (также *generics*, *templates*) · [в онтологии](concepts.md#subprograms-generics)

- **да (layer: language, profile: haskell2010)** — Параметрический полиморфизм функций и типов данных; ограничения классов добавляют доступные операции.

### Полиморфизм и организация { #abstraction }

#### Контракты полиморфизма { #abstraction-contracts }

англ. *Polymorphic contracts* (также *interfaces*, *traits*, *type classes*, *protocols*) · [в онтологии](concepts.md#abstraction-contracts)

- **Классы типов (layer: language, profile: haskell2010)** — class объявляет набор операций, instance — реализацию для типов. Это не класс объектов и не наследование реализации через CLOS/Java-классы. ([Haskell 2010, Type Classes and Overloading](https://www.haskell.org/onlinereport/haskell2010/haskellch4.html))

#### Модульность { #abstraction-modules }

англ. *Modules* (также *module system*, *namespaces*, *packages*) · [в онтологии](concepts.md#abstraction-modules)

- **Явная граница экспорта (layer: language, profile: haskell2010)** — module/import, списки экспорта и квалифицированный импорт; при отсутствии списка экспорта действуют стандартные правила экспорта локальных определений. ([Haskell 2010, Modules](https://www.haskell.org/onlinereport/haskell2010/haskellch5.html))

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

англ. *Evaluation strategy* (также *eager evaluation*, *lazy evaluation*) · [в онтологии](concepts.md#evaluation-strategy)

- **Нестрогая (layer: language, profile: haskell2010)** — Результат может не зависеть от вычисления аргумента. seq и строгие поля позволяют требовать вычисление; нестрогость не равна обещанию мемоизировать каждый вызов функции. ([Haskell 2010, §6.2 Strict Evaluation](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html))

#### Контроль эффектов { #evaluation-effects }

англ. *Effect control* (также *effect system*, *purity*) · [в онтологии](concepts.md#evaluation-effects)

- **Эффекты отражены в типах (layer: language, profile: haskell2010)** — Действия ввода-вывода имеют тип IO a; do — синтаксис монадического связывания, а не разрешение произвольной мутации чистых переменных. ([Haskell 2010, Basic Input/Output](https://www.haskell.org/onlinereport/haskell2010/haskellch7.html))

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

англ. *Memory management* (также *memory reclamation*, *garbage collection*, *reference counting*) · [в онтологии](concepts.md#memory-management)

- **Трассирующая сборка мусора (layer: implementation, profile: ghc, implementation: GHC)** — Среда выполнения управляет кучей и сборкой мусора; конкретный алгоритм и настройки — свойства GHC, а не Report. ([GHC User's Guide: RTS control and garbage collection (reference snapshot)](https://downloads.haskell.org/ghc/9.8.2/docs/users_guide/runtime_control.html))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

англ. *Error handling* (также *exceptions*, *result types*, *error codes*) · [в онтологии](concepts.md#errors-model)

- **Размеченный результат (layer: standard_library, profile: haskell2010)** — Either e a позволяет явно возвращать ошибку как данные; обработка выражается сопоставлением или функциями.
- **Исключения (layer: standard_library, profile: haskell2010, applies_to: ошибки IO)** — Report задаёт IOError и catch/ioError для IO. Ошибки чистых выражений описаны как bottom, а не как универсально перехватываемые исключения. ([Haskell 2010, Exception Handling in the I/O Monad](https://www.haskell.org/onlinereport/haskell2010/haskellch7.html))
- **Исключения (layer: implementation, profile: ghc, implementation: GHC / base, applies_to: Control.Exception)** — Расширяет модель типизированными синхронными и асинхронными исключениями; bracket/finally — библиотечные комбинаторы очистки, не конструкции синтаксиса Haskell 2010. ([GHC base: Control.Exception (reference snapshot)](https://hackage.haskell.org/package/base-4.19.1.0/docs/Control-Exception.html))

### Ресурсы и взаимодействие { #resources }

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

англ. *Input/output* (также *I/O library*) · [в онтологии](concepts.md#resources-io)

- **API стандартной библиотеки (layer: standard_library, profile: haskell2010)** — Prelude и System.IO предоставляют действия чтения, записи и работы с потоками; чистое выражение не выполняет I/O само по себе.

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

англ. *Syntactic grouping boundaries* (также *block delimiters*, *compound statement*, *off-side rule*) · [в онтологии](concepts.md#syntax-blocks)

- **Значимые отступы (layer: language, profile: haskell2010)** — Layout rule вставляет границы групп объявлений и do/case по отступам.
- **Явные разделители (layer: language, profile: haskell2010)** — Те же группы могут использовать явные фигурные скобки и точки с запятой; синтаксис смешанный, а не только отступы. ([Haskell 2010, §2.7 Layout](https://www.haskell.org/onlinereport/haskell2010/haskellch2.html))

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

англ. *Programming paradigms* (также *supported paradigms*) · [в онтологии](concepts.md#paradigm-supported)

- **Функциональная (layer: language, profile: haskell2010)**
- **Декларативная (layer: language, profile: haskell2010)**

### Инструменты построения языковых процессоров { #tooling }

#### Способ построения синтаксического анализатора { #tooling-parser-construction }

англ. *Parser construction* (также *parser generator*, *compiler-compiler*, *hand-written parser*, *parser combinators*) · [в онтологии](concepts.md#tooling-parser-construction)

- **Генератор по грамматике (layer: implementation, profile: haskell2010, implementation: GHC)** — Парсер GHC генерируется Happy — LALR-генератором для Haskell — из GHC/Parser.y. ([Happy User Guide — Introduction](https://haskell-happy.readthedocs.io/en/latest/introduction.html))

#### Алгоритм синтаксического анализа { #tooling-parsing-algorithm }

англ. *Parsing algorithm* (также *LL(k)*, *ALL(*)*, *LALR(1)*, *GLR*, *Earley*, *PEG*, *packrat*) · [в онтологии](concepts.md#tooling-parsing-algorithm)

- **Восходящий LR(1) / LALR(1) / IELR(1) (layer: implementation, profile: haskell2010, implementation: GHC)** — LALR(1)-таблицы Happy; правило отступов (layout) обрабатывается лексером и специальным правилом восстановления.
