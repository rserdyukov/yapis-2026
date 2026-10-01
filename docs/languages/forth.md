---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Forth

Forth — стековый язык с постфиксной записью: слова берут аргументы со стека данных и кладут туда результаты, а стек возвратов хранит адреса вызовов и параметры циклов. Новые слова определяются через `:` и `;` и попадают в словарь; немедленные слова выполняются во время компиляции и расширяют сам компилятор, а ячейки не типизированы — смысл значения задаёт применяемое слово. Основа карточки — стандарт Forth-2012 (предыдущий — ANS Forth 1994); необязательные наборы слов отмечены в пояснениях, свойства систем вроде Gforth не включены.

*Карточка сравнительная: 33/85 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1970 — [Wikidata P571](https://www.wikidata.org/wiki/Q275472) (получено 2026-09-25) |
| Авторы | [Чарльз Мур](people.md#moore) |
| Организации | Forth, Inc. |
| Сайт | <https://forth-standard.org/> |
| Спецификация | <https://forth-standard.org/standard/words> |
| Внешние каталоги | [Wikidata Q275472](https://www.wikidata.org/wiki/Q275472) |

## Люди { #people }

- [Чарльз Мур](people.md#moore) — Создатель языка Forth (около 1970 года) и сооснователь Forth, Inc.

## Публикации { #publications }

- Чарльз Мур, Elizabeth D. Rather, Donald R. Colburn. *The Evolution of Forth*. HOPL II, 1993. DOI: [10.1145/155360.155369](https://doi.org/10.1145/155360.155369). История Forth от авторов: стек, словарь и расширяемый компилятор как единый минимальный механизм. ([в источниках](sources.md#hopl-forth))
- Jon Purdy. [Why Concatenative Programming Matters](https://evincarofautumn.blogspot.com/2012/02/why-concatenative-programming-matters.html). 2012. Короткое введение в конкатенативную парадигму (композиция вместо применения) и её связь с комбинаторной логикой; фон к карточке Forth. ([в источниках](sources.md#purdy-concatenative))
- Frederick J. Ross. [The seven programming ur-languages](https://madhadron.com/programming/seven_ur_languages.html). 2022. Семь семейств-«праязыков» (ALGOL, Lisp, ML, Self, Forth, APL, Prolog) с характерными приёмами мышления — рамка для каталога языков. ([в источниках](sources.md#ross-ur-languages))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **forth2012** — Стандарт Forth-2012 (Core и Core Extension; необязательные наборы Exception, Locals, Search-Order, File-Access, Facility отмечаются в applies_to). Конкретные системы, например Gforth, — слой implementation.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

англ. *Binding introduction* (также *declaration*, *name binding*) · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: forth2012)** — Имена вводятся определяющими словами: `:` для слов, `VARIABLE`, `CONSTANT`, `VALUE`, `CREATE`. Значения на стеке данных безымянны. ([Forth-2012 6.1.2410 VARIABLE](https://forth-standard.org/standard/core/VARIABLE); [Forth-2012 6.1.0450 :](https://forth-standard.org/standard/core/Colon))

#### Изменяемость связывания { #bindings-mutation }

англ. *Binding mutability* (также *rebinding*, *immutable binding*, *const qualification*) · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: forth2012, applies_to: VARIABLE и VALUE)** — `VARIABLE` возвращает адрес ячейки, содержимое меняется через `!`; значение `VALUE` меняется через `TO`. ([Forth-2012 6.2.2295 TO](https://forth-standard.org/standard/core/TO))
- **Неизменяемое (layer: language, profile: forth2012, applies_to: CONSTANT)** — `CONSTANT` при исполнении кладёт на стек зафиксированное значение; стандартного слова для его изменения нет. ([Forth-2012 6.1.0950 CONSTANT](https://forth-standard.org/standard/core/CONSTANT))

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

англ. *Assignment and binding forms* (также *assignment*, *destructuring*, *unification*) · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: forth2012)** — `x addr !` записывает одну ячейку по адресу, `x TO name` — одно значение `VALUE`. Распаковки нет: несколько значений раскладываются стековыми операциями. ([Forth-2012 6.1.0010 !](https://forth-standard.org/standard/core/Store))

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

англ. *Name resolution* (также *name lookup*, *lexical scoping*, *dynamic scoping*) · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: forth2012, applies_to: локальные имена `{: … :}` из необязательного набора Locals)** — Локальные имена видимы только в тексте текущего определения. Глобальные имена ищутся в словаре по порядку поиска в момент трансляции, и найденное определение фиксируется в скомпилированном коде. ([Forth-2012 13.6.2.2550 {:](https://forth-standard.org/standard/locals/bColon))

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

англ. *Top-level bindings* (также *global variables*, *file scope*, *namespace scope*) · [в онтологии](concepts.md#scope-globals)

- **Глобальные переменные (layer: language, profile: forth2012)** — Определения словаря, включая `VARIABLE`, доступны всем последующим определениям в текущем порядке поиска; без Locals других областей для имён нет.

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

англ. *Name shadowing* (также *name hiding*, *variable shadowing*) · [в онтологии](concepts.md#scope-shadowing)

- **Новое связывание в той же области (layer: language, profile: forth2012)** — Повторное определение имени скрывает прежнее при последующем поиске, но ранее скомпилированные слова продолжают вызывать старое определение. Тест к `:` показывает `: GDX 123 ; : GDX GDX 234 ;` — внутри второго определения `GDX` ещё ссылается на первое. ([Forth-2012 6.1.0450 : — тест search order](https://forth-standard.org/standard/core/Colon))

### Типизация { #typing }

#### Проверка типов { #typing-checking }

англ. *Type checking* (также *static typing*, *dynamic typing*) · [в онтологии](concepts.md#typing-checking)

- **неприменимо (n/a) (layer: language, profile: forth2012)** — Типов значений у ячеек нет, поэтому нет ни статической, ни динамической проверки: слово интерпретирует ячейку как число, адрес или флаг по своему контракту. Следить за типами должен программист; нарушение контракта — неоднозначное условие, а не ошибка типа. ([Forth-2012 3.1 Data types; 3.2.3.1 Data stack](https://forth-standard.org/standard/usage))

#### Аннотации типов { #typing-annotations }

англ. *Type annotations* (также *type declarations*, *type signatures*) · [в онтологии](concepts.md#typing-annotations)

- **Отсутствуют (layer: language, profile: forth2012)** — Стековые комментарии вида `( a b -- c )` — соглашение документации, система их не проверяет; `(` просто пропускает текст до `)`.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

англ. *Type conversions* (также *type coercion*, *type casting*) · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: forth2012)** — Смена представления делается словами, например `S>D` расширяет одинарную ячейку до двойной. Большинство операций ничего не преобразует, а применяет свою интерпретацию к тем же битам. ([Forth-2012 6.1.2170 S>D](https://forth-standard.org/standard/core/StoD))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

англ. *Conditional selection* (также *selection statement*, *conditional expression*) · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: forth2012)** — `flag IF … ELSE … THEN` снимает флаг со стека данных; работает только внутри определения. Результат ветвей оставляется на стеке, отдельной формы условного выражения нет. ([Forth-2012 6.1.1700 IF](https://forth-standard.org/standard/core/IF))

#### Выбор по значению switch/case { #control-switch }

англ. *Switch statement* (также *case statement*, *multiway branch*) · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: forth2012, applies_to: `CASE … OF … ENDOF … ENDCASE` (Core Extension))** — `OF` сравнивает значение с вершиной стека; варианты перебираются последовательно. ([Forth-2012 6.2.0873 CASE](https://forth-standard.org/standard/core/CASE))

<a id="req-7-2-until"></a>

#### Цикл до истинности условия { #control-until }

англ. *Until loop* (также *repeat-until loop*) · [в онтологии](concepts.md#control-until)

- **Проверка после тела (layer: language, profile: forth2012)** — `BEGIN … flag UNTIL`: тело выполняется хотя бы один раз, цикл завершается, когда флаг истинен. ([Forth-2012 6.1.2390 UNTIL](https://forth-standard.org/standard/core/UNTIL))

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

англ. *Do-while loop* (также *post-test loop*) · [в онтологии](concepts.md#control-do-while)

- **нет (layer: language, profile: forth2012)** — Отдельной формы с продолжением при истинном постусловии нет; `BEGIN … 0= UNTIL` лишь имитирует её. `BEGIN … WHILE … REPEAT` проверяет условие в середине цикла. ([Forth-2012 6.1.2430 WHILE](https://forth-standard.org/standard/core/WHILE); [Forth-2012 6.1.2140 REPEAT](https://forth-standard.org/standard/core/REPEAT))

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

англ. *Iteration* (также *loops*, *for loop*, *foreach loop*, *range-based for loop*) · [в онтологии](concepts.md#control-iteration)

- **Инициализация / условие / шаг (layer: language, profile: forth2012)** — `limit start DO … LOOP` и `DO … n +LOOP` — счётный цикл с индексом `I`, границей и шагом; параметры хранятся на стеке возвратов. Произвольного условия, как в C, нет; итерации по коллекции нет. ([Forth-2012 6.1.1240 DO](https://forth-standard.org/standard/core/DO))

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

англ. *Function overloading* (также *overloading*, *operator overloading*) · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: forth2012)** — Имени соответствует последнее видимое определение; сигнатур нет.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

англ. *Parameter passing* (также *call by value*, *call by reference*, *call by sharing*) · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: forth2012)** — Аргументы и результаты передаются через общий стек данных как значения ячеек. Передача адреса — тоже передача значения; объявленных параметров у слова нет. ([Forth-2012 6.1.1290 DUP — стековая нотация](https://forth-standard.org/standard/core/DUP))

<a id="variants-9"></a>

#### Место определения подпрограмм { #subprograms-placement }

англ. *Subprogram definition placement* (также *top-level function*, *member function*, *local function*) · [в онтологии](concepts.md#subprograms-placement)

- **Выделенная область объявлений (layer: language, profile: forth2012)** — Определения вводятся из входного потока текстового интерпретатора, вне других определений, и добавляются в текущий список слов.

#### Вложенные именованные подпрограммы { #subprograms-nesting }

англ. *Nested functions* (также *nested subprograms*) · [в онтологии](concepts.md#subprograms-nesting)

- **нет (layer: language, profile: forth2012)** — Стандарт не разрешает вкладывать компиляцию одного определения в другое (3.4.5). Цитаты `[: … ;]` в Forth-2012 не входят. ([Forth-2012 3.4.5 Compilation](https://forth-standard.org/standard/usage))

#### Захват окружения { #subprograms-closures }

англ. *Closures* (также *lambda capture*, *captured variables*) · [в онтологии](concepts.md#subprograms-closures)

- **нет (layer: language, profile: forth2012)** — Определение не захватывает окружение; локальные имена существуют только во время выполнения своего слова.

#### Анонимные функции { #subprograms-lambda }

англ. *Anonymous functions* (также *lambda expressions*, *function literals*) · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: forth2012, applies_to: `:NONAME … ;` (Core Extension))** — `:NONAME` создаёт безымянное определение и оставляет его execution token для `EXECUTE` или `DEFER`/`IS`. Это не замыкание: окружение не захватывается. ([Forth-2012 6.2.0455 :NONAME](https://forth-standard.org/standard/core/ColonNONAME))

### Полиморфизм и организация { #abstraction }

#### Модульность { #abstraction-modules }

англ. *Modules* (также *module system*, *namespaces*, *packages*) · [в онтологии](concepts.md#abstraction-modules)

- **Пространства имён и пакеты (layer: language, profile: forth2012, applies_to: необязательный набор Search-Order)** — Списки слов (`WORDLIST`) и порядок поиска разделяют пространства имён; явной границы экспорта нет. ([Forth-2012 16 Search-Order word set](https://forth-standard.org/standard/search))
- **Текстовое включение (layer: language, profile: forth2012, applies_to: необязательный набор File-Access)** — `INCLUDED` интерпретирует содержимое файла как входной поток. ([Forth-2012 11.6.1.1718 INCLUDED](https://forth-standard.org/standard/file/INCLUDED))

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

англ. *Evaluation strategy* (также *eager evaluation*, *lazy evaluation*) · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: forth2012)** — Каждое слово выполняется в порядке записи над уже вычисленными значениями на стеке.

#### Контроль эффектов { #evaluation-effects }

англ. *Effect control* (также *effect system*, *purity*) · [в онтологии](concepts.md#evaluation-effects)

- **Без общего статического разделения эффектов (layer: language, profile: forth2012)** — Любое слово может менять память, словарь и стеки; статического разделения эффектов нет.

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

англ. *Tail-call elimination* (также *proper tail calls*, *tail-call optimization*) · [в онтологии](concepts.md#evaluation-tail-calls)

- **нет (layer: language, profile: forth2012)** — Стандарт не гарантирует устранение хвостовых вызовов; отдельные системы могут его выполнять.

### Память и владение { #memory }

#### Освобождение памяти { #memory-management }

англ. *Memory management* (также *memory reclamation*, *garbage collection*, *reference counting*) · [в онтологии](concepts.md#memory-management)

- **Ручное (layer: language, profile: forth2012)** — Пространство данных словаря выделяется через `HERE`, `ALLOT`, `,` и освобождается только удалением определений (`MARKER`); `ALLOCATE`/`FREE` необязательного набора Memory-Allocation — явная куча. Сборки мусора нет. ([Forth-2012 6.1.0710 ALLOT](https://forth-standard.org/standard/core/ALLOT); [Forth-2012 14 Memory-Allocation word set](https://forth-standard.org/standard/memory))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

англ. *Error handling* (также *exceptions*, *result types*, *error codes*) · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: language, profile: forth2012, applies_to: необязательный набор Exception)** — `CATCH` выполняет execution token и возвращает 0 или код, переданный `THROW`; стеки восстанавливаются до глубины на момент `CATCH`. ([Forth-2012 9.6.1.0875 CATCH](https://forth-standard.org/standard/exception/CATCH); [Forth-2012 9.6.1.2275 THROW](https://forth-standard.org/standard/exception/THROW))
- **Код ошибки (layer: language, profile: forth2012)** — Исключения несут целый код, а слова File-Access и Memory-Allocation возвращают код результата ior, который проверяет вызывающий. ([Forth-2012 14.6.1.0707 ALLOCATE](https://forth-standard.org/standard/memory/ALLOCATE))

### Ресурсы и взаимодействие { #resources }

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

англ. *Input/output* (также *I/O library*) · [в онтологии](concepts.md#resources-io)

- **Встроенные функции (layer: language, profile: forth2012)** — `EMIT`, `TYPE`, `KEY`, `ACCEPT` входят в Core; файлы — необязательный набор File-Access. ([Forth-2012 6.1.2310 TYPE](https://forth-standard.org/standard/core/TYPE))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

англ. *Syntactic grouping boundaries* (также *block delimiters*, *compound statement*, *off-side rule*) · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: forth2012)** — Группы ограничены парными словами: `:` … `;`, `IF` … `THEN`, `BEGIN` … `UNTIL`, `DO` … `LOOP`. Соответствие проверяется через стек управления при компиляции.

#### Границы операторов и определений { #syntax-statement-terminator }

англ. *Statement terminators* (также *statement separators*, *automatic semicolon insertion*) · [в онтологии](concepts.md#syntax-statement-terminator)

- **Структура выражения (layer: language, profile: forth2012)** — Операторов нет: программа — последовательность слов, разделённых пробелами; определение заканчивается словом `;`. Перевод строки не значим. ([Forth-2012 6.1.0460 ;](https://forth-standard.org/standard/core/Semi))

#### Метапрограммирование { #syntax-metaprogramming }

англ. *Metaprogramming* (также *macros*, *reflection*, *compile-time evaluation*) · [в онтологии](concepts.md#syntax-metaprogramming)

- **Вычисление при компиляции (layer: language, profile: forth2012)** — Слово, помеченное `IMMEDIATE`, выполняется во время компиляции определения; `POSTPONE` откладывает семантику компиляции другого слова. Так в самом языке определены `IF`, `DO` и другие управляющие слова. ([Forth-2012 6.1.1710 IMMEDIATE](https://forth-standard.org/standard/core/IMMEDIATE); [Forth-2012 6.1.2033 POSTPONE](https://forth-standard.org/standard/core/POSTPONE))
- **Построение и выполнение кода (layer: language, profile: forth2012)** — `EVALUATE` интерпретирует строку во время выполнения; `CREATE … DOES>` определяет новые определяющие слова с собственным поведением. ([Forth-2012 6.1.1360 EVALUATE](https://forth-standard.org/standard/core/EVALUATE); [Forth-2012 6.1.1250 DOES>](https://forth-standard.org/standard/core/DOES))

#### Нотация исходной программы { #syntax-program-representation }

англ. *Source program notation* (также *visual programming language*) · [в онтологии](concepts.md#syntax-program-representation)

- **Текстовая нотация (layer: language, profile: forth2012)** — Исходный текст разбирается на слова, разделённые пробелами; исторический формат блоков по 1024 символа — тоже текст.

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

англ. *Programming paradigms* (также *supported paradigms*) · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: forth2012)** — Явная работа со стеками и памятью.
- **Процедурная (layer: language, profile: forth2012)** — Программа строится как иерархия слов-подпрограмм.

### Семантика данных { #data }

#### Ограничение числовой точности { #data-numeric-precision }

англ. *Numeric precision bound* (также *arbitrary-precision arithmetic*, *bignum*, *fixed-width integers*) · [в онтологии](concepts.md#data-numeric-precision)

- **Фиксированная разрядность типа или поля (layer: language, profile: forth2012)** — Целые занимают одинарную или двойную ячейку фиксированной разрядности; при переполнении результат определяется реализацией (3.2.2.2). ([Forth-2012 3.2.1 Numbers; 3.2.2.2 Other integer operations](https://forth-standard.org/standard/usage))
