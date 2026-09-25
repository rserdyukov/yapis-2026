---
title: "Карта исследования языков: семантическое расширение онтологии v2"
publish: false
status: research-draft
date: 2026-09-20
---

# Карта исследования языков для онтологии v2

## Краткий вывод

Каталог стоит расширять **по различиям в семантике, а не по популярности языков**.
Исторические, исследовательские и предметно-ориентированные языки обнаруживают
пробелы, которые почти не видны при сравнении Python, Java и Rust: продолжения,
ранги массивов, стековая композиция, возобновляемый поиск, ожидание данных,
неподвижные точки, логическое время, системы уравнений и аппаратная симуляция.

Ниже — **60 именованных языков/языковых семейств в основной выборке**, отдельно
два пограничных примера, **15 приоритетных языков для следующего исследования**
и предложения независимых concept ID. Это репрезентативная исследовательская
карта, а не утверждение, что обследованы буквально все языки или полностью
изучены все перечисленные реализации.

Основание — прочитанный рабочий файл
[`docs/languages/_data/ontology.yaml`](../languages/_data/ontology.yaml):
`schema_version: 2`, `coverage_policy: informational`, **52 концепции** на
2026-09-20. Учитывается текущая незакоммиченная редакция, а не только `HEAD`.
Предложения ниже не меняют онтологию. Документ имеет `publish: false`;
`docs/_design/` также уже исключён из публикации через `mkdocs.yml`.

## 1. Метод отбора и границы доказательности

### Что именно сравниваем

Единица исследования — **язык + редакция/профиль + конкретное утверждение**.
«Lisp», «SQL», «Datalog» и «APL» не обозначают один неизменный стандарт.
Версии языка не считаются дополнительными языками ради увеличения числа строк.

Отбор балансирует пять факторов:

1. **Новый наблюдаемый эффект.** Меняется ли результат, допустимость программы,
   момент выполнения, множество решений или представляемый объект вычисления?
2. **Независимость.** Можно ли иметь это свойство без уже имеющегося соседнего?
   Например, зависимая типизация не равна обязательной тотальности.
3. **Исторический контраст.** Старый язык может лучше обнаруживать различие,
   чем очередной современный язык той же традиции.
4. **Предметное разнообразие.** Базы данных, бизнес-данные, управление,
   аппаратные схемы, ограничения и квантовые вычисления — полноценные объекты
   сравнения, даже если к ним неприменим обычный пример с `main` и циклом.
5. **Проверяемость.** Нужны определение, первичный источник и маленький
   различающий пример; новизна синтаксиса сама по себе недостаточна.

Это качественный отбор с убывающей отдачей, не доказательство оптимального
покрытия. Близкие языки оставлены как контрольные пары: Smalltalk/Self,
APL/J, Prolog/Datalog/Mercury, Erlang/occam/Oz, Lustre/Esterel/Modelica.

### Статусы утверждений

| Метка | Значение |
|---|---|
| **S** | Указанный семантический тезис изучен по реально полученному и прочитанному первичному тексту. Это не полная верификация языка. |
| **P** | Подтверждена только часть: например, назначение языка, семейство или наличие механизма; детали остаются кандидатными. Граница указана явно. |
| **C** | Кандидат из общих знаний; семантика в этой сессии источником не подтверждена. |
| **B** | Пограничный пример для проверки применимости схемы, не рекомендация включать в основной каталог. |

Тип источника также важен: нормативный текст, руководство разработчиков,
официальная документация реализации, авторский материал или историческая
перепечатка. **Успешный HTTP-ответ не равен подтверждению тезиса**: оглавление,
пустая страница, оболочка JavaScript и неразобранный PDF не засчитываются.
Реестр §7 фиксирует URL, изученную часть и ограничения. Все обращения выполнены
2026-09-20. Даты происхождения в §3 — ориентировочные периоды для стратификации,
а не отдельно проверенная хронологическая база.

### Язык, реализация, библиотека, инструмент

- Scheme R7RS-small задаёт `call/cc` через стандартную процедуру: это
  стандартизованная возможность, но не специальная синтаксическая форма.
  В карточке слой процедуры — `standard_library`; её семантические гарантии
  ссылаются на отчёт о языке.
- Smalltalk задаёт посылку сообщений и блоки; `ifTrue:` — поведение Boolean
  в библиотеке. Нельзя автоматически помечать его как встроенный `if`.
- Self — самостоятельный прототипный язык. Его traits-объекты не тождественны
  `abstraction.contracts: traits` в смысле контрактов полиморфизма.
- Dyalog — реализация/диалект APL; оператор ранга из Dyalog 19.0 нельзя
  переносить на исходную нотацию APL 1962 года. J исследуется отдельно.
- Mozart реализует Oz; Oz 1, Oz 2 и Oz 3 различаются моделью конкурентности.
  Здесь предмет доказанного описания — **Oz 3 по документации Mozart 1.4.0**.
- SQL исследуется через явно названный PostgreSQL-профиль; документация
  PostgreSQL не заменяет весь ISO SQL. `DISTINCT ON` — расширение PostgreSQL.
- Datalog — семейство. Soufflé и Datalog-движок Z3 — конкретные реализации
  с расширениями, а не универсальное определение всех диалектов.
- CHR — язык правил ограничений, часто встроенный в host-язык. CHR в SWI-Prolog
  не превращает все программы ISO Prolog в программы с CHR-семантикой.
- SPARK — ограниченное и дополненное подмножество Ada; GNATprove — инструмент
  доказательства. Наличие контракта в исходнике не означает, что он доказан.
- G — графический язык; LabVIEW — среда и реализация. Prograph — язык;
  Marten — одна его среда. Граф не является просто картинкой к текстовой программе.
- Fortran coarrays — языковой механизм определённых редакций; MPI — отдельная
  библиотека. OpenMP также нельзя без оговорок записать как свойство базового языка.
- Verilog/SystemVerilog описывают и симуляцию, и аппаратную структуру;
  синтезируемое подмножество зависит от профиля и инструмента.
- Q# functor, SML functor и Oz functor — разные понятия, несмотря на одно слово.

Существующие `layer`, `implementation`, `profile`, `applies_to`, `since/until`
полезны для этих различий. Отсутствующая запись означает «не исследовано»,
а не автоматически `false`. Для графического языка «неприменимо» к разделителю
текстовых операторов не должно превращаться в «разделитель отсутствует».

## 2. Что покрывают нынешние 52 концепции

### Инвентаризация прочитанной редакции

В таблице перечислены суффиксы ID внутри соответствующего пространства имён.

| Пространство | Количество | Концепции |
|---|---:|---|
| `bindings` | 3 | `introduction`, `mutation`, `assignment` |
| `scope` | 4 | `resolution`, `constructs`, `globals`, `shadowing` |
| `typing` | 8 | `checking`, `annotations`, `inference`, `conversions`, `compatibility`, `sum_types`, `product_types`, `nullability` |
| `control` | 7 | `selection`, `switch`, `pattern_matching`, `until`, `do_while`, `iteration`, `logic_search` |
| `subprograms` | 10 | `overloading`, `parameter_passing`, `placement`, `nesting`, `closures`, `lambda`, `generics`, `generic_mechanism`, `default_args`, `named_args` |
| `abstraction` | 4 | `contracts`, `dispatch`, `inheritance`, `modules` |
| `evaluation` | 3 | `strategy`, `effects`, `tail_calls` |
| `memory` | 2 | `management`, `transfer` |
| `errors` | 3 | `model`, `checked_exceptions`, `must_use` |
| `resources` | 3 | `cleanup`, `io`, `concurrency` |
| `syntax` | 4 | `blocks`, `statement_terminator`, `case_sensitive`, `metaprogramming` |
| `paradigm` | 1 | `supported` |
| **Итого** | **52** | |

### Уже имеющиеся механизмы не надо объявлять новыми пробелами

