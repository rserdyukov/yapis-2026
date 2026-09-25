---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Go

Go — компилируемый императивный язык со статической типизацией, сборкой мусора и встроенными в язык горутинами и каналами. Интерфейсы реализуются структурно, без объявления `implements`; наследования реализации нет, а ошибки обычно возвращаются как значения типа `error`. Описан срез по спецификации языка go1.27 и стандартной библиотеке; свойства компилятора gc и утилит отмечены отдельными слоями.

*Карточка сравнительная: 38/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 2009 — [Wikidata P571](https://www.wikidata.org/wiki/Q37227) (получено 2026-09-25) |
| Авторы | [Роб Пайк](people.md#pike), [Кен Томпсон](people.md#thompson), [Роберт Гризмер](people.md#griesemer) |
| Организации | Google |
| Сайт | <https://go.dev/> |
| Спецификация | <https://go.dev/ref/spec> |
| Внешние каталоги | [Wikidata Q37227](https://www.wikidata.org/wiki/Q37227) |

## Версии { #versions }

Перечислены вехи, на которые ссылаются концепции ниже, а не все выпуски.

| Версия | Дата | Тип | Источник |
|---|---|---|---|
| Go 1 — первый выпуск | 2012-03-28 | выпуск | [Go — Release History](https://go.dev/doc/devel/release) (получено 2026-09-25) |
| Go 1.18 | 2022-03-15 | выпуск | [Go 1.18 Release Notes](https://go.dev/doc/go1.18) (получено 2026-09-25) |
| Go 1.27 — актуальная | 2026-08-19 | выпуск | [Go — Release History](https://go.dev/doc/devel/release) (получено 2026-09-25) |

## Статьи { #articles }

- [Go: сознательная бедность языка](../garden/go-simplicity.md)

## Люди { #people }

- [Кен Томпсон](people.md#thompson) — Соавтор Unix и языка B в Bell Labs; один из трёх авторов Go в Google.
- [Роб Пайк](people.md#pike) — Один из трёх авторов Go в Google; ранее участвовал в разработке Plan 9 и вместе с Кеном Томпсоном создал UTF-8.
- [Роберт Гризмер](people.md#griesemer) — Один из трёх авторов Go и соавтор его спецификации.

## Публикации { #publications }

- Роб Пайк, Роберт Гризмер, Кен Томпсон, Russ Cox, Ian Lance Taylor. *The Go Programming Language and Environment*. Communications of the ACM 65(5), 2022. DOI: [10.1145/3488716](https://doi.org/10.1145/3488716). Авторы Go о целях языка — масштаб разработки, простота, инструменты — и о сознательно не включённых возможностях. ([в источниках](sources.md#go-cacm-2022))
- Роб Пайк. [Go at Google: Language Design in the Service of Software Engineering](https://go.dev/talks/2012/splash.article). SPLASH 2012, 2012. DOI: [10.1145/2384716.2384720](https://doi.org/10.1145/2384716.2384720). Почему в Go нет исключений, наследования и перегрузки: язык проектировался под большие кодовые базы и команды. ([в источниках](sources.md#pike-go-at-google))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **go127** — The Go Programming Language Specification, Language version go1.27 (May 26, 2026), и стандартная библиотека; реализация по умолчанию — тулчейн go.dev (компилятор gc).

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: go127)** — Имена вводятся объявлениями `var`, `const`, `type`, `func` и короткой формой `x := expr`. `:=` — тоже объявление: слева должно быть хотя бы одно новое имя в текущем блоке. ([Go spec — Short variable declarations](https://go.dev/ref/spec#Short_variable_declarations); [Go spec — Variable declarations](https://go.dev/ref/spec#Variable_declarations))

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: go127)**
- **Распаковка при присваивании (layer: language, profile: go127)** — Кортежное присваивание `a, b = b, a` и приём нескольких результатов вызова `v, err := f()`. Операнды вычисляются до присваиваний; распаковки структур или срезов по образцу нет. ([Go spec — Assignment statements](https://go.dev/ref/spec#Assignment_statements))

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: go127)** ([Go spec — Declarations and scope](https://go.dev/ref/spec#Declarations_and_scope))

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Блок (layer: language, profile: go127)** — Блоки в фигурных скобках, а также неявные блоки `if`, `for`, `switch` и каждой ветви `case`; блоки вселенной, пакета и файла входят в ту же иерархию. ([Go spec — Blocks](https://go.dev/ref/spec#Blocks))
- **Модуль (layer: language, profile: go127, applies_to: блок пакета и блок файла)** — Объявления верхнего уровня видимы во всём пакете; имена импортируемых пакетов — только в файле с импортом.

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

*Name shadowing* · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: go127)** — Объявление во вложенном блоке скрывает внешнее, например `err` внутри `if`. Повтор имени в `:=` в том же блоке не создаёт новую переменную, а присваивает уже объявленной.

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Статическая (layer: language, profile: go127)** — Типы проверяются компилятором; утверждение типа `x.(T)` и type switch проверяют динамический тип значения интерфейса во время выполнения.

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **да (layer: language, profile: go127)** — Тип переменной выводится из инициализатора в `var x = e` и `x := e`; с Go 1.18 выводятся и аргументы типов обобщённых функций. Параметры и результаты функций аннотируются всегда. ([Go spec — Type inference](https://go.dev/ref/spec#Type_inference))

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: go127)** — Смешивать разные числовые типы нельзя, даже `int` и `int64`: нужна явная конверсия `T(x)`. Нетипизированные константы неявно принимают нужный тип, если значение в нём представимо. ([Go spec — Conversions](https://go.dev/ref/spec#Conversions); [Go spec — Representability](https://go.dev/ref/spec#Representability))

#### Совместимость типов { #typing-compatibility }

*Type compatibility* · [в онтологии](concepts.md#typing-compatibility)

- **Номинальная (layer: language, profile: go127, applies_to: определённые (именованные) типы)** — `type Celsius float64` вводит новый тип, отличный от `float64`; присваивание между ними требует конверсии. ([Go spec — Type identity](https://go.dev/ref/spec#Type_identity))
- **Структурная (layer: language, profile: go127, applies_to: реализация интерфейсов и идентичность безымянных составных типов)** — Тип реализует интерфейс, если его набор методов содержит методы интерфейса; объявлять это не нужно. Безымянные типы-литералы с одинаковой структурой идентичны. ([Go spec — Implementing an interface](https://go.dev/ref/spec#Implementing_an_interface); [Go spec — Assignability](https://go.dev/ref/spec#Assignability))

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Записи и структуры (layer: language, profile: go127)** — `struct` с именованными и встроенными полями; значения создаются составными литералами `Point{X: 1, Y: 2}`. Несколько результатов функции — не тип-кортеж: их нельзя сохранить в одну переменную. ([Go spec — Struct types](https://go.dev/ref/spec#Struct_types); [Go spec — Composite literals](https://go.dev/ref/spec#Composite_literals))

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Специальное значение (layer: language, profile: go127)** — `nil` — нулевое значение указателей, срезов, отображений, каналов, функций и интерфейсов. Числа, строки, массивы и структуры не бывают `nil`: они имеют собственные нулевые значения. ([Go spec — The zero value](https://go.dev/ref/spec#The_zero_value))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: go127)** — `if` с необязательным оператором инициализации `if v, ok := m[k]; ok {…}`. Тернарного условного выражения нет. ([Go spec — If statements](https://go.dev/ref/spec#If_statements); [Go FAQ — Does Go have the ?: operator?](https://go.dev/doc/faq#Does_Go_have_a_ternary_form))

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: go127)** — Выражение-switch с произвольными выражениями в `case` и type switch по динамическому типу. Переход в следующую ветвь только явным `fallthrough`. ([Go spec — Switch statements](https://go.dev/ref/spec#Switch_statements))

<a id="req-7-2-until"></a>

#### Цикл до истинности условия { #control-until }

*Until loop* · [в онтологии](concepts.md#control-until)

- **Отдельная конструкция отсутствует (layer: language, profile: go127)** — `for` — единственный оператор цикла; отдельных `while`, `until` и `repeat` нет.

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · [в онтологии](concepts.md#control-do-while)

- **нет (layer: language, profile: go127)** — Цикл с постусловием имитируют `for { …; if !cond { break } }`.

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **Инициализация / условие / шаг (layer: language, profile: go127)** — `for init; cond; post {}`; с Go 1.22 каждая итерация получает собственную переменную цикла. Форма `for cond {}` заменяет while. ([Go spec — For statements](https://go.dev/ref/spec#For_statements))
- **По последовательности или итератору (layer: language, profile: go127)** — `for k, v := range x` по массивам, срезам, строкам (по рунам), отображениям, каналам, целым числам и функциям-итераторам; последние две формы появились в Go 1.22–1.23. ([Go spec — For statements with range clause](https://go.dev/ref/spec#For_range))

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: go127)** — Функции и методы не перегружаются по сигнатуре: имя в блоке уникально. ([Go FAQ — Why does Go not support overloading?](https://go.dev/doc/faq#overloading))

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: go127)** — Аргументы, включая структуры и массивы, копируются. Срез, отображение, канал и указатель копируются как дескрипторы, поэтому изменения данных через них видны вызывающему. ([Go FAQ — When are function parameters passed by value?](https://go.dev/doc/faq#pass_by_value))

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: go127)** — Функциональные литералы захватывают переменные охватывающей функции по ссылке; захваченные переменные живут, пока доступно замыкание. ([Go spec — Function literals](https://go.dev/ref/spec#Function_literals))

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: go127)** — Функциональный литерал `func(x int) int { return x * 2 }`; вложенные именованные объявления `func` внутри функции запрещены.

#### Параметрический полиморфизм { #subprograms-generics }

*Parametric polymorphism* · [в онтологии](concepts.md#subprograms-generics)

- **да (с Go 1.18 включительно, layer: language, profile: go127)** — Параметры типов у функций и типов; ограничения — интерфейсы, в том числе с наборами типов `~int | ~float64`. Методы не могут иметь собственных параметров типов. ([Go spec — Type parameter declarations](https://go.dev/ref/spec#Type_parameter_declarations); [Go spec — Type constraints](https://go.dev/ref/spec#Type_constraints))

#### Аргументы по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **нет (layer: language, profile: go127)** — Все параметры обязательны; вариативный последний параметр `...T` и паттерн «функциональных опций» — замена, а не аргументы по умолчанию.

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **нет (layer: language, profile: go127)** — Аргументы сопоставляются только по позиции; именованные поля есть лишь в составных литералах структур. ([Go spec — Calls](https://go.dev/ref/spec#Calls))

### Полиморфизм и организация { #abstraction }

#### Контракты полиморфизма { #abstraction-contracts }

*Polymorphic contracts* · [в онтологии](concepts.md#abstraction-contracts)

- **Интерфейсы (layer: language, profile: go127)** — Интерфейс задаёт набор методов и неявно удовлетворяется; с Go 1.18 интерфейсы также служат ограничениями параметров типов. ([Go spec — Interface types](https://go.dev/ref/spec#Interface_types))

#### Диспетчеризация вызовов { #abstraction-dispatch }

*Call dispatch* · [в онтологии](concepts.md#abstraction-dispatch)

- **Статическая (layer: language, profile: go127, applies_to: вызов метода конкретного типа)** — Метод выбирается по статическому типу получателя.
- **По одному динамическому типу (layer: language, profile: go127, applies_to: вызов метода через значение интерфейса)** — Реализация выбирается по динамическому типу значения, хранящегося в интерфейсе.

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Отсутствует (layer: language, profile: go127)** — Встраивание поля продвигает его методы во внешний тип, но это композиция: внешняя структура не становится подтипом встроенной, а метод встроенного типа не переопределяется виртуально. ([Go FAQ — Why is there no type inheritance?](https://go.dev/doc/faq#inheritance); [Go spec — Struct types (embedded fields, promoted methods)](https://go.dev/ref/spec#Struct_types))

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Пространства имён и пакеты (layer: language, profile: go127)** — Пакет — единица компиляции и пространство имён; импорт по пути, обращение через квалифицированный идентификатор `pkg.Name`. ([Go spec — Packages](https://go.dev/ref/spec#Packages))
- **Явная граница экспорта (layer: language, profile: go127)** — Экспортируются идентификаторы верхнего уровня, поля и методы, имя которых начинается с заглавной буквы Unicode; отдельного списка экспорта нет. ([Go spec — Exported identifiers](https://go.dev/ref/spec#Exported_identifiers))

### Вычисление и эффекты { #evaluation }

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · [в онтологии](concepts.md#evaluation-tail-calls)

- **нет (layer: language, profile: go127)** — Спецификация не требует устранения хвостовых вызовов; глубокая рекурсия расходует растущий стек горутины.

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

*Memory reclamation* · [в онтологии](concepts.md#memory-management)

- **Трассирующая сборка мусора (layer: language, profile: go127)** — Спецификация называет язык garbage-collected: явного освобождения памяти нет. Алгоритм (конкурентный трассирующий сборщик gc) — свойство реализации. ([Go spec — Introduction](https://go.dev/ref/spec#Introduction); [A Guide to the Go Garbage Collector](https://go.dev/doc/gc-guide))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Код ошибки (layer: language, profile: go127)** — Функция возвращает ошибку дополнительным результатом типа-интерфейса `error`, `nil` означает успех. Это не размеченный Result: обе компоненты существуют одновременно, и проверку `err != nil` компилятор не требует. ([Go spec — Errors](https://go.dev/ref/spec#Errors); [Go FAQ — Why does Go not have exceptions?](https://go.dev/doc/faq#exceptions))
- **Паника (layer: language, profile: go127)** — `panic` раскручивает стек горутины, выполняя отложенные вызовы; `recover` внутри отложенной функции может остановить панику. Предназначена для программных ошибок, а не для обычного потока ошибок. ([Go spec — Handling panics](https://go.dev/ref/spec#Handling_panics); [Go spec — Run-time panics](https://go.dev/ref/spec#Run_time_panics))

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Отложенный вызов при выходе (layer: language, profile: go127)** — `defer f.Close()` откладывает вызов до возврата из функции (не блока); аргументы вычисляются сразу, вызовы выполняются в обратном порядке, в том числе при панике. ([Go spec — Defer statements](https://go.dev/ref/spec#Defer_statements))

#### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · [в онтологии](concepts.md#resources-concurrency)

- **Потоки (layer: language, profile: go127)** — `go f()` запускает горутину — независимый поток управления в общем адресном пространстве. Горутины легковесны и мультиплексируются рантаймом на потоки ОС. ([Go spec — Go statements](https://go.dev/ref/spec#Go_statements))
- **Передача сообщений (layer: language, profile: go127)** — Типизированные каналы `chan T`, операции `<-` и `select` для ожидания нескольких коммуникаций; мьютексы пакета `sync` — альтернатива на уровне стандартной библиотеки. ([Go spec — Channel types](https://go.dev/ref/spec#Channel_types); [Go spec — Select statements](https://go.dev/ref/spec#Select_statements))

#### Синхронизация отправки и приёма { #resources-communication-coupling }

*Send and receive coupling* · [в онтологии](concepts.md#resources-communication-coupling)

- **Синхронное рандеву по каналу (layer: language, profile: go127, applies_to: небуферизованные каналы)** — Отправка завершается только при встрече с получателем. Буферизованный канал — ограниченная FIFO-очередь, общая для любых горутин: отправка блокируется при заполнении, поэтому это не почтовый ящик процесса и значение asynchronous_mailbox не заявлено. ([Go spec — Channel types](https://go.dev/ref/spec#Channel_types))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: go127)** — Блоки ограничены фигурными скобками, обязательными даже для одного оператора в `if` и `for`.

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Необязательная точка с запятой (layer: language, profile: go127)** — Грамматика использует `;`, но лексер автоматически вставляет её после строки, оканчивающейся идентификатором, литералом, `)`, `]`, `}` и некоторыми ключевыми словами. Поэтому `{` нельзя переносить на новую строку; `gofmt` задаёт единый стиль. ([Go spec — Semicolons](https://go.dev/ref/spec#Semicolons))

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **да (layer: language, profile: go127)** — Регистр первой буквы ещё и определяет экспорт: `Println` видим вне пакета, `println` — нет. ([Go spec — Identifiers](https://go.dev/ref/spec#Identifiers))

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: go127)**
- **Процедурная (layer: language, profile: go127)**
- **Объектно-ориентированная (layer: language, profile: go127)** — Методы у любых определённых типов и интерфейсы без классов и иерархий типов; FAQ отвечает на вопрос об ООП «и да и нет». ([Go FAQ — Is Go an object-oriented language?](https://go.dev/doc/faq#Is_Go_an_object-oriented_language))

### Семантика данных { #data }

#### Ограничение числовой точности { #data-numeric-precision }

*Numeric precision bound* · [в онтологии](concepts.md#data-numeric-precision)

- **Фиксированная разрядность типа или поля (layer: language, profile: go127, applies_to: типизированные числовые значения)** — `int8`…`int64`, `uint*`, `float32/64`; разрядность `int` зависит от платформы (32 или 64 бита). Целочисленное переполнение заворачивается по модулю. ([Go spec — Numeric types](https://go.dev/ref/spec#Numeric_types); [Go spec — Integer overflow](https://go.dev/ref/spec#Integer_overflow))
- **Нефиксированная заранее разрядность (layer: language, profile: go127, applies_to: нетипизированные константные выражения)** — Константы вычисляются точно при компиляции (реализация обязана поддерживать не менее 256 бит); `math/big` даёт такую арифметику во время выполнения на уровне библиотеки. ([Go spec — Constants](https://go.dev/ref/spec#Constants))
