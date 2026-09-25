---
title: "Карта языков и вычислительных традиций"
publish: true
---

# Карта языков и вычислительных традиций

Языки полезно сравнивать по тому, **что означает программа**: какие данные она
описывает, как получает результат, когда ждёт, какие свойства проверяет.
Исторические, исследовательские, визуальные и предметные языки здесь так же
важны, как современные языки общего назначения.

Эта карта объединяет **60 языков и языковых семейств**, 15 приоритетных
исследовательских пакетов и 22 дополнительные концепции онтологии. Она охватывает
разные традиции, но не претендует на буквальную исчерпывающую перепись языков.
Группы — маршруты сравнения, а не взаимоисключающие классы.

**[Каталог языков](../languages/index.md)** содержит доступные карточки;
**[понятия онтологии](../languages/glossary.md)** — общий словарь, а [сравнение языков](../languages/concepts.md) — матрицу.
Перечисление языка ниже означает место на карте исследования, а не наличие
опубликованной карточки или заполненных утверждений по новым осям.

## Как читать доказательность

| Метка | Что установлено |
|---|---|
| **S — подтверждено** | Прочитанный первичный текст подтверждает указанный тезис в названном профиле. Это не проверка всего языка. |
| **P — частично** | Подтверждена только явно названная часть; остальные вопросы остаются планом. |
| **C — запланировано** | Источник для указанного вопроса ещё не проверен; строка задаёт направление исследования, а не факт для каталога. |

