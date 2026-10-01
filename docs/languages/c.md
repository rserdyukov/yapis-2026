---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# C

C17 — процедурный язык со статическими типами, адресуемыми объектами и явным управлением динамической памятью. Базовая среда — hosted C17; расширения отдельных компиляторов не включены.

*Карточка сравнительная: 44/85 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1972 — [Wikidata P571](https://www.wikidata.org/wiki/Q15777) (получено 2026-09-24) |
| Авторы | [Деннис Ритчи](people.md#ritchie) |
| Организации | Bell Labs |
| Сайт | <https://www.open-std.org/jtc1/sc22/wg14/> |
| Спецификация | <https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf> |
| Внешние каталоги | [Wikidata Q15777](https://www.wikidata.org/wiki/Q15777) |

## Люди { #people }

- [Деннис Ритчи](people.md#ritchie) — Создатель языка C и соавтор операционной системы Unix в Bell Labs.

## Публикации { #publications }

- Деннис Ритчи. *The Development of the C Language*. HOPL II, 1993. DOI: [10.1145/154766.155580](https://doi.org/10.1145/154766.155580). История C от BCPL и B; объяснение модели указателей и массивов. ([в источниках](sources.md#hopl-c))
- [cppreference.com — справочник по языкам C и C++](https://cppreference.com/). Вики-справочник по ядру языков и стандартным библиотекам C и C++ с пометками версий стандарта (C11, C++20 и т. д.). Нормативным текстом не является: спорные утверждения сверяйте с проектами стандартов WG14/WG21. Названия страниц — устоявшиеся английские термины; ссылки на конкретные страницы даны у понятий в словаре и на карточках C и C++. ([в источниках](sources.md#cppreference))
- Ричард Гэбриел. [The Rise of "Worse is Better"](https://www.dreamsongs.com/RiseOfWorseIsBetter.html). 1991. Эссе о компромиссе между простотой реализации и корректностью интерфейса на примере C/Unix и Lisp; материал для обсуждения критериев оценки языков. ([в источниках](sources.md#gabriel-worse-is-better))
- Rui Pereira, Marco Couto, Francisco Ribeiro, Rui Rua, Jácome Cunha, João Paulo Fernandes, João Saraiva. [Energy Efficiency across Programming Languages: How Do Energy, Time, and Memory Relate?](https://greenlab.di.uminho.pt/wp-content/uploads/2017/10/sleFinal.pdf). SLE 2017, 2017. DOI: [10.1145/3136014.3136031](https://doi.org/10.1145/3136014.3136031). Измерения энергии, времени и памяти для 27 языков на задачах Benchmarks Game — материал к критерию «стоимость»; обсуждайте вместе с ограничениями методики. ([в источниках](sources.md#pereira-energy-2017))
- Terence Kelly. [Schrödinger's Code: Undefined Behavior in Theory and Practice](https://queue.acm.org/detail.cfm?id=3468263). ACM Queue 19(2), 2021. DOI: [10.1145/3466132.3468263](https://doi.org/10.1145/3466132.3468263). Что такое неопределённое поведение в C и C++, откуда распространённые заблуждения и как оптимизатор использует UB. ([в источниках](sources.md#kelly-ub-2021))
- Ralf Jung. [Undefined Behavior deserves a better reputation](https://blog.sigplan.org/2021/11/18/undefined-behavior-deserves-a-better-reputation/). SIGPLAN Blog, 2021. UB как контракт между программистом и оптимизатором — взгляд исследователя семантики Rust; дополняет статью Kelly. ([в источниках](sources.md#jung-ub-2021))
- Frederick J. Ross. [The seven programming ur-languages](https://madhadron.com/programming/seven_ur_languages.html). 2022. Семь семейств-«праязыков» (ALGOL, Lisp, ML, Self, Forth, APL, Prolog) с характерными приёмами мышления — рамка для каталога языков. ([в источниках](sources.md#ross-ur-languages))
- Theia Vogel. [Writing a C compiler in 500 lines of Python](https://vgel.me/posts/c500/). 2023. Однопроходный компилятор подмножества C в WebAssembly (WAT) на Python — компактный образец для ЛР 5. Есть перевод на Хабре (habr.com/ru/companies/cloud4y/articles/760400). ([в источниках](sources.md#vogel-c500))
- Xavier Leroy. [Formal Verification of a Realistic Compiler](https://compcert.org/). Communications of the ACM 52(7), 2009. DOI: [10.1145/1538788.1538814](https://doi.org/10.1145/1538788.1538814). Компилятор C CompCert с машинно проверенным доказательством того, что код сохраняет семантику исходной программы; цепочка промежуточных языков с формальной семантикой у каждого. ([в источниках](sources.md#leroy-compcert-2009))
- Chucky Ellison, Grigore Roşu. *An Executable Formal Semantics of C with Applications*. POPL '12, 2012. DOI: [10.1145/2103656.2103719](https://doi.org/10.1145/2103656.2103719). Исполняемая формальная семантика C в K-framework; находит неопределённое поведение, которое пропускают компиляторы. ([в источниках](sources.md#ellison-rosu-c-2012))
- [GNU Compiler Collection Internals](https://gcc.gnu.org/onlinedocs/gccint/). Конвейер GCC: GENERIC, GIMPLE и SSA, RTL, описания машин в .md-файлах, DSL match.pd для упрощения выражений, распределители IRA и LRA. ([в источниках](sources.md#gcc-internals))
- [Clang Internals Manual](https://clang.llvm.org/docs/InternalsManual.html). Рукописный лексер и парсер рекурсивного спуска, Sema, строящая AST во время разбора, CodeGen в LLVM IR, диагностики на TableGen. ([в источниках](sources.md#clang-internals))
- [GNU Bison](https://www.gnu.org/software/bison/). Наследник yacc: LALR(1), IELR(1), канонический LR(1) и GLR, семантические действия на C, C++, Java и D, восстановление токеном error. ([в источниках](sources.md#bison))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **c17** — ISO/IEC 9899:2018 (C17), hosted-реализация; все записи относятся к этому базовому профилю. Источник — проект WG14 N2176.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

англ. *Binding introduction* (также *declaration*, *name binding*) · [в онтологии](concepts.md#bindings-introduction)

Справочник: [cppreference.com](sources.md#cppreference): [Declarations](https://cppreference.com/c/language/declarations)

- **Явное объявление (layer: language, profile: c17)** — Объекты и функции объявляются; C17 не допускает implicit int.

#### Изменяемость связывания { #bindings-mutation }

англ. *Binding mutability* (также *rebinding*, *immutable binding*, *const qualification*) · [в онтологии](concepts.md#bindings-mutation)

Справочник: [cppreference.com](sources.md#cppreference): [const type qualifier](https://cppreference.com/c/language/const)

- **Перепривязываемое (layer: language, profile: c17)** — Присваивание меняет значение объекта, обозначенного именем; имя не меняет объявленный тип.
- **Неизменяемое (layer: language, profile: c17, applies_to: объекты с const-квалифицированным типом)** — const ограничивает изменение объекта; const-указатель и указатель на const — разные типы.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

англ. *Assignment and binding forms* (также *assignment*, *destructuring*, *unification*) · [в онтологии](concepts.md#bindings-assignment)

Справочник: [cppreference.com](sources.md#cppreference): [Assignment operators](https://cppreference.com/c/language/operator_assignment)

- **Одиночное присваивание (layer: language, profile: c17)** — Левая часть — модифицируемое lvalue; цепочка присваиваний состоит из отдельных выражений.

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

англ. *Name resolution* (также *name lookup*, *lexical scoping*, *dynamic scoping*) · [в онтологии](concepts.md#scope-resolution)

Справочник: [cppreference.com](sources.md#cppreference): [Lookup and name spaces](https://cppreference.com/c/language/name_space)

- **Лексическое (layer: language, profile: c17)**

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

англ. *Scoping constructs* (также *scope*, *block scope*) · [в онтологии](concepts.md#scope-constructs)

Справочник: [cppreference.com](sources.md#cppreference): [Scope](https://cppreference.com/c/language/scope)

- **Блок (layer: language, profile: c17)**
- **Подпрограмма (layer: language, profile: c17, applies_to: метки функции)** — Область функции в терминологии C относится к меткам; параметры определения находятся в области блока.

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

англ. *Top-level bindings* (также *global variables*, *file scope*, *namespace scope*) · [в онтологии](concepts.md#scope-globals)

Справочник: [cppreference.com](sources.md#cppreference): [External and tentative definitions](https://cppreference.com/c/language/extern)

- **Глобальные переменные (layer: language, profile: c17)** — Файловая область видимости; external/internal linkage определяет связь имён между единицами трансляции.

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

англ. *Name shadowing* (также *name hiding*, *variable shadowing*) · [в онтологии](concepts.md#scope-shadowing)

Справочник: [cppreference.com](sources.md#cppreference): [Scope](https://cppreference.com/c/language/scope)

- **Во вложенной области (layer: language, profile: c17)** — Объявление во вложенном блоке может скрыть внешнее.

#### Связывание имён между единицами трансляции { #scope-linkage }

англ. *Linkage* (также *external linkage*, *internal linkage*, *one definition rule*) · [в онтологии](concepts.md#scope-linkage)

Справочник: [cppreference.com](sources.md#cppreference): [Storage-class specifiers: linkage](https://cppreference.com/c/language/storage_duration#Linkage)

- **Внешнее связывание (layer: language, profile: c17)** — Имена функций и объектов файловой области без static; одно определение на программу.
- **Внутреннее связывание единицы трансляции (layer: language, profile: c17)** — static на уровне файла ограничивает связывание единицей трансляции.
- **Без связывания (layer: language, profile: c17)** — Локальные переменные без extern, параметры, typedef и теги. ([WG14 N2176, §6.2.2 Linkages of identifiers](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

### Типизация { #typing }

#### Проверка типов { #typing-checking }

англ. *Type checking* (также *static typing*, *dynamic typing*) · [в онтологии](concepts.md#typing-checking)

Справочник: [cppreference.com](sources.md#cppreference): [Type](https://cppreference.com/c/language/type)

- **Статическая (layer: language, profile: c17)** — Статические ограничения типов не исключают неопределённого поведения при выполнении.

#### Аннотации типов { #typing-annotations }

англ. *Type annotations* (также *type declarations*, *type signatures*) · [в онтологии](concepts.md#typing-annotations)

- **Обязательны (layer: language, profile: c17)** — Спецификаторы типа входят в объявления объектов, параметров и функций.

#### Вывод статических типов { #typing-inference }

англ. *Type inference* (также *type deduction*) · [в онтологии](concepts.md#typing-inference)

- **нет (layer: language, profile: c17)** — Нет вывода типа объявления из инициализатора; auto в C17 — спецификатор класса хранения. Типы выражений определяются статически.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

англ. *Type conversions* (также *type coercion*, *type casting*) · [в онтологии](concepts.md#typing-conversions)

Справочник: [cppreference.com](sources.md#cppreference): [Implicit conversions](https://cppreference.com/c/language/conversion); [cast operator](https://cppreference.com/c/language/cast)

- **Неявные (layer: language, profile: c17)** — Целочисленные продвижения, обычные арифметические преобразования и преобразования при присваивании могут менять диапазон и точность. ([WG14 N2176, §6.3 Conversions](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))
- **Явные (layer: language, profile: c17)** — Cast явно задаёт преобразование; не делает произвольное преобразование указателя или последующее обращение безопасным.

#### Типы-произведения { #typing-product-types }

англ. *Product types* (также *tuples*, *records*, *structs*) · [в онтологии](concepts.md#typing-product-types)

Справочник: [cppreference.com](sources.md#cppreference): [Struct declaration](https://cppreference.com/c/language/struct)

- **Записи и структуры (layer: language, profile: c17)** — struct объединяет именованные поля; union использует перекрывающееся хранение и не содержит встроенной метки варианта.

#### Представление отсутствия значения { #typing-nullability }

англ. *Nullability* (также *null reference*, *option type*) · [в онтологии](concepts.md#typing-nullability)

- **Специальное значение (layer: language, profile: c17)** — Null pointer обозначает отсутствие адресуемого объекта или функции; разыменование недопустимо. NULL — макрос стандартной библиотеки.

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

англ. *Conditional selection* (также *selection statement*, *conditional expression*) · [в онтологии](concepts.md#control-selection)

Справочник: [cppreference.com](sources.md#cppreference): [if statement](https://cppreference.com/c/language/if); [Other operators (conditional operator)](https://cppreference.com/c/language/operator_other)

- **Условный оператор (layer: language, profile: c17)** — if/else; скалярное условие сравнивается с нулём.
- **Условное выражение (layer: language, profile: c17)** — Условный оператор ?: вычисляет только выбранный операнд.

#### Выбор по значению switch/case { #control-switch }

англ. *Switch statement* (также *case statement*, *multiway branch*) · [в онтологии](concepts.md#control-switch)

Справочник: [cppreference.com](sources.md#cppreference): [switch statement](https://cppreference.com/c/language/switch)

- **да (layer: language, profile: c17)** — switch по целочисленному значению; переход к следующей ветви возможен без break.

#### Сопоставление с образцом { #control-pattern-matching }

англ. *Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **нет (layer: language, profile: c17)**

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

англ. *Do-while loop* (также *post-test loop*) · [в онтологии](concepts.md#control-do-while)

Справочник: [cppreference.com](sources.md#cppreference): [do-while loop](https://cppreference.com/c/language/do)

- **да (layer: language, profile: c17)**

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

англ. *Iteration* (также *loops*, *for loop*, *foreach loop*, *range-based for loop*) · [в онтологии](concepts.md#control-iteration)

Справочник: [cppreference.com](sources.md#cppreference): [for loop](https://cppreference.com/c/language/for)

- **Инициализация / условие / шаг (layer: language, profile: c17)** — for; также есть while и do-while.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

англ. *Function overloading* (также *overloading*, *operator overloading*) · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: c17)** — Функции не перегружаются по типам параметров. _Generic выбирает выражение по типу, но не создаёт перегруженные функции.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

англ. *Parameter passing* (также *call by value*, *call by reference*, *call by sharing*) · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: c17)** — Параметр получает значение аргумента. Указатель также копируется по значению; через него можно менять объект вызывающего. Массив в объявлении параметра корректируется до указателя. ([WG14 N2176, §6.5.2.2 Function calls; §6.7.6.3 Function declarators](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

<a id="variants-9"></a>

#### Место определения подпрограмм { #subprograms-placement }

англ. *Subprogram definition placement* (также *top-level function*, *member function*, *local function*) · [в онтологии](concepts.md#subprograms-placement)

Справочник: [cppreference.com](sources.md#cppreference): [Function definitions](https://cppreference.com/c/language/function_definition)

- **Выделенная область объявлений (layer: language, profile: c17)** — Определения функций находятся на внешнем уровне единицы трансляции; объявить прототип можно и в блоке.

#### Вложенные именованные подпрограммы { #subprograms-nesting }

англ. *Nested functions* (также *nested subprograms*) · [в онтологии](concepts.md#subprograms-nesting)

Справочник: [cppreference.com](sources.md#cppreference): [Function definitions](https://cppreference.com/c/language/function_definition)

- **нет (layer: language, profile: c17)** — Вложенные определения функций — расширение, например GNU C, а не C17. ([WG14 N2176, §6.9 External definitions](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

#### Захват окружения { #subprograms-closures }

англ. *Closures* (также *lambda capture*, *captured variables*) · [в онтологии](concepts.md#subprograms-closures)

- **нет (layer: language, profile: c17)** — Указатель на функцию не захватывает локальное окружение; контекст callback передают отдельно.

#### Анонимные функции { #subprograms-lambda }

англ. *Anonymous functions* (также *lambda expressions*, *function literals*) · [в онтологии](concepts.md#subprograms-lambda)

- **нет (layer: language, profile: c17)**

#### Разрешение перегрузки { #subprograms-overload-resolution }

англ. *Overload resolution* (также *best viable function*, *argument-dependent lookup*) · [в онтологии](concepts.md#subprograms-overload-resolution)

Справочник: [cppreference.com](sources.md#cppreference): [Generic selection](https://cppreference.com/c/language/generic)

- **неприменимо (n/a) (layer: language, profile: c17)** — Перегрузки функций нет. _Generic (C11) выбирает ассоциацию по совместимости типа управляющего выражения, без ранжирования преобразований; это выбор выражения, а не функции. ([WG14 N2176, §6.5.1.1 Generic selection](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

### Полиморфизм и организация { #abstraction }

#### Модульность { #abstraction-modules }

англ. *Modules* (также *module system*, *namespaces*, *packages*) · [в онтологии](concepts.md#abstraction-modules)

Справочник: [cppreference.com](sources.md#cppreference): [Source file inclusion](https://cppreference.com/c/preprocessor/include)

- **Текстовое включение (layer: language, profile: c17)** — #include текстуально включает заголовок; единицы трансляции связываются посредством linkage.

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

англ. *Evaluation strategy* (также *eager evaluation*, *lazy evaluation*) · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: c17)** — Аргументы вычисляются перед входом в функцию; порядок вычисления разных аргументов не задан. ([WG14 N2176, §6.5.2.2 Function calls](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

#### Порядок вычисления подвыражений { #evaluation-order }

англ. *Order of evaluation* (также *sequencing*, *sequence points*, *sequenced-before*) · [в онтологии](concepts.md#evaluation-order)

Справочник: [cppreference.com](sources.md#cppreference): [Order of evaluation](https://cppreference.com/c/language/eval_order)

- **Не задан стандартом (layer: language, profile: c17)** — Порядок вычисления операндов и аргументов вызова не задан; непоследовательные побочные эффекты над одним объектом — неопределённое поведение.
- **Задан для отдельных операций (layer: language, profile: c17)** — Точки следования есть у &&, ||, ?:, запятой и перед вызовом функции. ([WG14 N2176, §5.1.2.3 Program execution; §6.5 Expressions](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

#### Неопределённое поведение { #evaluation-undefined-behavior }

англ. *Undefined behavior* (также *UB*, *unspecified behavior*, *implementation-defined behavior*) · [в онтологии](concepts.md#evaluation-undefined-behavior)

Справочник: [cppreference.com](sources.md#cppreference): [Undefined behavior](https://cppreference.com/c/language/behavior)

- **Неопределённое поведение (layer: language, profile: c17)** — Например, переполнение знакового целого, выход за границы массива, разыменование нулевого указателя.
- **Неуточнённое поведение (layer: language, profile: c17)**
- **Определяемое реализацией (layer: language, profile: c17)** — Например, размер int и знаковость char; реализация обязана документировать выбор. ([WG14 N2176, §3.4 Behavior; Annex J](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

#### Вычисления во время компиляции { #evaluation-compile-time }

англ. *Constant evaluation* (также *compile-time evaluation*, *constant expressions*, *constexpr*) · [в онтологии](concepts.md#evaluation-compile-time)

Справочник: [cppreference.com](sources.md#cppreference): [Constant expressions](https://cppreference.com/c/language/constant_expression)

- **Константные выражения из ограниченного набора операций (layer: language, profile: c17)** — Целочисленные и арифметические константные выражения без вызовов функций; нужны для размеров массивов, case и статических инициализаторов. constexpr-объекты появились только в C23. ([WG14 N2176, §6.6 Constant expressions](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

англ. *Memory management* (также *memory reclamation*, *garbage collection*, *reference counting*) · [в онтологии](concepts.md#memory-management)

Справочник: [cppreference.com](sources.md#cppreference): [Dynamic memory management](https://cppreference.com/c/memory)

- **Ручное (layer: standard_library, profile: c17, applies_to: динамически выделенная память)** — malloc/calloc/realloc и free; автоматические объекты имеют время жизни, определяемое областью выполнения, и не требуют free. ([WG14 N2176, §6.2.4 Storage durations; §7.22.3 Memory management](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

#### Передача и разделение владения { #memory-transfer }

англ. *Ownership transfer and sharing* (также *move semantics*, *copy semantics*, *borrowing*) · [в онтологии](concepts.md#memory-transfer)

- **Копирование значения (layer: language, profile: c17)** — Присваивание структур и указателей копирует значение; копия указателя не передаёт и не проверяет владение выделенной памятью.

#### Длительность хранения и время жизни объекта { #memory-storage-duration }

англ. *Storage duration* (также *object lifetime*, *automatic storage*, *static storage*, *dynamic storage*) · [в онтологии](concepts.md#memory-storage-duration)

Справочник: [cppreference.com](sources.md#cppreference): [Storage-class specifiers](https://cppreference.com/c/language/storage_duration); [Lifetime](https://cppreference.com/c/language/lifetime)

- **Автоматическая (layer: language, profile: c17)**
- **Статическая (layer: language, profile: c17)**
- **Поточная (layer: language, profile: c17)** — _Thread_local, C11.
- **Динамическая (layer: standard_library, profile: c17)** — В терминах стандарта — allocated storage duration: malloc/free. ([WG14 N2176, §6.2.4 Storage durations of objects](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

#### Категории значений выражений { #memory-value-categories }

англ. *Value categories* (также *lvalue*, *rvalue*, *glvalue*, *prvalue*, *xvalue*) · [в онтологии](concepts.md#memory-value-categories)

Справочник: [cppreference.com](sources.md#cppreference): [Value categories](https://cppreference.com/c/language/value_category)

- **Два вида — lvalue и rvalue (layer: language, profile: c17)** — Стандарт определяет lvalue и указатель функции; остальные выражения — просто значения (rvalue в неформальном смысле). ([WG14 N2176, §6.3.2.1 Lvalues, arrays, and function designators](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

#### Модель памяти для параллельного доступа { #memory-concurrency-model }

англ. *Memory model* (также *data race*, *happens-before*, *memory ordering*, *atomics*) · [в онтологии](concepts.md#memory-concurrency-model)

Справочник: [cppreference.com](sources.md#cppreference): [Memory model](https://cppreference.com/c/language/memory_model); [memory_order](https://cppreference.com/c/atomic/memory_order)

- **Гонка данных — неопределённое поведение (layer: language, profile: c17)**
- **Явно выбираемое упорядочивание атомарных операций (layer: language, profile: c17, applies_to: _Atomic и stdatomic.h)** — memory_order_relaxed/acquire/release/seq_cst; volatile не синхронизирует потоки. ([WG14 N2176, §5.1.2.4 Multi-threaded executions and data races; §7.17 Atomics](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

англ. *Error handling* (также *exceptions*, *result types*, *error codes*) · [в онтологии](concepts.md#errors-model)

Справочник: [cppreference.com](sources.md#cppreference): [Error handling](https://cppreference.com/c/error)

- **Код ошибки (layer: standard_library, profile: c17)** — Библиотечные функции используют возвращаемые коды, специальные значения и в определённых случаях errno. Проверка ошибок возложена на вызывающего. ([WG14 N2176, §7.5 Errors; §7.21 Input/output](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

англ. *Resource cleanup* (также *RAII*, *deterministic destruction*, *finally*, *defer*) · [в онтологии](concepts.md#resources-cleanup)

- **Явное освобождение (layer: language, profile: c17)** — free и fclose вызываются явно. longjmp не запускает автоматическую очистку пользовательских ресурсов.

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

англ. *Input/output* (также *I/O library*) · [в онтологии](concepts.md#resources-io)

Справочник: [cppreference.com](sources.md#cppreference): [File input/output](https://cppreference.com/c/io)

- **API стандартной библиотеки (layer: standard_library, profile: c17)** — stdio.h задаёт потоки FILE и операции ввода-вывода; наличие всего hosted API не требуется от freestanding-реализации. ([WG14 N2176, §7.21 Input/output](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

англ. *Syntactic grouping boundaries* (также *block delimiters*, *compound statement*, *off-side rule*) · [в онтологии](concepts.md#syntax-blocks)

Справочник: [cppreference.com](sources.md#cppreference): [Statements](https://cppreference.com/c/language/statements)

- **Явные разделители (layer: language, profile: c17)** — Составные операторы ограничены фигурными скобками.

#### Метапрограммирование { #syntax-metaprogramming }

англ. *Metaprogramming* (также *macros*, *reflection*, *compile-time evaluation*) · [в онтологии](concepts.md#syntax-metaprogramming)

Справочник: [cppreference.com](sources.md#cppreference): [Replacing text macros](https://cppreference.com/c/preprocessor/replace)

- **Текстовые макросы (layer: language, profile: c17)** — Препроцессор заменяет последовательности preprocessing tokens; макросы не имеют лексической гигиены.

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

англ. *Programming paradigms* (также *supported paradigms*) · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: c17)**
- **Процедурная (layer: language, profile: c17)**

### Инструменты построения языковых процессоров { #tooling }

#### Способ построения синтаксического анализатора { #tooling-parser-construction }

англ. *Parser construction* (также *parser generator*, *compiler-compiler*, *hand-written parser*, *parser combinators*) · [в онтологии](concepts.md#tooling-parser-construction)

- **Рукописный анализатор (layer: implementation, profile: c17, implementation: GCC 4.1+)** — Bison-парсер C и Objective-C заменён рукописным рекурсивным спуском в GCC 4.1; у Clang парсер тоже рукописный. ([GCC 4.1 Release Series — Changes](https://gcc.gnu.org/gcc-4.1/changes.html); [Clang — Features and Goals](https://clang.llvm.org/features.html))

#### Алгоритм синтаксического анализа { #tooling-parsing-algorithm }

англ. *Parsing algorithm* (также *LL(k)*, *ALL(*)*, *LALR(1)*, *GLR*, *Earley*, *PEG*, *packrat*) · [в онтологии](concepts.md#tooling-parsing-algorithm)

- **Нисходящий LL(k) и рекурсивный спуск (layer: implementation, profile: c17, implementation: GCC 4.1+, Clang)** — Рукописный рекурсивный спуск; контекстная зависимость typedef-имён решается обратной связью от таблицы символов к лексеру. ([Clang — Features and Goals](https://clang.llvm.org/features.html))