- **ALGOL 60:** `subprograms.parameter_passing` уже содержит `by_name`,
  `by_need`, `by_value`, `by_reference`, `by_result`, `by_value_result`.
  Исторический пример нужен для правильного понимания существующей оси [S01].
- **Koka:** `evaluation.effects` уже содержит `type_tracked` и
  `effect_handlers`. Пробел — степень полиморфизма эффектов и свойства
  возобновления, а не само наличие обработчиков [S15].
- **Erlang:** `resources.concurrency` уже содержит `actors`, `processes`,
  `message_passing`. Недостаточна детализация транспорта и выбора сообщения [S08].
- **Prolog/Oz/Mercury:** уже есть логические переменные, single assignment,
  унификация, backtracking, tabling, constraints и logical failure. Но из этого
  не следуют ожидание связывания, объявленные modes или число решений.
- **Scheme:** замыкания, lexical scope, синтаксические макросы и tail calls
  уже представлены. Продолжения и гигиена не выводятся из этих признаков [S02].
- **Ada/Eiffel/SPARK:** существующее `abstraction.contracts` означает
  interfaces/traits/type classes/protocols. **Это не Design by Contract** [S12–S14].
- **COBOL:** `typing.product_types: record` уже есть; отсутствуют точность,
  масштаб и семантика представления бизнес-данных [S23].

### Почему 52 осей недостаточно

Проблема не в самом числе, а в том, что разные семантики получают одинаковые
ярлыки или остаются только в свободном `note`:

| Нынешняя ось | Неразличимые случаи | Недостающее наблюдаемое различие |
|---|---|---|
| `evaluation.strategy: strict/non_strict` | eager-вызов, ожидание dataflow-переменной, генерация альтернатив | Что запускает вычисление; может ли оно возобновиться с другим результатом? |
| `control.logic_search` + `errors.model` | Prolog backtracking, Icon failure, Datalog closure, CHR rules | Поиск по запросу, переисполнение выражения, вывод всех фактов и переписывание store — разные операции. |
| `resources.concurrency` | Erlang, occam, Oz | Mailbox, rendezvous и ожидание информации имеют разные условия блокировки. |
| `typing.checking` + `generics` | Java, SML, Idris | Проверка типов не описывает зависимость типа от значения или абстрактные типы модулей. |
| `abstraction.dispatch/inheritance` | class-based OO и Self | Число родителей не говорит, являются ли родители классами или объектами и как идёт lookup. |
| `typing.product_types` | tuple/record, массив ранга N, отношение | Нет формы, ранга, кратности строк и правил поднятия операций. |
| `typing.nullability` | Optional и SQL NULL | Представление отсутствия не определяет трёхзначные таблицы истинности. |
| `memory.transfer` | move, `iso`, `val`, `box` | Перенос владения не определяет все разрешённые алиасы и права чтения/записи. |
| `syntax.metaprogramming` | textual/syntactic/procedural macros | Форма трансформера не определяет защиту от захвата имён. |
| `paradigm.supported: declarative/event_driven` | SQL, Lustre, Modelica, Verilog | Не определены время, уравнения, события, драйверы сигналов или аппаратная структура. |
| `syntax.blocks/statement_terminator` | G и Prograph | Текстовые разделители не описывают граф как исходную программу. |
| `resources.cleanup` | освобождение файла и квантовое uncomputation | Удаление временного квантового состояния может менять наблюдаемый результат. |

Полнота по существующему набору значений не означает полноту семантической карты.
Это согласуется с `coverage_policy: informational`: не нужно добиваться 100%
искусственным приписыванием всем языкам всех конструкций.

## 3. Основная выборка: 60 языков

**Вклад** означает полезность для расширения или проверки карты, а не заявление
об историческом первенстве. Для C-строк все особенности ниже — гипотезы для
будущего чтения первичных источников. Периоды обозначают происхождение языка;
изучаемый профиль может быть значительно новее.

### 3.1. Исторические основания и альтернативные формы программы

| № | Язык; период / профиль | Статус | Отличительный вклад относительно 52 осей |
|---:|---|---|---|
| 1 | **FORTRAN / Fortran**, 1950-е → 77/90/2003/2008/2018/2023 | P [S24] | Эволюция одного языка: whole-array операции, затем OO и coarray images. WG5 подтверждает coarrays 2008 и дальнейшие parallel features; точные переходы остальных признаков ещё проверить. |
| 2 | **Lisp 1.5**, 1960-е | C | Историческая среда связывания, символьные выражения и код как данные; не переносить лексическую семантику Scheme на ранний Lisp. |
| 3 | **COBOL**, 1950-е; GnuCOBOL 3.1 RC-1 | S [S23] | `PICTURE`, десятичный масштаб, group items и описания записей: record без числовой/представленческой семантики недостаточен. |
| 4 | **ALGOL 60**, 1960; Revised Report | S [S01] | Call-by-name и capture-avoiding подстановка; главным образом проверка уже имеющегося `by_name`, не новый ID. |
| 5 | **ALGOL 68**, 1960-е | C | Контекстные coercions, modes и orthogonal composition; развести выбор преобразования и простое «implicit». |
| 6 | **PL/I**, 1960-е | C | Сочетание decimal/binary, fixed/float, условий и хранения; числовая модель шире оси conversions. |
| 7 | **Simula 67**, 1960-е | C | Симуляционные процессы и сопрограммы рядом с классами; не сводить историческую роль к inheritance. |
| 8 | **Pascal**, 1970-е | C | Поддиапазоны, множества, packed/variant records; контрольный случай для уточнения типов и layout. |
| 9 | **SNOBOL4**, 1960-е | C [U01] | Композиционные string patterns как значения, success/failure и замена фрагментов; не просто булевый `pattern_matching`. |
| 10 | **Refal**, 1960-е; будущий профиль Refal-5 | C [U02] | Разбор и переписывание символьных последовательностей, переменные разных категорий образцов; отделить от Prolog unification. |
| 11 | **APL**, 1960-е; Dyalog 19.0 | S [S05] | Массивы, cells и оператор ранга; область доказанного тезиса — современный Dyalog, не все исторические APL. |
| 12 | **Forth**, 1970-е; стандартный core | S [S06] | Явный data stack, композиция слов, различение compile/interpret semantics; стандарт не требует проверки типов данных. |
| 13 | **Smalltalk**, 1970-е; GNU Smalltalk для примера | S [S03] | Посылки сообщений, блоки и управление через Boolean protocol; библиотечная конструкция не обязана быть ключевым словом. |
| 14 | **Scheme**, 1970-е; R7RS-small | S [S02] | First-class multi-shot continuations и hygienic `syntax-rules`; strictness, closures и macros не объясняют их полностью. |
| 15 | **Prolog**, 1970-е; ISO core как будущая база | C | Опорный случай SLD-поиска, порядка целей и cut; большая часть уже представима, стратегия/полнота поиска требуют уточнения. |
| 16 | **CLU**, 1970-е | C | Clusters, representation independence и yield-итераторы; мост между ADT и управлением производителем результатов. |
| 17 | **SETL**, 1960–1970-е | C | Множества и отношения как основные значения; независимый контроль для set/bag/sequence. |
| 18 | **Icon**, 1970-е; v9 overview | S [S07] | Goal-directed evaluation: неудача внешнего выражения возобновляет внутренний генератор; сравнение может вернуть операнд. |
| 19 | **Common Lisp**, 1980-е; ANSI профиль | C | Conditions/restarts, CLOS multiple dispatch, special variables; в основном богатое покрытие уже существующих значений. |
| 20 | **Self**, 1980-е; Handbook 2024.1 | S [S04] | Parent slots, object delegation, assignable parents и uniform access через сообщения; не class inheritance. |

### 3.2. Семейства типов, модулей, прав доступа и эффектов

