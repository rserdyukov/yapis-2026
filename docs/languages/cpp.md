---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# C++

C++23 сочетает статическую типизацию, классы, шаблоны и управление временем жизни объектов через конструкторы и деструкторы. За основу взят проект стандарта N4950, без расширений компиляторов.

*Карточка сравнительная: 34/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

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

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: cpp23)**
- **Связывание образцом (layer: language, profile: cpp23)** — Structured bindings объявляют набор имён; это не произвольное сопоставление с образцом.

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: cpp23)** — Изменяемому объекту можно присвоить новое значение; reference после инициализации не переназначается на другой объект.
- **Неизменяемое (layer: language, profile: cpp23, applies_to: const-объекты)** — const не означает глубокую неизменяемость всего достижимого графа; mutable-члены имеют особые правила.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: cpp23)** — operator= для классов может быть перегружен; structured binding — объявление, а не множественное присваивание.

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: cpp23)**

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Блок (layer: language, profile: cpp23)**
- **Класс (layer: language, profile: cpp23)**

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Статическая (layer: language, profile: cpp23)**

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Необязательны (layer: language, profile: cpp23, applies_to: объявления с auto и выводимыми типами)** — Явные типы по-прежнему нужны во многих сигнатурах; auto не отменяет объявления.

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **да (layer: language, profile: cpp23)** — auto, вывод аргументов шаблона и class template argument deduction.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Неявные (layer: language, profile: cpp23)** — Стандартные и пользовательские преобразования участвуют в разрешении перегрузки; сужающие преобразования в list-initialization ограничены.
- **Явные (layer: language, profile: cpp23)** — Именованные cast имеют разные контракты; reinterpret_cast не обеспечивает безопасный доступ к произвольной памяти. ([N4950, [conv], [expr.cast], [dcl.init.list]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Совместимость типов { #typing-compatibility }

*Type compatibility* · [в онтологии](concepts.md#typing-compatibility)

- **Номинальная (layer: language, profile: cpp23, applies_to: типы классов и перечислений)** — Совпадение набора полей не делает два независимо объявленных класса одним типом.

#### Типы-суммы { #typing-sum-types }

*Sum types* · [в онтологии](concepts.md#typing-sum-types)

- **Размеченные варианты (layer: standard_library, profile: cpp23)** — std::variant хранит активную альтернативу. Встроенный union сам по себе не хранит метку.

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Записи и структуры (layer: language, profile: cpp23)** — struct/class с полями.
- **Кортежи (layer: standard_library, profile: cpp23)** — std::tuple и std::pair.

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Специальное значение (layer: language, profile: cpp23)** — nullptr для указателей; корректно инициализированная ссылка должна обозначать объект или функцию.
- **Тип Option/Optional (layer: standard_library, profile: cpp23)** — `std::optional<T>` хранит значение либо состояние отсутствия.

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: cpp23)**
- **Условное выражение (layer: language, profile: cpp23)** — if и ?:; if constexpr выбирает ветвь при инстанцировании шаблона по правилам стандарта.

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: cpp23)**

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **Инициализация / условие / шаг (layer: language, profile: cpp23)**
- **По последовательности или итератору (layer: language, profile: cpp23)** — Range-based for работает с диапазонами через begin/end.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **да (layer: language, profile: cpp23)** — Свободные функции, методы и операторы; один лишь возвращаемый тип не различает перегрузки обычных функций.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: cpp23)**
- **По ссылке на переменную (layer: language, profile: cpp23)** — Параметры T&, const T& и T&& связываются с объектом. Ссылки не обеспечивают проверку владения или исключительности, аналогичную Rust borrow checker. ([N4950, [dcl.ref], [dcl.init.ref], [expr.call]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms* · [в онтологии](concepts.md#subprograms-nesting)

- **нет (layer: language, profile: cpp23)** — Определение свободной именованной функции внутри функции запрещено; локальные классы могут иметь методы, а лямбды — свои тела.

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: cpp23)** — Лямбды захватывают по значению или по ссылке; захват по ссылке не продлевает автоматически время жизни объекта. ([N4950, [expr.prim.lambda]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: cpp23)**

#### Параметрический полиморфизм { #subprograms-generics }

*Parametric polymorphism* · [в онтологии](concepts.md#subprograms-generics)

- **да (layer: language, profile: cpp23)** — Шаблоны функций, классов и переменных; concepts ограничивают допустимые аргументы шаблонов.

### Полиморфизм и организация { #abstraction }

#### Диспетчеризация вызовов { #abstraction-dispatch }

*Call dispatch* · [в онтологии](concepts.md#abstraction-dispatch)

- **Статическая (layer: language, profile: cpp23)** — Разрешение перегрузок и невиртуальные вызовы.
- **По одному динамическому типу (layer: language, profile: cpp23)** — Виртуальный вызов выбирает final overrider по динамическому типу получателя.

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Множественное (layer: language, profile: cpp23)** — Возможны несколько базовых классов и виртуальное наследование.

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Текстовое включение (layer: language, profile: cpp23)**
- **Пространства имён и пакеты (layer: language, profile: cpp23)**
- **Явная граница экспорта (layer: language, profile: cpp23)** — Именованные модули с export/import; #include и пространства имён также поддерживаются. Модуль не создаёт собственного пространства имён.

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: cpp23)** — Аргументы вычисляются перед входом в функцию; строгая стратегия не задаёт единого порядка аргументов слева направо.

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Ручное (layer: language, profile: cpp23)** — new/delete позволяют явное управление динамической памятью; обычный указатель не выражает проверяемое владение.
- **Владение и время жизни (layer: standard_library, profile: cpp23, applies_to: std::unique_ptr и владеющие контейнеры)** — Владение реализовано библиотечными типами и деструкторами; общей статической проверки всех времён жизни нет.
- **Подсчёт ссылок (layer: standard_library, profile: cpp23, applies_to: std::shared_ptr)** — Разделяемое владение; циклы сильных ссылок автоматически не разрываются, для невладеющих связей есть weak_ptr. ([N4950, [unique.ptr], [util.smartptr.shared], [util.smartptr.weak]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

#### Передача и разделение владения { #memory-transfer }

*Ownership transfer and sharing* · [в онтологии](concepts.md#memory-transfer)

- **Копирование значения (layer: language, profile: cpp23)**
- **Перемещение владения (layer: language, profile: cpp23, applies_to: типы с перемещающими операциями)** — Перенос ресурса определяется move-конструктором/присваиванием. std::move лишь меняет категорию выражения; исходный объект остаётся существовать, а копирование тоже может быть выбрано. ([N4950, [class.copy.ctor], [class.copy.assign], [forward]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: language, profile: cpp23)**
- **Размеченный результат (layer: standard_library, profile: cpp23)** — `std::expected<T, E>` — явный результат или ошибка; исключения при этом сохраняются как отдельный канал. ([N4950, [except], [expected]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Деструктор при выходе из области (layer: language, profile: cpp23)** — Деструкторы автоматических объектов вызываются при обычном выходе и раскрутке стека исключением; terminate и аварийное завершение не дают общей гарантии очистки. ([N4950, [class.dtor], [except.ctor]](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf))

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

*I/O interface* · [в онтологии](concepts.md#resources-io)

- **API стандартной библиотеки (layer: standard_library, profile: cpp23)** — iostream, fstream и std::print; ввод-вывод не является оператором ядра языка.

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: cpp23)**

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Текстовые макросы (layer: language, profile: cpp23)**
- **Вычисление при компиляции (layer: language, profile: cpp23)** — constexpr/consteval и шаблонные вычисления; препроцессор — отдельный механизм.

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: cpp23)**
- **Процедурная (layer: language, profile: cpp23)**
- **Объектно-ориентированная (layer: language, profile: cpp23)**
- **Функциональная (layer: language, profile: cpp23)**