Срез источников — **20 сентября 2026**. Основа S/P — реестр чтения исследования;
при подготовке этой страницы дополнительно прочитаны разделы Python о числах,
последовательностях и итераторах, Racket о продолжениях и Lua 5.4 о корутинах.
Ссылки в [реестре источников](#evidence) сопровождаются областью подтверждения.
Успешная загрузка оглавления, оболочки сайта или неразобранного PDF не считается
прочтением семантического определения. Примеры ниже — задания для проверки,
а не отчёт об уже выполненных запусках.

### Язык, редакция, реализация

Единица утверждения: **язык + редакция/профиль + механизм + источник**.

- Dyalog 19.0 — конкретный APL-профиль; его rank operator не приписывается
  всем историческим APL. J имеет собственные правила agreement.
- Oz 3 описывается по Mozart 1.4.0; свойства Oz 1/2 не переносятся автоматически.
- SQL рассматривается через PostgreSQL 18; это не замена ISO SQL.
  Datalog — семейство: положительное конечное ядро и расширения Soufflé/Z3
  требуют разных утверждений.
- G — язык, LabVIEW — среда; Prograph — язык, Marten — среда.
  Verilog по Icarus — источник о реализации симуляции, не полная IEEE-модель.
- SML '97 и расширения SML/NJ различаются; SPARK — профиль на основе Ada,
  GNATprove — инструмент. Написанный контракт ещё не доказанный контракт.
- `call/cc` Scheme — стандартизованная процедура; `Decimal` Python — стандартная
  библиотека. В карточках используются `layer`, `implementation`, `profile`,
  `applies_to`, `since/until`. Одно имя механизма не делает его встроенным синтаксисом.

## Широкая карта

### Исторические процедурные, научные и деловые языки

| Язык / исследуемый профиль | Статус | Подтверждение или следующий вопрос |
|---|---|---|
| Fortran / линия редакций, отдельно 2008 | P [WG5][fortran] | Подтверждены coarrays 2008; переходы arrays/modules/OO по редакциям ещё сверить. |
| COBOL / GnuCOBOL 3.1 RC-1 | S [руководство][cobol] | `PICTURE`, десятичные позиции, подразумеваемая точка и group items. |
| ALGOL 60 / Revised Report | S [отчёт][algol] | Call-by-name и предотвращение захвата при подстановке; уточняет уже имеющийся `by_name`. |
| ALGOL 68 | C | Исследовать modes и контекстные coercions. |
| PL/I | C | Проверить независимость radix, scale, precision и обработки условий. |
| Simula 67 | C | Проверить симуляционные процессы и сопрограммы наряду с классами. |
| Pascal | C | Проверить поддиапазоны, множества и packed/variant records. |

### Символы, объекты, макросы и продолжения

| Язык / исследуемый профиль | Статус | Подтверждение или следующий вопрос |
|---|---|---|
| Lisp 1.5 | C | Исследовать исторические правила связывания; не переносить на них Scheme. |
| Common Lisp / ANSI | S [карточка](../languages/common-lisp.md) | Conditions/restarts, special variables и multiple dispatch описаны с источниками; исторические Lisp исследуются отдельно. |
| Scheme / R7RS-small | S [§4][scheme4], [§6][scheme6] | Hygienic `syntax-rules`, `call/cc` с unlimited extent и повторными вызовами. |
| Racket / Reference, срез 2026-09-20 | P [продолжения][racket] | Подтверждены prompts и захват до prompt; phases и остальные macro API ещё исследовать. |
| Smalltalk / GNU Smalltalk | S [условия][smalltalk] | `ifTrue:` — сообщение Boolean с блоком, а не обязательное ключевое слово. |
| Self / Handbook 2024.1 | S [справочник][self] | Parent objects, delegation и lookup; parents могут быть изменяемыми слотами. |
| SNOBOL4 | C | Получить читаемый первичный текст для string patterns и success/failure. |
| Refal / будущий профиль Refal-5 | C | Подтвердить семантику сопоставления и переписывания последовательностей. |

### Массивы, стек и возобновляемые вычисления

| Язык / исследуемый профиль | Статус | Подтверждение или следующий вопрос |
|---|---|---|
| APL / Dyalog 19.0 | S [Rank][dyalog] | Выбор cells оператором ранга; не универсальная характеристика всех APL. |
| J / Jsoftware Dictionary | S [Nouns][jnouns], [Verbs][jverbs] | Shape, rank, cells, frames и применение verb по рангу. |
| Forth / стандартный core | S [Usage requirements][forth] | Data stack и среда исполнения; стандарт не требует проверки типов данных. |
| Joy | C | Проверить quotations и композицию стековых преобразований. |
| Icon / overview v9 | S [авторский обзор][icon] | Failure внешнего выражения возобновляет поиск альтернатив внутреннего генератора. |
| Lua / 5.4 | S [§2.6][lua] | Явные `resume`/`yield`, включая yield из вложенного вызова; это не автоматический поиск Icon. |

### Типы, модули, эффекты и проверка свойств

| Язык / исследуемый профиль | Статус | Подтверждение или следующий вопрос |
|---|---|---|
| Standard ML / SML '97 | S [авторское руководство][sml] | Structures/signatures/functors и свежие типы opaque result signature. |
| OCaml / 4.x и 5.x отдельно | C | Проверить модульные случаи и версионные границы effect handlers. |
| Haskell / Haskell 2010, отдельно GHC | P [карточка](../languages/haskell.md) | Нестрогость и IO описаны; productivity и гарантии завершения требуют отдельного исследования. |
| Clean | C | Проверить uniqueness, не отождествляя её с borrowing или reference capabilities. |
| Ada / 2012 для контрактов | S [RM §6.1.1][ada] | `Pre`/`Post`, `Old`, class-wide аспекты и assertion policy. Rendezvous отдельно исследовать. |
| SPARK / семейство SPARK 2014 | S [обзор языка][spark] | Границы Ada-подмножества, спецификаций и GNATprove; не полная семантика доказательства. |
| Eiffel | S [Design by Contract][eiffel] | Предусловия, постусловия, class invariants, `old` и уровни monitoring. |
| Agda / Agda 2 | P [termination checking][agda] | Подтверждены checker и escape hatches; зависимые семейства отдельно проверить. |
| Idris / Idris 2 | S [Types and Functions][idris] | `Vect`/`Fin`, dependent pairs, различие covering/total/partial. |
| Pony | S [capabilities][pony] | `iso/ref/val/box/tag`, права и допустимые алиасы; `val` не равен `box`. |
| Koka / срез web book | S [книга][koka] | Effect-polymorphic функции и handlers/resume; базовые эффекты уже есть в онтологии. |

### Современные контрольные языки общего назначения

Здесь сохранены языки исходной учебной выборки, включая **TypeScript и C#**.
Метка C относится к следующему исследовательскому вопросу, а не обесценивает
утверждения, уже оформленные в существующих карточках.

| Язык / исследуемый профиль | Статус | Подтверждение или следующий вопрос |
|---|---|---|
| C / C17, отдельно C23 | C | Дополнить [карточку](../languages/c.md) object representation, lifetime и pointer provenance. |
| C++ / C++23 | C | Дополнить [карточку](../languages/cpp.md) lifetime, категориями значений и template constraints. |
| Java / SE 21 | C | Расширить [карточку](../languages/java.md): границы nominal OO и generics по первичным текстам. |
| C# / C# 12 | C | Расширить [карточку](../languages/csharp.md): decimal, итераторы и различие спецификации языка и runtime. |
| Python / документация 3.14 | P [Built-in Types][python] | Подтверждены unlimited-precision int, binary float, sequence и generator protocol; другие оси требуют своих источников. |
| JavaScript / ES2024 strict и sloppy | C | Расширить [карточку](../languages/javascript.md): prototype semantics; event loop отдельно привязать к host. |
| TypeScript / 5.x strict | C | Расширить [карточку](../languages/typescript.md): границы статических гарантий после стирания типов. |
| Rust / edition 2024 | C | Расширить [карточку](../languages/rust.md): alias permissions и межпоточные ограничения отдельно от cleanup. |

### Логика, отношения и ограничения

| Язык / исследуемый профиль | Статус | Подтверждение или следующий вопрос |
|---|---|---|
| Prolog / ISO core, отдельно SWI-Prolog | C | Дополнить [карточку](../languages/prolog.md) порядком целей, SLD-поиском и cut; CHR не переносится на весь Prolog. |
| Mercury / release reference | S [modes][modes], [determinism][det] | Переходы instantiation и кратность решений для каждого mode. |
| Datalog / positive finite core, Soufflé, Z3 | S [Soufflé][souffle], [Z3][z3] | Замыкание отношений; арифметические расширения могут нарушать завершение. |
| SQL / PostgreSQL 18 | S [SELECT][sql], [логика][sqltruth] | Дубли по умолчанию, `DISTINCT`, трёхзначные таблицы логических операций. |
| CHR / embedding SWI-Prolog | S [семантика][chr] | Committed simplification/propagation/simpagation над store ограничений. |
| MiniZinc / stable manual | S [моделирование][minizinc] | Decision variables, domains, satisfy/optimization и граница solver backend. |

### Конкурентность и ожидание информации

| Язык / исследуемый профиль | Статус | Подтверждение или следующий вопрос |
|---|---|---|
| Erlang / OTP documentation | S [Concurrent Programming][erlang] | Mailbox и selective receive с сохранением неподходящих сообщений. |
| occam / occam 2 | S [INMOS runtime model §3][occam] | Синхронные небуферизованные point-to-point channels; не все детали scheduler являются гарантиями языка. |
| Oz / Oz 3 по Mozart 1.4.0 | S [tutorial][oz] | Dataflow threads ждут необходимой информации в монотонном store переменных. |

### Время, модели, схемы и графические программы

| Язык / исследуемый профиль | Статус | Подтверждение или следующий вопрос |
|---|---|---|
| Lustre / core, V4/V6 отдельно | S [Verimag][lustre] | Clocked streams, уравнения, `pre` и инициализация. |
| Esterel | P [обзор][esterel] | Подтверждено synchronous reactive семейство; constructive causality и preemption ещё исследовать. |
| Modelica / specification 3.6 | S [§8][modelica] | Уравнения, производные, события и сочетание непрерывной/дискретной динамики. |
| Verilog / Icarus simulation | S [simulation][iverilog], [VVP][vvp] | Blocking/nonblocking updates; точные IEEE event regions ещё сверить. |
| VHDL / IEEE-редакцию выбрать | C | Проверить signal/variable, delta cycles и resolution. |
| Prograph / Marten 1.6 | P [описание среды][prograph] | Подтверждены графические cases/operations/links; порядок эффектов ещё проверить. |
| G / LabVIEW | S [NI][g] | Исходный граф и all-input readiness; независимые готовые ветви допускают параллелизм. |

### Следующий предметный горизонт

| Язык | Статус | Следующий исследовательский пакет |
|---|---|---|
| Janus / язык Lutz | P [архив][janus] | Идентификация обратимого языка подтверждена; точные ограничения updates и control flow требуют читаемого определения. |
| Q# | P [руководство][qsharp] | Есть прочитанный узкий источник; выбор редакции и перенос контекстных утверждений в каталог запланированы отдельным квантовым пакетом. |
| Silq | P [авторский обзор][silq] | Есть прочитанный первичный обзор; подтверждение профиля и различающие примеры для карточки запланированы отдельно. |
| Stan | C | Подтвердить семантику вероятностной модели и inference по первичному руководству. |

Для Q#/Silq метка P фиксирует наличие прочитанных узких источников и неполную
готовность исследовательского пакета. Семантические квантовые факты в эту
редакцию онтологии не внесены.

## Пятнадцать приоритетных пакетов

Для всех 15 пакетов подготовлены [различающие примеры](examples/index.md):
исходники, команды, ожидаемые результаты и границы проверки. Шесть пакетов
проверены запуском; остальные имеют явно отмеченный статус без запуска.

Приоритет определяется новым наблюдаемым различием и возможностью короткого
проверяемого примера. Это порядок подготовки утверждений, а не рейтинг языков.

| № | Язык | Зачем выбран и какой пример различает механизмы |
|---|---|---|
| 1 | Scheme | Сохранить и повторно вызвать continuation; отдельно раскрыть `syntax-rules` рядом с локальным одноимённым связыванием. [Продолжения](../languages/concepts.md#control-continuation-extent) и [гигиена](../languages/concepts.md#syntax-macro-hygiene) независимы. |
| 2 | J | Менять rank одного verb при применении к строкам и целой матрице; [rank lifting](../languages/concepts.md#evaluation-rank-lifting) объясняет больше, чем наличие массива. |
| 3 | Icon | В `5 < find(...)` отвергнуть ранний результат и автоматически продолжить поиск; сравнить с явным `next`/`resume` в [протоколах результатов](../languages/concepts.md#evaluation-result-protocol). |
| 4 | Oz | Начать `Y=X+1` до связывания `X`; наблюдать [ожидание информации](../languages/concepts.md#evaluation-data-availability), затем продолжение. |
| 5 | Mercury | Сравнить `append(in,in,out) is det` и `append(out,out,in) is multi`; [modes](../languages/concepts.md#computation-instantiation-modes) отделить от [кратности](../languages/concepts.md#computation-solution-cardinality). |
| 6 | Datalog | Построить достижимость графа с циклом до насыщения; [fixed point](../languages/concepts.md#computation-rule-semantics) сравнить с поиском цели и CHR rewriting. |
| 7 | SQL | Два одинаковых входных значения в `SELECT ALL` и `DISTINCT`; [кратность коллекции](../languages/concepts.md#data-collection-multiplicity) отделить от порядка вывода. |
| 8 | Standard ML | Две инстанциации functor с opaque result signature; [идентичность типов](../languages/concepts.md#typing-abstract-type-identity) отделить от самой [параметризации модулей](../languages/concepts.md#abstraction-modules). |
| 9 | Idris 2 | Сигнатура `Fin n -> Vect n a -> a` связывает индекс с длиной; [value dependency](../languages/concepts.md#typing-value-dependency) и [проверка тотальности](../languages/concepts.md#verification-totality) — разные гарантии. |
| 10 | Eiffel | `require`/`ensure`/`old` и invariant на счёте; [поведенческий контракт](../languages/concepts.md#verification-behavioral-contracts) задаёт больше, чем набор методов интерфейса. |
| 11 | COBOL | `PIC 9(3)V9`: четыре десятичные позиции и подразумеваемая точка; различить [radix](../languages/concepts.md#data-numeric-radix), [precision](../languages/concepts.md#data-numeric-precision) и scale. |
| 12 | Pony | Сопоставить `val` и `box`, затем `iso` и `ref`; [права ссылки](../languages/concepts.md#memory-reference-permissions) не сводятся к immutable binding. |
| 13 | Lustre | `i = 0 -> pre(i) + a` как поток по [логическим тактам](../languages/concepts.md#computation-time-domain), а не однократное присваивание. |
| 14 | Modelica | `v = R*i` и `der(x) = v` в системе [ненаправленных уравнений](../languages/concepts.md#computation-equation-causality); известные величины не задают универсальное направление вычисления. |
| 15 | Verilog | Обмен `a <= b; b <= a;` на фронте clock при известных начальных значениях и единственных writers; сравнить с blocking assignment в [очередях обновлений](../languages/concepts.md#computation-update-scheduling). |

Ближайшие контрольные пары: **Erlang/occam** для
[связи отправки и приёма](../languages/concepts.md#resources-communication-coupling)
и [selective receive](../languages/concepts.md#resources-receive-selection);
**G/Prograph** для [графической нотации](../languages/concepts.md#syntax-program-representation).
Forth нужен для отдельного исследования стековой композиции, Self — delegation,
ALGOL 60 — точного примера к существующему `by_name`. Их ценность не зависит
от появления нового ID именно в этом проходе.

## Что добавлено в словарь

Все новые концепции имеют `ru/en`, `kind: choice`, стабильный `slug`, значения,
объяснение границ и первичные источники. Значения — возможности в контексте,
а не обязательный единственный ярлык всего языка. Наличие значения в словаре
не является утверждением о конкретной карточке. Контрасты вроде `head_only`
также требуют собственного источника при заполнении карточки.

| Новый ID | Значения |
|---|---|
| `typing.value_dependency` | `indexed_families`, `dependent_functions`, `dependent_pairs` |
| `typing.abstract_type_identity` | `transparent`, `opaque_fresh` |
| `control.continuation_extent` | `undelimited`, `delimited` |
| `evaluation.rank_lifting` | `scalar_extension`, `cell_rank` |
| `evaluation.result_protocol` | `ordinary_return`, `explicit_resume`, `goal_directed` |
| `evaluation.data_availability` | `needed_information`, `all_inputs` |
| `memory.reference_permissions` | `isolated`, `mutable_aliases`, `immutable_shared`, `read_only_view`, `identity_only` |
| `resources.communication_coupling` | `asynchronous_mailbox`, `synchronous_rendezvous` |
| `resources.receive_selection` | `head_only`, `selective_matching` |
| `syntax.macro_hygiene` | `hygienic`, `unhygienic` |
| `syntax.program_representation` | `textual`, `graphical_graph` |
| `data.collection_multiplicity` | `set`, `bag`, `sequence` |
| `data.numeric_radix` | `binary`, `decimal` |
| `data.numeric_precision` | `fixed_precision`, `arbitrary_precision` |
| `computation.rule_semantics` | `goal_search`, `least_fixed_point`, `committed_rewriting` |
| `computation.instantiation_modes` | `ground_to_ground`, `free_to_ground`, `declared_transition` |
| `computation.solution_cardinality` | `det`, `semidet`, `multi`, `nondet` |
| `computation.time_domain` | `logical_ticks`, `discrete_simulation`, `continuous`, `hybrid` |
| `computation.equation_causality` | `directed_assignment`, `directed_equation`, `acausal_equation` |
| `computation.update_scheduling` | `blocking_update`, `deferred_nonblocking` |
| `verification.totality` | `checked_required`, `checked_opt_in`, `unchecked_escape`, `partial_allowed` |
| `verification.behavioral_contracts` | `preconditions`, `postconditions`, `invariants` |

К существующей `abstraction.modules` добавлено только значение `module_functors`.
Остальные исходные концепции сохраняют смысл. В сумме словарь содержит 74
концепции; это размер схемы, а не мера полноты исследования.

### Границы этой редакции

- **Radix, precision и scale** независимы: fixed precision не означает fixed
  point; decimal бывает с разным масштабом. Масштаб пока описывается в контексте.
- **Reference capabilities и линейность** не синонимы: изоляция алиасов не
  означает обязательное использование ровно один раз. Для linear/affine use
  нужен отдельный подтверждённый пакет, а не переименование Pony `iso`.
- **Shape и rank lifting** различаются: здесь добавлено правило применения
  операции, а не самостоятельная классификация всех форм массивов.
- **Strictness и порядок операндов**, **эффекты и handlers**, **контракт и
  способ его проверки** не объединяются в новые универсальные bins.
  Полиморфизм эффектов, SQL truth domain, стековая композиция, object delegation
  и детальные режимы доказательства остаются следующими независимыми осями.
- Гигиена не следует из S-выражений; графическая нотация не доказывает dataflow;
  synchronous rendezvous не означает synchronous reactive time.

## Когда утверждение готово для каталога

1. **Источник:** прочитанный содержательный фрагмент спецификации, руководства
   авторов или документации названной реализации; URL, заголовок, раздел и
   редакция/дата среза позволяют проверить тезис.
2. **Контекстное утверждение:** определено, к какой конструкции, типу, операции,
   версии, профилю и слою относится значение. Гарантия языка отделена от
   реализации, стандартной библиотеки, инструмента и расширения.
3. **Различающий пример — когда он объясняет различие:** короткая программа,
   запрос, модель или граф с ожидаемым результатом/диагностикой. Фиксируются
   реализация и статус запуска; схема не выдаётся за исполненный пример.
   Иллюстрация ради количества не обязательна.
4. **Границы гарантии:** названы допущения и исключения. Например, `det` не
   доказывает termination, `total` без проверки не становится доказательством,
   positive finite Datalog не охватывает все расширения.

После этого публикуется карточка или новое утверждение в ней. Отсутствующая
запись означает «не исследовано», а не `false`; «неприменимо» отличается от
«механизм отсутствует». Информационная политика покрытия не требует заполнять
все оси для всех языков.

## Реестр подтверждений и следующий поиск {#evidence}

### Прочитанные источники: точная область подтверждения

| Источник | Подтверждённая область и ограничение |
|---|---|
| [ALGOL 60 Revised Report][algol] | §4.7.3: call-by-name/value; историческая HTML-перепечатка нормативного текста. |
| [Scheme R7RS §4][scheme4], [§6][scheme6] | §4.3 hygiene, §6.10 first-class continuations; отчёт R7RS-small. |
| [Racket Reference §10.4][racket] | Prompts, truncated capture и continuation barriers; другие Racket API не выводятся отсюда. |
| [GNU Smalltalk Conditions][smalltalk], [Self Handbook 2024.1][self] | Boolean messages и parent lookup соответственно; это разные объектные модели. |
| [J Nouns][jnouns], [Verbs][jverbs], [Dyalog Rank][dyalog] | Shape/cells/frames и rank application; правила J и Dyalog не объявляются одинаковыми. |
| [Forth Usage requirements][forth] | §3.1 отсутствие требования type checking, §3.2.3 stacks; отдельные words требуют проверки word set. |
| [Icon IPD266a][icon], [Lua 5.4 §2.6][lua] | Автоматическое возобновление по failure против явных resume/yield. |
| [Python Built-in Types][python] | Unlimited-precision int, binary float, sequences, iterator/generator protocol; Decimal отмечен как стандартная библиотека с настраиваемой точностью. |
| [GnuCOBOL Programmer's Guide][cobol] | §§2.1.7–2.1.8 group items, §6.9.33 PICTURE/V; профиль 3.1 RC-1. |
| [WG5 Fortran 2008][fortran] | Coarrays и дальнейшие parallel features; не источник всех дат появления возможностей Fortran. |
| [SML '97 Modules][sml] | Signatures/sharing и §1.3.9 opaque results/fresh instantiation; отделять SML/NJ extensions. |
| [Idris 2 Types and Functions][idris], [Agda Termination Checking][agda] | Dependent types и totality в Idris; checker/escape hatches в Agda. По странице Agda не подтверждаются все зависимые типы. |
| [Ada 2012 RM §6.1.1][ada], [Eiffel contracts][eiffel], [SPARK overview][spark] | Предикаты, runtime policy и границы proof tooling; наличие спецификации не означает доказанность. |
| [Pony capabilities][pony] | Права ссылок и алиасы; не полная soundness-теорема и не анализ FFI. |
| [Koka Book][koka] | Effect inference/polymorphism и handlers/resume; изменяемый web snapshot. |
| [Mercury modes][modes], [determinism][det] | Inst transitions и таблица числа решений, с оговоркой о returning calls. |
| [Soufflé tutorial][souffle], [relations][relations], [Z3 Basic Datalog][z3] | Множества кортежей и рекурсивное замыкание; расширения с порождением значений могут не завершаться. |
| [PostgreSQL 18 SELECT][sql], [Logical Operators][sqltruth] | Кратность и трёхзначная логика; не весь ISO SQL. |
| [SWI-Prolog CHR][chr], [MiniZinc modelling][minizinc] | Store rewriting и satisfaction/optimization соответственно; разные модели ограничений. |
| [Erlang/OTP][erlang], [INMOS occam runtime model][occam], [Oz 3 tutorial][oz] | Mailbox/selective receive, unbuffered rendezvous и ожидание информации; не доказательство fairness. |
| [Lustre / Verimag][lustre], [Esterel overview][esterel] | Для Lustre — streams/equations/pre; для Esterel только семейство, не constructive causality. |
| [Modelica 3.6 §8][modelica] | Equations, derivatives, continuous integration и events; разрешимость произвольной модели не обещается. |
| [Icarus simulation][iverilog], [VVP][vvp] | Scheduling и updates реализации; полные IEEE event regions ещё не сверены. |
| [NI G/LabVIEW][g], [Marten 1.6][prograph] | У NI — граф и readiness, у Marten — нотация; маркетинговые обещания производительности не используются. |
| [Janus archive][janus] | Только идентификация языка; бинарный PDF не засчитан как прочитанное определение. |

### Запланировано / не подтверждено

- Для всех C-вопросов основной карты нужны первичные источники выбранного
  профиля. Известность Java, C++, TypeScript или C# не заменяет эту работу.
- SNOBOL4 и Refal: предыдущие маршруты дали пустые ответы, ошибки передачи либо
  навигацию с проблемами кодировки. Нужен читаемый manual; семантика пока C.
- Esterel constructive semantics, Janus definition и Lustre V6 full reference:
  оглавления или неразобранные PDF недостаточны для детальных гарантий.
- Fortran — сверка по редакциям; VHDL/Verilog — конкретные IEEE-профили;
  Agda safe profiles, Racket phases и Stan — отдельные источники и примеры.
- Q#/Silq: [Q# Functors][qsharp] и [Silq Overview][silq] уже имеются в реестре
  чтения как узкие первичные тексты. Их перенос, контекстные утверждения и
  различающие примеры запланированы отдельным предметным пакетом.

[algol]: https://www.masswerk.at/algol60/report.htm
[scheme4]: https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-6.html
[scheme6]: https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-8.html
[racket]: https://docs.racket-lang.org/reference/cont.html
[smalltalk]: https://www.gnu.org/software/smalltalk/manual/html_node/Conditions.html
[self]: https://handbook.selflanguage.org/2024.1/langref.html
[jnouns]: https://www.jsoftware.com/help/dictionary/dicta.htm
[jverbs]: https://www.jsoftware.com/help/dictionary/dictb.htm
[dyalog]: https://help.dyalog.com/19.0/Content/Language/Primitive%20Operators/Rank.htm
[forth]: https://forth-standard.org/standard/usage
[icon]: https://www2.cs.arizona.edu/icon/docs/ipd266.htm
[lua]: https://www.lua.org/manual/5.4/manual.html#2.6
[python]: https://docs.python.org/3/library/stdtypes.html
[cobol]: https://gnucobol.sourceforge.io/HTML/gnucobpg.html
[fortran]: https://wg5-fortran.org/f2008.html
[sml]: https://www.smlnj.org/doc/Conversion/modules.html
[idris]: https://idris2.readthedocs.io/en/latest/tutorial/typesfuns.html
[agda]: https://agda.readthedocs.io/en/latest/language/termination-checking.html
[ada]: https://www.adaic.org/resources/add_content/standards/12rm/html/RM-6-1-1.html
[eiffel]: https://www.eiffel.org/doc/eiffel/ET-_Design_by_Contract_(tm),_Assertions_and_Exceptions
[spark]: https://docs.adacore.com/spark2014-docs/html/ug/en/spark_2014.html
[pony]: https://tutorial.ponylang.io/reference-capabilities/reference-capabilities.html
[koka]: https://koka-lang.github.io/koka/doc/book.html
[modes]: https://www.mercurylang.org/information/doc-release/mercury_ref/Insts-modes-and-mode-definitions.html
[det]: https://www.mercurylang.org/information/doc-release/mercury_ref/Determinism-categories.html
[souffle]: https://souffle-lang.github.io/tutorial
[relations]: https://souffle-lang.github.io/relations
[z3]: https://microsoft.github.io/z3guide/docs/fixedpoints/basicdatalog/
[sql]: https://www.postgresql.org/docs/18/queries-select-lists.html
[sqltruth]: https://www.postgresql.org/docs/18/functions-logical.html
[chr]: https://www.swi-prolog.org/pldoc/man?section=chr-syntaxandsemantics
[minizinc]: https://docs.minizinc.dev/en/stable/modelling.html
[erlang]: https://www.erlang.org/doc/system/conc_prog.html
[occam]: https://www.transputer.net/obooks/sw-0064-4/sw-0064-4.html
[oz]: https://mozart.github.io/mozart-v1/doc-1.4.0/tutorial/node1.html
[lustre]: https://www-verimag.imag.fr/The-Lustre-Programming-Language-and.html
[esterel]: https://www-sop.inria.fr/esterel.org/files/Html/About/AboutEsterel.htm
[modelica]: https://specification.modelica.org/maint/3.6/equations.html
[iverilog]: https://steveicarus.github.io/iverilog/usage/simulation.html
[vvp]: https://steveicarus.github.io/iverilog/developer/guide/vvp/vvp.html
[prograph]: https://www.andescotia.com/products/marten/
[g]: https://www.ni.com/en/shop/labview/benefits-of-programming-graphically-in-ni-labview.html
[janus]: https://www.tetsuo.jp/ref/janus.html
[qsharp]: https://learn.microsoft.com/en-us/azure/quantum/user-guide/language/expressions/functorapplication
[silq]: https://silq.ethz.ch/overview