| № | Язык; период / профиль | Статус | Отличительный вклад относительно 52 осей |
|---:|---|---|---|
| 21 | **Standard ML**, 1980-е; SML '97 | S [S17] | Structures/signatures/functors, sharing и opaque sealing; параметризация модулей и идентичность типов не равны generic functions. |
| 22 | **OCaml**, 1990-е; отдельно 4.x/5.x | C | Applicative/generative module cases, polymorphic variants; effect handlers 5.x потребуют версионного профиля. |
| 23 | **Haskell**, 1990-е; Haskell 2010 | C | Non-strict evaluation и типизированные эффекты уже покрываются; кандидат для проверки productivity и чистоты отдельно от totality. |
| 24 | **Clean**, 1980-е | C | Uniqueness types: права использования без отождествления с Rust lifetimes или Pony capabilities. |
| 25 | **Ada**, 1980-е; для контрактов Ada 2012 | S [S12] | `Pre`/`Post`, class-wide contracts и assertion policy. Task rendezvous, ranges и fixed point — отдельные будущие исследования. |
| 26 | **SPARK**, 1980-е → SPARK 2014 family | S [S13] | Ограниченный Ada-профиль плюс спецификации и доказательство инструментом; разделить выразимость контракта и способ проверки. |
| 27 | **Eiffel**, 1980-е | S [S14] | Preconditions/postconditions/class invariants, `old`, настраиваемый runtime monitoring; это поведенческий контракт. |
| 28 | **Mercury**, 1990-е; release reference manual | S [S11] | Instantiation modes и determinism на каждый mode; `det` не означает доказанное завершение. |
| 29 | **Agda**, 1990-е; Agda 2 reference | P [S19] | Подтверждены termination checker и исключения `TERMINATING`/`NON_TERMINATING`; зависимые семейства — кандидатный тезис этой строки. |
| 30 | **Idris**, 2000-е; Idris 2 | S [S18] | Типы, зависящие от значений, `Vect n a`, `Fin n`, различение covering/total/partial и продуктивности. |
| 31 | **ATS**, 2000-е | C | Dependent/linear types и отделение proof terms от вычисления; потенциальная декомпозиция «статически типизирован». |
| 32 | **C**, 1970-е; редакцию выбрать | C | Object representation, pointer provenance и undefined behavior; нужен контроль для того, что не выражает `manual` memory. |
| 33 | **C++**, 1980-е; редакцию выбрать | C | RAII уже покрыт; object lifetime, value categories и template constraints — отдельные вопросы, не синоним move. |
| 34 | **Rust**, 2010-е; существующая карточка | C | Контроль текущей модели ownership/borrowing; alias permissions и `Send`/`Sync` нельзя свести к освобождению памяти. |
| 35 | **Pony**, 2010-е | S [S16] | `iso/val/ref/box/trn/tag`: права и ограничения алиасов каждой ссылки, включая межакторное разделение. |
| 36 | **Koka**, 2010-е; web book snapshot | S [S15] | Inferred polymorphic effects, handlers/resume, отдельный divergence effect; базовые handlers уже есть в v2. |
| 37 | **Java**, 1990-е; существующая карточка | C | Контроль nominal OO, checked exceptions и generics; небольшой ожидаемый прирост после нынешней базы. |
| 38 | **Python**, 1990-е; существующая карточка | C | Контроль динамической объектной модели, генераторов и библиотечного decimal; генератор не означает Icon evaluation. |
| 39 | **JavaScript**, 1990-е; ECMAScript-профиль | C | Современный контрпример для prototype semantics; event loop уточнять по host, не объявлять целиком свойством ECMAScript. |
| 40 | **Racket**, 1990-е; линия PLT Scheme | C | Programmable languages, phases и richer macro systems; эти свойства не переносить на весь Scheme. |

### 3.3. Альтернативные вычислительные и предметные модели

| № | Язык; период / профиль | Статус | Отличительный вклад относительно 52 осей |
|---:|---|---|---|
| 41 | **J**, 1990-е; Jsoftware dictionary | S [S05] | Rank/cell/frame agreement как правило применения verb, а не библиотечный обход массива. |
| 42 | **Joy**, 1990-е | C | Quotations и комбинаторы над стековыми функциями; контроль для отделения concatenative semantics от конкретного Forth compiler. |
| 43 | **Erlang**, 1980-е; OTP documentation | S [S08] | Mailbox и selective receive; процессы не являются потоками ОС. Supervision — отдельный слой OTP. |
| 44 | **occam**, 1980-е; occam 2 | S [S09] | CSP-derived process composition, synchronous unbuffered point-to-point channels; противопоставление Erlang mailbox. |
| 45 | **Oz**, 1990-е; Oz 3 | S [S10] | Dataflow threads, блокировка до появления нужной информации и монотонный store логических переменных. |
| 46 | **Datalog**, 1970–1980-е; positive finite core / Soufflé / Z3 | S [S20] | Fixed-point deduction над отношениями; стратифицированное отрицание исследуется отдельно от положительного ядра. |
| 47 | **SQL**, 1970-е; PostgreSQL 18 для подтверждения | S [S21] | Relational queries, bag по умолчанию для `SELECT`, `DISTINCT` и three-valued logic с NULL. |
| 48 | **CHR**, 1990-е; SWI-Prolog embedding | S [S25] | Multi-headed committed rules, simplification/propagation/simpagation над store ограничений; не просто флаг constraints. |
| 49 | **MiniZinc**, 2000-е | S [S26] | Parameters против decision variables, domains, `solve satisfy/minimize/maximize`; модель отделена от solver backend. |
| 50 | **Lustre**, 1980-е; core, отдельно V4/V6 | S [S22] | Clocked streams, уравнения и `pre`/initialization: логическое время является частью значения программы. |
| 51 | **Esterel**, 1980-е | P [S27] | Подтверждены synchronous reactive family и строгая semantics; constructive causality и preemption пока требуют чтения определения. |
| 52 | **Modelica**, 1990-е; specification 3.6 | S [S28] | Ненаправленные системы уравнений, производные, дискретные события и гибридное время; `=` не присваивание. |
| 53 | **Verilog**, 1980-е; язык через Icarus documentation | S [S29] | Event scheduling, blocking/nonblocking updates, multi-valued signals и elaborated hardware; точная IEEE-редакция ещё нужна. |
| 54 | **VHDL**, 1980-е; будущий IEEE-профиль | C | Signal/variable distinction, delta cycles и resolution; контроль для отделения HDL-гарантий от Icarus implementation. |
| 55 | **Prograph**, 1980-е; Marten 1.6 | P [S30] | Подтверждены исполняемые графические cases/operations/links; точные правила готовности и порядка эффектов ещё проверить. |
| 56 | **G (LabVIEW)**, 1980-е | S [S31] | Граф — исходная программа; узел готов при наличии входов, data dependencies задают порядок, независимые ветви допускают параллелизм. |
| 57 | **Janus**, 1980-е; time-reversible language Lutz | P [S32] | Подтверждена идентификация обратимого языка; invertible updates и `uncall` — пока кандидатные детали. Не одноимённый concurrent constraint language. |
| 58 | **Q#**, 2010-е | S [S33] | Quantum operations с `Adjoint`/`Controlled`; применять можно только при наличии требуемых specializations. |
| 59 | **Silq**, 2020 | S [S34] | Quantum/classical distinction, consumption, measurement и безопасное automatic uncomputation при определённых условиях. |
| 60 | **Stan**, 2010-е | C | Программа задаёт плотность вероятности; conditioning/inference отделены от обычного вызова случайной функции. |

### 3.4. Пограничные примеры, вне основной шестидесятки

| Язык | Статус | Зачем нужен и почему не первый кандидат каталога |
|---|---|---|
| **Brainfuck** | B/C | Минимальная машина с лентой и указателем: проверяет применимость «binding», «subprogram», «type». Размер ячейки, лента и overflow зависят от диалекта. Семантическая отдача ниже Forth при сопоставимой цене объяснения. |
| **Piet** | B/C | Изображение участвует в исполнении; полезен для проверки предположения «исходник всегда текст». Для практического исследования графов сначала G/Prograph: иной носитель сам по себе не гарантирует иной dataflow model. |

