---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Prolog

Prolog описывает отношения посредством клауз, логических переменных и унификации; поиск решений использует возврат. Основа — ISO Prolog (ISO/IEC 13211-1); модули, табулирование, ограничения и управление памятью SWI-Prolog отмечены как свойства реализации. Сайт и открытое руководство относятся к SWI-Prolog, а не ко всем диалектам.

*Карточка сравнительная: 28/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1972 — [Wikidata P571](https://www.wikidata.org/wiki/Q163468) (получено 2026-09-24) |
| Авторы | [Ален Колмероэ](people.md#colmerauer), [Филипп Руссель](people.md#roussel), [Роберт Ковальский](people.md#kowalski) |
| Сайт | <https://www.swi-prolog.org/> |
| Спецификация | <https://www.iso.org/standard/21413.html> |
| Внешние каталоги | [Wikidata Q163468](https://www.wikidata.org/wiki/Q163468) |

## Люди { #people }

- [Ален Колмероэ](people.md#colmerauer) — Руководил созданием Prolog в Марселе в 1972 году.
- [Филипп Руссель](people.md#roussel) — Автор первой реализации Prolog.
- [Роберт Ковальский](people.md#kowalski) — Предложил процедурную интерпретацию хорновских дизъюнктов — логическую основу Prolog.

## Публикации { #publications }

- Ален Колмероэ, Филипп Руссель. *The Birth of Prolog*. HOPL II, 1993. DOI: [10.1145/154766.155362](https://doi.org/10.1145/154766.155362). Как из задач обработки естественного языка появился Prolog. ([в источниках](sources.md#hopl-prolog))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **iso** — ISO/IEC 13211-1:1995, General core; базовый профиль записей без другого контекста. Руководство SWI отмечает ISO-предикаты отдельно.
- **swi** — Расширения SWI-Prolog, описанные в его Reference Manual; версия выпуска и дата не фиксируются, профиль не означает последнюю версию.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Логическая переменная в терме (layer: language, profile: iso)** — Переменная вводится своим вхождением в терм; имя обычно начинается с прописной буквы или подчёркивания. Каждое вхождение одиночного _ — отдельная анонимная переменная. ([SWI-Prolog: Syntax](https://www.swi-prolog.org/pldoc/man?section=syntax))

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Однократное связывание логической переменной (layer: language, profile: iso)** — Унификация уточняет значение или связывает переменные друг с другом. Связывания отменяются при возврате за создавшую их точку; это не императивное переприсваивание. ([Comparison and Unification of Terms](https://www.swi-prolog.org/pldoc/man?section=compare))

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Унификация термов (layer: language, profile: iso)** — =/2 унифицирует термы; is/2 вычисляет арифметическое выражение справа и унифицирует результат слева. Ни один из них не является обычным изменяемым присваиванием. ([ISO unification predicates](https://www.swi-prolog.org/pldoc/man?section=compare); [ISO is/2](https://www.swi-prolog.org/pldoc/man?predicate=is/2))

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: iso, applies_to: логические переменные клаузы)** — Совпадение написания переменной в разных клаузах не связывает их; при использовании клаузы её переменные свежие.

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Логическая клауза (layer: language, profile: iso)** — Переменные общей головы и тела относятся к одной клаузе; запрос имеет собственные переменные.
- **Модуль (layer: implementation, profile: swi, implementation: SWI-Prolog)** — Модуль задаёт пространство имён предикатов; это отдельное расширение относительно выбранного ISO core. ([SWI-Prolog: Modules](https://www.swi-prolog.org/pldoc/man?section=modules))

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

*Top-level bindings* · [в онтологии](concepts.md#scope-globals)

- **Имена модуля (layer: implementation, profile: swi, implementation: SWI-Prolog, applies_to: имена предикатов)** — Имя и арность идентифицируют предикат в модуле. Это не глобальные логические переменные.

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Динамическая (layer: language, profile: iso)** — Типы и достаточная инстанцированность проверяются операциями при выполнении. Несовместимость термов при унификации обычно означает неудачу, а не type error. ([Verify Type of a Term](https://www.swi-prolog.org/pldoc/man?section=typetest); [Exception handling](https://www.swi-prolog.org/pldoc/man?section=exception))

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Отсутствуют (layer: language, profile: iso)** — ISO core не требует сигнатур статических типов; режимы +/−/? в документации описывают ожидаемую инстанцированность аргументов.

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **нет (layer: language, profile: iso)** — Унификация логических термов во время поиска — не вывод статических типов программы.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: iso)** — Предикаты atom_chars/2 и number_chars/2 связывают разные представления. Арифметика is/2 требует вычислимого выражения, а не автоматически вычисляет любой терм при унификации. ([ISO number_chars/2](https://www.swi-prolog.org/pldoc/man?predicate=number_chars/2))

### Управление потоком { #control }

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **нет (layer: language, profile: iso)** — Выбор клаузы по унификации головы и индексирование реализации не являются конструкцией switch/case.

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · [в онтологии](concepts.md#control-do-while)

- **нет (layer: language, profile: iso)** — Повторение задаётся рекурсией и поиском с возвратом, а не оператором do-while.

#### Логический поиск решений { #control-logic-search }

*Logic search* · [в онтологии](concepts.md#control-logic-search)

- **Поиск с возвратом (layer: language, profile: iso)** — Обычный поиск перебирает клаузы и цели в процедурном порядке; cut отсекает часть альтернатив. Бесконечная ветвь может помешать достижению других решений. Условие ->/2 — цель, а не булево выражение; конструкция фиксирует первый успех условия. ([Control predicates and cut](https://www.swi-prolog.org/pldoc/man?section=control))
- **Табулирование подцелей (layer: implementation, profile: swi, implementation: SWI-Prolog)** — Объявленные табулируемые предикаты сохраняют ответы и переиспользуют подцели; это не стандартное поведение каждого ISO-предиката. ([SWI-Prolog: Table execution (SLG resolution)](https://www.swi-prolog.org/pldoc/man?section=tabling))
- **Распространение ограничений (layer: implementation, profile: swi, implementation: SWI-Prolog, applies_to: library(clpfd))** — Ограничения на целые распространяются без обязательной немедленной конкретизации переменных; поиск конкретных значений — отдельный шаг. ([SWI-Prolog: CLP(FD)](https://www.swi-prolog.org/pldoc/man?section=clpfd))

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: iso)** — Предикаты с разными арностями — разные предикаты; несколько клауз одного предиката задают альтернативы поиска, а не перегрузки по типам сигнатур. ([Notation of Predicate Descriptions](https://www.swi-prolog.org/pldoc/man?section=preddesc))

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **Унификация аргументов с термами головы (layer: language, profile: iso)** — Аргументы цели унифицируются с термами головы свежего экземпляра клаузы. Режим вход/выход зависит от вызова и контракта предиката, а не от отдельного механизма copy-out. ([Implicit unification in predicate heads](https://www.swi-prolog.org/pldoc/man?section=compare))

<a id="variants-9"></a>

#### Место определения подпрограмм { #subprograms-placement }

*Subprogram definition placement* · [в онтологии](concepts.md#subprograms-placement)

- **Выделенная область объявлений (layer: language, profile: iso)** — Клаузы и директивы записываются как термы верхнего уровня исходного текста.
- **Верхний уровень модуля (layer: implementation, profile: swi, implementation: SWI-Prolog)** — Клаузы принадлежат предикатам модуля.

#### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms* · [в онтологии](concepts.md#subprograms-nesting)

- **нет (layer: language, profile: iso)** — Тело клаузы содержит цели, а не лексически вложенные определения предикатов.

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **нет (layer: language, profile: iso)** — call/1 вызывает цель-терм; анонимные функции не являются конструкцией ISO core.

### Полиморфизм и организация { #abstraction }

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Явная граница экспорта (layer: implementation, profile: swi, implementation: SWI-Prolog)** — module/2 и списки экспортируемых предикатов; система SWI не отождествляется с ISO/IEC 13211-2. ([SWI-Prolog module system](https://www.swi-prolog.org/pldoc/man?section=modules))

### Вычисление и эффекты { #evaluation }

#### Контроль эффектов { #evaluation-effects }

*Effect control* · [в онтологии](concepts.md#evaluation-effects)

- **Без общего статического разделения эффектов (layer: language, profile: iso)** — Ввод-вывод и изменение динамической базы доступны без общей статической системы эффектов; возврат не отменяет произвольные побочные эффекты. ([Database predicates](https://www.swi-prolog.org/pldoc/man?section=db))

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Трассирующая сборка мусора (layer: implementation, profile: swi, implementation: SWI-Prolog)** — SWI автоматически собирает недостижимые термы и имеет отдельные механизмы сбора атомов и клауз; это не требование ISO к алгоритму управления памятью. ([SWI-Prolog: Memory Management](https://www.swi-prolog.org/pldoc/man?section=memory))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Логическая неудача (layer: language, profile: iso)** — fail/0 и неуспешная унификация означают отсутствие решения на текущем пути и могут запустить поиск альтернатив. Это обычный исход отношения, а не обязательно ошибка программы. ([ISO fail/0 and control predicates](https://www.swi-prolog.org/pldoc/man?section=control))
- **Исключения (layer: language, profile: iso)** — throw/1 и catch/3 передают и перехватывают исключительный терм; type_error и instantiation_error отличны от логической неудачи. ([ISO exception handling](https://www.swi-prolog.org/pldoc/man?section=exception))

### Ресурсы и взаимодействие { #resources }

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

*I/O interface* · [в онтологии](concepts.md#resources-io)

- **Встроенные функции (layer: language, profile: iso)** — ISO core включает потоковые предикаты open/4, close/2 и чтение/запись термов; дополнительные средства SWI имеют собственные контракты. ([Input and output; ISO-marked predicates](https://www.swi-prolog.org/pldoc/man?section=IO))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: iso)** — Скобки группируют цели и термы; запятая и точка с запятой — операторы конъюнкции и дизъюнкции, а не границы императивных блоков.

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Точка в конце клаузы (layer: language, profile: iso)** — Исходный терм заканчивается точкой с последующим layout или концом ввода.

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да (layer: language, profile: iso)** — Регистр значим, а начальный символ также различает обычную запись переменной и атома.

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Построение и выполнение кода (layer: language, profile: iso)** — call/1 вызывает представленные термами цели; assertz/1 и retract/1 изменяют динамические предикаты. ([Meta-Call Predicates](https://www.swi-prolog.org/pldoc/man?section=metacall); [Database predicates](https://www.swi-prolog.org/pldoc/man?section=db))

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Логическая (layer: language, profile: iso)**
- **Декларативная (layer: language, profile: iso)** — Порядок целей, cut, ввод-вывод и изменение базы добавляют процедурную семантику поверх отношений.
