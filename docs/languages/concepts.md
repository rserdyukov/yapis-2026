---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Сравнение языков

Матрица «понятие × язык»: значения [понятий онтологии](glossary.md) для всех языков каталога в порядке появления. Значение в ячейке — из закрытого перечисления; в скобках — версии и контекст: слой, профиль, реализация и область применимости. since включительно, until исключительно. Подробности (примечания, источники, код) — на карточке языка по ссылке в ячейке. «неприменимо (n/a)» требует пояснения; «нет» — булево false; пустая ячейка — данных нет.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

[Понятия: определения и связи](glossary.md) · [Проверочные вопросы](questions.md) · [Люди](people.md) · [Источники](sources.md)

Практическое чтение: [различающие примеры для 15 языков](../concepts/examples/index.md) — код, ожидаемый результат и статус проверки.

## Покрытие { #coverage }

Доля значений перечислений, для которых в каталоге есть хотя бы один язык. Пробелы покрытия информационные; возможные примеры указаны в скобках, если известны.

| Категория | Покрыто | Ожидают языков |
|---|---|---|
| Имена и связывание | 11/11 (100%) | — |
| Области видимости | 15/15 (100%) | — |
| Типизация | 20/25 (80%) | typing.value_dependency.indexed_families; typing.value_dependency.dependent_functions; typing.value_dependency.dependent_pairs; typing.abstract_type_identity.transparent; typing.abstract_type_identity.opaque_fresh |
| Управление потоком | 13/15 (87%) | control.continuation_extent.undelimited; control.continuation_extent.delimited |
| Подпрограммы и абстракция | 12/16 (75%) | subprograms.parameter_passing.by_result; subprograms.parameter_passing.by_value_result; subprograms.parameter_passing.by_name; subprograms.generic_mechanism.dictionary_passing |
| Полиморфизм и организация | 14/15 (93%) | abstraction.modules.module_functors |
| Вычисление и эффекты | 4/12 (33%) | evaluation.effects.effect_handlers; evaluation.rank_lifting.scalar_extension; evaluation.rank_lifting.cell_rank; evaluation.result_protocol.ordinary_return; evaluation.result_protocol.explicit_resume; evaluation.result_protocol.goal_directed; evaluation.data_availability.needed_information; evaluation.data_availability.all_inputs |
| Память и владение | 9/14 (64%) | memory.reference_permissions.isolated; memory.reference_permissions.mutable_aliases; memory.reference_permissions.immutable_shared; memory.reference_permissions.read_only_view; memory.reference_permissions.identity_only |
| Каналы ошибок | 8/9 (89%) | errors.must_use.error |
| Ресурсы и взаимодействие | 12/18 (67%) | resources.cleanup.defer; resources.concurrency.actors; resources.communication_coupling.asynchronous_mailbox; resources.communication_coupling.synchronous_rendezvous; resources.receive_selection.head_only; resources.receive_selection.selective_matching |
| Синтаксис и метапрограммирование | 14/18 (78%) | syntax.macro_hygiene.hygienic; syntax.macro_hygiene.unhygienic; syntax.program_representation.textual; syntax.program_representation.graphical_graph |
| Парадигмы | 6/7 (86%) | paradigm.supported.event_driven |
| Семантика данных | 0/7 (0%) | data.collection_multiplicity.set; data.collection_multiplicity.bag; data.collection_multiplicity.sequence; data.numeric_radix.binary; data.numeric_radix.decimal; data.numeric_precision.fixed_precision; data.numeric_precision.arbitrary_precision |
| Правила вычисления и модели времени | 0/19 (0%) | computation.rule_semantics.goal_search; computation.rule_semantics.least_fixed_point; computation.rule_semantics.committed_rewriting; computation.instantiation_modes.ground_to_ground; computation.instantiation_modes.free_to_ground; computation.instantiation_modes.declared_transition; computation.solution_cardinality.det; computation.solution_cardinality.semidet; computation.solution_cardinality.multi; computation.solution_cardinality.nondet; computation.time_domain.logical_ticks; computation.time_domain.discrete_simulation; computation.time_domain.continuous; computation.time_domain.hybrid; computation.equation_causality.directed_assignment; computation.equation_causality.directed_equation; computation.equation_causality.acausal_equation; computation.update_scheduling.blocking_update; computation.update_scheduling.deferred_nonblocking |
| Проверяемые свойства программ | 0/7 (0%) | verification.totality.checked_required; verification.totality.checked_opt_in; verification.totality.unchecked_escape; verification.totality.partial_allowed; verification.behavioral_contracts.preconditions; verification.behavioral_contracts.postconditions; verification.behavioral_contracts.invariants |