Первичные спецификации этих двух языков в этой сессии не получены. Их роль —
проверка границ, а не обязательные следующие публичные карточки.

## 4. Пятнадцать приоритетных добавлений

Здесь **15 конкретных языков**, а не 15 групп, скрывающих ещё несколько десятков.
«Добавление» означает следующий исследовательский пакет и затем кандидатную
карточку; готовность к публикации не предполагается. Порядок учитывает
семантическую отдачу, краткость демонстрации и доступность источника.

| Приоритет | Язык | Концептуальный прирост и минимальный различающий пример |
|---:|---|---|
| 1 | **Scheme** | Сохранить continuation и вызвать повторно; отдельно раскрыть макрос рядом с одноимённым локальным связыванием. Две независимые оси вместо «есть lambda/macros». |
| 2 | **J** | Применить один verb к строкам и к матрице целиком, меняя только rank; показать frame agreement. |
| 3 | **Forth** | Описать `dup *` как преобразование стека `( n -- n² )`; не приписывать стандарту обязательный type checker. |
| 4 | **Icon** | `write(5 < find("or", sentence))`: ранний результат отвергается, генератор возобновляется автоматически. |
| 5 | **Self** | Один receiver получает слот от parent object; изменить parent и наблюдать иной lookup без изменения класса. |
| 6 | **Oz** | Поток вычисляет `Y=X+1` до связывания `X`; он ждёт, затем продолжает после `X=41`. Сравнить с rendezvous и mailbox. |
| 7 | **Mercury** | `append(in,in,out) is det` против `append(out,out,in) is multi`; отделить instantiation от типов и числа решений. |
| 8 | **Datalog** | Достижимость в графе с циклом до насыщения; перестановка правил положительного ядра не меняет множество фактов. |
| 9 | **SQL** | Дубли при `SELECT` против `DISTINCT`; отдельно `FALSE AND NULL` и `TRUE AND NULL`. |
| 10 | **Standard ML** | Две инстанциации functor с opaque result signature; экспортированные абстрактные типы различны. |
| 11 | **Idris 2** | `Fin n -> Vect n a -> a`; затем отдельно covering-функция, для которой не доказано завершение. |
| 12 | **Eiffel** | `require`, `ensure`, `old` и class invariant на банковском счёте; контракты выражают поведение, не набор методов. |
| 13 | **Lustre** | `i = 0 -> pre(i) + a`: последовательность значений по тактам, а не присваивание один раз. |
| 14 | **Modelica** | `v = R*i` и `der(x) = v` в системе уравнений; задаваемые известные величины не фиксируют универсальное направление вычисления. |
| 15 | **Verilog** | Два регистра с nonblocking assignments обмениваются предыдущими значениями на фронте clock; сравнить с blocking assignment. |

**Следом, с высокой ценностью:**

- **G (LabVIEW)** и **Pony** — первые расширения бюджета: графическая форма
  программы и reference capabilities. G может заменить Verilog, если ближайшая
  цель — визуальные языки; это редакционное предпочтение, не меньшая семантическая
  значимость G. Сформулированные оси для обоих уже приведены ниже.
- **Erlang и occam** нужны как контрольная пара для Oz: actors уже есть в v2,
  но mailbox/rendezvous обязательно должны получить разные описания.
- **COBOL** — первый числовой/record-oriented пакет; **Fortran** — первый
  подробный тест эволюции языка по версиям.
- **Koka** — углубление уже имеющейся effects-оси; **Ada/SPARK** — контраст
  runtime contracts и статического доказательства после Eiffel.
- **CHR/MiniZinc** — отдельные модели store rewriting и решения ограничений;
  **Refal/SNOBOL4** — после восстановления надёжных источников.
- **Silq/Q#** — следующий предметный блок; **Janus** — важный классический
  контраст обратимости, но пока слабее подтверждён источниками.

ALGOL 60 достоин раннего небольшого примера к `by_name`, хотя не попал в 15:
он улучшает точность существующей оси больше, чем число независимых различий.
Ни историческая известность, ни экзотичность не являются автоматическим
основанием заводить новую концепцию.

## 5. Предлагаемые независимые concept ID

Все ID в этом разделе **предложения**, не записи `ontology.yaml`. Значения —
рабочий словарь, а не окончательная схема сериализации. Не следует вводить
одну огромную ось `execution_model`, где смешаются время, стек, графы, поиск
и аппаратная реализация. Независимость здесь — аналитическая разделимость
свойств, а не утверждение, что все их сочетания реализуемы.

### 5.1. Управление, применение и связывание

| Новый ID | Вопрос / возможные различия | Свидетель и почему соседней оси мало |
|---|---|---|
| `control.continuation_extent` | Доступны escape-only, delimited или undelimited first-class continuations? | Scheme `call/cc` [S02]; `closures` сохраняет окружение, но не само продолжение вычисления. |
| `control.resumption_multiplicity` | Продолжение/обработчик допускает ноль, одно или повторные возобновления? | Scheme multi-shot [S02], Koka handlers [S15]; независимо от границы захвата. При описании — конкретный механизм, не одно свойство всего языка. |
| `evaluation.result_protocol` | Одно значение, явный iterator, success/failure с автоматическим поиском альтернатив? | Icon [S07]; `logical_failure` не задаёт распространение generation через выражения. Множественные возвращаемые значения Scheme — не поток альтернатив. |
| `evaluation.composition` | Обычное применение с аргументами или композиция преобразований неявного стека? | Forth [S06], Joy C; postfix notation сама по себе не доказывает concatenative semantics. |
| `evaluation.operand_order` | Порядок операндов определён, не определён или ограничен отдельными формами? | Scheme R7RS §4.1.3 против Self §3.1.5 [S02, S04]; strictness не определяет порядок. |
| `syntax.macro_hygiene` | Сохраняются ли связывания при вставке имён; как разрешён намеренный capture? | `syntax-rules` [S02]; procedural/syntactic описывает трансформер, не гигиену. |
| `typing.check_enforcement` | Обязательная проверка, необязательная проверка или отсутствие требования проверять? | Forth §3.1 [S06]: данные имеют типы, но система не обязана их проверять. Это не обычная dynamic type checking. |

Для последней оси перед принятием проверить, не лучше ли расширить существующую
`typing.checking` значением «проверка не требуется». Отдельный ID оправдан,
если «когда проверяют» и «обязаны ли проверять» действительно нужны независимо.
Не дублировать одно и то же знание в двух полях.

### 5.2. Данные и абстракция

