---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# C++

C++23 сочетает статическую типизацию, классы, шаблоны и управление временем жизни объектов через конструкторы и деструкторы. За основу взят проект стандарта N4950, без расширений компиляторов.

*Карточка сравнительная: 44/85 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1983 — [Wikidata P571](https://www.wikidata.org/wiki/Q2407) (получено 2026-09-24) |
| Авторы | [Бьёрн Страуструп](people.md#stroustrup) |
| Организации | Bell Labs |
| Сайт | <https://isocpp.org/> |
| Спецификация | <https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf> |
| Внешние каталоги | [Wikidata Q2407](https://www.wikidata.org/wiki/Q2407) |

## Люди { #people }

- [Бьёрн Страуструп](people.md#stroustrup) — Создатель C++; ввёл термин RAII — связывание освобождения ресурса со временем жизни объекта.

## Публикации { #publications }

- Бьёрн Страуструп. *Дизайн и эволюция C++*. Пер. с англ. М.: ДМК Пресс; СПб.: Питер, 2006. Как автор языка обосновывает конкретные проектные решения и компромиссы. ([в источниках](sources.md#stroustrup-de))
- Бьёрн Страуструп. *A History of C++*. HOPL II, 1993. DOI: [10.1145/154766.155375](https://doi.org/10.1145/154766.155375). Происхождение классов, перегрузки и шаблонов C++. ([в источниках](sources.md#hopl-cpp))
- [cppreference.com — справочник по языкам C и C++](https://cppreference.com/). Вики-справочник по ядру языков и стандартным библиотекам C и C++ с пометками версий стандарта (C11, C++20 и т. д.). Нормативным текстом не является: спорные утверждения сверяйте с проектами стандартов WG14/WG21. Названия страниц — устоявшиеся английские термины; ссылки на конкретные страницы даны у понятий в словаре и на карточках C и C++. ([в источниках](sources.md#cppreference))
- Rui Pereira, Marco Couto, Francisco Ribeiro, Rui Rua, Jácome Cunha, João Paulo Fernandes, João Saraiva. [Energy Efficiency across Programming Languages: How Do Energy, Time, and Memory Relate?](https://greenlab.di.uminho.pt/wp-content/uploads/2017/10/sleFinal.pdf). SLE 2017, 2017. DOI: [10.1145/3136014.3136031](https://doi.org/10.1145/3136014.3136031). Измерения энергии, времени и памяти для 27 языков на задачах Benchmarks Game — материал к критерию «стоимость»; обсуждайте вместе с ограничениями методики. ([в источниках](sources.md#pereira-energy-2017))
- Terence Kelly. [Schrödinger's Code: Undefined Behavior in Theory and Practice](https://queue.acm.org/detail.cfm?id=3468263). ACM Queue 19(2), 2021. DOI: [10.1145/3466132.3468263](https://doi.org/10.1145/3466132.3468263). Что такое неопределённое поведение в C и C++, откуда распространённые заблуждения и как оптимизатор использует UB. ([в источниках](sources.md#kelly-ub-2021))
- Ralf Jung. [Undefined Behavior deserves a better reputation](https://blog.sigplan.org/2021/11/18/undefined-behavior-deserves-a-better-reputation/). SIGPLAN Blog, 2021. UB как контракт между программистом и оптимизатором — взгляд исследователя семантики Rust; дополняет статью Kelly. ([в источниках](sources.md#jung-ub-2021))
- Russ Cox. [Programming Language Memory Models](https://research.swtch.com/plmm). 2021. Как Java, C++, JavaScript, Rust и Go определяют семантику разделяемой памяти и атомарных операций и почему это трудно. ([в источниках](sources.md#cox-memory-models))
- Tristan Hume. [Comparing the Same Project in Rust, Haskell, C++, Python, Scala and OCaml](https://thume.ca/2019/04/29/comparing-compilers-in-rust-haskell-c-and-python/). 2019. Один и тот же учебный компилятор, написанный командами на шести языках: объём кода, генераторы парсеров, представление AST. К выбору языка и архитектуры в ЛР. ([в источниках](sources.md#hume-comparing-compilers))
- [GNU Compiler Collection Internals](https://gcc.gnu.org/onlinedocs/gccint/). Конвейер GCC: GENERIC, GIMPLE и SSA, RTL, описания машин в .md-файлах, DSL match.pd для упрощения выражений, распределители IRA и LRA. ([в источниках](sources.md#gcc-internals))
- [Clang Internals Manual](https://clang.llvm.org/docs/InternalsManual.html). Рукописный лексер и парсер рекурсивного спуска, Sema, строящая AST во время разбора, CodeGen в LLVM IR, диагностики на TableGen. ([в источниках](sources.md#clang-internals))
- [GNU Bison](https://www.gnu.org/software/bison/). Наследник yacc: LALR(1), IELR(1), канонический LR(1) и GLR, семантические действия на C, C++, Java и D, восстановление токеном error. ([в источниках](sources.md#bison))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **cpp23** — C++23, проект WG21 N4950; базовый профиль всех записей, включая отдельно отмеченную стандартную библиотеку.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

англ. *Binding introduction* (также *declaration*, *name binding*) · [в онтологии](concepts.md#bindings-introduction)

Справочник: [cppreference.com](sources.md#cppreference): [Declarations](https://cppreference.com/cpp/language/declarations); [Structured binding declaration](https://cppreference.com/cpp/language/structured_binding)

- **Явное объявление (layer: language, profile: cpp23)**
- **Связывание образцом (layer: language, profile: cpp23)** — Structured bindings объявляют набор имён; это не произвольное сопоставление с образцом.

#### Изменяемость связывания { #bindings-mutation }

англ. *Binding mutability* (также *rebinding*, *immutable binding*, *const qualification*) · [в онтологии](concepts.md#bindings-mutation)

Справочник: [cppreference.com](sources.md#cppreference): [cv (const and volatile) type qualifiers](https://cppreference.com/cpp/language/cv)

- **Перепривязываемое (layer: language, profile: cpp23)** — Изменяемому объекту можно присвоить новое значение; reference после инициализации не переназначается на другой объект.
- **Неизменяемое (layer: language, profile: cpp23, applies_to: const-объекты)** — const не означает глубокую неизменяемость всего достижимого графа; mutable-члены имеют особые правила.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

англ. *Assignment and binding forms* (также *assignment*, *destructuring*, *unification*) · [в онтологии](concepts.md#bindings-assignment)

Справочник: [cppreference.com](sources.md#cppreference): [Assignment operators](https://cppreference.com/cpp/language/operator_assignment)

- **Одиночное присваивание (layer: language, profile: cpp23)** — operator= для классов может быть перегружен; structured binding — объявление, а не множественное присваивание.

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

англ. *Name resolution* (также *name lookup*, *lexical scoping*, *dynamic scoping*) · [в онтологии](concepts.md#scope-resolution)

Справочник: [cppreference.com](sources.md#cppreference): [Name lookup](https://cppreference.com/cpp/language/lookup)

- **Лексическое (layer: language, profile: cpp23)**

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

англ. *Scoping constructs* (также *scope*, *block scope*) · [в онтологии](concepts.md#scope-constructs)

Справочник: [cppreference.com](sources.md#cppreference): [Scope](https://cppreference.com/cpp/language/scope)

- **Блок (layer: language, profile: cpp23)**
- **Класс (layer: language, profile: cpp23)**

#### Связывание имён между единицами трансляции { #scope-linkage }

англ. *Linkage* (также *external linkage*, *internal linkage*, *one definition rule*) · [в онтологии](concepts.md#scope-linkage)

Справочник: [cppreference.com](sources.md#cppreference): [Storage class specifiers: linkage](https://cppreference.com/cpp/language/storage_duration#Linkage); [Definitions and ODR (One Definition Rule)](https://cppreference.com/cpp/language/definition)

- **Внешнее связывание (layer: language, profile: cpp23)**
- **Внутреннее связывание единицы трансляции (layer: language, profile: cpp23)** — static на уровне пространства имён, безымянное пространство имён, const-переменные пространства имён без extern.
- **Связывание в пределах модуля (layer: language, profile: cpp23)** — Имена, объявленные в модуле без export, связываются только внутри модуля (C++20).
- **Без связывания (layer: language, profile: cpp23)** ([N4950, [basic.link], [basic.def.odr]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

### Типизация { #typing }

#### Проверка типов { #typing-checking }

англ. *Type checking* (также *static typing*, *dynamic typing*) · [в онтологии](concepts.md#typing-checking)

Справочник: [cppreference.com](sources.md#cppreference): [Type](https://cppreference.com/cpp/language/type)

- **Статическая (layer: language, profile: cpp23)**

#### Аннотации типов { #typing-annotations }

англ. *Type annotations* (также *type declarations*, *type signatures*) · [в онтологии](concepts.md#typing-annotations)

- **Необязательны (layer: language, profile: cpp23, applies_to: объявления с auto и выводимыми типами)** — Явные типы по-прежнему нужны во многих сигнатурах; auto не отменяет объявления.

#### Вывод статических типов { #typing-inference }

англ. *Type inference* (также *type deduction*) · [в онтологии](concepts.md#typing-inference)

Справочник: [cppreference.com](sources.md#cppreference): [Placeholder type specifiers](https://cppreference.com/cpp/language/auto); [Template argument deduction](https://cppreference.com/cpp/language/template_argument_deduction); [Class template argument deduction (CTAD)](https://cppreference.com/cpp/language/class_template_argument_deduction)

- **да (layer: language, profile: cpp23)** — auto, вывод аргументов шаблона и class template argument deduction.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

англ. *Type conversions* (также *type coercion*, *type casting*) · [в онтологии](concepts.md#typing-conversions)

Справочник: [cppreference.com](sources.md#cppreference): [Implicit conversions](https://cppreference.com/cpp/language/implicit_conversion); [Explicit type conversion](https://cppreference.com/cpp/language/explicit_cast)

- **Неявные (layer: language, profile: cpp23)** — Стандартные и пользовательские преобразования участвуют в разрешении перегрузки; сужающие преобразования в list-initialization ограничены.
- **Явные (layer: language, profile: cpp23)** — Именованные cast имеют разные контракты; reinterpret_cast не обеспечивает безопасный доступ к произвольной памяти. ([N4950, [conv], [expr.cast], [dcl.init.list]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Совместимость типов { #typing-compatibility }

англ. *Type compatibility* (также *type equivalence*, *nominal typing*, *structural typing*, *duck typing*) · [в онтологии](concepts.md#typing-compatibility)

- **Номинальная (layer: language, profile: cpp23, applies_to: типы классов и перечислений)** — Совпадение набора полей не делает два независимо объявленных класса одним типом.

#### Типы-суммы { #typing-sum-types }

англ. *Sum types* (также *tagged unions*, *variant types*, *discriminated unions*) · [в онтологии](concepts.md#typing-sum-types)

Справочник: [cppreference.com](sources.md#cppreference): [std::variant](https://cppreference.com/cpp/utility/variant); [Union declaration](https://cppreference.com/cpp/language/union)

- **Размеченные варианты (layer: standard_library, profile: cpp23)** — std::variant хранит активную альтернативу. Встроенный union сам по себе не хранит метку.

#### Типы-произведения { #typing-product-types }

англ. *Product types* (также *tuples*, *records*, *structs*) · [в онтологии](concepts.md#typing-product-types)

Справочник: [cppreference.com](sources.md#cppreference): [Class declaration](https://cppreference.com/cpp/language/class); [std::tuple](https://cppreference.com/cpp/utility/tuple)

- **Записи и структуры (layer: language, profile: cpp23)** — struct/class с полями.
- **Кортежи (layer: standard_library, profile: cpp23)** — std::tuple и std::pair.

#### Представление отсутствия значения { #typing-nullability }

англ. *Nullability* (также *null reference*, *option type*) · [в онтологии](concepts.md#typing-nullability)

Справочник: [cppreference.com](sources.md#cppreference): [nullptr, the pointer literal](https://cppreference.com/cpp/language/nullptr); [std::optional](https://cppreference.com/cpp/utility/optional)

- **Специальное значение (layer: language, profile: cpp23)** — nullptr для указателей; корректно инициализированная ссылка должна обозначать объект или функцию.
- **Тип Option/Optional (layer: standard_library, profile: cpp23)** — `std::optional<T>` хранит значение либо состояние отсутствия.

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

англ. *Conditional selection* (также *selection statement*, *conditional expression*) · [в онтологии](concepts.md#control-selection)

Справочник: [cppreference.com](sources.md#cppreference): [if statement](https://cppreference.com/cpp/language/if); [Other operators (conditional operator)](https://cppreference.com/cpp/language/operator_other)

- **Условный оператор (layer: language, profile: cpp23)**
- **Условное выражение (layer: language, profile: cpp23)** — if и ?:; if constexpr выбирает ветвь при инстанцировании шаблона по правилам стандарта.

#### Выбор по значению switch/case { #control-switch }

англ. *Switch statement* (также *case statement*, *multiway branch*) · [в онтологии](concepts.md#control-switch)

Справочник: [cppreference.com](sources.md#cppreference): [switch statement](https://cppreference.com/cpp/language/switch)

- **да (layer: language, profile: cpp23)**

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

англ. *Iteration* (также *loops*, *for loop*, *foreach loop*, *range-based for loop*) · [в онтологии](concepts.md#control-iteration)

Справочник: [cppreference.com](sources.md#cppreference): [for loop](https://cppreference.com/cpp/language/for); [Range-based for loop](https://cppreference.com/cpp/language/range-for)

- **Инициализация / условие / шаг (layer: language, profile: cpp23)**
- **По последовательности или итератору (layer: language, profile: cpp23)** — Range-based for работает с диапазонами через begin/end.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

англ. *Function overloading* (также *overloading*, *operator overloading*) · [в онтологии](concepts.md#subprograms-overloading)

Справочник: [cppreference.com](sources.md#cppreference): [operator overloading](https://cppreference.com/cpp/language/operators)

- **да (layer: language, profile: cpp23)** — Свободные функции, методы и операторы; один лишь возвращаемый тип не различает перегрузки обычных функций.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

англ. *Parameter passing* (также *call by value*, *call by reference*, *call by sharing*) · [в онтологии](concepts.md#subprograms-parameter-passing)

Справочник: [cppreference.com](sources.md#cppreference): [Reference declaration](https://cppreference.com/cpp/language/reference)

- **По значению (layer: language, profile: cpp23)**
- **По ссылке на переменную (layer: language, profile: cpp23)** — Параметры T&, const T& и T&& связываются с объектом. Ссылки не обеспечивают проверку владения или исключительности, аналогичную Rust borrow checker. ([N4950, [dcl.ref], [dcl.init.ref], [expr.call]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Вложенные именованные подпрограммы { #subprograms-nesting }

англ. *Nested functions* (также *nested subprograms*) · [в онтологии](concepts.md#subprograms-nesting)

- **нет (layer: language, profile: cpp23)** — Определение свободной именованной функции внутри функции запрещено; локальные классы могут иметь методы, а лямбды — свои тела.

#### Захват окружения { #subprograms-closures }

англ. *Closures* (также *lambda capture*, *captured variables*) · [в онтологии](concepts.md#subprograms-closures)

Справочник: [cppreference.com](sources.md#cppreference): [Lambda expressions](https://cppreference.com/cpp/language/lambda)

- **да (layer: language, profile: cpp23)** — Лямбды захватывают по значению или по ссылке; захват по ссылке не продлевает автоматически время жизни объекта. ([N4950, [expr.prim.lambda]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Анонимные функции { #subprograms-lambda }

англ. *Anonymous functions* (также *lambda expressions*, *function literals*) · [в онтологии](concepts.md#subprograms-lambda)

Справочник: [cppreference.com](sources.md#cppreference): [Lambda expressions](https://cppreference.com/cpp/language/lambda)

- **да (layer: language, profile: cpp23)**

#### Параметрический полиморфизм { #subprograms-generics }

англ. *Parametric polymorphism* (также *generics*, *templates*) · [в онтологии](concepts.md#subprograms-generics)

Справочник: [cppreference.com](sources.md#cppreference): [Templates](https://cppreference.com/cpp/language/templates); [Constraints and concepts](https://cppreference.com/cpp/language/constraints)

- **да (layer: language, profile: cpp23)** — Шаблоны функций, классов и переменных; concepts ограничивают допустимые аргументы шаблонов.

#### Разрешение перегрузки { #subprograms-overload-resolution }

англ. *Overload resolution* (также *best viable function*, *argument-dependent lookup*) · [в онтологии](concepts.md#subprograms-overload-resolution)

Справочник: [cppreference.com](sources.md#cppreference): [Overload resolution](https://cppreference.com/cpp/language/overload_resolution); [Argument-dependent lookup](https://cppreference.com/cpp/language/adl)

- **Ранжирование неявных преобразований аргументов (layer: language, profile: cpp23)** — Кандидаты сравниваются по рангам неявных последовательностей преобразований (exact match, promotion, conversion, пользовательские); при равенстве вызов неоднозначен.
- **Поиск кандидатов по типам аргументов (layer: language, profile: cpp23)** — Для неквалифицированного вызова кандидаты ищутся и в пространствах имён типов аргументов. ([N4950, [over.match], [over.ics.rank], [basic.lookup.argdep]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

### Полиморфизм и организация { #abstraction }

#### Диспетчеризация вызовов { #abstraction-dispatch }

англ. *Method dispatch* (также *static dispatch*, *dynamic dispatch*, *virtual functions*, *multiple dispatch*) · [в онтологии](concepts.md#abstraction-dispatch)

Справочник: [cppreference.com](sources.md#cppreference): [virtual function specifier](https://cppreference.com/cpp/language/virtual)

- **Статическая (layer: language, profile: cpp23)** — Разрешение перегрузок и невиртуальные вызовы.
- **По одному динамическому типу (layer: language, profile: cpp23)** — Виртуальный вызов выбирает final overrider по динамическому типу получателя.

#### Наследование реализации { #abstraction-inheritance }

англ. *Implementation inheritance* (также *inheritance*, *subclassing*, *derived classes*) · [в онтологии](concepts.md#abstraction-inheritance)

Справочник: [cppreference.com](sources.md#cppreference): [Derived classes](https://cppreference.com/cpp/language/derived_class)

- **Множественное (layer: language, profile: cpp23)** — Возможны несколько базовых классов и виртуальное наследование.

#### Модульность { #abstraction-modules }

англ. *Modules* (также *module system*, *namespaces*, *packages*) · [в онтологии](concepts.md#abstraction-modules)

Справочник: [cppreference.com](sources.md#cppreference): [Modules](https://cppreference.com/cpp/language/modules); [Namespaces](https://cppreference.com/cpp/language/namespace); [Source file inclusion](https://cppreference.com/cpp/preprocessor/include)

- **Текстовое включение (layer: language, profile: cpp23)**
- **Пространства имён и пакеты (layer: language, profile: cpp23)**
- **Явная граница экспорта (layer: language, profile: cpp23)** — Именованные модули с export/import; #include и пространства имён также поддерживаются. Модуль не создаёт собственного пространства имён.

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

англ. *Evaluation strategy* (также *eager evaluation*, *lazy evaluation*) · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: cpp23)** — Аргументы вычисляются перед входом в функцию; строгая стратегия не задаёт единого порядка аргументов слева направо.

#### Порядок вычисления подвыражений { #evaluation-order }

англ. *Order of evaluation* (также *sequencing*, *sequence points*, *sequenced-before*) · [в онтологии](concepts.md#evaluation-order)

Справочник: [cppreference.com](sources.md#cppreference): [Order of evaluation](https://cppreference.com/cpp/language/eval_order)

- **Не задан стандартом (layer: language, profile: cpp23)** — Порядок вычисления аргументов вызова не задан; с C++17 они вычисляются indeterminately sequenced, а не unsequenced.
- **Задан для отдельных операций (layer: language, profile: cpp23)** — С C++17 задан порядок для <<, >>, присваивания (справа налево), индексирования и постфиксного выражения вызова; также &&, ||, ?: и запятая. ([N4950, [intro.execution], [expr.call], [expr.ass]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Неопределённое поведение { #evaluation-undefined-behavior }

англ. *Undefined behavior* (также *UB*, *unspecified behavior*, *implementation-defined behavior*) · [в онтологии](concepts.md#evaluation-undefined-behavior)

Справочник: [cppreference.com](sources.md#cppreference): [Undefined behavior](https://cppreference.com/cpp/language/ub); [The as-if rule](https://cppreference.com/cpp/language/as_if)

- **Неопределённое поведение (layer: language, profile: cpp23)** — Компилятор вправе считать UB невозможным; внутри константного вычисления UB делает выражение неконстантным и диагностируется.
- **Неуточнённое поведение (layer: language, profile: cpp23)**
- **Определяемое реализацией (layer: language, profile: cpp23)** ([N4950, [intro.abstract], [defns.undefined], [expr.const]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Вычисления во время компиляции { #evaluation-compile-time }

англ. *Constant evaluation* (также *compile-time evaluation*, *constant expressions*, *constexpr*) · [в онтологии](concepts.md#evaluation-compile-time)

Справочник: [cppreference.com](sources.md#cppreference): [Constant expressions](https://cppreference.com/cpp/language/constant_expression); [constexpr specifier](https://cppreference.com/cpp/language/constexpr); [consteval specifier](https://cppreference.com/cpp/language/consteval)

- **Константные выражения из ограниченного набора операций (layer: language, profile: cpp23)**
- **Функции (layer: language, profile: cpp23)** — constexpr-функции вычисляются при компиляции в константном контексте и допустимы при выполнении.
- **Функции (layer: language, profile: cpp23)** — consteval-функции (C++20) — immediate functions, каждый вызов вычисляется при компиляции. ([N4950, [expr.const], [dcl.constexpr]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

англ. *Memory management* (также *memory reclamation*, *garbage collection*, *reference counting*) · [в онтологии](concepts.md#memory-management)

Справочник: [cppreference.com](sources.md#cppreference): [new expression](https://cppreference.com/cpp/language/new); [delete expression](https://cppreference.com/cpp/language/delete); [std::unique_ptr](https://cppreference.com/cpp/memory/unique_ptr)

- **Ручное (layer: language, profile: cpp23)** — new/delete позволяют явное управление динамической памятью; обычный указатель не выражает проверяемое владение.
- **Владение и время жизни (layer: standard_library, profile: cpp23, applies_to: std::unique_ptr и владеющие контейнеры)** — Владение реализовано библиотечными типами и деструкторами; общей статической проверки всех времён жизни нет.
- **Подсчёт ссылок (layer: standard_library, profile: cpp23, applies_to: std::shared_ptr)** — Разделяемое владение; циклы сильных ссылок автоматически не разрываются, для невладеющих связей есть weak_ptr. ([N4950, [unique.ptr], [util.smartptr.shared], [util.smartptr.weak]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Передача и разделение владения { #memory-transfer }

англ. *Ownership transfer and sharing* (также *move semantics*, *copy semantics*, *borrowing*) · [в онтологии](concepts.md#memory-transfer)

Справочник: [cppreference.com](sources.md#cppreference): [Move constructors](https://cppreference.com/cpp/language/move_constructor); [Copy constructors](https://cppreference.com/cpp/language/copy_constructor)

- **Копирование значения (layer: language, profile: cpp23)**
- **Перемещение владения (layer: language, profile: cpp23, applies_to: типы с перемещающими операциями)** — Перенос ресурса определяется move-конструктором/присваиванием. std::move лишь меняет категорию выражения; исходный объект остаётся существовать, а копирование тоже может быть выбрано. ([N4950, [class.copy.ctor], [class.copy.assign], [forward]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Длительность хранения и время жизни объекта { #memory-storage-duration }

англ. *Storage duration* (также *object lifetime*, *automatic storage*, *static storage*, *dynamic storage*) · [в онтологии](concepts.md#memory-storage-duration)

Справочник: [cppreference.com](sources.md#cppreference): [Storage class specifiers](https://cppreference.com/cpp/language/storage_duration); [Lifetime](https://cppreference.com/cpp/language/lifetime)

- **Автоматическая (layer: language, profile: cpp23)**
- **Статическая (layer: language, profile: cpp23)**
- **Поточная (layer: language, profile: cpp23)** — thread_local, C++11.
- **Динамическая (layer: language, profile: cpp23)** — new/delete и функции выделения; время жизни объекта может начаться позже выделения памяти (placement new). ([N4950, [basic.stc], [basic.life]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Категории значений выражений { #memory-value-categories }

англ. *Value categories* (также *lvalue*, *rvalue*, *glvalue*, *prvalue*, *xvalue*) · [в онтологии](concepts.md#memory-value-categories)

Справочник: [cppreference.com](sources.md#cppreference): [Value categories](https://cppreference.com/cpp/language/value_category)

- **По идентичности и возможности перемещения (layer: language, profile: cpp23)** — glvalue (lvalue, xvalue) и prvalue; с C++17 prvalue материализуется во временный объект только при необходимости (гарантированный copy elision). ([N4950, [basic.lval], [conv.rval]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Модель памяти для параллельного доступа { #memory-concurrency-model }

англ. *Memory model* (также *data race*, *happens-before*, *memory ordering*, *atomics*) · [в онтологии](concepts.md#memory-concurrency-model)

Справочник: [cppreference.com](sources.md#cppreference): [Memory model](https://cppreference.com/cpp/language/memory_model); [Multi-threaded executions and data races](https://cppreference.com/cpp/language/multithread); [std::memory_order](https://cppreference.com/cpp/atomic/memory_order)

- **Гонка данных — неопределённое поведение (layer: language, profile: cpp23)**
- **Явно выбираемое упорядочивание атомарных операций (layer: standard_library, profile: cpp23, applies_to: std::atomic и std::memory_order)** — По умолчанию seq_cst; relaxed, acquire, release, acq_rel задаются явно. ([N4950, [intro.races], [atomics.order]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

англ. *Error handling* (также *exceptions*, *result types*, *error codes*) · [в онтологии](concepts.md#errors-model)

Справочник: [cppreference.com](sources.md#cppreference): [Exceptions](https://cppreference.com/cpp/language/exceptions); [std::expected](https://cppreference.com/cpp/utility/expected)

- **Исключения (layer: language, profile: cpp23)**
- **Размеченный результат (layer: standard_library, profile: cpp23)** — `std::expected<T, E>` — явный результат или ошибка; исключения при этом сохраняются как отдельный канал. ([N4950, [except], [expected]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

англ. *Resource cleanup* (также *RAII*, *deterministic destruction*, *finally*, *defer*) · [в онтологии](concepts.md#resources-cleanup)

Справочник: [cppreference.com](sources.md#cppreference): [RAII](https://cppreference.com/cpp/language/raii); [Destructors](https://cppreference.com/cpp/language/destructor)

- **Деструктор при выходе из области (layer: language, profile: cpp23)** — Деструкторы автоматических объектов вызываются при обычном выходе и раскрутке стека исключением; terminate и аварийное завершение не дают общей гарантии очистки. ([N4950, [class.dtor], [except.ctor]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

англ. *Input/output* (также *I/O library*) · [в онтологии](concepts.md#resources-io)

Справочник: [cppreference.com](sources.md#cppreference): [Input/output library](https://cppreference.com/cpp/io)

- **API стандартной библиотеки (layer: standard_library, profile: cpp23)** — iostream, fstream и std::print; ввод-вывод не является оператором ядра языка.

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

англ. *Syntactic grouping boundaries* (также *block delimiters*, *compound statement*, *off-side rule*) · [в онтологии](concepts.md#syntax-blocks)

Справочник: [cppreference.com](sources.md#cppreference): [Statements](https://cppreference.com/cpp/language/statements)

- **Явные разделители (layer: language, profile: cpp23)**

#### Метапрограммирование { #syntax-metaprogramming }

англ. *Metaprogramming* (также *macros*, *reflection*, *compile-time evaluation*) · [в онтологии](concepts.md#syntax-metaprogramming)

Справочник: [cppreference.com](sources.md#cppreference): [Replacing text macros](https://cppreference.com/cpp/preprocessor/replace); [Template Metaprogramming](https://cppreference.com/cpp/language/template_metaprogramming)

- **Текстовые макросы (layer: language, profile: cpp23)**
- **Вычисление при компиляции (layer: language, profile: cpp23)** — constexpr/consteval и шаблонные вычисления; препроцессор — отдельный механизм.

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

англ. *Programming paradigms* (также *supported paradigms*) · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: cpp23)**
- **Процедурная (layer: language, profile: cpp23)**
- **Объектно-ориентированная (layer: language, profile: cpp23)**
- **Функциональная (layer: language, profile: cpp23)**

### Инструменты построения языковых процессоров { #tooling }

#### Способ построения синтаксического анализатора { #tooling-parser-construction }

англ. *Parser construction* (также *parser generator*, *compiler-compiler*, *hand-written parser*, *parser combinators*) · [в онтологии](concepts.md#tooling-parser-construction)

- **Рукописный анализатор (layer: implementation, profile: cpp23, implementation: GCC 3.4+, Clang)** — В GCC 3.4 YACC-парсер C++ заменён рукописным рекурсивным спуском; Clang обосновывает рукописный парсер диагностикой и восстановлением после ошибок. ([GCC 3.4 Release Series — Changes](https://gcc.gnu.org/gcc-3.4/changes.html); [Clang — Features and Goals](https://clang.llvm.org/features.html))

#### Алгоритм синтаксического анализа { #tooling-parsing-algorithm }

англ. *Parsing algorithm* (также *LL(k)*, *ALL(*)*, *LALR(1)*, *GLR*, *Earley*, *PEG*, *packrat*) · [в онтологии](concepts.md#tooling-parsing-algorithm)

- **Нисходящий LL(k) и рекурсивный спуск (layer: implementation, profile: cpp23, implementation: GCC 3.4+, Clang)** — Рекурсивный спуск с произвольным просмотром вперёд и откатами там, где грамматика C++ неоднозначна.