## Имена и связывание { #bindings }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Введение связывания](#bindings-introduction) | [Явное объявление (layer: language, profile: c17) *](c.md#bindings-introduction) | [Логическая переменная в терме (layer: language, profile: iso) *](prolog.md#bindings-introduction) | [Явное объявление (layer: language, profile: cpp23); Связывание образцом (layer: language, profile: cpp23) *](cpp.md#bindings-introduction) | [Явное объявление (layer: language, profile: ansi); Связывание образцом (layer: language, profile: ansi, applies_to: destructuring-bind) *](common-lisp.md#bindings-introduction) | [Явное объявление (layer: language, profile: haskell2010); Связывание образцом (layer: language, profile: haskell2010) *](haskell.md#bindings-introduction) | [Связывание присваиванием (layer: language, profile: python314); Связывание образцом (с Python 3.10 включительно, layer: language, profile: python314, applies_to: захватывающие образцы match) *](python.md#bindings-introduction) | [Явное объявление (layer: language, profile: java21) *](java.md#bindings-introduction) | [Явное объявление (layer: language, profile: es2024); Связывание образцом (layer: language, profile: es2024); Связывание присваиванием (layer: language, profile: sloppy, applies_to: присваивание неразрешимому имени) *](javascript.md#bindings-introduction) | [Явное объявление (layer: language, profile: csharp12); Связывание образцом (layer: language, profile: csharp12) *](csharp.md#bindings-introduction) | [Явное объявление (layer: language, profile: rust2024); Связывание образцом (layer: language, profile: rust2024, applies_to: let и образцы match) *](rust.md#bindings-introduction) | [Явное объявление (layer: language, profile: ts5_strict); Связывание образцом (layer: language, profile: ts5_strict) *](typescript.md#bindings-introduction) |
| [Изменяемость связывания](#bindings-mutation) | [Перепривязываемое (layer: language, profile: c17); Неизменяемое (layer: language, profile: c17, applies_to: объекты с const-квалифицированным типом) *](c.md#bindings-mutation) | [Однократное связывание логической переменной (layer: language, profile: iso) *](prolog.md#bindings-mutation) | [Перепривязываемое (layer: language, profile: cpp23); Неизменяемое (layer: language, profile: cpp23, applies_to: const-объекты) *](cpp.md#bindings-mutation) | [Перепривязываемое (layer: language, profile: ansi) *](common-lisp.md#bindings-mutation) | [Неизменяемое (layer: language, profile: haskell2010) *](haskell.md#bindings-mutation) | [Перепривязываемое (layer: language, profile: python314) *](python.md#bindings-mutation) | [Перепривязываемое (layer: language, profile: java21); Неизменяемое (layer: language, profile: java21, applies_to: final-переменные) *](java.md#bindings-mutation) | [Перепривязываемое (layer: language, profile: es2024, applies_to: let и var); Неизменяемое (layer: language, profile: es2024, applies_to: const) *](javascript.md#bindings-mutation) | [Перепривязываемое (layer: language, profile: csharp12, applies_to: обычные локальные переменные и поля); Неизменяемое (layer: language, profile: csharp12, applies_to: const и readonly-поля после разрешённой инициализации) *](csharp.md#bindings-mutation) | [Неизменяемое (layer: language, profile: rust2024); Перепривязываемое (layer: language, profile: rust2024, applies_to: let mut) *](rust.md#bindings-mutation) | [Перепривязываемое (layer: language, profile: ts5_strict, applies_to: let и var); Неизменяемое (layer: language, profile: ts5_strict, applies_to: const) *](typescript.md#bindings-mutation) |
| [Формы присваивания и связывания](#bindings-assignment) | [Одиночное присваивание (layer: language, profile: c17) *](c.md#bindings-assignment) | [Унификация термов (layer: language, profile: iso) *](prolog.md#bindings-assignment) | [Одиночное присваивание (layer: language, profile: cpp23) *](cpp.md#bindings-assignment) | [Одиночное присваивание (layer: language, profile: ansi); Распаковка при присваивании (layer: language, profile: ansi, applies_to: multiple-value-setq) *](common-lisp.md#bindings-assignment) | [Неизменяемое определение (layer: language, profile: haskell2010) *](haskell.md#bindings-assignment) | [Одиночное присваивание (layer: language, profile: python314); Распаковка при присваивании (layer: language, profile: python314) *](python.md#bindings-assignment) | [Одиночное присваивание (layer: language, profile: java21) *](java.md#bindings-assignment) | [Одиночное присваивание (layer: language, profile: es2024); Распаковка при присваивании (layer: language, profile: es2024) *](javascript.md#bindings-assignment) | [Одиночное присваивание (layer: language, profile: csharp12); Распаковка при присваивании (layer: language, profile: csharp12) *](csharp.md#bindings-assignment) | [Одиночное присваивание (layer: language, profile: rust2024); Распаковка при присваивании (с Rust 1.59 включительно, layer: language, profile: rust2024) *](rust.md#bindings-assignment) | [Одиночное присваивание (layer: language, profile: ts5_strict); Распаковка при присваивании (layer: language, profile: ts5_strict)](typescript.md#bindings-assignment) |

<a id="variants-1"></a>

### Введение связывания { #bindings-introduction }

*Binding introduction*

Установление связи между именем и сущностью программы — значением, местом хранения, функцией или логической переменной. Конструкция введения имени не определяет, нужно ли писать его тип.

[Пример, границы понятия и связи](glossary.md#bindings-introduction)

Наличие объявления независимо от аннотации и вывода типа; var в Java — явное объявление.

- `explicit` — **Явное объявление** (*explicit declaration*)
- `assignment` — **Связывание присваиванием** (*assignment binding*)
- `pattern` — **Связывание образцом** (*pattern binding*)
- `logic_variable` — **Логическая переменная в терме** (*logic variable in a term*)

### Изменяемость связывания { #bindings-mutation }

*Binding mutability*

Правила, определяющие, можно ли после введения связывания менять обозначаемое им значение или содержимое соответствующей переменной. Эти правила задаются отдельно от изменяемости достижимого объекта.

[Пример, границы понятия и связи](glossary.md#bindings-mutation)

Изменяемость объекта отделена от возможности перепривязать имя.

- `rebindable` — **Перепривязываемое** (*rebindable*)
- `immutable` — **Неизменяемое** (*immutable*)
- `single_assignment` — **Однократное связывание логической переменной** (*single-assignment logic binding*)

<a id="variants-3"></a>

### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms*

Семейство операций обновления мест хранения и установления связей со значениями. Для сравнения различаются присваивание одной цели, распаковка, неизменяемое определение и унификация, а не объявляются одной операцией.

[Пример, границы понятия и связи](glossary.md#bindings-assignment)

- `single` — **Одиночное присваивание** (*single-target assignment*)
- `multiple` — **Распаковка при присваивании** (*destructuring assignment*)
- `unification` — **Унификация термов** (*term unification*)
- `immutable_definition` — **Неизменяемое определение** (*immutable definition*)

## Области видимости { #scope }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Правило разрешения имён](#scope-resolution) | [Лексическое (layer: language, profile: c17)](c.md#scope-resolution) | [Лексическое (layer: language, profile: iso, applies_to: логические переменные клаузы) *](prolog.md#scope-resolution) | [Лексическое (layer: language, profile: cpp23)](cpp.md#scope-resolution) | [Лексическое (layer: language, profile: ansi); Динамическое (layer: language, profile: ansi, applies_to: special-переменные) *](common-lisp.md#scope-resolution) | [Лексическое (layer: language, profile: haskell2010)](haskell.md#scope-resolution) | [Лексическое (layer: language, profile: python314) *](python.md#scope-resolution) | [Лексическое (layer: language, profile: java21)](java.md#scope-resolution) | [Лексическое (layer: language, profile: strict); Лексическое (layer: language, profile: sloppy) *](javascript.md#scope-resolution) | [Лексическое (layer: language, profile: csharp12)](csharp.md#scope-resolution) | [Лексическое (layer: language, profile: rust2024)](rust.md#scope-resolution) | [Лексическое (layer: language, profile: ts5_strict)](typescript.md#scope-resolution) |
| [Конструкции областей видимости](#scope-constructs) | [Блок (layer: language, profile: c17); Подпрограмма (layer: language, profile: c17, applies_to: метки функции) *](c.md#scope-constructs) | [Логическая клауза (layer: language, profile: iso); Модуль (layer: implementation, profile: swi, implementation: SWI-Prolog) *](prolog.md#scope-constructs) | [Блок (layer: language, profile: cpp23); Класс (layer: language, profile: cpp23)](cpp.md#scope-constructs) | [Форма связывания let/where (layer: language, profile: ansi); Подпрограмма (layer: language, profile: ansi, applies_to: параметры функций) *](common-lisp.md#scope-constructs) | [Модуль (layer: language, profile: haskell2010); Форма связывания let/where (layer: language, profile: haskell2010); Генераторная конструкция (layer: language, profile: haskell2010); Подпрограмма (layer: language, profile: haskell2010, applies_to: параметры и образцы уравнений функций) *](haskell.md#scope-constructs) | [Подпрограмма (layer: language, profile: python314); Модуль (layer: language, profile: python314); Класс (layer: language, profile: python314); Генераторная конструкция (layer: language, profile: python314) *](python.md#scope-constructs) | [Подпрограмма (layer: language, profile: java21); Блок (layer: language, profile: java21); Класс (layer: language, profile: java21)](java.md#scope-constructs) | [Подпрограмма (layer: language, profile: es2024); Блок (layer: language, profile: es2024); Модуль (layer: language, profile: es2024); Класс (layer: language, profile: es2024) *](javascript.md#scope-constructs) |  | [Подпрограмма (layer: language, profile: rust2024); Модуль (layer: language, profile: rust2024); Блок (layer: language, profile: rust2024) *](rust.md#scope-constructs) | [Блок (layer: language, profile: ts5_strict); Подпрограмма (layer: language, profile: ts5_strict); Модуль (layer: language, profile: ts5_strict); Класс (layer: language, profile: ts5_strict)](typescript.md#scope-constructs) |
| [Связывания верхнего уровня](#scope-globals) | [Глобальные переменные (layer: language, profile: c17) *](c.md#scope-globals) | [Имена модуля (layer: implementation, profile: swi, implementation: SWI-Prolog, applies_to: имена предикатов) *](prolog.md#scope-globals) |  | [Глобальные переменные (layer: language, profile: ansi) *](common-lisp.md#scope-globals) | [Имена модуля (layer: language, profile: haskell2010) *](haskell.md#scope-globals) | [Имена модуля (layer: language, profile: python314) *](python.md#scope-globals) | [Статические члены типов (layer: language, profile: java21) *](java.md#scope-globals) | [Глобальные переменные (layer: language, profile: es2024); Имена модуля (layer: language, profile: es2024) *](javascript.md#scope-globals) |  | [Имена модуля (layer: language, profile: rust2024) *](rust.md#scope-globals) |  |
| [Сокрытие имён](#scope-shadowing) | [Во вложенной области (layer: language, profile: c17) *](c.md#scope-shadowing) |  |  | [Во вложенной области (layer: language, profile: ansi) *](common-lisp.md#scope-shadowing) | [Во вложенной области (layer: language, profile: haskell2010) *](haskell.md#scope-shadowing) | [Во вложенной области (layer: language, profile: python314) *](python.md#scope-shadowing) | [Запрет сокрытия локальных в охватывающем блоке (layer: language, profile: java21, applies_to: локальные переменные); Во вложенной области (layer: language, profile: java21, applies_to: поля и параметры) *](java.md#scope-shadowing) | [Во вложенной области (layer: language, profile: es2024) *](javascript.md#scope-shadowing) | [Запрет сокрытия локальных в охватывающем блоке (layer: language, profile: csharp12) *](csharp.md#scope-shadowing) | [Во вложенной области (layer: language, profile: rust2024); Новое связывание в той же области (layer: language, profile: rust2024) *](rust.md#scope-shadowing) |  |

### Правило разрешения имён { #scope-resolution }

*Name resolution*

Правило выбора связывания для конкретного вхождения имени. Лексическое разрешение использует структуру программы, динамическое — активные связывания в ходе выполнения.

[Пример, границы понятия и связи](glossary.md#scope-resolution)

- `lexical` — **Лексическое** (*lexical*)
- `dynamic` — **Динамическое** (*dynamic*): Например, special-переменные Common Lisp; не синоним динамической типизации.

<a id="variants-4"></a>

### Конструкции областей видимости { #scope-constructs }

*Scoping constructs*

Синтаксические конструкции, создающие области, внутри которых действуют определённые связывания имён и правила их видимости.

[Пример, границы понятия и связи](glossary.md#scope-constructs)

- `subprogram` — **Подпрограмма** (*subprogram*)
- `block` — **Блок** (*block*)
- `module` — **Модуль** (*module*)
- `class` — **Класс** (*class*)
- `comprehension` — **Генераторная конструкция** (*comprehension*)
- `binding_form` — **Форма связывания let/where** (*let/where binding form*)
- `clause` — **Логическая клауза** (*logic clause*)

<a id="req-8-2"></a>

### Связывания верхнего уровня { #scope-globals }

*Top-level bindings*

Формы доступности и организации связываний вне локального вызова — глобальная среда, пространство модуля или статические члены типа.

[Пример, границы понятия и связи](glossary.md#scope-globals)

- `globals` — **Глобальные переменные** (*global variables*)
- `module_bindings` — **Имена модуля** (*module bindings*)
- `static_members` — **Статические члены типов** (*static type members*)

<a id="syntax-shadowing"></a>

### Сокрытие имён { #scope-shadowing }

*Name shadowing*

Введение нового связывания с тем же именем, из-за которого часть вхождений перестаёт обозначать прежнее связывание.

[Пример, границы понятия и связи](glossary.md#scope-shadowing)

Повторное присваивание тому же имени в Python — перепривязка, а не shadowing.

- `allowed` — **Во вложенной области** (*nested-scope shadowing*)
- `forbidden_in_block` — **Запрет сокрытия локальных в охватывающем блоке** (*enclosing-local shadowing forbidden*)
- `allowed_same_scope` — **Новое связывание в той же области** (*new binding in the same scope*)

## Типизация { #typing }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Проверка типов](#typing-checking) | [Статическая (layer: language, profile: c17) *](c.md#typing-checking) | [Динамическая (layer: language, profile: iso) *](prolog.md#typing-checking) | [Статическая (layer: language, profile: cpp23)](cpp.md#typing-checking) | [Динамическая (layer: language, profile: ansi) *](common-lisp.md#typing-checking) | [Статическая (layer: language, profile: haskell2010) *](haskell.md#typing-checking) | [Динамическая (layer: language, profile: runtime); Постепенная (с Python 3.5 включительно, layer: tooling, profile: static_analysis) *](python.md#typing-checking) | [Статическая (layer: language, profile: java21)](java.md#typing-checking) | [Динамическая (layer: language, profile: es2024)](javascript.md#typing-checking) | [Статическая (layer: language, profile: csharp12); Динамическая (layer: language, profile: csharp12, applies_to: операции с dynamic) *](csharp.md#typing-checking) | [Статическая (layer: language, profile: rust2024)](rust.md#typing-checking) | [Статическая (layer: language, profile: ts5_strict); Динамическая (layer: language, profile: javascript_runtime) *](typescript.md#typing-checking) |
| [Аннотации типов](#typing-annotations) | [Обязательны (layer: language, profile: c17) *](c.md#typing-annotations) | [Отсутствуют (layer: language, profile: iso) *](prolog.md#typing-annotations) | [Необязательны (layer: language, profile: cpp23, applies_to: объявления с auto и выводимыми типами) *](cpp.md#typing-annotations) | [Необязательны (layer: language, profile: ansi) *](common-lisp.md#typing-annotations) | [Необязательны (layer: language, profile: haskell2010) *](haskell.md#typing-annotations) | [Необязательны (layer: language, profile: python314) *](python.md#typing-annotations) | [Обязательны (layer: language, profile: signatures); Необязательны (с Java SE 10 включительно, layer: language, profile: local_variables, applies_to: локальные переменные с инициализатором) *](java.md#typing-annotations) | [Отсутствуют (layer: language, profile: es2024) *](javascript.md#typing-annotations) | [Необязательны (layer: language, profile: csharp12, applies_to: локальные объявления с var и выводимые параметры лямбд) *](csharp.md#typing-annotations) | [Необязательны (layer: language, profile: locals); Обязательны (layer: language, profile: signatures)](rust.md#typing-annotations) | [Необязательны (layer: language, profile: ts5_strict) *](typescript.md#typing-annotations) |
| [Вывод статических типов](#typing-inference) | [нет (layer: language, profile: c17) *](c.md#typing-inference) | [нет (layer: language, profile: iso) *](prolog.md#typing-inference) | [да (layer: language, profile: cpp23) *](cpp.md#typing-inference) |  | [да (layer: language, profile: haskell2010) *](haskell.md#typing-inference) | [нет (layer: language, profile: runtime); да (layer: tooling, profile: static_analysis) *](python.md#typing-inference) | [да (с Java SE 10 включительно, layer: language, profile: local_variables, applies_to: локальные переменные с var); да (с Java SE 5 включительно, layer: language, profile: java21, applies_to: аргументы типов при вызове обобщённых методов); да (с Java SE 8 включительно, layer: language, profile: java21, applies_to: типы параметров лямбды из целевого функционального интерфейса) *](java.md#typing-inference) |  | [да (layer: language, profile: csharp12) *](csharp.md#typing-inference) | [да (layer: language, profile: locals) *](rust.md#typing-inference) | [да (layer: language, profile: ts5_strict) *](typescript.md#typing-inference) |
| [Преобразования типов](#typing-conversions) | [Неявные (layer: language, profile: c17); Явные (layer: language, profile: c17) *](c.md#typing-conversions) | [Явные (layer: language, profile: iso) *](prolog.md#typing-conversions) | [Неявные (layer: language, profile: cpp23); Явные (layer: language, profile: cpp23) *](cpp.md#typing-conversions) | [Явные (layer: language, profile: ansi); Неявные (layer: language, profile: ansi, applies_to: числовые операции) *](common-lisp.md#typing-conversions) | [Явные (layer: language, profile: haskell2010) *](haskell.md#typing-conversions) | [Явные (layer: language, profile: python314); Неявные (layer: language, profile: python314, applies_to: смешанная числовая арифметика) *](python.md#typing-conversions) | [Явные (layer: language, profile: java21); Неявные (layer: language, profile: java21, applies_to: расширяющие преобразования и boxing) *](java.md#typing-conversions) | [Неявные (layer: language, profile: es2024); Явные (layer: language, profile: es2024) *](javascript.md#typing-conversions) | [Неявные (layer: language, profile: csharp12); Явные (layer: language, profile: csharp12) *](csharp.md#typing-conversions) | [Явные (layer: language, profile: rust2024); Неявные (layer: language, profile: rust2024, applies_to: разрешённые позиции coercion) *](rust.md#typing-conversions) | [Явные (layer: language, profile: javascript_runtime); Неявные (layer: language, profile: javascript_runtime) *](typescript.md#typing-conversions) |
| [Совместимость типов](#typing-compatibility) |  |  | [Номинальная (layer: language, profile: cpp23, applies_to: типы классов и перечислений) *](cpp.md#typing-compatibility) |  | [Номинальная (layer: language, profile: haskell2010, applies_to: объявленные data/newtype) *](haskell.md#typing-compatibility) | [По доступным операциям во время выполнения (layer: language, profile: runtime); Номинальная (layer: tooling, profile: static_analysis, applies_to: обычные классы); Структурная (layer: tooling, profile: static_analysis, applies_to: typing.Protocol) *](python.md#typing-compatibility) | [Номинальная (layer: language, profile: java21)](java.md#typing-compatibility) | [По доступным операциям во время выполнения (layer: language, profile: es2024) *](javascript.md#typing-compatibility) | [Номинальная (layer: language, profile: csharp12, applies_to: классы, структуры и интерфейсы) *](csharp.md#typing-compatibility) | [Номинальная (layer: language, profile: rust2024, applies_to: struct, enum и явные реализации trait); Структурная (layer: language, profile: rust2024, applies_to: кортежи и типы указателей на функции) *](rust.md#typing-compatibility) | [Структурная (layer: language, profile: ts5_strict) *](typescript.md#typing-compatibility) |
| [Типы-суммы](#typing-sum-types) |  |  | [Размеченные варианты (layer: standard_library, profile: cpp23) *](cpp.md#typing-sum-types) |  | [Размеченные варианты (layer: language, profile: haskell2010) *](haskell.md#typing-sum-types) | [Объединения типов (layer: tooling, profile: static_analysis) *](python.md#typing-sum-types) | [Закрытая иерархия (с Java SE 17 включительно, layer: language, profile: java21, applies_to: sealed-иерархии) *](java.md#typing-sum-types) |  |  | [Размеченные варианты (layer: language, profile: rust2024) *](rust.md#typing-sum-types) | [Объединения типов (layer: language, profile: ts5_strict) *](typescript.md#typing-sum-types) |
| [Типы-произведения](#typing-product-types) | [Записи и структуры (layer: language, profile: c17) *](c.md#typing-product-types) |  | [Записи и структуры (layer: language, profile: cpp23); Кортежи (layer: standard_library, profile: cpp23) *](cpp.md#typing-product-types) | [Записи и структуры (layer: language, profile: ansi) *](common-lisp.md#typing-product-types) | [Кортежи (layer: language, profile: haskell2010); Записи и структуры (layer: language, profile: haskell2010) *](haskell.md#typing-product-types) | [Кортежи (layer: language, profile: python314)](python.md#typing-product-types) | [Записи и структуры (layer: language, profile: java21, applies_to: классы с полями; record-классы в Java 16 и новее) *](java.md#typing-product-types) |  | [Записи и структуры (layer: language, profile: csharp12); Кортежи (layer: language, profile: csharp12) *](csharp.md#typing-product-types) | [Кортежи (layer: language, profile: rust2024); Записи и структуры (layer: language, profile: rust2024)](rust.md#typing-product-types) | [Записи и структуры (layer: language, profile: ts5_strict); Кортежи (layer: language, profile: ts5_strict) *](typescript.md#typing-product-types) |
| [Представление отсутствия значения](#typing-nullability) | [Специальное значение (layer: language, profile: c17) *](c.md#typing-nullability) |  | [Специальное значение (layer: language, profile: cpp23); Тип Option/Optional (layer: standard_library, profile: cpp23) *](cpp.md#typing-nullability) | [Специальное значение (layer: language, profile: ansi) *](common-lisp.md#typing-nullability) | [Тип Option/Optional (layer: standard_library, profile: haskell2010) *](haskell.md#typing-nullability) | [Специальное значение (layer: language, profile: runtime); Явно nullable-типы (layer: tooling, profile: static_analysis) *](python.md#typing-nullability) | [Nullable-ссылки по умолчанию (layer: language, profile: java21); Тип Option/Optional (с Java SE 8 включительно, layer: standard_library, profile: java21) *](java.md#typing-nullability) | [Специальное значение (layer: language, profile: es2024) *](javascript.md#typing-nullability) | [Явно nullable-типы (layer: language, profile: csharp12) *](csharp.md#typing-nullability) | [Тип Option/Optional (layer: standard_library, profile: safe) *](rust.md#typing-nullability) | [Явно nullable-типы (layer: language, profile: ts5_strict) *](typescript.md#typing-nullability) |
| [Зависимость типа от значения](#typing-value-dependency) |  |  |  |  |  |  |  |  |  |  |  |
| [Идентичность абстрактных типов модулей](#typing-abstract-type-identity) |  |  |  |  |  |  |  |  |  |  |  |

### Проверка типов { #typing-checking }

*Type checking* · также: статическая типизация, динамическая типизация

Проверка допустимости операций и сочетаний значений по правилам типов. Статическая выполняется до соответствующего выполнения программы, динамическая — при выполнении; gradual-система описывает взаимодействие статически и динамически типизированных частей.

[Пример, границы понятия и связи](glossary.md#typing-checking)

- `static` — **Статическая** (*static*)
- `dynamic` — **Динамическая** (*dynamic*)
- `gradual` — **Постепенная** (*gradual*): Статически типизированные и динамические части; для внешнего анализатора указывается layer tooling.

### Аннотации типов { #typing-annotations }

*Type annotations*

Записанная автором программы информация о типе выражения, связывания, параметра или результата. Роль аннотации зависит от языка и проверяющего инструмента.

[Пример, границы понятия и связи](glossary.md#typing-annotations)

- `required` — **Обязательны** (*required*)
- `optional` — **Необязательны** (*optional*)
- `absent` — **Отсутствуют** (*absent*)

### Вывод статических типов { #typing-inference }

*Static type inference*

Выведение статического типа из структуры программы, ограничений и контекста без полной записи типа программистом.

[Пример, границы понятия и связи](glossary.md#typing-inference)

- да / нет

<a id="variants-2"></a>
<a id="typing-strength"></a>

### Преобразования типов { #typing-conversions }

*Type conversions*

Правила перехода от значения или представления одного типа к другому, явно запрошенного или вставленного неявно. Преобразование может требовать вычисления, проверки и сопровождаться потерей информации.

[Пример, границы понятия и связи](glossary.md#typing-conversions)

Ось заменяет неоднозначное деление strong/weak; допустимость и потери описываются в контексте.

- `explicit` — **Явные** (*explicit*)
- `implicit` — **Неявные** (*implicit coercions*)

### Совместимость типов { #typing-compatibility }

*Type compatibility*

Условия, при которых значение или выражение допустимо использовать там, где требуется определённый тип или набор операций. Основанием могут быть имена типов, структура или фактически поддержанные операции.

[Пример, границы понятия и связи](glossary.md#typing-compatibility)

- `nominal` — **Номинальная** (*nominal*)
- `structural` — **Структурная** (*structural*)
- `duck` — **По доступным операциям во время выполнения** (*runtime duck typing*)

### Типы-суммы { #typing-sum-types }

*Sum types*

Описание значения как одной из альтернатив типов или вариантов. Конкретная система определяет, как альтернативы различаются, пересекаются и проверяются при использовании.

[Пример, границы понятия и связи](glossary.md#typing-sum-types)

- `tagged` — **Размеченные варианты** (*tagged variants*)
- `union` — **Объединения типов** (*type unions*)
- `closed_hierarchy` — **Закрытая иерархия** (*closed hierarchy*)

### Типы-произведения { #typing-product-types }

*Product types*

Составной тип, значение которого содержит компоненты всех заданных типов одновременно; позиции или имена различают компоненты.

[Пример, границы понятия и связи](glossary.md#typing-product-types)

- `tuple` — **Кортежи** (*tuples*)
- `record` — **Записи и структуры** (*records and structs*)

### Представление отсутствия значения { #typing-nullability }

*Absence of a value*

Способ выразить отсутствие полезного значения и ограничить места, где такое отсутствие допустимо: специальное значение, nullable-тип либо явная обёртка с вариантами.

[Пример, границы понятия и связи](glossary.md#typing-nullability)

- `nullable_everywhere` — **Nullable-ссылки по умолчанию** (*nullable references by default*)
- `optional_type` — **Тип Option/Optional** (*option type*)
- `nullable_types` — **Явно nullable-типы** (*explicitly nullable types*)
- `sentinel` — **Специальное значение** (*sentinel value*): Например, None; его допустимость зависит от операции.

### Зависимость типа от значения { #typing-value-dependency }

*Value-dependent types*

Зависимость структуры типа от значения параметра, позволяющая выражать отношения между данными в типе функции или семейства типов.

[Пример, границы понятия и связи](glossary.md#typing-value-dependency)

Тип может зависеть от значения параметра: Vect n a связывает длину с n, в отличие от параметризации только типом a. Зависимые пары связывают тип второго компонента со значением первого. Проверка типов сама по себе не гарантирует тотальность.

Источники определения: [Idris 2 — Types and Functions: Vect, Fin, dependent pairs](https://idris2.readthedocs.io/en/latest/tutorial/typesfuns.html)

- `indexed_families` — **Семейства типов с индексами-значениями** (*value-indexed type families*)
- `dependent_functions` — **Зависимые типы функций** (*dependent function types*)
- `dependent_pairs` — **Зависимые пары** (*dependent pairs*)

### Идентичность абстрактных типов модулей { #typing-abstract-type-identity }

*Abstract module type identity*

Правила сохранения или создания идентичности типового компонента при абстракции модулей и скрытии его представления.

[Пример, границы понятия и связи](glossary.md#typing-abstract-type-identity)

Прозрачное сопоставление сигнатуре сохраняет известные равенства типов; opaque sealing скрывает представление абстрактных компонентов. В SML '97 применение functor с opaque result signature создаёт свежие абстрактные типы. Это не свойство каждого type alias и не синоним nominal/structural compatibility.

Источники определения: [SML '97 Modules — signatures and §1.3.9 opaque result signatures](https://www.smlnj.org/doc/Conversion/modules.html)

- `transparent` — **Сохранение равенств типов представления** (*transparent type equality*)
- `opaque_fresh` — **Свежая идентичность скрытого абстрактного типа** (*fresh opaque abstract identity*)

## Управление потоком { #control }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Условный выбор](#control-selection) | [Условный оператор (layer: language, profile: c17); Условное выражение (layer: language, profile: c17) *](c.md#control-selection) |  | [Условный оператор (layer: language, profile: cpp23); Условное выражение (layer: language, profile: cpp23) *](cpp.md#control-selection) | [Условное выражение (layer: language, profile: ansi) *](common-lisp.md#control-selection) | [Условное выражение (layer: language, profile: haskell2010); Охранные условия (layer: language, profile: haskell2010) *](haskell.md#control-selection) | [Условный оператор (layer: language, profile: python314); Условное выражение (layer: language, profile: python314) *](python.md#control-selection) | [Условный оператор (layer: language, profile: java21); Условное выражение (layer: language, profile: java21) *](java.md#control-selection) | [Условный оператор (layer: language, profile: es2024); Условное выражение (layer: language, profile: es2024) *](javascript.md#control-selection) | [Условный оператор (layer: language, profile: csharp12); Условное выражение (layer: language, profile: csharp12) *](csharp.md#control-selection) | [Условное выражение (layer: language, profile: rust2024) *](rust.md#control-selection) | [Условный оператор (layer: language, profile: ts5_strict); Условное выражение (layer: language, profile: ts5_strict) *](typescript.md#control-selection) |
| [Выбор по значению switch/case](#control-switch) | [да (layer: language, profile: c17) *](c.md#control-switch) | [нет (layer: language, profile: iso) *](prolog.md#control-switch) | [да (layer: language, profile: cpp23)](cpp.md#control-switch) | [да (layer: language, profile: ansi) *](common-lisp.md#control-switch) | [нет (layer: language, profile: haskell2010) *](haskell.md#control-switch) | [нет (layer: language, profile: python314)](python.md#control-switch) | [да (layer: language, profile: java21) *](java.md#control-switch) | [да (layer: language, profile: es2024) *](javascript.md#control-switch) | [да (layer: language, profile: csharp12) *](csharp.md#control-switch) | [нет (layer: language, profile: rust2024)](rust.md#control-switch) | [да (layer: language, profile: ts5_strict) *](typescript.md#control-switch) |
| [Сопоставление с образцом](#control-pattern-matching) | [нет (layer: language, profile: c17)](c.md#control-pattern-matching) |  |  |  | [да (layer: language, profile: haskell2010) *](haskell.md#control-pattern-matching) | [нет (до Python 3.10 исключительно, layer: language, profile: python314); да (с Python 3.10 включительно, layer: language, profile: python314) *](python.md#control-pattern-matching) | [да (с Java SE 21 включительно, layer: language, profile: java21, applies_to: record patterns) *](java.md#control-pattern-matching) | [нет (layer: language, profile: es2024) *](javascript.md#control-pattern-matching) | [да (layer: language, profile: csharp12) *](csharp.md#control-pattern-matching) | [да (layer: language, profile: rust2024)](rust.md#control-pattern-matching) | [нет (layer: language, profile: ts5_strict) *](typescript.md#control-pattern-matching) |
| [Цикл до истинности условия](#control-until) |  |  |  | [Проверка перед телом (layer: language, profile: ansi, applies_to: loop с until перед основным действием); Проверка после тела (layer: language, profile: ansi, applies_to: loop с until после основного действия) *](common-lisp.md#control-until) | [Отдельная конструкция отсутствует (layer: language, profile: haskell2010) *](haskell.md#control-until) | [Отдельная конструкция отсутствует (layer: language, profile: python314) *](python.md#control-until) | [Отдельная конструкция отсутствует (layer: language, profile: java21) *](java.md#control-until) |  |  | [Отдельная конструкция отсутствует (layer: language, profile: rust2024) *](rust.md#control-until) |  |
| [Цикл do-while с постусловием](#control-do-while) | [да (layer: language, profile: c17)](c.md#control-do-while) | [нет (layer: language, profile: iso) *](prolog.md#control-do-while) |  |  |  | [нет (layer: language, profile: python314) *](python.md#control-do-while) | [да (layer: language, profile: java21)](java.md#control-do-while) | [да (layer: language, profile: es2024)](javascript.md#control-do-while) |  | [нет (layer: language, profile: rust2024) *](rust.md#control-do-while) |  |
| [Формы итерации](#control-iteration) | [Инициализация / условие / шаг (layer: language, profile: c17) *](c.md#control-iteration) |  | [Инициализация / условие / шаг (layer: language, profile: cpp23); По последовательности или итератору (layer: language, profile: cpp23) *](cpp.md#control-iteration) | [По последовательности или итератору (layer: language, profile: ansi); Функции обхода (layer: language, profile: ansi) *](common-lisp.md#control-iteration) | [Генераторная конструкция (layer: language, profile: haskell2010); Функции обхода (layer: standard_library, profile: haskell2010) *](haskell.md#control-iteration) | [По последовательности или итератору (layer: language, profile: python314); Генераторная конструкция (layer: language, profile: python314) *](python.md#control-iteration) | [Инициализация / условие / шаг (layer: language, profile: java21); По последовательности или итератору (с Java SE 5 включительно, layer: language, profile: java21) *](java.md#control-iteration) | [Инициализация / условие / шаг (layer: language, profile: es2024); По последовательности или итератору (layer: language, profile: es2024); Функции обхода (layer: standard_library, profile: es2024) *](javascript.md#control-iteration) | [Инициализация / условие / шаг (layer: language, profile: csharp12); По последовательности или итератору (layer: language, profile: csharp12) *](csharp.md#control-iteration) | [По последовательности или итератору (layer: language, profile: rust2024) *](rust.md#control-iteration) | [Инициализация / условие / шаг (layer: language, profile: ts5_strict); По последовательности или итератору (layer: language, profile: ts5_strict) *](typescript.md#control-iteration) |
| [Логический поиск решений](#control-logic-search) |  | [Поиск с возвратом (layer: language, profile: iso); Табулирование подцелей (layer: implementation, profile: swi, implementation: SWI-Prolog); Распространение ограничений (layer: implementation, profile: swi, implementation: SWI-Prolog, applies_to: library(clpfd)) *](prolog.md#control-logic-search) |  |  |  |  |  |  |  |  |  |
| [Граница захвата продолжения](#control-continuation-extent) |  |  |  |  |  |  |  |  |  |  |  |

<a id="variants-6"></a>

### Условный выбор { #control-selection }

*Conditional selection*

Выбор ветви вычисления по условию или условиям. Выбор может быть оператором, выражением со значением или набором охранных условий.

[Пример, границы понятия и связи](glossary.md#control-selection)

- `statement` — **Условный оператор** (*conditional statement*)
- `expression` — **Условное выражение** (*conditional expression*)
- `guards` — **Охранные условия** (*guards*)

### Выбор по значению switch/case { #control-switch }

*Switch/case value selection*

Специализированный многовариантный выбор по проверяемому значению и меткам вариантов, с правилами совпадения и переходов конкретного языка.

[Пример, границы понятия и связи](glossary.md#control-switch)

Учитывается отдельная конструкция switch/case, не любая цепочка условий или match.

- да / нет

### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching*

Сопоставление значения с описанием допустимой формы, литерала или конструктора с возможным извлечением частей и связыванием имён.

[Пример, границы понятия и связи](glossary.md#control-pattern-matching)

- да / нет

<a id="req-7-2-until"></a>

### Цикл до истинности условия { #control-until }

*Until loop*

Повторение до истинности условия остановки. Проверка перед телом допускает ноль выполнений, после тела — требует хотя бы одного.

[Пример, границы понятия и связи](glossary.md#control-until)

Отрицательная полярность условия не определяет момент проверки. Имитирующий код не означает наличие конструкции.

- `pre_test` — **Проверка перед телом** (*pre-test until*)
- `post_test` — **Проверка после тела** (*post-test repeat-until*)
- `absent` — **Отдельная конструкция отсутствует** (*no dedicated until construct*)

<a id="req-7-2-do-while"></a>

### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop*

Конструкция цикла, сначала выполняющая тело и затем проверяющая условие продолжения для следующей итерации.

[Пример, границы понятия и связи](glossary.md#control-do-while)

- да / нет

<a id="req-7-3"></a>

### Формы итерации { #control-iteration }

*Iteration forms*

Способ систематически повторять вычисление — по условию и шагу, элементам последовательности, через генераторную конструкцию или функцию обхода.

[Пример, границы понятия и связи](glossary.md#control-iteration)

- `c_style` — **Инициализация / условие / шаг** (*C-style loop*)
- `foreach` — **По последовательности или итератору** (*foreach*)
- `comprehension` — **Генераторная конструкция** (*comprehension*)
- `higher_order` — **Функции обхода** (*higher-order traversal*)

### Логический поиск решений { #control-logic-search }

*Logic search*

Механизмы построения решений логических целей — перебор альтернатив с возвратом, сохранение результатов подцелей или распространение ограничений.

[Пример, границы понятия и связи](glossary.md#control-logic-search)

- `backtracking` — **Поиск с возвратом** (*backtracking*)
- `tabling` — **Табулирование подцелей** (*tabling*)
- `constraints` — **Распространение ограничений** (*constraint propagation*)

### Граница захвата продолжения { #control-continuation-extent }

*Continuation capture boundary*

Граница контекста вычисления, представленного захваченным продолжением: весь текущий остаток вычисления либо его часть до ограничителя.

[Пример, границы понятия и связи](glossary.md#control-continuation-extent)

Продолжение представляет оставшийся контекст вычисления, а не только окружение замыкания. Undelimited захватывает полный текущий контекст; delimited — часть до заданной границы (prompt). Время жизни, escape-only и число допустимых возобновлений указываются отдельно в контексте: R7RS call/cc допускает сохранение и повторные вызовы, но это не определение границы захвата.

Источники определения: [Scheme R7RS-small §6.10 — call-with-current-continuation](https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-8.html); [Racket Reference §10.4 — prompts and delimited continuations](https://docs.racket-lang.org/reference/cont.html)

- `undelimited` — **Полное продолжение** (*undelimited continuation*)
- `delimited` — **Продолжение до ограничителя** (*delimited continuation*)

## Подпрограммы и абстракция { #subprograms }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Перегрузка по сигнатуре](#subprograms-overloading) | [нет (layer: language, profile: c17) *](c.md#subprograms-overloading) | [нет (layer: language, profile: iso) *](prolog.md#subprograms-overloading) | [да (layer: language, profile: cpp23) *](cpp.md#subprograms-overloading) | [нет (layer: language, profile: ansi) *](common-lisp.md#subprograms-overloading) | [нет (layer: language, profile: haskell2010, applies_to: перегрузка отдельных функций по сигнатурам) *](haskell.md#subprograms-overloading) | [нет (layer: language, profile: python314) *](python.md#subprograms-overloading) | [да (layer: language, profile: java21) *](java.md#subprograms-overloading) | [нет (layer: language, profile: es2024) *](javascript.md#subprograms-overloading) | [да (layer: language, profile: csharp12) *](csharp.md#subprograms-overloading) | [нет (layer: language, profile: rust2024) *](rust.md#subprograms-overloading) | [да (layer: language, profile: ts5_strict) *](typescript.md#subprograms-overloading) |
| [Связывание параметров](#subprograms-parameter-passing) | [По значению (layer: language, profile: c17) *](c.md#subprograms-parameter-passing) | [Унификация аргументов с термами головы (layer: language, profile: iso) *](prolog.md#subprograms-parameter-passing) | [По значению (layer: language, profile: cpp23); По ссылке на переменную (layer: language, profile: cpp23) *](cpp.md#subprograms-parameter-passing) | [Разделение объекта (layer: language, profile: ansi) *](common-lisp.md#subprograms-parameter-passing) | [По необходимости с мемоизацией (layer: implementation, profile: ghc, implementation: GHC) *](haskell.md#subprograms-parameter-passing) | [Разделение объекта (layer: language, profile: python314) *](python.md#subprograms-parameter-passing) | [По значению (layer: language, profile: java21, applies_to: примитивные и ссылочные типы) *](java.md#subprograms-parameter-passing) | [По значению (layer: language, profile: es2024, applies_to: значения аргументов); Разделение объекта (layer: language, profile: es2024, applies_to: объектные значения) *](javascript.md#subprograms-parameter-passing) | [По значению (layer: language, profile: csharp12); По ссылке на переменную (layer: language, profile: csharp12) *](csharp.md#subprograms-parameter-passing) | [По значению (layer: language, profile: rust2024) *](rust.md#subprograms-parameter-passing) | [По значению (layer: language, profile: ts5_strict); Разделение объекта (layer: language, profile: ts5_strict, applies_to: объекты JavaScript) *](typescript.md#subprograms-parameter-passing) |
| [Место определения подпрограмм](#subprograms-placement) | [Выделенная область объявлений (layer: language, profile: c17) *](c.md#subprograms-placement) | [Выделенная область объявлений (layer: language, profile: iso); Верхний уровень модуля (layer: implementation, profile: swi, implementation: SWI-Prolog) *](prolog.md#subprograms-placement) |  | [Локальное определение (layer: language, profile: ansi) *](common-lisp.md#subprograms-placement) |  | [Верхний уровень модуля (layer: language, profile: python314); Член типа (layer: language, profile: python314); Локальное определение (layer: language, profile: python314) *](python.md#subprograms-placement) | [Член типа (layer: language, profile: java21) *](java.md#subprograms-placement) |  |  | [Верхний уровень модуля (layer: language, profile: rust2024); Член типа (layer: language, profile: rust2024); Локальное определение (layer: language, profile: rust2024) *](rust.md#subprograms-placement) |  |
| [Вложенные именованные подпрограммы](#subprograms-nesting) | [нет (layer: language, profile: c17) *](c.md#subprograms-nesting) | [нет (layer: language, profile: iso) *](prolog.md#subprograms-nesting) | [нет (layer: language, profile: cpp23) *](cpp.md#subprograms-nesting) | [да (layer: language, profile: ansi) *](common-lisp.md#subprograms-nesting) | [да (layer: language, profile: haskell2010) *](haskell.md#subprograms-nesting) | [да (layer: language, profile: python314)](python.md#subprograms-nesting) | [нет (layer: language, profile: java21)](java.md#subprograms-nesting) | [да (layer: language, profile: es2024)](javascript.md#subprograms-nesting) | [да (layer: language, profile: csharp12) *](csharp.md#subprograms-nesting) | [да (layer: language, profile: rust2024)](rust.md#subprograms-nesting) | [да (layer: language, profile: ts5_strict)](typescript.md#subprograms-nesting) |
| [Захват окружения](#subprograms-closures) | [нет (layer: language, profile: c17) *](c.md#subprograms-closures) |  | [да (layer: language, profile: cpp23) *](cpp.md#subprograms-closures) | [да (layer: language, profile: ansi) *](common-lisp.md#subprograms-closures) | [да (layer: language, profile: haskell2010) *](haskell.md#subprograms-closures) | [да (layer: language, profile: python314)](python.md#subprograms-closures) | [да (с Java SE 8 включительно, layer: language, profile: java21, applies_to: лямбды) *](java.md#subprograms-closures) | [да (layer: language, profile: es2024) *](javascript.md#subprograms-closures) | [да (layer: language, profile: csharp12) *](csharp.md#subprograms-closures) | [да (layer: language, profile: rust2024)](rust.md#subprograms-closures) | [да (layer: language, profile: ts5_strict)](typescript.md#subprograms-closures) |
| [Анонимные функции](#subprograms-lambda) | [нет (layer: language, profile: c17)](c.md#subprograms-lambda) | [нет (layer: language, profile: iso) *](prolog.md#subprograms-lambda) | [да (layer: language, profile: cpp23)](cpp.md#subprograms-lambda) | [да (layer: language, profile: ansi)](common-lisp.md#subprograms-lambda) | [да (layer: language, profile: haskell2010)](haskell.md#subprograms-lambda) | [да (layer: language, profile: python314) *](python.md#subprograms-lambda) | [да (с Java SE 8 включительно, layer: language, profile: java21) *](java.md#subprograms-lambda) | [да (layer: language, profile: es2024) *](javascript.md#subprograms-lambda) | [да (layer: language, profile: csharp12)](csharp.md#subprograms-lambda) | [да (layer: language, profile: rust2024) *](rust.md#subprograms-lambda) | [да (layer: language, profile: ts5_strict)](typescript.md#subprograms-lambda) |
| [Параметрический полиморфизм](#subprograms-generics) |  |  | [да (layer: language, profile: cpp23) *](cpp.md#subprograms-generics) |  | [да (layer: language, profile: haskell2010) *](haskell.md#subprograms-generics) | [да (с Python 3.5 включительно, layer: tooling, profile: static_analysis) *](python.md#subprograms-generics) | [да (с Java SE 5 включительно, layer: language, profile: java21) *](java.md#subprograms-generics) |  | [да (layer: language, profile: csharp12) *](csharp.md#subprograms-generics) | [да (layer: language, profile: rust2024) *](rust.md#subprograms-generics) | [да (layer: language, profile: ts5_strict) *](typescript.md#subprograms-generics) |
| [Реализация параметрического полиморфизма](#subprograms-generic-mechanism) |  |  |  |  |  |  | [Стирание типов (с Java SE 5 включительно, layer: language, profile: java21)](java.md#subprograms-generic-mechanism) |  | [Параметры типов во время выполнения (layer: implementation, profile: dotnet8, implementation: .NET 8 / CLR) *](csharp.md#subprograms-generic-mechanism) | [Мономорфизация (layer: implementation, profile: rust2024, implementation: rustc)](rust.md#subprograms-generic-mechanism) | [Стирание типов (layer: language, profile: ts5_strict) *](typescript.md#subprograms-generic-mechanism) |
| [Аргументы по умолчанию](#subprograms-default-args) |  |  |  | [да (layer: language, profile: ansi) *](common-lisp.md#subprograms-default-args) |  | [да (layer: language, profile: python314) *](python.md#subprograms-default-args) | [нет (layer: language, profile: java21) *](java.md#subprograms-default-args) | [да (layer: language, profile: es2024) *](javascript.md#subprograms-default-args) |  | [нет (layer: language, profile: rust2024) *](rust.md#subprograms-default-args) |  |
| [Именованные аргументы](#subprograms-named-args) |  |  |  | [да (layer: language, profile: ansi) *](common-lisp.md#subprograms-named-args) |  | [да (layer: language, profile: python314)](python.md#subprograms-named-args) | [нет (layer: language, profile: java21) *](java.md#subprograms-named-args) |  |  | [нет (layer: language, profile: rust2024) *](rust.md#subprograms-named-args) |  |

<a id="variants-7"></a>

### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading*

Использование одного имени для нескольких сигнатур подпрограмм с выбором применимой сигнатуры по правилам языка и контексту вызова.

[Пример, границы понятия и связи](glossary.md#subprograms-overloading)

- да / нет

<a id="variants-8"></a>

### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing*

Правила связывания фактических аргументов с формальными параметрами, определяющие доступ к значениям, переменным вызывающей стороны или отложенным вычислениям.

[Пример, границы понятия и связи](glossary.md#subprograms-parameter-passing)

Передача значения отделена от переноса владения; ссылка сама может передаваться по значению.

- `by_value` — **По значению** (*by value*)
- `by_reference` — **По ссылке на переменную** (*by reference*)
- `by_result` — **Копирование результата при возврате** (*copy out*)
- `by_value_result` — **Копирование входа и результата** (*copy in/copy out*)
- `by_sharing` — **Разделение объекта** (*call by sharing*)
- `by_name` — **По имени** (*by name*)
- `by_need` — **По необходимости с мемоизацией** (*by need*)
- `unification` — **Унификация аргументов с термами головы** (*head-argument unification*)

<a id="variants-9"></a>

### Место определения подпрограмм { #subprograms-placement }

*Subprogram definition placement*

Допустимые структурные места определения подпрограммы в программе: верхний уровень, выделенная область объявлений, член типа или локальная область.

[Пример, границы понятия и связи](glossary.md#subprograms-placement)

- `declaration_region` — **Выделенная область объявлений** (*declaration region*)
- `module` — **Верхний уровень модуля** (*module level*)
- `type_member` — **Член типа** (*type member*)
- `local` — **Локальное определение** (*local definition*)

### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms*

Возможность определять именованную подпрограмму внутри области другой подпрограммы или локальной связывающей конструкции.

[Пример, границы понятия и связи](glossary.md#subprograms-nesting)

- да / нет

### Захват окружения { #subprograms-closures }

*Closure capture*

Сохранение функции вместе с доступом к необходимым связываниям окружающей лексической среды. Способ захвата значений, переменных и владения определяется языком.

[Пример, границы понятия и связи](glossary.md#subprograms-closures)

- да / нет

### Анонимные функции { #subprograms-lambda }

*Anonymous functions*

Конструкция создания функции как выражения без обязательного отдельного именованного определения.

[Пример, границы понятия и связи](glossary.md#subprograms-lambda)

- да / нет

### Параметрический полиморфизм { #subprograms-generics }

*Parametric polymorphism*

Параметризация типов или подпрограмм типовыми параметрами, позволяющая описать семейство применений без отдельной ручной реализации для каждого конкретного типа.

[Пример, границы понятия и связи](glossary.md#subprograms-generics)

- да / нет

### Реализация параметрического полиморфизма { #subprograms-generic-mechanism }

*Generic implementation mechanism*

Механизмы реализации обобщённого кода и его ограничений — специализированные экземпляры, стирание параметров, их сохранение во время исполнения или передача наборов операций.

[Пример, границы понятия и связи](glossary.md#subprograms-generic-mechanism)

- `erasure` — **Стирание типов** (*type erasure*)
- `monomorphization` — **Мономорфизация** (*monomorphization*)
- `reification` — **Параметры типов во время выполнения** (*reified type parameters*)
- `dictionary_passing` — **Передача словарей операций** (*dictionary passing*)

### Аргументы по умолчанию { #subprograms-default-args }

*Default arguments*

Правила получения аргумента, который вызывающий код не передал явно, из заданного определения или выражения по умолчанию.

[Пример, границы понятия и связи](glossary.md#subprograms-default-args)

- да / нет

### Именованные аргументы { #subprograms-named-args }

*Named arguments*

Сопоставление фактического аргумента с параметром по имени, а не только по позиции в списке вызова.

[Пример, границы понятия и связи](glossary.md#subprograms-named-args)

- да / нет

## Полиморфизм и организация { #abstraction }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Контракты полиморфизма](#abstraction-contracts) |  |  |  |  | [Классы типов (layer: language, profile: haskell2010) *](haskell.md#abstraction-contracts) | [Структурные протоколы (layer: tooling, profile: static_analysis, applies_to: typing.Protocol) *](python.md#abstraction-contracts) | [Интерфейсы (layer: language, profile: java21)](java.md#abstraction-contracts) |  | [Интерфейсы (layer: language, profile: csharp12) *](csharp.md#abstraction-contracts) | [Трейты (layer: language, profile: rust2024)](rust.md#abstraction-contracts) | [Интерфейсы (layer: language, profile: ts5_strict) *](typescript.md#abstraction-contracts) |
| [Диспетчеризация вызовов](#abstraction-dispatch) |  |  | [Статическая (layer: language, profile: cpp23); По одному динамическому типу (layer: language, profile: cpp23) *](cpp.md#abstraction-dispatch) | [По нескольким динамическим типам (layer: language, profile: ansi) *](common-lisp.md#abstraction-dispatch) |  | [По одному динамическому типу (layer: language, profile: python314, applies_to: поиск метода по классу получателя); По одному динамическому типу (layer: standard_library, profile: python314, applies_to: functools.singledispatch по первому аргументу) *](python.md#abstraction-dispatch) | [Статическая (layer: language, profile: java21, applies_to: статические методы и выбор перегрузки); По одному динамическому типу (layer: language, profile: java21, applies_to: переопределяемые методы экземпляра) *](java.md#abstraction-dispatch) |  | [Статическая (layer: language, profile: csharp12); По одному динамическому типу (layer: language, profile: csharp12, applies_to: виртуальные экземплярные методы) *](csharp.md#abstraction-dispatch) | [Статическая (layer: language, profile: rust2024, applies_to: обобщённые функции с ограничениями trait); По одному динамическому типу (layer: language, profile: rust2024, applies_to: вызовы через dyn Trait) *](rust.md#abstraction-dispatch) |  |
| [Наследование реализации](#abstraction-inheritance) |  |  | [Множественное (layer: language, profile: cpp23) *](cpp.md#abstraction-inheritance) | [Множественное (layer: language, profile: ansi) *](common-lisp.md#abstraction-inheritance) |  | [Множественное (layer: language, profile: python314)](python.md#abstraction-inheritance) | [Одиночное (layer: language, profile: java21) *](java.md#abstraction-inheritance) | [Одиночное (layer: language, profile: es2024) *](javascript.md#abstraction-inheritance) | [Одиночное (layer: language, profile: csharp12) *](csharp.md#abstraction-inheritance) | [Отсутствует (layer: language, profile: rust2024) *](rust.md#abstraction-inheritance) | [Одиночное (layer: language, profile: ts5_strict) *](typescript.md#abstraction-inheritance) |
| [Модульность](#abstraction-modules) | [Текстовое включение (layer: language, profile: c17) *](c.md#abstraction-modules) | [Явная граница экспорта (layer: implementation, profile: swi, implementation: SWI-Prolog) *](prolog.md#abstraction-modules) | [Текстовое включение (layer: language, profile: cpp23); Пространства имён и пакеты (layer: language, profile: cpp23); Явная граница экспорта (layer: language, profile: cpp23) *](cpp.md#abstraction-modules) | [Пространства имён и пакеты (layer: language, profile: ansi) *](common-lisp.md#abstraction-modules) | [Явная граница экспорта (layer: language, profile: haskell2010) *](haskell.md#abstraction-modules) | [Пространства имён и пакеты (layer: language, profile: python314); Модули как объекты времени выполнения (layer: language, profile: python314)](python.md#abstraction-modules) | [Пространства имён и пакеты (layer: language, profile: java21); Явная граница экспорта (с Java SE 9 включительно, layer: language, profile: java21, applies_to: модульная система Java) *](java.md#abstraction-modules) | [Явная граница экспорта (layer: language, profile: es2024) *](javascript.md#abstraction-modules) | [Пространства имён и пакеты (layer: language, profile: csharp12) *](csharp.md#abstraction-modules) | [Пространства имён и пакеты (layer: language, profile: rust2024); Явная граница экспорта (layer: language, profile: rust2024) *](rust.md#abstraction-modules) | [Явная граница экспорта (layer: language, profile: ts5_strict) *](typescript.md#abstraction-modules) |

### Контракты полиморфизма { #abstraction-contracts }

*Polymorphic contracts*

Требования к доступным операциям типа или значения, через которые код использует разные реализации единообразно: интерфейсы, traits, type classes или протоколы.

[Пример, границы понятия и связи](glossary.md#abstraction-contracts)

- `interfaces` — **Интерфейсы** (*interfaces*)
- `traits` — **Трейты** (*traits*)
- `type_classes` — **Классы типов** (*type classes*)
- `protocols` — **Структурные протоколы** (*structural protocols*)

### Диспетчеризация вызовов { #abstraction-dispatch }

*Call dispatch*

Выбор реализации вызываемой операции по статической информации или динамическим характеристикам одного либо нескольких аргументов.

[Пример, границы понятия и связи](glossary.md#abstraction-dispatch)

- `static` — **Статическая** (*static dispatch*)
- `single` — **По одному динамическому типу** (*single dispatch*)
- `multiple` — **По нескольким динамическим типам** (*multiple dispatch*)

### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance*

Получение реализации или состояния типа из одного либо нескольких родительских типов с правилами дополнения и переопределения.

[Пример, границы понятия и связи](glossary.md#abstraction-inheritance)

- `single` — **Одиночное** (*single*)
- `multiple` — **Множественное** (*multiple*)
- `absent` — **Отсутствует** (*absent*)

### Модульность { #abstraction-modules }

*Modules*

Организация программы в единицы с контролируемыми именами, зависимостями и границами использования; конкретный механизм определяет импорт, экспорт и параметризацию.

[Пример, границы понятия и связи](glossary.md#abstraction-modules)

- `textual_inclusion` — **Текстовое включение** (*textual inclusion*)
- `namespaces` — **Пространства имён и пакеты** (*namespaces and packages*)
- `explicit_exports` — **Явная граница экспорта** (*explicit export boundary*)
- `runtime_modules` — **Модули как объекты времени выполнения** (*runtime module objects*)
- `module_functors` — **Параметризация модулей модулями** (*module functors*): SML functor принимает структуру по сигнатуре, включая типовые компоненты, и строит структуру-результат. Это не generic function; скрытие и идентичность типов описывает typing.abstract_type_identity. — [SML '97 Modules — structures, signatures and functors](https://www.smlnj.org/doc/Conversion/modules.html)

## Вычисление и эффекты { #evaluation }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Стратегия вычисления](#evaluation-strategy) | [Строгая (layer: language, profile: c17) *](c.md#evaluation-strategy) |  | [Строгая (layer: language, profile: cpp23) *](cpp.md#evaluation-strategy) | [Строгая (layer: language, profile: ansi, applies_to: обычные вызовы функций) *](common-lisp.md#evaluation-strategy) | [Нестрогая (layer: language, profile: haskell2010) *](haskell.md#evaluation-strategy) | [Строгая (layer: language, profile: python314) *](python.md#evaluation-strategy) | [Строгая (layer: language, profile: java21)](java.md#evaluation-strategy) | [Строгая (layer: language, profile: es2024) *](javascript.md#evaluation-strategy) | [Строгая (layer: language, profile: csharp12) *](csharp.md#evaluation-strategy) | [Строгая (layer: language, profile: rust2024)](rust.md#evaluation-strategy) | [Строгая (layer: language, profile: ts5_strict) *](typescript.md#evaluation-strategy) |
| [Контроль эффектов](#evaluation-effects) |  | [Без общего статического разделения эффектов (layer: language, profile: iso) *](prolog.md#evaluation-effects) |  |  | [Эффекты отражены в типах (layer: language, profile: haskell2010) *](haskell.md#evaluation-effects) | [Без общего статического разделения эффектов (layer: language, profile: python314)](python.md#evaluation-effects) | [Без общего статического разделения эффектов (layer: language, profile: java21) *](java.md#evaluation-effects) |  |  | [Без общего статического разделения эффектов (layer: language, profile: rust2024) *](rust.md#evaluation-effects) |  |
| [Гарантированное устранение хвостовых вызовов](#evaluation-tail-calls) |  |  |  |  |  | [нет (layer: language, profile: python314)](python.md#evaluation-tail-calls) | [нет (layer: language, profile: java21)](java.md#evaluation-tail-calls) | [да (layer: language, profile: strict); нет (layer: language, profile: sloppy) *](javascript.md#evaluation-tail-calls) |  | [нет (layer: language, profile: rust2024)](rust.md#evaluation-tail-calls) |  |
| [Поднятие операций по рангу массива](#evaluation-rank-lifting) |  |  |  |  |  |  |  |  |  |  |  |
| [Протокол выдачи и возобновления результатов](#evaluation-result-protocol) |  |  |  |  |  |  |  |  |  |  |  |
| [Ожидание доступности данных](#evaluation-data-availability) |  |  |  |  |  |  |  |  |  |  |  |

### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy*

Правила востребованности вычислений: требует ли операция значения аргумента до своего выполнения или может получить результат без вычисления некоторых аргументов.

[Пример, границы понятия и связи](glossary.md#evaluation-strategy)

Отложенный генератор сам по себе не делает вычисление обычных аргументов нестрогим.

- `strict` — **Строгая** (*strict*)
- `non_strict` — **Нестрогая** (*non-strict*)

### Контроль эффектов { #evaluation-effects }

*Effect control*

Способы выражения и контроля наблюдаемых действий помимо получения обычного значения — изменения состояния, ввода-вывода и других эффектов.

[Пример, границы понятия и связи](glossary.md#evaluation-effects)

- `unrestricted` — **Без общего статического разделения эффектов** (*no general static effect separation*)
- `type_tracked` — **Эффекты отражены в типах** (*type-tracked effects*)
- `effect_handlers` — **Обработчики алгебраических эффектов** (*algebraic effect handlers*)

### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination*

Гарантия, что хвостовой вызов не требует сохранения дополнительного контекста возврата и не вызывает неограниченного роста такого контекста в цепочке хвостовых вызовов.

[Пример, границы понятия и связи](glossary.md#evaluation-tail-calls)

- да / нет

### Поднятие операций по рангу массива { #evaluation-rank-lifting }

*Array rank lifting*

Автоматическое применение операции к ячейкам массива выбранной размерности с правилами объединения результатов и согласования аргументов.

[Пример, границы понятия и связи](glossary.md#evaluation-rank-lifting)

Shape — размеры осей, rank — их число; cell — подмассив выбранного ранга, frame — оставшиеся оси. Ось описывает автоматическое применение операции к элементам или cells и согласование аргументов, а не просто наличие N-мерных массивов. Правила agreement J и Dyalog фиксируются отдельно; явный map не доказывает rank lifting.

Источники определения: [J Dictionary — Nouns: shape, rank and cells](https://www.jsoftware.com/help/dictionary/dicta.htm); [J Dictionary — Verbs: rank and agreement](https://www.jsoftware.com/help/dictionary/dictb.htm); [Dyalog APL 19.0 — Rank operator](https://help.dyalog.com/19.0/Content/Language/Primitive%20Operators/Rank.htm)

- `scalar_extension` — **Распространение скаляра на элементы массива** (*scalar extension*)
- `cell_rank` — **Применение к ячейкам выбранного ранга** (*rank-selected cell application*)

### Протокол выдачи и возобновления результатов { #evaluation-result-protocol }

*Result and resumption protocol*

Правила выдачи результатов и инициирования следующего результата: обычный возврат, явное возобновление или автоматический поиск альтернатив при неудаче.

[Пример, границы понятия и связи](glossary.md#evaluation-result-protocol)

Кто запрашивает следующий результат: caller при обычном возврате, потребитель генератора/корутины или охватывающее выражение после неудачи? Python yield и Lua resume/yield дают явное возобновление; Icon автоматически ищет альтернативу внутреннего генератора при неудаче внешнего выражения. Несколько значений одного return не являются потоком альтернатив. Это не strictness и не гарантия конкурентного исполнения.

Источники определения: [Griswold — Icon overview §§2–3: generators and goal-directed evaluation](https://www2.cs.arizona.edu/icon/docs/ipd266.htm); [Python 3 — Iterator and Generator Types](https://docs.python.org/3/library/stdtypes.html#iterator-types); [Lua 5.4 Reference Manual §2.6 — Coroutines](https://www.lua.org/manual/5.4/manual.html#2.6)

- `ordinary_return` — **Обычный возврат результата вызова** (*ordinary call return*)
- `explicit_resume` — **Явное возобновление генератора или корутины** (*explicit generator or coroutine resumption*)
- `goal_directed` — **Возобновление альтернатив по неудаче выражения** (*goal-directed resumption on failure*)

### Ожидание доступности данных { #evaluation-data-availability }

*Data availability suspension*

Приостановка или запуск вычисления в зависимости от наличия необходимой информации на входах или в логических переменных.

[Пример, границы понятия и связи](glossary.md#evaluation-data-availability)

В Oz 3 поток приостанавливается, когда операции не хватает информации о логической переменной; в G готовность узла определяется наличием всех требуемых входов. Это разные условия запуска, независимые от strictness, порядка операндов и mailbox/rendezvous. Наличие унификации не означает автоматического ожидания.

Источники определения: [Mozart 1.4.0 tutorial — Oz 3 dataflow threads](https://mozart.github.io/mozart-v1/doc-1.4.0/tutorial/node1.html); [NI — G dataflow and node readiness in LabVIEW](https://www.ni.com/en/shop/labview/benefits-of-programming-graphically-in-ni-labview.html)

- `needed_information` — **Ожидание необходимой операции информации** (*suspension on needed information*)
- `all_inputs` — **Готовность по всем входам узла** (*all-input node readiness*)

## Память и владение { #memory }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Освобождение памяти](#memory-management) | [Ручное (layer: standard_library, profile: c17, applies_to: динамически выделенная память) *](c.md#memory-management) | [Трассирующая сборка мусора (layer: implementation, profile: swi, implementation: SWI-Prolog) *](prolog.md#memory-management) | [Ручное (layer: language, profile: cpp23); Владение и время жизни (layer: standard_library, profile: cpp23, applies_to: std::unique_ptr и владеющие контейнеры); Подсчёт ссылок (layer: standard_library, profile: cpp23, applies_to: std::shared_ptr) *](cpp.md#memory-management) |  | [Трассирующая сборка мусора (layer: implementation, profile: ghc, implementation: GHC) *](haskell.md#memory-management) | [Подсчёт ссылок (layer: implementation, profile: python314, implementation: CPython); Трассирующая сборка мусора (layer: implementation, profile: python314, implementation: CPython) *](python.md#memory-management) | [Трассирующая сборка мусора (layer: language, profile: java21) *](java.md#memory-management) |  | [Трассирующая сборка мусора (layer: implementation, profile: dotnet8, implementation: .NET 8 / CLR) *](csharp.md#memory-management) | [Владение и время жизни (layer: language, profile: safe); Подсчёт ссылок (layer: standard_library, profile: rust2024, applies_to: разделяемое владение) *](rust.md#memory-management) |  |
| [Передача и разделение владения](#memory-transfer) | [Копирование значения (layer: language, profile: c17) *](c.md#memory-transfer) |  | [Копирование значения (layer: language, profile: cpp23); Перемещение владения (layer: language, profile: cpp23, applies_to: типы с перемещающими операциями) *](cpp.md#memory-transfer) |  |  | [Разделяемая ссылка на объект (layer: language, profile: python314)](python.md#memory-transfer) | [Копирование значения (layer: language, profile: java21); Разделяемая ссылка на объект (layer: language, profile: java21, applies_to: объекты ссылочных типов) *](java.md#memory-transfer) | [Разделяемая ссылка на объект (layer: language, profile: es2024, applies_to: объекты) *](javascript.md#memory-transfer) | [Копирование значения (layer: language, profile: csharp12, applies_to: значимые типы при передаче и присваивании по значению); Разделяемая ссылка на объект (layer: language, profile: csharp12, applies_to: значения ссылочных типов) *](csharp.md#memory-transfer) | [Копирование значения (layer: language, profile: rust2024, applies_to: типы Copy, включая &T, но не &mut T); Перемещение владения (layer: language, profile: rust2024, applies_to: передача принадлежащего вызывающему значения не-Copy типа); Разделяемое заимствование (layer: language, profile: safe); Исключительное заимствование (layer: language, profile: safe) *](rust.md#memory-transfer) | [Разделяемая ссылка на объект (layer: language, profile: ts5_strict, applies_to: объектные значения) *](typescript.md#memory-transfer) |
| [Права ссылок и ограничения алиасов](#memory-reference-permissions) |  |  |  |  |  |  |  |  |  |  |  |

### Освобождение памяти { #memory-management }

*Memory reclamation*

Политика определения момента и ответственного за освобождение памяти объектов: явный вызов, анализ достижимости, подсчёт ссылок или правила владения и времени жизни.

[Пример, границы понятия и связи](glossary.md#memory-management)

- `gc` — **Трассирующая сборка мусора** (*tracing garbage collection*)
- `refcount` — **Подсчёт ссылок** (*reference counting*)
- `ownership` — **Владение и время жизни** (*ownership and lifetimes*)
- `manual` — **Ручное** (*manual*)

### Передача и разделение владения { #memory-transfer }

*Ownership transfer and sharing*

Правила копирования значений, перемещения владения и разделения доступа к объектам, включая заимствования с ограниченным временем использования.

[Пример, границы понятия и связи](glossary.md#memory-transfer)

- `copy` — **Копирование значения** (*value copy*)
- `move` — **Перемещение владения** (*ownership move*)
- `shared_reference` — **Разделяемая ссылка на объект** (*shared object reference*)
- `shared_borrow` — **Разделяемое заимствование** (*shared borrow*)
- `exclusive_borrow` — **Исключительное заимствование** (*exclusive borrow*)

### Права ссылок и ограничения алиасов { #memory-reference-permissions }

*Reference permissions and alias restrictions*

Права конкретной ссылки на чтение и изменение объекта и ограничения на одновременное существование других ссылок к нему.

[Пример, границы понятия и связи](glossary.md#memory-reference-permissions)

Права относятся к ссылке и совместимым алиасам объекта, а не к перепривязке имени или способу освобождения памяти. Pony val гарантирует неизменяемость объекта, box — только read-only view, ref разрешает изменяемые алиасы, iso изолирует доступ. Изоляция не означает обязательное использование ровно один раз: линейность, аффинность и consume требуют отдельного утверждения; не помечать весь Pony как линейный.

Источники определения: [Pony Tutorial — Reference Capabilities: iso, ref, val, box, tag](https://tutorial.ponylang.io/reference-capabilities/reference-capabilities.html)

- `isolated` — **Изолированный доступ** (*isolated access*)
- `mutable_aliases` — **Изменяемый доступ с алиасами** (*mutable aliased access*)
- `immutable_shared` — **Разделяемый неизменяемый объект** (*shared immutable object*)
- `read_only_view` — **Представление только для чтения** (*read-only view*)
- `identity_only` — **Только идентичность без чтения состояния** (*identity-only access*)

## Каналы ошибок { #errors }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Представление и передача ошибок](#errors-model) | [Код ошибки (layer: standard_library, profile: c17) *](c.md#errors-model) | [Логическая неудача (layer: language, profile: iso); Исключения (layer: language, profile: iso) *](prolog.md#errors-model) | [Исключения (layer: language, profile: cpp23); Размеченный результат (layer: standard_library, profile: cpp23) *](cpp.md#errors-model) | [Условия и перезапуски (layer: language, profile: ansi) *](common-lisp.md#errors-model) | [Размеченный результат (layer: standard_library, profile: haskell2010); Исключения (layer: standard_library, profile: haskell2010, applies_to: ошибки IO); Исключения (layer: implementation, profile: ghc, implementation: GHC / base, applies_to: Control.Exception) *](haskell.md#errors-model) | [Исключения (layer: language, profile: python314) *](python.md#errors-model) | [Исключения (layer: language, profile: java21) *](java.md#errors-model) | [Исключения (layer: language, profile: es2024) *](javascript.md#errors-model) | [Исключения (layer: language, profile: csharp12) *](csharp.md#errors-model) | [Размеченный результат (layer: standard_library, profile: rust2024); Паника (layer: language, profile: rust2024) *](rust.md#errors-model) | [Исключения (layer: language, profile: ts5_strict) *](typescript.md#errors-model) |
| [Проверяемые исключения](#errors-checked-exceptions) |  |  |  |  |  | [нет (layer: language, profile: python314)](python.md#errors-checked-exceptions) | [да (layer: language, profile: java21) *](java.md#errors-checked-exceptions) |  |  | [нет (layer: language, profile: rust2024) *](rust.md#errors-checked-exceptions) | [нет (layer: language, profile: ts5_strict) *](typescript.md#errors-checked-exceptions) |
| [Диагностика неиспользованного результата](#errors-must-use) |  |  |  |  |  | [Нет специальной диагностики (layer: language, profile: runtime)](python.md#errors-must-use) | [Нет специальной диагностики (layer: language, profile: java21) *](java.md#errors-must-use) |  |  | [Предупреждение (layer: language, profile: rust2024, applies_to: значения типов и функций с #[must_use], в частности Result) *](rust.md#errors-must-use) |  |

### Представление и передача ошибок { #errors-model }

*Error representation and propagation*

Каналы представления и передачи неуспешного исхода или исключительной ситуации: значение, исключение, condition/restart, логическая неудача или аварийный механизм.

[Пример, границы понятия и связи](glossary.md#errors-model)

Сигнал ОС не является общей моделью ошибок языка. Паника, исключение и логическая неудача различаются.

- `exceptions` — **Исключения** (*exceptions*)
- `result_type` — **Размеченный результат** (*tagged result type*)
- `error_code` — **Код ошибки** (*error code*)
- `conditions_restarts` — **Условия и перезапуски** (*conditions and restarts*)
- `logical_failure` — **Логическая неудача** (*logical failure*)
- `panic` — **Паника** (*panic*)

<a id="errors-checked"></a>

### Проверяемые исключения { #errors-checked-exceptions }

*Checked exceptions*

Статическое требование обработать определённые классы исключений или объявить возможность их распространения в контракте подпрограммы.

[Пример, границы понятия и связи](glossary.md#errors-checked-exceptions)

Статическое требование catch/throws для исключений; Result в возвращаемом типе — другой механизм.

- да / нет

### Диагностика неиспользованного результата { #errors-must-use }

*Unused-result diagnostics*

Диагностика отбрасывания результата, который помечен как требующий внимания вызывающего кода. Уровень диагностики и допустимые способы отбрасывания зависят от профиля.

[Пример, границы понятия и связи](glossary.md#errors-must-use)

Предупреждение не означает обязательную обработку ошибки; явное отбрасывание может быть разрешено.

- `absent` — **Нет специальной диагностики** (*no dedicated diagnostic*)
- `warning` — **Предупреждение** (*warning*)
- `error` — **Ошибка** (*error*)

## Ресурсы и взаимодействие { #resources }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Освобождение ресурсов](#resources-cleanup) | [Явное освобождение (layer: language, profile: c17) *](c.md#resources-cleanup) |  | [Деструктор при выходе из области (layer: language, profile: cpp23) *](cpp.md#resources-cleanup) | [Блок finally / unwind-protect (layer: language, profile: ansi); Конструкция управления ресурсом (layer: language, profile: ansi, applies_to: with-open-file) *](common-lisp.md#resources-cleanup) |  | [Блок finally / unwind-protect (layer: language, profile: python314); Контекстный менеджер (layer: language, profile: python314) *](python.md#resources-cleanup) | [Блок finally / unwind-protect (layer: language, profile: java21); Конструкция управления ресурсом (с Java SE 7 включительно, layer: language, profile: java21, applies_to: try-with-resources) *](java.md#resources-cleanup) | [Блок finally / unwind-protect (layer: language, profile: es2024) *](javascript.md#resources-cleanup) | [Блок finally / unwind-protect (layer: language, profile: csharp12); Конструкция управления ресурсом (layer: language, profile: csharp12) *](csharp.md#resources-cleanup) | [Деструктор при выходе из области (layer: language, profile: rust2024) *](rust.md#resources-cleanup) | [Блок finally / unwind-protect (layer: language, profile: ts5_strict) *](typescript.md#resources-cleanup) |
| [Интерфейс ввода-вывода](#resources-io) | [API стандартной библиотеки (layer: standard_library, profile: c17) *](c.md#resources-io) | [Встроенные функции (layer: language, profile: iso) *](prolog.md#resources-io) | [API стандартной библиотеки (layer: standard_library, profile: cpp23) *](cpp.md#resources-io) | [API стандартной библиотеки (layer: standard_library, profile: ansi) *](common-lisp.md#resources-io) | [API стандартной библиотеки (layer: standard_library, profile: haskell2010) *](haskell.md#resources-io) | [Встроенные функции (layer: standard_library, profile: python314) *](python.md#resources-io) | [API стандартной библиотеки (layer: standard_library, profile: java21) *](java.md#resources-io) |  | [API стандартной библиотеки (layer: standard_library, profile: dotnet8) *](csharp.md#resources-io) | [Макросы (layer: standard_library, profile: rust2024, applies_to: вывод); API стандартной библиотеки (layer: standard_library, profile: rust2024, applies_to: ввод) *](rust.md#resources-io) |  |
| [Конкурентное выполнение](#resources-concurrency) |  |  |  |  |  | [Асинхронные корутины (с Python 3.5 включительно, layer: language, profile: python314); Потоки (layer: standard_library, profile: python314); Процессы (layer: standard_library, profile: python314)](python.md#resources-concurrency) | [Потоки (layer: standard_library, profile: java21)](java.md#resources-concurrency) | [Асинхронные корутины (layer: language, profile: es2024) *](javascript.md#resources-concurrency) | [Асинхронные корутины (layer: language, profile: csharp12) *](csharp.md#resources-concurrency) | [Потоки (layer: standard_library, profile: rust2024); Передача сообщений (layer: standard_library, profile: rust2024); Асинхронные корутины (layer: language, profile: rust2024) *](rust.md#resources-concurrency) | [Асинхронные корутины (layer: language, profile: ts5_strict) *](typescript.md#resources-concurrency) |
| [Синхронизация отправки и приёма](#resources-communication-coupling) |  |  |  |  |  |  |  |  |  |  |  |
| [Выбор сообщения из очереди](#resources-receive-selection) |  |  |  |  |  |  |  |  |  |  |  |

<a id="errors-finally"></a>

### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup*

Правила выполнения освобождающих действий при завершении работы с ресурсом или выходе из области, включая обычные и исключительные пути.

[Пример, границы понятия и связи](glossary.md#resources-cleanup)

Гарантии зависят от пути выхода; аварийное завершение процесса может пропустить очистку.

- `finally` — **Блок finally / unwind-protect** (*finally / unwind-protect*)
- `context_manager` — **Контекстный менеджер** (*context manager*)
- `resource_statement` — **Конструкция управления ресурсом** (*resource-management statement*)
- `raii` — **Деструктор при выходе из области** (*scope-bound destruction*)
- `defer` — **Отложенный вызов при выходе** (*deferred scope-exit call*)
- `manual` — **Явное освобождение** (*manual release*)

<a id="req-4"></a>

### Интерфейс ввода-вывода { #resources-io }

*I/O interface*

Уровень и форма предоставления операций обмена с внешним окружением — встроенная операция, стандартная библиотека, макрос или API конкретной среды.

[Пример, границы понятия и связи](glossary.md#resources-io)

- `builtin` — **Встроенные функции** (*built-in functions*)
- `stdlib` — **API стандартной библиотеки** (*standard-library API*)
- `macro` — **Макросы** (*macros*)

### Конкурентное выполнение { #resources-concurrency }

*Concurrency*

Возможность организовать несколько вычислений с перекрывающимся временем жизни и правила их продвижения и взаимодействия.

[Пример, границы понятия и связи](glossary.md#resources-concurrency)

- `threads` — **Потоки** (*threads*)
- `async_await` — **Асинхронные корутины** (*async/await coroutines*)
- `actors` — **Акторы** (*actors*)
- `message_passing` — **Передача сообщений** (*message passing*)
- `processes` — **Процессы** (*processes*)

### Синхронизация отправки и приёма { #resources-communication-coupling }

*Send and receive coupling*

Степень зависимости завершения отправки от готовности получателя: независимое помещение сообщения в очередь или согласованная встреча отправителя и получателя.

[Пример, границы понятия и связи](glossary.md#resources-communication-coupling)

Асинхронная отправка в mailbox не требует одновременного receive; rendezvous завершает коммуникацию при встрече отправителя и получателя по небуферизованному каналу. Это не выбор сообщения, не модель времени и не гарантия доставки/fairness. Свидетели — Erlang/OTP и occam 2; scheduler архивного occam runtime не обобщается на язык.

Источники определения: [Erlang/OTP — Concurrent Programming: send and receive](https://www.erlang.org/doc/system/conc_prog.html); [INMOS occam Run-time Model Specification SW-0064-4 §3 — synchronized unbuffered channels](https://www.transputer.net/obooks/sw-0064-4/sw-0064-4.html)

- `asynchronous_mailbox` — **Асинхронная отправка в почтовый ящик** (*asynchronous mailbox send*)
- `synchronous_rendezvous` — **Синхронное рандеву по каналу** (*synchronous channel rendezvous*)

### Выбор сообщения из очереди { #resources-receive-selection }

*Message selection from a queue*

Правило выбора доступного сообщения из очереди получателя — например, только голова либо первое сообщение, подходящее под образец.

[Пример, границы понятия и связи](glossary.md#resources-receive-selection)

Selective receive ищет первое подходящее сообщение, сохраняя более ранние неподходящие; head-only допускает извлечение только головы очереди. Асинхронный mailbox сам по себе не задаёт эту политику. Значение head_only — контраст для документирования, а не утверждение об occam: к rendezvous без очереди эта ось неприменима.

Источники определения: [Erlang/OTP — Concurrent Programming: selective receive and retained messages](https://www.erlang.org/doc/system/conc_prog.html)

- `head_only` — **Только голова очереди** (*queue head only*)
- `selective_matching` — **Выбор по образцу с пропуском неподходящих** (*selective matching*)

## Синтаксис и метапрограммирование { #syntax }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Границы синтаксических групп](#syntax-blocks) | [Явные разделители (layer: language, profile: c17) *](c.md#syntax-blocks) | [Явные разделители (layer: language, profile: iso) *](prolog.md#syntax-blocks) | [Явные разделители (layer: language, profile: cpp23)](cpp.md#syntax-blocks) | [S-выражения (layer: language, profile: ansi) *](common-lisp.md#syntax-blocks) | [Значимые отступы (layer: language, profile: haskell2010); Явные разделители (layer: language, profile: haskell2010) *](haskell.md#syntax-blocks) | [Значимые отступы (layer: language, profile: python314) *](python.md#syntax-blocks) | [Явные разделители (layer: language, profile: java21) *](java.md#syntax-blocks) | [Явные разделители (layer: language, profile: es2024)](javascript.md#syntax-blocks) | [Явные разделители (layer: language, profile: csharp12)](csharp.md#syntax-blocks) | [Явные разделители (layer: language, profile: rust2024) *](rust.md#syntax-blocks) | [Явные разделители (layer: language, profile: ts5_strict)](typescript.md#syntax-blocks) |
| [Границы операторов и определений](#syntax-statement-terminator) |  | [Точка в конце клаузы (layer: language, profile: iso) *](prolog.md#syntax-statement-terminator) |  | [Структура выражения (layer: language, profile: ansi) *](common-lisp.md#syntax-statement-terminator) |  | [Перевод строки (layer: language, profile: python314) *](python.md#syntax-statement-terminator) | [Точка с запятой (layer: language, profile: java21)](java.md#syntax-statement-terminator) | [Необязательная точка с запятой (layer: language, profile: es2024) *](javascript.md#syntax-statement-terminator) |  | [Точка с запятой (layer: language, profile: rust2024) *](rust.md#syntax-statement-terminator) |  |
| [Чувствительность имён к регистру](#syntax-case-sensitive) |  | [да (layer: language, profile: iso) *](prolog.md#syntax-case-sensitive) |  |  |  | [да (layer: language, profile: python314)](python.md#syntax-case-sensitive) | [да (layer: language, profile: java21)](java.md#syntax-case-sensitive) |  |  | [да (layer: language, profile: rust2024)](rust.md#syntax-case-sensitive) |  |
| [Метапрограммирование](#syntax-metaprogramming) | [Текстовые макросы (layer: language, profile: c17) *](c.md#syntax-metaprogramming) | [Построение и выполнение кода (layer: language, profile: iso) *](prolog.md#syntax-metaprogramming) | [Текстовые макросы (layer: language, profile: cpp23); Вычисление при компиляции (layer: language, profile: cpp23) *](cpp.md#syntax-metaprogramming) | [Синтаксические макросы (layer: language, profile: ansi); Построение и выполнение кода (layer: language, profile: ansi) *](common-lisp.md#syntax-metaprogramming) |  | [Рефлексия (layer: language, profile: python314); Построение и выполнение кода (layer: language, profile: python314) *](python.md#syntax-metaprogramming) | [Рефлексия (layer: standard_library, profile: java21)](java.md#syntax-metaprogramming) |  |  | [Синтаксические макросы (layer: language, profile: rust2024); Процедурные макросы (layer: language, profile: rust2024); Вычисление при компиляции (layer: language, profile: rust2024) *](rust.md#syntax-metaprogramming) |  |
| [Гигиена макросов](#syntax-macro-hygiene) |  |  |  |  |  |  |  |  |  |  |  |
| [Нотация исходной программы](#syntax-program-representation) |  |  |  |  |  |  |  |  |  |  |  |

<a id="variants-5"></a>

### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries*

Способ обозначения границ синтаксических групп — разделителями, значимыми отступами или структурой читаемых форм.

[Пример, границы понятия и связи](glossary.md#syntax-blocks)

- `explicit` — **Явные разделители** (*explicit delimiters*)
- `indentation` — **Значимые отступы** (*significant indentation*)
- `s_expressions` — **S-выражения** (*S-expressions*)

### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries*

Правила распознавания границ операторов и определений: терминатор, разделитель, перевод строки либо структура формы.

[Пример, границы понятия и связи](glossary.md#syntax-statement-terminator)

- `semicolon` — **Точка с запятой** (*semicolon*)
- `newline` — **Перевод строки** (*newline*)
- `optional_semicolon` — **Необязательная точка с запятой** (*optional semicolon*)
- `period` — **Точка в конце клаузы** (*clause-ending period*)
- `structural` — **Структура выражения** (*expression structure*)

### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity*

Правило различения идентификаторов по регистру после предусмотренных языком шагов чтения и нормализации.

[Пример, границы понятия и связи](glossary.md#syntax-case-sensitive)

- да / нет

### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming*

Средства, с помощью которых программа анализирует, создаёт или преобразует код либо его представление на определённой стадии обработки.

[Пример, границы понятия и связи](glossary.md#syntax-metaprogramming)

- `textual_macros` — **Текстовые макросы** (*textual macros*)
- `syntactic_macros` — **Синтаксические макросы** (*syntactic macros*)
- `procedural_macros` — **Процедурные макросы** (*procedural macros*)
- `reflection` — **Рефлексия** (*reflection*)
- `compile_time_execution` — **Вычисление при компиляции** (*compile-time execution*)
- `runtime_code` — **Построение и выполнение кода** (*runtime code generation and execution*)

### Гигиена макросов { #syntax-macro-hygiene }

*Macro hygiene*

Сохранение корректных связей имён при раскрытии макроса, предотвращающее непреднамеренный захват между введёнными именами и контекстом использования.

[Пример, границы понятия и связи](glossary.md#syntax-macro-hygiene)

Ось описывает защиту связываний от непреднамеренного захвата имён при раскрытии, независимо от textual/syntactic/procedural формы трансформера. R7RS syntax-rules сохраняет лексические связывания; негигиеничный механизм требует ручного предотвращения capture. Намеренное нарушение гигиены нужно описывать для конкретного API, не выводить из слова macro.

Источники определения: [Scheme R7RS-small §4.3 — hygienic macros](https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-6.html)

- `hygienic` — **Автоматическая защита от захвата имён** (*hygienic binding preservation*)
- `unhygienic` — **Нет автоматической защиты от захвата** (*no automatic capture protection*)

### Нотация исходной программы { #syntax-program-representation }

*Source program notation*

Форма, в которой автор задаёт исходную программу для исполнения или трансляции: текст либо структурный граф с узлами и связями.

[Пример, границы понятия и связи](glossary.md#syntax-program-representation)

Текст или структурный граф являются исходной программой, а не иллюстрацией, AST компилятора или визуализацией отладчика. Нотация независима от dataflow semantics: не каждый графический язык имеет правило готовности G. G — язык, LabVIEW — среда; для Prograph/Marten подтверждена графическая нотация, но не все правила исполнения.

Источники определения: [NI — G graphical programming in LabVIEW](https://www.ni.com/en/shop/labview/benefits-of-programming-graphically-in-ni-labview.html); [Marten 1.6 — Prograph cases, operations and links (notation only)](https://www.andescotia.com/products/marten/)

- `textual` — **Текстовая нотация** (*textual notation*)
- `graphical_graph` — **Граф из узлов и связей** (*graphical nodes and links*)

## Парадигмы { #paradigm }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Поддерживаемые парадигмы](#paradigm-supported) | [Императивная (layer: language, profile: c17); Процедурная (layer: language, profile: c17)](c.md#paradigm-supported) | [Логическая (layer: language, profile: iso); Декларативная (layer: language, profile: iso) *](prolog.md#paradigm-supported) | [Императивная (layer: language, profile: cpp23); Процедурная (layer: language, profile: cpp23); Объектно-ориентированная (layer: language, profile: cpp23); Функциональная (layer: language, profile: cpp23)](cpp.md#paradigm-supported) | [Императивная (layer: language, profile: ansi); Функциональная (layer: language, profile: ansi); Объектно-ориентированная (layer: language, profile: ansi)](common-lisp.md#paradigm-supported) | [Функциональная (layer: language, profile: haskell2010); Декларативная (layer: language, profile: haskell2010)](haskell.md#paradigm-supported) | [Императивная (layer: language, profile: python314); Процедурная (layer: language, profile: python314); Объектно-ориентированная (layer: language, profile: python314); Функциональная (layer: language, profile: python314) *](python.md#paradigm-supported) | [Императивная (layer: language, profile: java21); Процедурная (layer: language, profile: java21); Объектно-ориентированная (layer: language, profile: java21); Функциональная (с Java SE 8 включительно, layer: language, profile: java21) *](java.md#paradigm-supported) | [Императивная (layer: language, profile: es2024); Объектно-ориентированная (layer: language, profile: es2024); Функциональная (layer: language, profile: es2024)](javascript.md#paradigm-supported) |  | [Императивная (layer: language, profile: rust2024); Процедурная (layer: language, profile: rust2024); Функциональная (layer: language, profile: rust2024); Объектно-ориентированная (layer: language, profile: rust2024) *](rust.md#paradigm-supported) | [Императивная (layer: language, profile: ts5_strict); Объектно-ориентированная (layer: language, profile: ts5_strict); Функциональная (layer: language, profile: ts5_strict)](typescript.md#paradigm-supported) |

### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms*

Устойчивые способы организации вычислений и программных абстракций, поддержанные механизмами языка и его практикой использования.

[Пример, границы понятия и связи](glossary.md#paradigm-supported)

- `imperative` — **Императивная** (*imperative*)
- `procedural` — **Процедурная** (*procedural*)
- `object_oriented` — **Объектно-ориентированная** (*object-oriented*)
- `functional` — **Функциональная** (*functional*)
- `declarative` — **Декларативная** (*declarative*)
- `logic` — **Логическая** (*logic*)
- `event_driven` — **Событийно-ориентированная** (*event-driven*)

## Семантика данных { #data }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Кратность элементов коллекции](#data-collection-multiplicity) |  |  |  |  |  |  |  |  |  |  |  |
| [Основание числового представления](#data-numeric-radix) |  |  |  |  |  |  |  |  |  |  |  |
| [Ограничение числовой точности](#data-numeric-precision) |  |  |  |  |  |  |  |  |  |  |  |

### Кратность элементов коллекции { #data-collection-multiplicity }

*Collection multiplicity*

Правила учёта повторных элементов и их позиций в конкретной коллекции или результате операции: присутствие, число вхождений либо позиционные вхождения.

[Пример, границы понятия и связи](glossary.md#data-collection-multiplicity)

Set хранит присутствие элемента, bag — число вхождений, sequence — отдельные позиционные вхождения. Ось задаёт модель конкретной коллекции или результата операции, а не всех данных языка: SQL SELECT ALL сохраняет дубли, DISTINCT устраняет их. Порядок выдачи строк и ORDER BY описываются отдельно; SQL bag не превращается в sequence из-за порядка конкретного плана.

Источники определения: [Soufflé — Relations as sets of tuples](https://souffle-lang.github.io/relations); [PostgreSQL 18 — Select Lists: ALL and DISTINCT](https://www.postgresql.org/docs/18/queries-select-lists.html); [Python 3 — Sequence Types](https://docs.python.org/3/library/stdtypes.html#sequence-types-list-tuple-range)

- `set` — **Множество без дубликатов** (*set*)
- `bag` — **Мультимножество с кратностями** (*bag or multiset*)
- `sequence` — **Последовательность позиционных вхождений** (*sequence of positional occurrences*)

### Основание числового представления { #data-numeric-radix }

*Numeric representation radix*

Основание представления и арифметики числового типа или поля, например двоичное либо десятичное.

[Пример, границы понятия и связи](glossary.md#data-numeric-radix)

Binary/decimal относится к представлению и арифметике конкретного числового типа, а не к записи литерала. Основание независимо от точности и fixed/floating scale: десятичное число не обязательно имеет фиксированный масштаб. COBOL PICTURE с V задаёт десятичные позиции и подразумеваемую точку; Python float — двоичное представление.

Источники определения: [GnuCOBOL 3.1 RC-1 Programmer's Guide §6.9.33 — PICTURE and V scale](https://gnucobol.sourceforge.io/HTML/gnucobpg.html); [Python 3 — binary float representation and hex conversion](https://docs.python.org/3/library/stdtypes.html#additional-methods-on-float)

- `binary` — **Двоичное** (*binary*)
- `decimal` — **Десятичное** (*decimal*)

### Ограничение числовой точности { #data-numeric-precision }

*Numeric precision bound*

Ограничение количества значащих разрядов, задаваемое типом, полем или настраиваемым контекстом вычисления.

[Пример, границы понятия и связи](glossary.md#data-numeric-precision)

Fixed precision ограничивает число разрядов выбранным типом/объявлением; arbitrary precision позволяет увеличивать его по значению или настраиваемому контексту в пределах ресурсов. Это не fixed point: положение точки, rounding и overflow описываются отдельно. Python int точен без фиксированной разрядности, decimal.Decimal использует контекст точности стандартной библиотеки; COBOL PIC ограничивает число позиций поля.

Источники определения: [Python 3 — unlimited-precision integers and user-definable Decimal precision](https://docs.python.org/3/library/stdtypes.html#numeric-types-int-float-complex); [GnuCOBOL 3.1 RC-1 Programmer's Guide §6.9.33 — numeric PICTURE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html)

- `fixed_precision` — **Фиксированная разрядность типа или поля** (*fixed type or field precision*)
- `arbitrary_precision` — **Нефиксированная заранее разрядность** (*arbitrary precision*)

## Правила вычисления и модели времени { #computation }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Смысл применения правил](#computation-rule-semantics) |  |  |  |  |  |  |  |  |  |  |  |
| [Режимы связанности аргументов](#computation-instantiation-modes) |  |  |  |  |  |  |  |  |  |  |  |
| [Объявленная кратность решений](#computation-solution-cardinality) |  |  |  |  |  |  |  |  |  |  |  |
| [Временная область модели](#computation-time-domain) |  |  |  |  |  |  |  |  |  |  |  |
| [Направленность уравнений и присваиваний](#computation-equation-causality) |  |  |  |  |  |  |  |  |  |  |  |
| [Планирование обновлений в HDL-симуляции](#computation-update-scheduling) |  |  |  |  |  |  |  |  |  |  |  |

### Смысл применения правил { #computation-rule-semantics }

*Rule application semantics*

Смысл применения правил к состоянию задачи: поиск ответа на цель, построение замыкания фактов либо преобразование хранилища с фиксацией выбора.

[Пример, границы понятия и связи](glossary.md#computation-rule-semantics)

Поиск решает заданную цель, fixed-point deduction задаёт замыкание отношений, committed rewriting меняет store без возврата к отвергнутому правилу. Это семантика конкретного ядра/профиля, не алгоритм реализации: top-down/bottom-up и tabling не подменяют определение результата. Наименьшая неподвижная точка здесь относится к положительному конечному Datalog без порождения новых значений; CHR может удалять ограничения и не обязан вычислять такое замыкание.

Источники определения: [Mercury Reference Manual — goal solutions and determinism](https://www.mercurylang.org/information/doc-release/mercury_ref/Determinism-categories.html); [Z3 Guide — Basic Datalog fixed-point engine](https://microsoft.github.io/z3guide/docs/fixedpoints/basicdatalog/); [Soufflé Tutorial — recursive relations and arithmetic extension limits](https://souffle-lang.github.io/tutorial); [SWI-Prolog CHR — simplification, propagation and simpagation](https://www.swi-prolog.org/pldoc/man?section=chr-syntaxandsemantics)

- `goal_search` — **Поиск решений заданной цели** (*goal-directed solution search*)
- `least_fixed_point` — **Наименьшее замыкание отношений** (*least fixed-point deduction*)
- `committed_rewriting` — **Переписывание хранилища с фиксацией выбора** (*committed store rewriting*)

### Режимы связанности аргументов { #computation-instantiation-modes }

*Argument instantiation modes*

Описание требуемой связанности аргументов до вызова и гарантируемой связанности после него, отдельно от типов значений.

[Пример, границы понятия и связи](glossary.md#computation-instantiation-modes)

Режим описывает состояние аргумента до и после вызова: например, Mercury in соответствует ground→ground, out — free→ground. Mode mapping независим от типа, by-reference передачи и числа решений. Точные допустимые структуры inst и ограничения реализации задаются в профиле.

Источники определения: [Mercury Reference Manual — Insts, modes and mode definitions](https://www.mercurylang.org/information/doc-release/mercury_ref/Insts-modes-and-mode-definitions.html)

- `ground_to_ground` — **Связанный вход остаётся связанным** (*ground to ground*)
- `free_to_ground` — **Свободный аргумент становится связанным** (*free to ground*)
- `declared_transition` — **Пользовательское отображение состояний inst** (*declared instantiation transition*)

### Объявленная кратность решений { #computation-solution-cardinality }

*Declared solution cardinality*

Контракт количества успешных решений и допустимости неудачи для определённого режима вызова при его возврате.

[Пример, границы понятия и связи](glossary.md#computation-solution-cardinality)

Классификация числа решений и допустимости failure относится к конкретному mode вызова. Mercury det — одно решение, semidet — ноль или одно, multi — одно или больше, nondet — ноль или больше. Гарантия условна для возвращающихся вызовов: det не доказывает завершение, отсутствие исключений или детерминированный порядок планирования потоков.

Источники определения: [Mercury Reference Manual — Determinism categories and returning-call qualification](https://www.mercurylang.org/information/doc-release/mercury_ref/Determinism-categories.html)

- `det` — **Ровно одно решение** (*exactly one solution*)
- `semidet` — **Ноль или одно решение** (*zero or one solution*)
- `multi` — **Одно или больше решений** (*one or more solutions*)
- `nondet` — **Ноль или больше решений** (*zero or more solutions*)

### Временная область модели { #computation-time-domain }

*Model time domain*

Встроенный смысл времени, относительно которого определены значения и изменения модели: логические такты, дискретные события, непрерывное время или их сочетание.

[Пример, границы понятия и связи](glossary.md#computation-time-domain)

Логические такты потоков Lustre, дискретное время HDL-симуляции и непрерывная динамика с событиями Modelica — разные смыслы времени. Hybrid сочетает непрерывную эволюцию и дискретные события. Область времени не определяет deadline реального времени, rendezvous, scheduler или реализуемость модели; при отсутствии встроенного времени нужна контекстная запись, а не вывод по пропуску данных.

Источники определения: [Verimag — Lustre clocked streams](https://www-verimag.imag.fr/The-Lustre-Programming-Language-and.html); [Modelica Specification 3.6 §8 — continuous integration and events](https://specification.modelica.org/maint/3.6/equations.html); [Icarus Verilog — discrete-event simulation](https://steveicarus.github.io/iverilog/usage/simulation.html)

- `logical_ticks` — **Дискретные логические такты** (*discrete logical ticks*)
- `discrete_simulation` — **Дискретное время симуляции** (*discrete simulation time*)
- `continuous` — **Непрерывное модельное время** (*continuous model time*)
- `hybrid` — **Непрерывная динамика и дискретные события** (*hybrid continuous and discrete time*)

### Направленность уравнений и присваиваний { #computation-equation-causality }

*Equation and assignment causality*

Различие между направленным обновлением цели, определением выходного потока и ненаправленным отношением величин, решаемым совместно с другими уравнениями.

[Пример, границы понятия и связи](glossary.md#computation-equation-causality)

Присваивание обновляет выбранную цель; направленное уравнение потока задаёт выход через входы; ненаправленная система уравнений задаёт отношения для совместного решения. Modelica equation с = не является algorithm assignment с :=. Уравнения не обещают существования или единственности решения; Lustre clocks и HDL очереди обновлений описываются отдельными осями.

Источники определения: [Verimag — Lustre unordered stream equations](https://www-verimag.imag.fr/The-Lustre-Programming-Language-and.html); [Modelica Specification 3.6 §8 — equations versus assignments](https://specification.modelica.org/maint/3.6/equations.html)

- `directed_assignment` — **Направленное обновление цели** (*directed assignment*)
- `directed_equation` — **Направленное определение потока** (*directed stream equation*)
- `acausal_equation` — **Ненаправленное отношение для совместного решения** (*acausal simultaneous equation*)

### Планирование обновлений в HDL-симуляции { #computation-update-scheduling }

*HDL simulation update scheduling*

Момент применения изменения состояния относительно вычисления правой части и других событий в модели аппаратной симуляции.

[Пример, границы понятия и связи](glossary.md#computation-update-scheduling)

В процедурном Verilog blocking assignment без задержки обновляет цель перед следующим оператором; nonblocking assignment вычисляет RHS и планирует применение значения позже. Ось описывает симуляционное обновление, не форму множественного присваивания и не порядок потоков. Источник — Icarus; точные IEEE event regions, delays и synthesizable subset требуют отдельного версионного профиля.

Источники определения: [Icarus Verilog — Simulation](https://steveicarus.github.io/iverilog/usage/simulation.html); [Icarus VVP Simulation Engine — blocking and nonblocking assignment events](https://steveicarus.github.io/iverilog/developer/guide/vvp/vvp.html)

- `blocking_update` — **Блокирующее процедурное обновление** (*blocking procedural update*)
- `deferred_nonblocking` — **Отложенное неблокирующее обновление** (*deferred nonblocking update*)

## Проверяемые свойства программ { #verification }

| Концепция | [C](c.md) | [Prolog](prolog.md) | [C++](cpp.md) | [Common Lisp](common-lisp.md) | [Haskell](haskell.md) | [Python](python.md) | [Java](java.md) | [JavaScript](javascript.md) | [C#](csharp.md) | [Rust](rust.md) | [TypeScript](typescript.md) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [Режим гарантии тотальности](#verification-totality) |  |  |  |  |  |  |  |  |  |  |  |
| [Поведенческие контракты](#verification-behavioral-contracts) |  |  |  |  |  |  |  |  |  |  |  |

### Режим гарантии тотальности { #verification-totality }

*Totality guarantee policy*

Политика проверки того, что определение покрывает допустимые входы и завершается либо продуктивно выдаёт результат в принятой модели вычислений.

[Пример, границы понятия и связи](glossary.md#verification-totality)

Ось задаёт обязательность проверки тотальности для определения/профиля, а не наличие dependent types. Нужно явно назвать проверяемые обязательства: coverage, termination либо productivity для corecursion. Idris 2 covering не равен total; Agda допускает отключения/утверждения вне safe-профиля. Принятая через escape hatch тотальность не считается доказанной; checked_required относится лишь к области, где профиль действительно требует все заявленные проверки.

Источники определения: [Idris 2 — covering, total, partial and Totality](https://idris2.readthedocs.io/en/latest/tutorial/typesfuns.html); [Agda — Termination Checking, TERMINATING, NON_TERMINATING and --safe](https://agda.readthedocs.io/en/latest/language/termination-checking.html)

- `checked_required` — **Проверка обязательна в указанной области** (*checking required in the stated scope*)
- `checked_opt_in` — **Проверка включается для определения или профиля** (*opt-in checking for a definition or profile*)
- `unchecked_escape` — **Непроверенное допущение или обход проверки** (*unchecked assumption or escape hatch*)
- `partial_allowed` — **Частичные определения разрешены** (*partial definitions allowed*)

### Поведенческие контракты { #verification-behavioral-contracts }

*Behavioral contracts*

Предикаты допустимого входа, результата, изменения состояния и инвариантов, которыми описывается наблюдаемое поведение программного компонента.

[Пример, границы понятия и связи](glossary.md#verification-behavioral-contracts)

Предикаты допустимого входа, результата/перехода состояния и инвариантов объекта. Это не abstraction.contracts: interfaces/traits задают контракт полиморфизма, а не такие предикаты. Наличие require/ensure/Pre/Post не означает доказательство: runtime monitoring, assertion policy и статический proof tool фиксируются отдельно с layer/profile; old обозначает состояние до вызова.

Источники определения: [Eiffel — Design by Contract: assertions, old and monitoring](https://www.eiffel.org/doc/eiffel/ET-_Design_by_Contract_(tm),_Assertions_and_Exceptions); [Ada 2012 RM §6.1.1 — preconditions, postconditions and assertion policy](https://www.adaic.org/resources/add_content/standards/12rm/html/RM-6-1-1.html); [SPARK User's Guide — language subset, contracts and GNATprove boundaries](https://docs.adacore.com/spark2014-docs/html/ug/en/spark_2014.html)

- `preconditions` — **Предусловия** (*preconditions*)
- `postconditions` — **Постусловия** (*postconditions*)
- `invariants` — **Инварианты объектов** (*object invariants*)

## Оценка по критериям лекции 20 { #assessment }

Критерии — не свойства, а оценки; каждая ссылается на концепции, из которых выводится.

| Критерий | [Python](python.md#assessment) | [Java](java.md#assessment) | [Rust](rust.md#assessment) |
|---|---|---|---|
| Читабельность | Отступы вместо скобок и минимум служебных слов делают код коротким и единообразным; отсутствие типов в сигнатурах затрудняет чтение больших программ, аннотации частично это компенсируют. | Явные объявления и типы в сигнатурах помогают читать код, но обвязка классов и скобки увеличивают объём по сравнению с Python и Kotlin. | Синтаксис явный и единообразный (скобки, `let`, типы в сигнатурах), но аннотации времён жизни и обобщений с ограничениями трейтов делают сигнатуры длинными и требуют изучения дополнительных понятий. |
| Лёгкость создания | Неявное объявление, множественное присваивание, встроенные коллекции и ввод-вывод без импорта — программа пишется быстро; ошибки типов откладываются до запуска. | Перегрузка, `var`, лямбды и Stream API сократили код по сравнению с ранними версиями; отсутствие свободных функций, параметров по умолчанию и множественного присваивания остаётся. | Вывод типов внутри функций и выражения-блоки сокращают код, но проверка заимствований заставляет заранее продумывать владение данными; высокая «входная цена». |
| Надёжность | Попытка сложения строки и числа вызывает TypeError во время выполнения; надёжность держится на тестах и внешних проверках аннотаций. Исключения структурные, с `finally` и `with`. | Статическая типизация и проверяемые исключения ловят ошибки на этапе компиляции; `null` допустим в ссылочных типах и остаётся одним из источников ошибок времени выполнения. | Статическая проверка типов, ненулевые ссылки и проверка владения предотвращают многие ошибки памяти в безопасном коде. Result явно представляет ошибку; предупреждение о неиспользованном результате допускает явное отбрасывание и не гарантирует обработку ошибки. |
| Стоимость | Низкий порог входа, огромная экосистема; цена — скорость выполнения и расходы на тесты вместо компилятора. | Зрелая экосистема JVM и инструменты; цена — многословность, время старта JVM и потребление памяти. | Дольше учить и дольше компилировать; окупается там, где критичны производительность и безопасность памяти без сборщика мусора. |