| Новый ID | Вопрос / возможные различия | Свидетель и почему соседней оси мало |
|---|---|---|
| `data.array_shape` | Есть ли rank/shape/cells как часть языковой модели массива? | J/Dyalog [S05]; tuple/record не описывают размерности. |
| `evaluation.rank_lifting` | Как операция автоматически применяется к cells, как согласуются frames? | J rank conjunction, Dyalog rank operator [S05]; наличие N-D array не определяет lifting. |
| `data.collection_multiplicity` | Set, bag/multiset, sequence; для каких операций? | Datalog sets [S20] и SQL `SELECT ALL`/`DISTINCT` [S21]; отделить кратность от порядка. |
| `data.truth_domain` | Двухзначная логика, SQL three-valued logic; какие таблицы операций? | SQL [S21]; `nullability` задаёт отсутствие, но не значение `AND/OR/NOT`. Аппаратные X/Z сюда автоматически не переносить. |
| `numeric.radix_scale` | Binary/decimal, fixed/variable scale; какие семантические ограничения? | COBOL `PIC 999V9` [S23], PL/I C; не считать числовую запись литерала radix арифметики. |
| `data.representation_control` | Языковые правила размеров, группировки, layout и overlays? | COBOL group items/PICTURE [S23]; подробности `REDEFINES` требуют отдельного чтения. Наличие record не задаёт layout. |
| `objects.delegation` | Lookup через классы или через parent objects; сохраняется ли исходный receiver? | Self [S04]; количество родителей не отвечает на этот вопрос. |
| `abstraction.module_parameterization` | Параметризуются ли модули модулями с типовыми компонентами? | SML functors [S17]; это не просто namespaces или generic functions. |
| `typing.abstract_type_identity` | Transparent equality, fresh abstract identity при sealing/instantiation? | SML `:>` [S17]; `nominal/structural` недостаточно для происхождения абстрактного типа. |
| `typing.value_dependency` | Может ли тип зависеть от значения; каковы допустимые индексы? | Idris `Vect n a` [S18]; параметризация типом и параметризация значением различны. |
| `verification.totality` | Что проверяется: coverage, termination, productivity; обязательность и escape hatches? | Idris/Agda [S18, S19]; static typing не гарантирует ни завершение, ни покрытие. |
| `verification.behavioral_contracts` | Preconditions, postconditions, invariants и frame/data-dependency specifications? | Eiffel/Ada/SPARK [S12–S14]; интерфейс полиморфизма не задаёт поведение. |
| `verification.contract_enforcement` | Runtime monitoring, static proof, assumptions; какой профиль их включает? | Ada assertion policy, Eiffel monitoring, GNATprove [S12–S14]; механизм проверки независим от возможности записать предикат. |
| `memory.reference_permissions` | Read/write/identity rights и допустимые алиасы конкретной ссылки? | Pony `val` против `box`, `iso` против `ref` [S16]; immutable binding и shared reference не дают этих гарантий. |
| `evaluation.effect_polymorphism` | Может ли абстракция параметризоваться эффектами вызываемой функции? | Koka `map` сохраняет effect parameter `e` [S15]; `type_tracked` не означает polymorphic effects. |

`numeric.radix_scale` перед включением может потребовать разделения на radix и
scale: decimal floating point и decimal fixed point — разные случаи. Точно так
же termination и productivity не следует объединять в один безусловный bool.
Таблица задаёт вопросы для исследования, а не обещает идеальную окончательную
нормализацию за один проход.

### 5.3. Конкурентность, логика и время

| Новый ID | Вопрос / возможные различия | Свидетель и почему соседней оси мало |
|---|---|---|
| `concurrency.communication_coupling` | Buffered asynchronous send или synchronous rendezvous; что блокируется? | Erlang/occam [S08, S09]; оба используют message passing. |
| `concurrency.receive_selection` | FIFO head-only, selective mailbox matching, guarded channel alternatives? | Erlang [S08]; occam ALT нуждается в отдельном чтении полной спецификации. Coupling не задаёт selection. |
| `evaluation.data_availability` | Недостаток входной информации вызывает suspension? Узел ждёт все входы или поток — только реально нужные? | Oz/G [S10, S31]; unification и strictness этого не объясняют. |
| `logic.instantiation_modes` | Проверяются ли переходы free/ground и направление использования аргументов? | Mercury [S11]; `by_reference` и type annotation — не mode. |
| `logic.solution_cardinality` | Заявлены и проверены ли 0/1/many решений и возможность failure? | Mercury `det/semidet/multi/nondet` [S11]; это не schedule determinism и не termination. |
| `logic.fixed_point_semantics` | Результат задаётся замыканием отношений / наименьшей неподвижной точкой? | Positive finite Datalog [S20]; tabling — техника вычисления подцелей, не полное определение модели. |
| `logic.negation_policy` | Как интерпретируется отрицание и какие зависимости разрешены? | Stratification в Soufflé [S20]; не переносить на все Datalog extensions. |
| `constraints.store_rules` | Simplification, propagation, simpagation; какие факты сохраняются/удаляются? | CHR [S25]; `constraints` не задаёт правило изменения store. |
| `constraints.solution_objective` | Satisfaction или optimization по целевой функции? | MiniZinc [S26]; распространять ограничения можно и без оптимизации. |
| `rewriting.rule_application` | Что сопоставляется и заменяется, как выбирается правило? | Refal/SNOBOL4 C, CHR [S25] как проверенный контраст; pattern matching bool не описывает replacement/commitment. |
| `time.domain` | Нет встроенного времени, logical ticks, discrete simulation time, continuous/hybrid time? | Lustre/Verilog/Modelica [S22, S28, S29]; event-driven не определяет временную область. |
| `time.synchronous_reaction` | Реакция атомарна в логическом instant? Как связаны clocks и streams? | Lustre [S22], Esterel P [S27]; язык с rendezvous не становится синхронным реактивным языком. |
| `hardware.update_scheduling` | Когда применяется изменение сигнала: сейчас, в отложенной очереди; каковы фазы? | Verilog blocking/nonblocking [S29]; это не варианты обычного `bindings.assignment`. Точные event regions ещё сверить с IEEE. |
| `hardware.signal_domain` | 0/1/X/Z, strengths, resolution нескольких drivers? | Icarus [S29]; X/Z не SQL NULL, а resolution не arithmetic coercion. |
| `modeling.equation_causality` | Направленный поток вычисления или ненаправленные уравнения для совместного решения? | Modelica [S28]; `immutable_definition` не обозначает equation solving. |

Для synchronous languages требуется дополнительно исследовать constructive
causality, instantaneous cycles и preemption. Пока это **кандидатные уточнения**,
а не доказанные универсальные значения для Lustre и Esterel.

### 5.4. Носитель программы и границы обычного исполнения

| Новый ID | Вопрос / возможные различия | Свидетель и почему соседней оси мало |
|---|---|---|
| `syntax.program_representation` | Текст, структурный граф или пространственное изображение? | G [S31], Prograph P [S30], Piet B/C; это независимо от execution model. |
| `evaluation.reversibility` | Какие операции имеют семантически определённое обратное исполнение? | Janus P [S32], Q# adjoint [S33]; rollback/debugger undo не дают обратимости языка. |
| `quantum.classical_boundary` | Где находятся quantum values, classical control и measurement? | Silq [S34]; линейное использование ссылки не описывает суперпозицию и измерение. |
| `quantum.uncomputation` | Явное восстановление вспомогательного состояния или проверяемое автоматическое? | Silq [S34], Q# adjoint как строительный механизм [S33]; не эквивалент GC или destructor. |
| `probability.model_semantics` | Программа задаёт sample procedure, density или conditioning model? | Stan C; `ndet`/случайный выбор не определяет вероятностную меру и inference. |

Это backlog исследовательских осей. Перед добавлением каждой нужны минимум
положительный свидетель и контраст, scope по версиям/слоям, пример и решение,
почему недостаточно нового значения существующей концепции. Новые категории
не должны создаваться только для красивого распределения названий языков.

## 6. Минимальные различающие примеры

Фрагменты ниже — объяснительные примеры, **не запускались**. Полные runnable
showcases потребуют выбранной реализации, версии и ожидаемого результата.
Схематические фрагменты прямо отмечены.

### ALGOL 60: call-by-name уже представим в v2

Схема: процедура читает формальный `a`, меняет `i`, затем снова читает `a`;
вызов передаёт `A[i]`. При call-by-name повторное использование `a` заново
обращается к выражению с текущим `i`. При call-by-reference к уже выбранной
ячейке адрес остаётся прежним; при call-by-need закешированный результат не
становится повторным вычислением. Это **смысл существующих значений**
`subprograms.parameter_passing`, а не основание добавить `algol_style` [S01].

### Scheme: continuation и hygiene — разные свойства

```scheme
(+ 1 (call/cc (lambda (escape) (escape 41)))) ; => 42
```

Пример показывает только escape. Более сильная гарантия R7RS: захваченная
процедура имеет unlimited extent, может сохраняться и вызываться многократно;
она возвращает управление в захваченный контекст, а не обычным `return`
своему текущему caller [S02, §6.10]. Для самостоятельного multi-shot showcase
нужно явно задать верхнеуровневый контекст, чтобы не получить повторное
исполнение всего сценария случайно.

