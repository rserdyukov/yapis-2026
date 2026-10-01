---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Common Lisp

ANSI Common Lisp сочетает динамические типы, лексические замыкания, special-переменные с динамической областью, CLOS и расширяемый синтаксис. Основа — ANSI X3.226-1994 в изложении Common Lisp HyperSpec; расширения отдельных реализаций не предполагаются.

*Карточка сравнительная: 35/85 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1984 — [Wikidata P571](https://www.wikidata.org/wiki/Q849146) (получено 2026-09-24) |
| Авторы | [Скотт Фалман](people.md#fahlman), [Ричард Гэбриел](people.md#gabriel), [Дэвид Мун](people.md#moon) |
| Организации | ANSI X3J13 |
| Сайт | <https://common-lisp.net/> |
| Спецификация | <https://www.lispworks.com/documentation/HyperSpec/Front/index.htm> |
| Внешние каталоги | [Wikidata Q849146](https://www.wikidata.org/wiki/Q849146) |

## Люди { #people }

- [Гай Стил](people.md#steele) — Автор «Common Lisp the Language», соавтор Scheme и спецификации Java.
- [Ричард Гэбриел](people.md#gabriel) — Участник проектирования Common Lisp и соавтор спецификации CLOS.
- [Скотт Фалман](people.md#fahlman) — Один из основных участников проектирования Common Lisp в Carnegie Mellon University.
- [Дэвид Мун](people.md#moon) — Участник проектирования Common Lisp и CLOS, разработчик Lisp-машин.

## Публикации { #publications }

- Гай Стил, Ричард Гэбриел. *The Evolution of Lisp*. HOPL II, 1993. DOI: [10.1145/154766.155373](https://doi.org/10.1145/154766.155373). История диалектов Lisp и их объединения в Common Lisp. ([в источниках](sources.md#hopl-lisp))
- Ричард Гэбриел. [The Rise of "Worse is Better"](https://www.dreamsongs.com/RiseOfWorseIsBetter.html). 1991. Эссе о компромиссе между простотой реализации и корректностью интерфейса на примере C/Unix и Lisp; материал для обсуждения критериев оценки языков. ([в источниках](sources.md#gabriel-worse-is-better))
- Frederick J. Ross. [The seven programming ur-languages](https://madhadron.com/programming/seven_ur_languages.html). 2022. Семь семейств-«праязыков» (ALGOL, Lisp, ML, Self, Forth, APL, Prolog) с характерными приёмами мышления — рамка для каталога языков. ([в источниках](sources.md#ross-ur-languages))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **ansi** — ANSI Common Lisp (X3.226-1994); базовый профиль всех записей. HyperSpec — гипертекстовое представление спецификации.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

англ. *Binding introduction* (также *declaration*, *name binding*) · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: ansi)** — let/let*, параметры функций и defvar/defparameter вводят связывания; setq меняет значение существующего связывания.
- **Связывание образцом (layer: language, profile: ansi, applies_to: destructuring-bind)** — Макрос связывает переменные по структуре списка, используя destructuring lambda list. ([CLHS: DESTRUCTURING-BIND](https://www.lispworks.com/documentation/HyperSpec/Body/m_destru.htm))

#### Изменяемость связывания { #bindings-mutation }

англ. *Binding mutability* (также *rebinding*, *immutable binding*, *const qualification*) · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: ansi)** — setq изменяет значение переменной; setf обобщает изменение на места хранения. Изменяемость объекта не равна изменяемости связывания. ([CLHS: SETQ](https://www.lispworks.com/documentation/HyperSpec/Body/s_setq.htm))

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

англ. *Assignment and binding forms* (также *assignment*, *destructuring*, *unification*) · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: ansi)** — setq и setf могут перечислять несколько мест, но обновляют их по определённым правилам последовательности.
- **Распаковка при присваивании (layer: language, profile: ansi, applies_to: multiple-value-setq)** — Распределяет несколько возвращённых значений по переменным; multiple values — отдельный механизм, а не объект-кортеж. ([CLHS: MULTIPLE-VALUE-SETQ](https://www.lispworks.com/documentation/HyperSpec/Body/m_mult_2.htm))

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

англ. *Name resolution* (также *name lookup*, *lexical scoping*, *dynamic scoping*) · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: ansi)** — Обычные локальные переменные и локальные функции имеют лексическую область; пространства имён переменных и функций различны.
- **Динамическое (layer: language, profile: ansi, applies_to: special-переменные)** — Объявление special и defvar/defparameter задают динамические связывания; соглашение об имёнах со звёздочками само по себе не включает этот режим. ([CLHS: SPECIAL declaration](https://www.lispworks.com/documentation/HyperSpec/Body/d_specia.htm))

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

англ. *Scoping constructs* (также *scope*, *block scope*) · [в онтологии](concepts.md#scope-constructs)

- **Форма связывания let/where (layer: language, profile: ansi)** — let/let*, flet/labels и другие связывающие формы; progn сам по себе не вводит область переменных.
- **Подпрограмма (layer: language, profile: ansi, applies_to: параметры функций)**

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

англ. *Top-level bindings* (также *global variables*, *file scope*, *namespace scope*) · [в онтологии](concepts.md#scope-globals)

- **Глобальные переменные (layer: language, profile: ansi)** — defvar и defparameter провозглашают переменную special и задают глобальное значение; defvar не заменяет уже связанное значение. ([CLHS: DEFVAR, DEFPARAMETER](https://www.lispworks.com/documentation/HyperSpec/Body/m_defpar.htm))

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

англ. *Name shadowing* (также *name hiding*, *variable shadowing*) · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: ansi)** — Внутреннее лексическое связывание скрывает внешнее; динамическое связывание special действует в пределах своего динамического времени жизни.

### Типизация { #typing }

#### Проверка типов { #typing-checking }

англ. *Type checking* (также *static typing*, *dynamic typing*) · [в онтологии](concepts.md#typing-checking)

- **Динамическая (layer: language, profile: ansi)** — Тип принадлежит объекту. Декларации типов могут использоваться компилятором; неверная декларация не обязана приводить к безопасной runtime-проверке во всех режимах optimize/safety. ([CLHS: Introduction to Types and Classes](https://www.lispworks.com/documentation/HyperSpec/Body/04_a.htm); [CLHS: TYPE declaration](https://www.lispworks.com/documentation/HyperSpec/Body/d_type.htm))

#### Аннотации типов { #typing-annotations }

англ. *Type annotations* (также *type declarations*, *type signatures*) · [в онтологии](concepts.md#typing-annotations)

- **Необязательны (layer: language, profile: ansi)** — declare/declaim и the выражают сведения и утверждения о типах; объявления не превращают ANSI Common Lisp в обязательно статически проверяемый язык.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

англ. *Type conversions* (также *type coercion*, *type casting*) · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: ansi)** — coerce и функции вроде float выполняют конкретные допустимые преобразования.
- **Неявные (layer: language, profile: ansi, applies_to: числовые операции)** — Правила numeric contagion согласуют представления аргументов; это не универсальное преобразование строк в числа. ([CLHS: Numeric Operations](https://www.lispworks.com/documentation/HyperSpec/Body/12_a.htm))

#### Типы-произведения { #typing-product-types }

англ. *Product types* (также *tuples*, *records*, *structs*) · [в онтологии](concepts.md#typing-product-types)

- **Записи и структуры (layer: language, profile: ansi)** — defstruct задаёт структуры со слотами, а CLOS — классы с объектами и слотами.

#### Представление отсутствия значения { #typing-nullability }

англ. *Nullability* (также *null reference*, *option type*) · [в онтологии](concepts.md#typing-nullability)

- **Специальное значение (layer: language, profile: ansi)** — nil одновременно ложь и пустой список; это обычный Lisp-объект, допустимость которого зависит от операции. Тип null содержит только nil. ([CLHS: Type NULL](https://www.lispworks.com/documentation/HyperSpec/Body/t_null.htm))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

англ. *Conditional selection* (также *selection statement*, *conditional expression*) · [в онтологии](concepts.md#control-selection)

- **Условное выражение (layer: language, profile: ansi)** — if и cond возвращают значения; только nil ложно.

#### Выбор по значению switch/case { #control-switch }

англ. *Switch statement* (также *case statement*, *multiway branch*) · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: ansi)** — case выбирает ветвь по eql с ключами; typecase — отдельный выбор по типу. ([CLHS: CASE, CCASE, ECASE](https://www.lispworks.com/documentation/HyperSpec/Body/m_case_.htm))

<a id="req-7-2-until"></a>

#### Цикл до истинности условия { #control-until }

англ. *Until loop* (также *repeat-until loop*) · [в онтологии](concepts.md#control-until)

- **Проверка перед телом (layer: language, profile: ansi, applies_to: loop с until перед основным действием)** — until — условие завершения макроса loop; положение в теле определяет, до каких действий оно проверяется.
- **Проверка после тела (layer: language, profile: ansi, applies_to: loop с until после основного действия)** — Проверка после действия даёт форму с постусловием; это не отдельный ключевой оператор ядра. ([CLHS: The LOOP Facility](https://www.lispworks.com/documentation/HyperSpec/Body/06_a.htm))

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

англ. *Iteration* (также *loops*, *for loop*, *foreach loop*, *range-based for loop*) · [в онтологии](concepts.md#control-iteration)

- **По последовательности или итератору (layer: language, profile: ansi)** — dolist и loop; dotimes задаёт счётное повторение.
- **Функции обхода (layer: language, profile: ansi)** — mapcar/map и reduce — стандартные функции обработки последовательностей.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

англ. *Function overloading* (также *overloading*, *operator overloading*) · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: ansi)** — CLOS generic functions используют динамическую множественную диспетчеризацию и комбинацию методов, а не Java-подобный выбор перегрузки по статической сигнатуре. ([CLHS: Generic Functions and Methods](https://www.lispworks.com/documentation/HyperSpec/Body/07_f.htm))

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

англ. *Parameter passing* (также *call by value*, *call by reference*, *call by sharing*) · [в онтологии](concepts.md#subprograms-parameter-passing)

- **Разделение объекта (layer: language, profile: ansi)** — Параметры связываются с переданными объектами. Изменение объекта может быть видно вызывающему; setq параметра меняет только соответствующее связывание. ([CLHS: Function Forms](https://www.lispworks.com/documentation/HyperSpec/Body/03_ababc.htm))

<a id="variants-9"></a>

#### Место определения подпрограмм { #subprograms-placement }

англ. *Subprogram definition placement* (также *top-level function*, *member function*, *local function*) · [в онтологии](concepts.md#subprograms-placement)

- **Локальное определение (layer: language, profile: ansi)** — flet задаёт локальные функции, labels допускает их взаимную рекурсию. defun создаёт глобальное определение и может вычисляться не только на верхнем уровне; это не автоматическое лексическое вложение.

#### Вложенные именованные подпрограммы { #subprograms-nesting }

англ. *Nested functions* (также *nested subprograms*) · [в онтологии](concepts.md#subprograms-nesting)

- **да (layer: language, profile: ansi)** — Именованные локальные функции flet/labels. ([CLHS: FLET, LABELS, MACROLET](https://www.lispworks.com/documentation/HyperSpec/Body/s_flet_.htm))

#### Захват окружения { #subprograms-closures }

англ. *Closures* (также *lambda capture*, *captured variables*) · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: ansi)** — Замыкание захватывает лексические связывания, а не снимок значений; special-переменные разрешаются динамически. ([CLHS: Closures and Lexical Binding](https://www.lispworks.com/documentation/HyperSpec/Body/03_ad.htm))

#### Анонимные функции { #subprograms-lambda }

англ. *Anonymous functions* (также *lambda expressions*, *function literals*) · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: ansi)**

#### Аргументы по умолчанию { #subprograms-default-args }

англ. *Default arguments* (также *optional parameters*) · [в онтологии](concepts.md#subprograms-default-args)

- **да (layer: language, profile: ansi)** — &optional и &key; init-form вычисляется при отсутствии соответствующего аргумента.

#### Именованные аргументы { #subprograms-named-args }

англ. *Named arguments* (также *keyword arguments*) · [в онтологии](concepts.md#subprograms-named-args)

- **да (layer: language, profile: ansi)** — &key задаёт keyword arguments; keyword-символы участвуют в протоколе обычного вызова. ([CLHS: Ordinary Lambda Lists](https://www.lispworks.com/documentation/HyperSpec/Body/03_da.htm))

### Полиморфизм и организация { #abstraction }

#### Диспетчеризация вызовов { #abstraction-dispatch }

англ. *Method dispatch* (также *static dispatch*, *dynamic dispatch*, *virtual functions*, *multiple dispatch*) · [в онтологии](concepts.md#abstraction-dispatch)

- **По нескольким динамическим типам (layer: language, profile: ansi)** — CLOS выбирает применимые методы по специализаторам обязательных аргументов, включая классы и eql-специализаторы; method combination определяет их совместное выполнение. ([CLHS: Generic Functions and Methods](https://www.lispworks.com/documentation/HyperSpec/Body/07_f.htm))

#### Наследование реализации { #abstraction-inheritance }

англ. *Implementation inheritance* (также *inheritance*, *subclassing*, *derived classes*) · [в онтологии](concepts.md#abstraction-inheritance)

- **Множественное (layer: language, profile: ansi)** — CLOS-класс может иметь несколько прямых суперклассов; порядок предшествования классов влияет на наследование и методы.

#### Модульность { #abstraction-modules }

англ. *Modules* (также *module system*, *namespaces*, *packages*) · [в онтологии](concepts.md#abstraction-modules)

- **Пространства имён и пакеты (layer: language, profile: ansi)** — Пакеты управляют идентичностью, доступностью и экспортом символов; это не система загрузки файлов или проектов вроде ASDF. ([CLHS: Package Concepts](https://www.lispworks.com/documentation/HyperSpec/Body/11_a.htm))

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

англ. *Evaluation strategy* (также *eager evaluation*, *lazy evaluation*) · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: ansi, applies_to: обычные вызовы функций)** — Аргументы вычисляются слева направо; специальные операторы и макросы имеют собственные правила вычисления подформ. ([CLHS: Function Forms](https://www.lispworks.com/documentation/HyperSpec/Body/03_ababc.htm))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

англ. *Error handling* (также *exceptions*, *result types*, *error codes*) · [в онтологии](concepts.md#errors-model)

- **Условия и перезапуски (layer: language, profile: ansi)** — Сигнализация condition отделена от выбора restart. Обработчик может работать до раскрутки стека; не всякое condition является ошибкой и не всякая обработка требует нелокального выхода. ([CLHS: Condition System Concepts](https://www.lispworks.com/documentation/HyperSpec/Body/09_a.htm))

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

англ. *Resource cleanup* (также *RAII*, *deterministic destruction*, *finally*, *defer*) · [в онтологии](concepts.md#resources-cleanup)

- **Блок finally / unwind-protect (layer: language, profile: ansi)** — unwind-protect выполняет cleanup-формы при нормальном и нелокальном выходе из защищённой формы. Соответствие finally здесь семантическое; имя конструкции — unwind-protect. ([CLHS: UNWIND-PROTECT](https://www.lispworks.com/documentation/HyperSpec/Body/s_unwind.htm))
- **Конструкция управления ресурсом (layer: language, profile: ansi, applies_to: with-open-file)** — Стандартный макрос ограничивает динамическое время жизни потока и закрывает его при выходе. ([CLHS: WITH-OPEN-FILE](https://www.lispworks.com/documentation/HyperSpec/Body/m_w_open.htm))

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

англ. *Input/output* (также *I/O library*) · [в онтологии](concepts.md#resources-io)

- **API стандартной библиотеки (layer: standard_library, profile: ansi)** — Стандартные потоки, read/write и format. Reader читает Lisp-объекты, что отличается от простого чтения строки.

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

англ. *Syntactic grouping boundaries* (также *block delimiters*, *compound statement*, *off-side rule*) · [в онтологии](concepts.md#syntax-blocks)

- **S-выражения (layer: language, profile: ansi)** — Формы представлены объектами, обычно записанными как списки в скобках; reader macros расширяют способ чтения.

#### Границы операторов и определений { #syntax-statement-terminator }

англ. *Statement terminators* (также *statement separators*, *automatic semicolon insertion*) · [в онтологии](concepts.md#syntax-statement-terminator)

- **Структура выражения (layer: language, profile: ansi)** — Границы формы определяются прочитанным объектом, в частности сбалансированным списком; точка с запятой начинает комментарий, а не завершает оператор.

#### Метапрограммирование { #syntax-metaprogramming }

англ. *Metaprogramming* (также *macros*, *reflection*, *compile-time evaluation*) · [в онтологии](concepts.md#syntax-metaprogramming)

- **Синтаксические макросы (layer: language, profile: ansi)** — defmacro преобразует формы до вычисления; гигиена не обеспечивается автоматически.
- **Построение и выполнение кода (layer: language, profile: ansi)** — eval и compile работают с представленными Lisp-объектами формами; eval не захватывает произвольное лексическое окружение вызывающего. ([CLHS: DEFMACRO](https://www.lispworks.com/documentation/HyperSpec/Body/m_defmac.htm); [CLHS: EVAL](https://www.lispworks.com/documentation/HyperSpec/Body/f_eval.htm))

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

англ. *Programming paradigms* (также *supported paradigms*) · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: ansi)**
- **Функциональная (layer: language, profile: ansi)**
- **Объектно-ориентированная (layer: language, profile: ansi)**
