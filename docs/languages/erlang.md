---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Erlang

Erlang — функциональный язык с динамической типизацией, однократным связыванием переменных и сопоставлением с образцом в головах функций, `case` и `receive`. Конкурентность строится на лёгких изолированных процессах, обменивающихся асинхронными сообщениями; отказоустойчивость — на связях, мониторах и супервизорах OTP по принципу «пусть упадёт». Профиль — Erlang/OTP Reference Manual; свойства виртуальной машины BEAM (сборка мусора, горячая замена кода) отмечены слоем реализации.

*Карточка сравнительная: 38/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1986 — [Wikidata P571](https://www.wikidata.org/wiki/Q334879) (получено 2026-09-25) |
| Авторы | [Джо Армстронг](people.md#armstrong), [Роберт Вирдинг](people.md#virding) |
| Организации | Ericsson |
| Сайт | <https://www.erlang.org/> |
| Спецификация | <https://www.erlang.org/doc/system/reference_manual.html> |
| Внешние каталоги | [Wikidata Q334879](https://www.wikidata.org/wiki/Q334879) |

## Статьи { #articles }

- [Erlang: модель ошибок «let it crash»](../garden/erlang-let-it-crash.md)

## Люди { #people }

- [Джо Армстронг](people.md#armstrong) — Один из создателей Erlang в Ericsson; в диссертации 2003 года описал построение отказоустойчивых систем из изолированных процессов.
- [Роберт Вирдинг](people.md#virding) — Один из первых разработчиков Erlang в лаборатории Ericsson Computer Science Laboratory.

## Публикации { #publications }

- Джо Армстронг. *A History of Erlang*. HOPL III, 2007. DOI: [10.1145/1238844.1238850](https://doi.org/10.1145/1238844.1238850). Первичный рассказ о происхождении процессов, сообщений и обработки ошибок в Erlang. ([в источниках](sources.md#hopl-erlang))
- Джо Армстронг. [Making Reliable Distributed Systems in the Presence of Software Errors](https://erlang.org/download/armstrong_thesis_2003.pdf). KTH, PhD thesis, 2003. Обоснование принципа «пусть упадёт», изоляции процессов и деревьев супервизоров. ([в источниках](sources.md#armstrong-thesis))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **otp** — Erlang Reference Manual и системная документация Erlang/OTP (текущая онлайн-редакция); библиотеки STDLIB/OTP помечены слоем standard_library, свойства ERTS/BEAM — implementation. Конкретный выпуск OTP не фиксируется.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Связывание образцом (layer: language, profile: otp)** — Переменная связывается при успешном сопоставлении образца: в операторе `=`, аргументах клаузы, `case`, `receive` и генераторах. Отдельного объявления нет. ([Erlang Reference Manual — Variables](https://www.erlang.org/doc/system/expressions.html#variables))

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Однократное связывание логической переменной (layer: language, profile: otp)** — Переменная связывается один раз в пределах клаузы; повторное `X = …` с уже связанной `X` — проверка равенства, а не присваивание. В отличие от логической переменной Prolog, связывание не отменяется возвратом. ([Erlang Reference Manual — Variables: single assignment](https://www.erlang.org/doc/system/expressions.html#variables))

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Распаковка при присваивании (layer: language, profile: otp)** — `Pattern = Expr` вычисляет правую часть и сопоставляет её с образцом, связывая все несвязанные переменные образца (деструктуризация кортежей, списков, map). Неудача — исключение `badmatch`. Это не унификация: правая часть — вычисленный терм без несвязанных переменных. ([Erlang Reference Manual — The Match Operator](https://www.erlang.org/doc/system/expressions.html#the-match-operator))

### Области видимости { #scope }

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Логическая клауза (layer: language, profile: otp)** — Областью переменной является клауза функции; переменная, связанная лишь в части ветвей `if`/`case`/`receive`, считается небезопасной после выражения. ([Erlang Reference Manual — Variables: scope](https://www.erlang.org/doc/system/expressions.html#variables))
- **Генераторная конструкция (layer: language, profile: otp)** — Переменные генераторов локальны для списочного, битового или map-включения.
- **Подпрограмма (layer: language, profile: otp, applies_to: `fun`-выражения)** — Переменные, связанные в теле `fun`, локальны для него.

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Динамическая (layer: language, profile: otp)** — Тип значения проверяется операцией при выполнении: `1 + a` возбуждает `badarith`. Спецификации `-spec` не проверяются компилятором. ([Erlang Reference Manual — Errors and Error Handling: Exceptions](https://www.erlang.org/doc/system/errors.html#exceptions))

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Необязательны (layer: language, profile: otp)** — `-spec` и `-type` — необязательные атрибуты модуля для документации и анализаторов; на исполнение они не влияют. ([Erlang Reference Manual — Types and Function Specifications](https://www.erlang.org/doc/system/typespec.html))

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **да (layer: tooling, profile: otp, implementation: Dialyzer)** — Dialyzer выводит success types и сообщает о гарантированных несоответствиях; это внешний анализатор, а не часть семантики языка, и он не отвергает все небезопасные программы. ([Dialyzer](https://www.erlang.org/doc/apps/dialyzer/dialyzer.html))

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: otp)** — BIF `list_to_integer/1`, `atom_to_list/1`, `integer_to_binary/1` и т. п.; строк в числа и обратно неявно не преобразуют. ([Erlang Reference Manual — Type Conversions](https://www.erlang.org/doc/system/data_types.html#type-conversions))
- **Неявные (layer: language, profile: otp, applies_to: арифметика и сравнение целых с float)** — В смешанной арифметике целое приводится к float; `==` сравнивает числа, а `=:=` различает `1` и `1.0`.

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Кортежи (layer: language, profile: otp)** — Кортеж фиксированного размера; по соглашению первый элемент-атом служит меткой (`{ok, V}`, `{error, R}`). ([Erlang Reference Manual — Tuple](https://www.erlang.org/doc/system/data_types.html#tuple))
- **Записи и структуры (layer: language, profile: otp)** — Запись с именованными полями — синтаксис времени компиляции, транслируемый в кортеж; отдельным типом времени выполнения не является. ([Erlang Reference Manual — Record](https://www.erlang.org/doc/system/data_types.html#record))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Охранные условия (layer: language, profile: otp)** — `if` выбирает первую ветвь с истинной последовательностью охран; охраны также допускаются в головах функций, `case`, `receive` и `fun`. Если ни одна ветвь `if` не подошла — ошибка `if_clause`. ([Erlang Reference Manual — If](https://www.erlang.org/doc/system/expressions.html#if); [Erlang Reference Manual — Guard Sequences](https://www.erlang.org/doc/system/expressions.html#guard-sequences))
- **Условное выражение (layer: language, profile: otp)** — `if`, `case` и `receive` — выражения, возвращающие значение выбранной ветви.

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **нет (layer: language, profile: otp)** — `case` сопоставляет с образцами, а не только сравнивает значения; отдельного switch нет.

#### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **да (layer: language, profile: otp)** — Образцы в головах клауз функций и `fun`, в `case`, `receive`, `try … catch` и операторе `=`; поддерживаются литералы, кортежи, списки, map и битовые образцы. Неудача без подходящей клаузы — исключение. ([Erlang Reference Manual — Pattern Matching](https://www.erlang.org/doc/system/patterns.html))

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · [в онтологии](concepts.md#control-do-while)

- **нет (layer: language, profile: otp)** — Циклических конструкций нет; повторение выражается рекурсией.

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **Генераторная конструкция (layer: language, profile: otp)** — Списочные, битовые и (с OTP 26) map-включения с генераторами и фильтрами. ([Erlang Reference Manual — Comprehensions](https://www.erlang.org/doc/system/expressions.html#comprehensions))
- **Функции обхода (layer: standard_library, profile: otp)** — `lists:map/2`, `lists:foldl/3`, `lists:foreach/2`; общий механизм повторения — хвостовая рекурсия. ([STDLIB — lists](https://www.erlang.org/doc/apps/stdlib/lists.html))

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: otp)** — Функция идентифицируется модулем, именем и арностью: `f/1` и `f/2` — разные функции. Несколько клауз одной функции выбираются сопоставлением образцов при выполнении, а не перегрузкой по статическим сигнатурам. ([Erlang Reference Manual — Function Declaration Syntax](https://www.erlang.org/doc/system/ref_man_functions.html#function-declaration-syntax))

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: otp)** — Аргументы — неизменяемые термы, сопоставляемые с образцами головы клаузы; из-за неизменяемости разделение представления в пределах процесса ненаблюдаемо.

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: otp)** — `fun` захватывает значения связанных переменных охватывающей клаузы; так как они неизменяемы, захват эквивалентен копированию значения. ([Erlang Reference Manual — Fun Expressions](https://www.erlang.org/doc/system/expressions.html#fun-expressions))

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: otp)** — `fun (X) -> X + 1 end`; `fun m:f/N` и `fun f/N` ссылаются на именованные функции.

### Полиморфизм и организация { #abstraction }

#### Контракты полиморфизма { #abstraction-contracts }

*Polymorphic contracts* · [в онтологии](concepts.md#abstraction-contracts)

- **Интерфейсы (layer: language, profile: otp, applies_to: атрибут `-behaviour` и `-callback`)** — Поведение объявляет набор обратных вызовов, которые модуль обязан экспортировать; компилятор предупреждает об отсутствующих. Стандартные поведения (`gen_server`, `supervisor`) задаёт OTP. ([Erlang Reference Manual — Behaviour Module Attribute](https://www.erlang.org/doc/system/modules.html#behaviour-module-attribute))

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Отсутствует (layer: language, profile: otp)**

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Явная граница экспорта (layer: language, profile: otp)** — Модуль задаёт `-module` и `-export([f/1, …])`; неэкспортированные функции недоступны извне модуля. ([Erlang Reference Manual — Module Syntax](https://www.erlang.org/doc/system/modules.html#module-syntax))
- **Модули как объекты времени выполнения (layer: implementation, profile: otp, implementation: ERTS/BEAM)** — Модули загружаются и заменяются в работающей системе; одновременно могут существовать старая и текущая версии кода, полностью квалифицированный вызов переходит к текущей. ([Erlang Reference Manual — Code Replacement](https://www.erlang.org/doc/system/code_loading.html#code-replacement))

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: otp)** — Аргументы вычисляются до вызова; `andalso`/`orelse` вычисляют правый операнд только при необходимости.

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · [в онтологии](concepts.md#evaluation-tail-calls)

- **да (layer: language, profile: otp)** — Reference Manual гарантирует, что вызов в последнем выражении тела не потребляет стек; бесконечный цикл хвостовой рекурсией может работать неограниченно. На этом строятся циклы серверных процессов. ([Erlang Reference Manual — Tail recursion](https://www.erlang.org/doc/system/ref_man_functions.html#tail-recursion))

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Трассирующая сборка мусора (layer: implementation, profile: otp, implementation: ERTS/BEAM)** — У каждого процесса собственная куча, собираемая независимо; крупные бинарные данные хранятся вне куч процессов с подсчётом ссылок. ([ERTS — Erlang Garbage Collector](https://www.erlang.org/doc/apps/erts/garbagecollection.html))

#### Передача и разделение владения { #memory-transfer }

*Ownership transfer and sharing* · [в онтологии](concepts.md#memory-transfer)

- **Копирование значения (layer: language, profile: otp, applies_to: сообщения между процессами)** — Процессы не разделяют память: терм сообщения копируется в кучу получателя (кроме реализационного исключения для крупных бинарных данных).

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: language, profile: otp)** — Три класса исключений — `error`, `exit`, `throw` — перехватываются `try … catch Class:Reason:Stack`; `catch Expr` класса не различает. ([Erlang Reference Manual — Exceptions](https://www.erlang.org/doc/system/errors.html#exceptions); [Erlang Reference Manual — Try](https://www.erlang.org/doc/system/expressions.html#try))
- **Размеченный результат (layer: language, profile: otp, applies_to: соглашения библиотек)** — Ожидаемые неудачи обычно возвращаются кортежами `{ok, Value}` / `{error, Reason}`; выражение `maybe` с `?=` сокращает их цепочки. Размеченность — соглашение, а не статический тип. ([Erlang Reference Manual — Maybe](https://www.erlang.org/doc/system/expressions.html#maybe))

#### Диагностика неиспользованного результата { #errors-must-use }

*Unused-result diagnostics* · [в онтологии](concepts.md#errors-must-use)

- **Нет специальной диагностики (layer: language, profile: otp)** — Результат выражения можно не использовать; компилятор предупреждает о неиспользуемых переменных и некоторых бесполезных выражениях, но не требует обработки `{error, _}`.

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Блок finally / unwind-protect (layer: language, profile: otp)** — `try … after … end` выполняет секцию `after` при нормальном завершении и при исключении. ([Erlang Reference Manual — Try](https://www.erlang.org/doc/system/expressions.html#try))

#### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · [в онтологии](concepts.md#resources-concurrency)

- **Акторы (layer: language, profile: otp)** — Процесс — изолированная единица с собственным состоянием и почтовым ящиком, создаваемая `spawn`; взаимодействие только сообщениями. Процессы — объекты VM, а не процессы ОС. ([Erlang Reference Manual — Process Creation](https://www.erlang.org/doc/system/ref_man_processes.html#process-creation))
- **Передача сообщений (layer: language, profile: otp)** — `Pid ! Message` и `receive`; связи (`link`) и мониторы доставляют сигналы о завершении процессов, на них строятся супервизоры OTP. ([Erlang Reference Manual — Links](https://www.erlang.org/doc/system/ref_man_processes.html#links); [Erlang Reference Manual — Monitors](https://www.erlang.org/doc/system/ref_man_processes.html#monitors))

#### Синхронизация отправки и приёма { #resources-communication-coupling }

*Send and receive coupling* · [в онтологии](concepts.md#resources-communication-coupling)

- **Асинхронная отправка в почтовый ящик (layer: language, profile: otp)** — Отправка `!` помещает сообщение в очередь получателя и не ждёт приёма; синхронный запрос-ответ (`gen_server:call`) строится поверх двух асинхронных сообщений. ([Erlang Reference Manual — Send](https://www.erlang.org/doc/system/expressions.html#send))

#### Выбор сообщения из очереди { #resources-receive-selection }

*Message selection from a queue* · [в онтологии](concepts.md#resources-receive-selection)

- **Выбор по образцу с пропуском неподходящих (layer: language, profile: otp)** — `receive` выбирает первое от начала очереди сообщение, подходящее под один из образцов с охраной; прочие сообщения остаются в очереди. Поиск линейный по длине очереди; `after` задаёт тайм-аут. ([Erlang Reference Manual — Receive](https://www.erlang.org/doc/system/expressions.html#receive))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: otp)** — Составные выражения `case`, `if`, `receive`, `try`, `fun`, `begin` закрываются ключевым словом `end`.

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Точка в конце клаузы (layer: language, profile: otp)** — Форма верхнего уровня (атрибут или объявление функции) заканчивается точкой; `,` разделяет выражения тела, `;` — клаузы. Все три — разделители грамматики, а не необязательная пунктуация. ([Erlang Reference Manual — Module Syntax](https://www.erlang.org/doc/system/modules.html#module-syntax))

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да (layer: language, profile: otp)** — Регистр первой буквы различает переменные (заглавная или `_`) и атомы (строчная).

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Текстовые макросы (layer: language, profile: otp)** — Препроцессор `epp`: `-define`, `?MACRO`, `-include`, условная компиляция; макросы раскрываются на уровне токенов. ([Erlang Reference Manual — Preprocessor](https://www.erlang.org/doc/system/macros.html))
- **Синтаксические макросы (layer: implementation, profile: otp, implementation: компилятор Erlang/OTP, applies_to: parse transforms)** — Модуль parse transform получает и возвращает абстрактное синтаксическое дерево модуля при компиляции; механизм не считается рекомендуемым для обычного кода.
- **Построение и выполнение кода (layer: standard_library, profile: otp)** — Модули `erl_scan`, `erl_parse`, `erl_eval` и `compile` позволяют разобрать, вычислить или скомпилировать и загрузить код во время выполнения.

#### Гигиена макросов { #syntax-macro-hygiene }

*Macro hygiene* · [в онтологии](concepts.md#syntax-macro-hygiene)

- **Нет автоматической защиты от захвата (layer: language, profile: otp, applies_to: макросы `-define`)** — Раскрытие подставляет токены; имена переменных в теле макроса могут совпасть с переменными места использования.

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Функциональная (layer: language, profile: otp)** — Неизменяемые данные, функции высшего порядка и рекурсия; побочные эффекты (сообщения, I/O) не ограничены типами.
- **Декларативная (layer: language, profile: otp, applies_to: сопоставление с образцом и охраны)** — Выбор клауз по образцам описывает форму данных, но порядок вычисления и эффекты остаются явными.

### Семантика данных { #data }

#### Ограничение числовой точности { #data-numeric-precision }

*Numeric precision bound* · [в онтологии](concepts.md#data-numeric-precision)

- **Нефиксированная заранее разрядность (layer: language, profile: otp, applies_to: целые)** — Целые не ограничены фиксированной разрядностью: при выходе за машинное слово представление автоматически расширяется (bignum), ограничение — память и системные пределы. ([Erlang Efficiency Guide — Memory usage: small and large integers](https://www.erlang.org/doc/system/memory.html))
- **Фиксированная разрядность типа или поля (layer: language, profile: otp, applies_to: float)** — 64-битные числа с плавающей точкой без Inf и NaN: такие результаты вызывают `badarith`. ([Erlang Reference Manual — Representation of Floating Point Numbers](https://www.erlang.org/doc/system/data_types.html#representation-of-floating-point-numbers))