```scheme
(define-syntax keep-second
  (syntax-rules ()
    ((_ first second) (let ((tmp first)) second))))
(let ((tmp 7)) (keep-second 1 tmp)) ; => 7, не 1
```

Вставленное связывание `tmp` не захватывает `tmp` из аргумента макроса [S02, §4.3].
Ни `s_expressions`, ни `syntactic_macros` сами по себе это не гарантируют.

### J и Forth: другой способ композиции

```text
J:      m =: 2 3 $ 1 2 3 4 5 6
        +/"1 m                 NB. суммы строк: 6 15

Forth:  : square ( n -- n-squared ) dup * ;
        5 square               \ верхушка стека: 25
```

Для J значим rank применяемого verb и cells массива [S05]. Для Forth комментарий
`( n -- n-squared )` описывает эффект на data stack, но не является требованием
к статическому доказательству этого эффекта стандартной системой [S06].

### Icon: неудача — сигнал продолжить поиск

```text
sentence := "Store it in the neighboring harbor"
write(5 < find("or", sentence))
```

`find` сначала выдаёт 3; сравнение не удаётся; `find` возобновляется и выдаёт
23, которое печатается. Это пример из авторского overview [S07]. Обычная
функция поиска, возвращающая Optional с первым совпадением, иначе ведёт себя
при той же внешней проверке.

### Три разных «ожидания»

```text
Erlang: receive {wanted, X} -> X end
        неприменимое раннее сообщение остаётся в mailbox.

occam:  c ! 41  ||  c ? x
        схема параллельной отправки/приёма: оба участника встречаются;
        «||» здесь пояснительная запись, не синтаксис occam.

Oz:     local X Y in
          thread Y = X + 1 end
          X = 41
        end
        поток с Y ждёт значения X, затем может получить Y=42.
```

Источники: selective receive [S08], unbuffered synchronization [S09],
dataflow suspension [S10]. Никакой из этих механизмов не означает автоматически
фиксированный период реального времени.

### Mercury: направление и число решений

```text
:- mode append(in, in, out) is det.
:- mode append(out, out, in) is multi.
:- mode append(in, in, in) is semidet.
```

Это три режима одного отношения [S11]. Modes задают переходы instantiation;
determinism классифицирует возможные решения **при возвращении вызова**.
`det` не доказывает, что вызов завершится без исключения.

### Datalog: результат как замыкание

```text
edge(a,b). edge(b,a). edge(b,c).
path(X,Y) :- edge(X,Y).
path(X,Z) :- path(X,Y), edge(Y,Z).
```

Это абстрактная Datalog-нотация, не готовый Soufflé-файл с объявлениями типов.
Для положительного, function-free, range-restricted ядра на конечных данных
результат — наименьшее замыкание, содержащее edges и все выводимые paths.
Цикл не требует бесконечного добавления дубликатов. Это не универсальная
гарантия всех расширений: Soufflé с арифметическим порождением новых значений
может не завершаться [S20].

### SQL: кратность и UNKNOWN независимы

```sql
SELECT x FROM (VALUES (1), (1)) AS t(x);          -- две строки
SELECT DISTINCT x FROM (VALUES (1), (1)) AS t(x); -- одна строка
SELECT FALSE AND NULL, TRUE AND NULL;           -- FALSE, NULL
```

Профиль — PostgreSQL [S21]. Вторая пара выражений требует three-valued logic,
а не только отметки «есть null». Для `DISTINCT` NULL участвует в сравнении
дубликатов по специальным правилам; нельзя вывести его поведение из обычного
равенства nullable-значений.

### SML и Idris: разные границы абстракции

```sml
signature TOKEN = sig type t val zero : t end
functor MakeToken (X : sig end) :> TOKEN =
struct type t = int val zero = 0 end
structure A = MakeToken (struct end)
structure B = MakeToken (struct end)
(* A.zero и B.zero имеют разные абстрактные типы. *)
```

Opaque result signature создаёт новую абстрактную инстанциацию при применении
functor [S17]. Это не утверждение, что каждый type alias любого SML functor
всегда становится новым типом.

```idris
index : Fin n -> Vect n a -> a
```

Сигнатура из документации Idris связывает допустимый индекс с длиной вектора;
`Fin Z` не имеет конструктора [S18]. `Vect`/`Fin` — определения библиотеки,
а возможность зависимых типов — свойство языка. Завершение проверяется отдельно.

### Eiffel и COBOL: разные виды ограничений

```text
Eiffel, схема контракта deposit(sum):
  require sum >= 0
  ensure balance = old balance + sum

COBOL, объявление:
  01 Amount PIC 9(3)V9.
```

Первое задаёт отношение состояния до/после вызова [S14]. Второе определяет
десятичные позиции и подразумеваемую точку: сохранённые цифры `1234`
интерпретируются как `123.4` [S23]. PICTURE не нужно ошибочно называть полным
dependent type или доказанным поведенческим контрактом.

### Lustre, Modelica и Verilog: три смысла «одновременно»

```text
Lustre:   i = 0 -> pre(i) + a;
Modelica: equation
            v = R*i;
            der(x) = v;
Verilog:  always @(posedge clk) begin
            a <= b;
            b <= a;
          end
```

Lustre задаёт поток по тактам [S22]; Modelica — совместно выполняющиеся
уравнения с непрерывной и дискретной динамикой [S28]; Verilog — события и
отложенные обновления аппаратной модели [S29]. При известном начальном
`a=0, b=1` и отсутствии других writers Verilog-фрагмент обменивает значения
после обработки nonblocking updates. Вариант `a = b; b = a;` в одном блоке
последовательно прочитает уже изменённое `a`.

### Графы, ограничения, обратимость и квантовые состояния

- **G:** схема `input → f → g` задаёт зависимость, а размещение `g` левее `f`
  на холсте не меняет её. Отдельные готовые ветви допускают параллельное
  выполнение; физически одновременное исполнение не обещается [S31].
- **CHR:** `p(X) <=> q(X)` заменяет совпавшее ограничение; `p(X) ==> q(X)`
  сохраняет его и добавляет следствие. Это схемы, требующие declarations
  выбранного host-профиля [S25].
- **MiniZinc:** `var 1..9: x; constraint x > 4; solve minimize x;`
  задаёт задачу оптимизации, а не цикл перебора в порядке текста [S26].
- **Pony:** `String val` гарантирует неизменяемость объекта, тогда как
  `String box` даёт read-only view, совместимый и с некоторыми mutable aliases.
  Оба случая нельзя пометить одной `bindings.mutation: immutable` [S16].
- **Janus, C-деталь:** условно `x += y` обращается через `x -= y` при
  ограничениях, сохраняющих информацию; обычное `x = 0` её уничтожает.
  Конкретную грамматику, допустимость self-reference и правила `uncall` ещё
  проверить по тексту языка [S32].
- **Q#:** `Adjoint U(q)` допустимо для operation с соответствующей
  specialization; измерение не становится обратимым только от написания
  `Adjoint` [S33].
- **Silq:** временное `f(cand)` в quantum conditional нужно uncompute,
  чтобы не разрушить нужные когерентные связи. Автоматическое uncomputation
  подтверждено для lifted expressions с `qfree`-функциями и `const`-зависимостями,
  а не произвольного забывания любых qubits [S34].

## 7. Реестр источников и фактического чтения

**S/P относятся к тезису, а не престижу домена.** Для изменяемых `latest`,
`current`, `stable`, `release` страниц зафиксирована дата обращения; перед
публичной карточкой желательно закрепить версию или immutable revision.
В реестре есть и нормативные тексты, и первичные руководства реализаций;
их области доказательности различаются.

### 7.1. Полученные и прочитанные содержательные источники

