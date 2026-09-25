---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# C

C17 — процедурный язык со статическими типами, адресуемыми объектами и явным управлением динамической памятью. Базовая среда — hosted C17; расширения отдельных компиляторов не включены.

*Карточка сравнительная: 34/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

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

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: c17)** — Объекты и функции объявляются; C17 не допускает implicit int.

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: c17)** — Присваивание меняет значение объекта, обозначенного именем; имя не меняет объявленный тип.
- **Неизменяемое (layer: language, profile: c17, applies_to: объекты с const-квалифицированным типом)** — const ограничивает изменение объекта; const-указатель и указатель на const — разные типы.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: c17)** — Левая часть — модифицируемое lvalue; цепочка присваиваний состоит из отдельных выражений.

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: c17)**

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Блок (layer: language, profile: c17)**
- **Подпрограмма (layer: language, profile: c17, applies_to: метки функции)** — Область функции в терминологии C относится к меткам; параметры определения находятся в области блока.

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

*Top-level bindings* · [в онтологии](concepts.md#scope-globals)

- **Глобальные переменные (layer: language, profile: c17)** — Файловая область видимости; external/internal linkage определяет связь имён между единицами трансляции.

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

*Name shadowing* · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: c17)** — Объявление во вложенном блоке может скрыть внешнее.

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Статическая (layer: language, profile: c17)** — Статические ограничения типов не исключают неопределённого поведения при выполнении.

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Обязательны (layer: language, profile: c17)** — Спецификаторы типа входят в объявления объектов, параметров и функций.

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **нет (layer: language, profile: c17)** — Нет вывода типа объявления из инициализатора; auto в C17 — спецификатор класса хранения. Типы выражений определяются статически.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Неявные (layer: language, profile: c17)** — Целочисленные продвижения, обычные арифметические преобразования и преобразования при присваивании могут менять диапазон и точность. ([WG14 N2176, §6.3 Conversions](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))
- **Явные (layer: language, profile: c17)** — Cast явно задаёт преобразование; не делает произвольное преобразование указателя или последующее обращение безопасным.

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Записи и структуры (layer: language, profile: c17)** — struct объединяет именованные поля; union использует перекрывающееся хранение и не содержит встроенной метки варианта.

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Специальное значение (layer: language, profile: c17)** — Null pointer обозначает отсутствие адресуемого объекта или функции; разыменование недопустимо. NULL — макрос стандартной библиотеки.

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: c17)** — if/else; скалярное условие сравнивается с нулём.
- **Условное выражение (layer: language, profile: c17)** — Условный оператор ?: вычисляет только выбранный операнд.

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: c17)** — switch по целочисленному значению; переход к следующей ветви возможен без break.

#### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **нет (layer: language, profile: c17)**

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · [в онтологии](concepts.md#control-do-while)

- **да (layer: language, profile: c17)**

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **Инициализация / условие / шаг (layer: language, profile: c17)** — for; также есть while и do-while.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: c17)** — Функции не перегружаются по типам параметров. _Generic выбирает выражение по типу, но не создаёт перегруженные функции.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: c17)** — Параметр получает значение аргумента. Указатель также копируется по значению; через него можно менять объект вызывающего. Массив в объявлении параметра корректируется до указателя. ([WG14 N2176, §6.5.2.2 Function calls; §6.7.6.3 Function declarators](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

<a id="variants-9"></a>

#### Место определения подпрограмм { #subprograms-placement }

*Subprogram definition placement* · [в онтологии](concepts.md#subprograms-placement)

- **Выделенная область объявлений (layer: language, profile: c17)** — Определения функций находятся на внешнем уровне единицы трансляции; объявить прототип можно и в блоке.

#### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms* · [в онтологии](concepts.md#subprograms-nesting)

- **нет (layer: language, profile: c17)** — Вложенные определения функций — расширение, например GNU C, а не C17. ([WG14 N2176, §6.9 External definitions](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **нет (layer: language, profile: c17)** — Указатель на функцию не захватывает локальное окружение; контекст callback передают отдельно.

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **нет (layer: language, profile: c17)**

### Полиморфизм и организация { #abstraction }

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Текстовое включение (layer: language, profile: c17)** — #include текстуально включает заголовок; единицы трансляции связываются посредством linkage.

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: c17)** — Аргументы вычисляются перед входом в функцию; порядок вычисления разных аргументов не задан. ([WG14 N2176, §6.5.2.2 Function calls](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Ручное (layer: standard_library, profile: c17, applies_to: динамически выделенная память)** — malloc/calloc/realloc и free; автоматические объекты имеют время жизни, определяемое областью выполнения, и не требуют free. ([WG14 N2176, §6.2.4 Storage durations; §7.22.3 Memory management](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

#### Передача и разделение владения { #memory-transfer }

*Ownership transfer and sharing* · [в онтологии](concepts.md#memory-transfer)

- **Копирование значения (layer: language, profile: c17)** — Присваивание структур и указателей копирует значение; копия указателя не передаёт и не проверяет владение выделенной памятью.

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Код ошибки (layer: standard_library, profile: c17)** — Библиотечные функции используют возвращаемые коды, специальные значения и в определённых случаях errno. Проверка ошибок возложена на вызывающего. ([WG14 N2176, §7.5 Errors; §7.21 Input/output](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Явное освобождение (layer: language, profile: c17)** — free и fclose вызываются явно. longjmp не запускает автоматическую очистку пользовательских ресурсов.

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

*I/O interface* · [в онтологии](concepts.md#resources-io)

- **API стандартной библиотеки (layer: standard_library, profile: c17)** — stdio.h задаёт потоки FILE и операции ввода-вывода; наличие всего hosted API не требуется от freestanding-реализации. ([WG14 N2176, §7.21 Input/output](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2176.pdf))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: c17)** — Составные операторы ограничены фигурными скобками.

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Текстовые макросы (layer: language, profile: c17)** — Препроцессор заменяет последовательности preprocessing tokens; макросы не имеют лексической гигиены.

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: c17)**
- **Процедурная (layer: language, profile: c17)**