| ID | URL и происхождение | Что действительно подтверждено |
|---|---|---|
| S01 | [Revised Report on ALGOL 60](https://www.masswerk.at/algol60/report.htm), исторический нормативный текст в сторонней HTML-перепечатке | §4.7.3.2 name replacement/call-by-name, переименование для избежания capture; §4.7.3.1 value. Перепечатка не современный официальный хост стандарта. |
| S02 | Scheme standards: [R7RS §4](https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-6.html), [§6](https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-8.html) | §4.1.3 unspecified argument order; §4.3 hygiene; §6.10 `call/cc`, unlimited extent, многократные вызовы, `dynamic-wind`. |
| S03 | GNU Smalltalk: [Conditions](https://www.gnu.org/software/smalltalk/manual/html_node/Conditions.html) | `ifTrue:` как message к Boolean с block argument; примечание о библиотечной природе conditional. Это руководство реализации. |
| S04 | Self project: [Handbook 2024.1, Language Reference](https://handbook.selflanguage.org/2024.1/langref.html) | Slots, left-to-right actual arguments, parent slots, dynamic inheritance, lookup, resend и non-local returns; также ограничения non-lifo blocks этой версии. |
| S05 | Jsoftware: [Nouns](https://www.jsoftware.com/help/dictionary/dicta.htm), [Verbs](https://www.jsoftware.com/help/dictionary/dictb.htm); Dyalog 19.0: [Rank](https://help.dyalog.com/19.0/Content/Language/Primitive%20Operators/Rank.htm) | Rank/shape/cells/frames, rank conjunction и agreement в J; monadic/dyadic cell selection у Dyalog rank operator. Правила двух языков не объявляются идентичными. |
| S06 | Forth standards: [Usage requirements](https://forth-standard.org/standard/usage) | §3.1 не требует data-type checking; §3.2.3 stacks; dictionary и среда исполнения. Для каждого дополнительного word нужно сверять word set. |
| S07 | Ralph Griswold / University of Arizona: [Icon overview, IPD266a, 1996](https://www2.cs.arizona.edu/icon/docs/ipd266.htm) | §§2–3 conditional expressions, generators, inherited failure/generation, goal-directed evaluation и scanning. |
| S08 | Erlang/OTP: [Concurrent Programming](https://www.erlang.org/doc/system/conc_prog.html) | Processes, `spawn`, `!`, input queue, сохранение неприменимых сообщений и selective receive. Не доказательство fairness или exactly-once delivery. |
| S09 | INMOS: [occam 2 Reference Manual, 1988: preface/contents](https://www.transputer.net/obooks/isbn-013629312-3/book.asp); [Run-time Model Specification SW-0064-4, §3](https://www.transputer.net/obooks/sw-0064-4/sw-0064-4.html) | CSP provenance и process/channel model; второй текст явно задаёт point-to-point synchronized unbuffered communication. Исторические документы на архивном, не действующем INMOS-хосте; scheduler/ABI разделы implementation-specific. |
| S10 | Mozart project archive: [Oz tutorial §1, v1.4.0](https://mozart.github.io/mozart-v1/doc-1.4.0/tutorial/node1.html) | Oz 1/2/3 distinction, futures, kernel, dataflow threads, suspension, monotonic variable store, mutable cells и ports. |
| S11 | Mercury: [Insts and modes](https://www.mercurylang.org/information/doc-release/mercury_ref/Insts-modes-and-mode-definitions.html), [Determinism categories](https://www.mercurylang.org/information/doc-release/mercury_ref/Determinism-categories.html) | `free/ground`, mode mappings и таблица cardinality/failure; оговорка о returning calls. Manual отдельно отмечает ограничения текущей реализации partially instantiated structures. |
| S12 | Ada Resource Association: [Ada 2012 RM §6.1.1](https://www.adaic.org/resources/add_content/standards/12rm/html/RM-6-1-1.html) | `Pre`, `Post`, class-wide aspects, `Old`, `Result`, assertion policy и dynamic checks. Не приписывается Ada 83. |
| S13 | AdaCore / Capgemini: [SPARK User's Guide, language overview](https://docs.adacore.com/spark2014-docs/html/ug/en/spark_2014.html) | SPARK как large subset of Ada with additions; разграничение Ada RM/SPARK RM/GNAT/GNATprove; перечень контрактов и supported profiles. Это обзор, не полный proof semantics. |
| S14 | Eiffel project: [Design by Contract, Assertions and Exceptions](https://www.eiffel.org/doc/eiffel/ET-_Design_by_Contract_(tm),_Assertions_and_Exceptions) | Preconditions/postconditions/invariants, `old`, monitoring levels. Прочитана содержательная часть после большого меню; defaults не обобщаются на все реализации/релизы. |
| S15 | Daan Leijen / Koka: [Book](https://koka-lang.github.io/koka/doc/book.html) | §§2.2–2.3: inferred effects, `total/exn/div`, effect-polymorphic `map`, effect handlers; разделы про `resume` и различное число resumptions. Это snapshot развивающегося языка. |
| S16 | Pony project: [Reference Capabilities](https://tutorial.ponylang.io/reference-capabilities/reference-capabilities.html) | Шесть capabilities, `val`/`box` distinction, isolation, mutable aliases и actor sharing. Полная soundness-теорема и FFI-границы не изучались. |
| S17 | SML/NJ / David MacQueen: [SML '97 Modules](https://www.smlnj.org/doc/Conversion/modules.html); SMLFamily: [Definitions index](https://smlfamily.github.io/) | Прочитан раздел о signatures/sharing и §1.3.9 opaque result signatures/fresh instantiation. Документ явно отделяет SML/NJ extensions/discrepancies. Индекс подтверждает происхождение Definition; полный PDF не изучен. |
| S18 | Idris 2 project: [Types and Functions](https://idris2.readthedocs.io/en/latest/tutorial/typesfuns.html) | Dependent types, `Vect`/`Fin`, dependent pairs, covering/partial и отдельный раздел Totality. Default covering не означает default total. |
| S19 | Agda project: [Termination Checking](https://agda.readthedocs.io/en/latest/language/termination-checking.html) | Structural/lexicographic recursion, `TERMINATING`, `NON_TERMINATING`, запрет `TERMINATING` в `--safe`; dependent types отдельно здесь не проверены. |
| S20 | Soufflé: [Tutorial](https://souffle-lang.github.io/tutorial), [Rules](https://souffle-lang.github.io/rules), [Relations](https://souffle-lang.github.io/relations); Microsoft Z3: [Basic Datalog](https://microsoft.github.io/z3guide/docs/fixedpoints/basicdatalog/) | Finite Datalog core, recursive closure, sets of tuples, stratifiable negation, potentially nonterminating arithmetic extensions; Z3 прямо описывает bottom-up fixed-point engine. Не все extensions сводятся к одному least-fixed-point правилу. |
| S21 | PostgreSQL: [Select Lists](https://www.postgresql.org/docs/current/queries-select-lists.html), [Logical Operators](https://www.postgresql.org/docs/current/functions-logical.html), получена документация 18 | Сохранение дубликатов по умолчанию, `DISTINCT`, отдельный статус `DISTINCT ON`; таблицы three-valued logic. ISO-текст SQL не получен. |
| S22 | Verimag, разработчики Lustre: [Language and Related Tools](https://www-verimag.imag.fr/The-Lustre-Programming-Language-and.html) | Unordered equations, clocked streams, `pre`/initialization, V4/V6 array differences. Не полная спецификация clock calculus. |
| S23 | GnuCOBOL: [Programmer's Guide](https://gnucobol.sourceforge.io/HTML/gnucobpg.html) | §§2.1.7–2.1.8 group items/files, §6.9.33 PICTURE и `V` scale. Руководство указывает July 2020 / 3.1 RC-1. Исторические рекламные обобщения руководства не использованы как факты. |
| S24 | ISO WG5: [Fortran 2008](https://wg5-fortran.org/f2008.html); Fortran community: [Learn](https://fortran-lang.org/learn/) | WG5 подтверждает coarrays 2008, дополнительные parallel features TS 18508 и последовательность редакций. Learn — указатель на учебные и нормативные материалы, не источник всех дат появления features. |
| S25 | SWI-Prolog / авторы CHR integration: [CHR Syntax and Semantics](https://www.swi-prolog.org/pldoc/man?section=chr-syntaxandsemantics) | Multi-headed rules, guards, active/passive constraints, commitment и три rule kinds. Описанная operational order — профиль CHR-in-Prolog. |
| S26 | MiniZinc project: [Basic Modelling](https://docs.minizinc.dev/en/stable/modelling.html) | Parameters/decision variables/domains, type-inst, constraints, satisfaction/optimization, отделение модели от выбора solver. |
| S27 | INRIA/CMA archive: [About Esterel](https://www-sop.inria.fr/esterel.org/files/Html/About/AboutEsterel.htm) | Подтверждены synchronous reactive language, control-dominated systems, происхождение и ссылки на Primer/Constructive Semantics. Детальная constructive/preemption semantics не прочитана. |
| S28 | Modelica Association: [Specification 3.6, Chapter 8](https://specification.modelica.org/maint/3.6/equations.html) | Equation sections против assignment, derivatives, when/reinit, synchronous data-flow principle, continuous integration и events. Не гарантия разрешимости любой записанной системы. |
| S29 | Icarus Verilog: [Simulation](https://steveicarus.github.io/iverilog/usage/simulation.html), [VVP Simulation Engine](https://steveicarus.github.io/iverilog/developer/guide/vvp/vvp.html) | Elaboration, simulation/synthesis distinction; events от nonblocking assignments, blocking updates, 0/1/X/Z и resolution. Первичный источник реализации, не полный IEEE scheduling standard. |
| S30 | Andescotia: [Marten 1.6](https://www.andescotia.com/products/marten/) | Прямо назван Prograph dataflow language; описаны graphical cases, operation nodes и links. Маркетинговая страница не даёт полной operational semantics. |
| S31 | NI: [Benefits of Programming Graphically in LabVIEW](https://www.ni.com/en/shop/labview/benefits-of-programming-graphically-in-ni-labview.html) | G как язык, LabVIEW как среда; all-input readiness, data-dependent ordering и implicit parallelism. Сравнительные performance/productivity заявления не используются. |
| S32 | Tetsuo Yokoyama, research archive: [Janus](https://www.tetsuo.jp/ref/janus.html) | Идентификация time-reversible language и письма Christopher Lutz 1986. [PDF письма](https://www.tetsuo.jp/ref/janus.pdf) получен как бинарный текст, его содержание не засчитано прочитанным. |
| S33 | Microsoft: [Q# Functors](https://learn.microsoft.com/en-us/azure/quantum/user-guide/language/expressions/functorapplication) | `Adjoint` и `Controlled`, условия specialization, adjoint как U† и их композиция. Не утверждение, что каждая Q# operation unitary. |
| S34 | ETH Zürich / Silq authors: [Overview](https://silq.ethz.ch/overview), [project](https://silq.ethz.ch/) | Classical/quantum values, measurement, `qfree/const`, consumption, automatic uncomputation и его ограничения, unsafe explicit escape cases. |

### 7.2. Неполученные или недостаточные источники

| ID / объект | Проверенный URL | Результат и последствие |
|---|---|---|
| U01 / SNOBOL4 | <https://www.snobol4.org/docs/burks/tutorial/contents.htm>; <https://www.snobol4.com/docs/burks/tutorial/contents.htm> | Первый ответ пустой, второй — transport error. String-pattern/replacement semantics остаётся C. Нужен читаемый manual или авторская архивная копия. |
| U02 / Refal | <https://refal.botik.ru/book/html/>; <https://www.refal.net/> | Первый — transport error; второй — навигационная страница с проблемами кодировки. Семантическое подтверждение не получено. |
| Старый Oz URL | <https://www.mozart-oz.org/documentation/tutorial/node1.html> | Возвращает посторонний сайт о казино. Исключён как свидетель; использован проектный архив S10. |
| Lustre V6 PDF | <https://www-verimag.imag.fr/DIST-TOOLS/SYNCHRONE/lustre-v6/doc/lv6-ref-man.pdf> | Получен PDF как бинарный текст, а не читаемая спецификация. Основные тезисы опираются на HTML S22. |
| Esterel Primer / mirror | <https://www-sop.inria.fr/members/Gerard.Berry/Papers/EsterelPrimer.pdf>; <https://www.cs.columbia.edu/~sedwards/classes/2002/w4995-02/esterel.pdf> | Первый 404; второй вернул неразобранный PDF. S27 подтверждает семейство, но не детали causality/preemption. |
| Janus semantics | <https://www.tetsuo.jp/ref/janus.pdf> | Бинарный ответ не засчитан чтением. Требуется текст/разобранный PDF для точных ограничений updates и control flow. |
| LabVIEW manual route | <https://www.ni.com/docs/en-US/bundle/labview/page/block-diagram-data-flow.html> | Получена оболочка сайта без нужного раздела. Содержательная NI-статья S31 впоследствии подтвердила readiness rule. |
| Ada 2022 route | <https://www.ada-auth.org/standards/22rm/html/RM-6-1-1.html> | Timeout. Контракты подтверждены по Ada 2012 RM S12; изменения 2022 не исследованы. |
| SML Definition route | <https://smlfamily.github.io/sml97-defn.html> | 404. Реальный index S17 содержит PDF, но для semantics использован прочитанный авторский SML/NJ-текст. |

Неудачные маршруты, после которых найдена содержательная замена, не понижают
соответствующий подтверждённый тезис. Но список ссылок без прочитанного тела
не переводит кандидатный язык в S. Все остальные C-строки §3 имеют статус
**«первичные источники ещё не проверены»**, даже если язык широко известен.

## 8. Как превратить карту в устойчивое расширение

Для каждого из 15 пакетов следующий артефакт исследования должен содержать:

1. Выбранную редакцию и профиль реализации; понятное происхождение источника.
2. Два маленьких примера, различающих новое свойство и уже имеющееся соседнее.
3. Разделение `language`, `standard_library`, `implementation`, `tooling`.
4. Одно из решений: достаточно нынешнего ID; требуется новое значение;
   требуется независимый ID; пока достаточно `note`.
5. Явные «не исследовано» и «неприменимо», без ложных отрицаний и требования
   заполнить каждую ось для каждого языка.

Первые концептуальные пакеты: continuations/hygiene, arrays/rank, stack/result
protocols, dataflow/communication, modes/fixed points, dependent types/contracts,
time/equations/hardware. Эти пакеты можно исследовать независимо; принятие
одного не обязывает немедленно расширять всю схему.

### Открытые вопросы после этого прохода

- Прочитать полноценные определения Janus, Esterel, Refal и SNOBOL4;
  краткий официальный overview не заменяет operational semantics.
- Сверить Verilog с доступной конкретной IEEE-редакцией: scheduling regions,
  races и границы synthesizable subset.
- Уточнить Fortran по версиям: FORTRAN 77 → arrays/modules/recursion в 90 →
  дальнейшие OO/C-interoperability/coarrays. Не сводить всю линию к фиксированной
  форме старого исходника или «передаче всегда по ссылке».
- Проверить альтернативы каждого ID: например, G и Oz разделяют зависимость
  от данных, но имеют разные правила готовности и носитель программы.
- Исследовать числовую семантику глубже: precision, rounding и overflow
  независимо от radix/scale; одного ярлыка decimal недостаточно.
- Сверить Agda dependent types и безопасные профили, Racket phases, Stan
  probability semantics по первичным текстам; они здесь не объявлены изученными.

**Результат прохода:** широкая, ограниченная по объёму карта с проверенными
семантическими опорами и честным backlog. Цель дальнейшего каталога — объяснять
различия вычисления, а не коллекционировать названия и не подгонять историю
языков под конструкции уже выбранной тройки.
