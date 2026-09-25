---
publish: true
title: Различающие примеры
---

# Различающие примеры

Каждый эксперимент отвечает на один вопрос о **семантике**, а не показывает
общий синтаксис языка. Сначала предскажите результат, затем выполните программу
и измените одну конструкцию. [Понятия онтологии](../../languages/glossary.md) задают
словарь, [карта языков](../language-map.md) объясняет выбор этих 15 пакетов.

Исходники доступны по ссылкам и включаются в страницу из тех же файлов:
код на странице и код для запуска не поддерживаются вручную в двух копиях.
Команды ниже выполняются из папки соответствующего примера, например
`docs/concepts/examples/src/scheme/`.

## Статусы проверки

**Запущено** означает фактический запуск именно этих файлов и сверку результата.
**По документации** означает, что механизм и ожидаемый результат разобраны по
указанному источнику, но этот исходник ещё не проверен соответствующим компилятором.
Это не гарантия переносимости на все версии и диалекты.

| Пакет | Механизм | Проверка |
|---|---|---|
| [Scheme](#scheme) | Повторный вход в продолжение; гигиена | Guile 3.0.9, `--r7rs` |
| [J](#j) | Применение операции по рангу | По документации; без запуска |
| [Icon](#icon) | Возобновление поиска после failure | Icon 9.4.3 |
| [Oz](#oz) | Ожидание связывания | По документации; без запуска |
| [Mercury](#mercury) | Режимы и число решений | По документации; без запуска |
| [Datalog](#datalog) | Неподвижная точка | По документации Soufflé; без запуска |
| [SQL](#sql) | Кратность строк и UNKNOWN | SQLite 3.45.1; PostgreSQL не запускался |
| [Standard ML](#sml) | Абстрактная идентичность типов | Poly/ML 5.7.1, включая отказ компиляции |
| [Idris 2](#idris) | Индекс в типе и тотальность | По документации; без запуска |
| [Eiffel](#eiffel) | Поведенческий контракт | По документации; без запуска |
| [COBOL](#cobol) | Десятичные позиции и переполнение | GnuCOBOL 3.1.2 |
| [Pony](#pony) | Права ссылки | По документации; без запуска |
| [Lustre](#lustre) | Поток по логическим тактам | Ручная трассировка; без запуска |
| [Modelica](#modelica) | Уравнение без направления | Ручной расчёт; без запуска |
| [Verilog](#verilog) | Отложенное обновление | Icarus Verilog 12.0 |

Запуски выполнены в Ubuntu 24.04, Linux ARM64. Версии пакетов и способ повторения —
в [инструкции к исходникам](#reproduce). Ожидаемые ошибки ниже не являются
дефектами примера: они проверяют границы гарантии.

## 1. Scheme: вернуться в вычисление {#scheme}

**Вопрос:** можно ли дважды вернуться в место, где вычислялся аргумент `+`?
Концепции: [продолжение](../../languages/concepts.md#control-continuation-extent),
[гигиена макросов](../../languages/concepts.md#syntax-macro-hygiene).

```scheme
--8<-- "src/scheme/continuation.scm"
```

```sh
guile --no-auto-compile --r7rs continuation.scm
```

**Получено:** строки `11`, `12`, `13`. `saved` сохраняет остаток вычисления:
прибавление 10, печать и выбор следующего действия. `phase` изменяем и находится
вне захваченного участка: повторный вход не откатывает память. Это не обычный
вызов функции, возвращающийся к строке после `(saved 2)`.

Отдельный эксперимент с именем `tmp`, которое совпадает с именем внутри макроса:

```scheme
--8<-- "src/scheme/hygiene.scm"
```

`guile --no-auto-compile --r7rs hygiene.scm` печатает **`(2 1)`**.
Введённый макросом `tmp` не захватывает переменную вызывающего кода.
**Контраст:** при наивной текстовой подстановке оба операнда могут стать равны 1.
Наличие скобок или макросов само по себе не гарантирует гигиену.

Исходники: [continuation.scm](src/scheme/continuation.scm), [hygiene.scm](src/scheme/hygiene.scm).
Источник: [R7RS §4.3](https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-6.html),
[§6.10](https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-8.html).

## 2. J: та же операция, другой ранг {#j}

Концепция: [rank lifting](../../languages/concepts.md#evaluation-rank-lifting).

```text
--8<-- "src/j/rank.ijs"
```

Матрица — строки `1 2 3` и `4 5 6`.
**Ожидается:** `6 15`, затем `5 7 9`. В первом случае `+/` применяется
к каждой строке (ячейке ранга 1), во втором — ко всей матрице (ранг 2)
и складывает её строки. Это не сумма всех элементов `21`.

Запуск: `/path/to/jconsole rank.ijs` в поставке **Jsoftware** с загруженным
профилем. `jconsole` из JDK — совершенно другой инструмент.
**Изменение:** заменить ранг 1 на 2 и объяснить форму результата.
Статус: исходник не запускался.

[Исходник](src/j/rank.ijs) · [J Dictionary: ranks of verbs](https://www.jsoftware.com/help/dictionary/dictb.htm).

## 3. Icon: неудача запускает следующую альтернативу {#icon}

Концепция: [протокол результатов](../../languages/concepts.md#evaluation-result-protocol).

```icon
--8<-- "src/icon/search.icn"
```

```sh
icont -s -o search search.icn
./search
```

**Получено:** `1`, `9`, `stored: fail`, `1`, `5`, `9` — по строкам.
`find` порождает позиции 1, 5 и 9. Сравнение `5 < ...` отклоняет первые две
и возобновляет генератор до 9. Присвоенный `first` содержит только первое
значение: сравнение с ним не умеет повторно запустить `find`.

**Изменение:** заменить `5 <` на `4 <` — первым успешным результатом будет 5.
Позиции начинаются с 1; успешное сравнение возвращает правый операнд, не `true`.

[Исходник](src/icon/search.icn) · [Icon overview §2](https://www2.cs.arizona.edu/icon/docs/ipd266.htm).

## 4. Oz: значение появится позже {#oz}

Концепции: [готовность данных](../../languages/concepts.md#evaluation-data-availability),
[логическое связывание](../../languages/concepts.md#bindings-mutation).

```oz
--8<-- "src/oz/dataflow.oz"
```

Для Mozart: `ozc -x dataflow.oz -o dataflow`, затем `./dataflow`.
**Ожидается:** `before binding`, затем `42`. Поток при вычислении `X + 1`
ждёт, если `X` ещё не связан; `X = 41` позволяет ему продолжиться.
Сигнал `Started` подтверждает вход в поток, но не доказывает, что планировщик
успел довести его до блокировки. Корректность не зависит от этой гонки.
`showInfo` и `show` могут выводить в разные потоки stdout/stderr: порядок строк
в объединённом журнале зависит от способа их захвата, а значение остаётся 42.

**Изменение:** удалить `thread ... end`, оставив `Y = X + 1` перед `X = 41`:
единственный поток блокируется до достижения связывания. Это не ошибка
«неинициализированное значение» и не автоматическое присваивание нуля.
Статус: без запуска, Oz 3 по руководству Mozart.

[Исходник](src/oz/dataflow.oz) · [Oz execution model](https://mozart.github.io/mozart-v1/doc-1.4.0/tutorial/node1.html).

## 5. Mercury: один предикат, два режима {#mercury}

Концепции: [режимы аргументов](../../languages/concepts.md#computation-instantiation-modes),
[кратность решений](../../languages/concepts.md#computation-solution-cardinality).

```prolog
--8<-- "src/mercury/modes.m"
```

Запуск: `mmc --make modes`, затем `./modes`.
**Ожидается:** список `[1, 2]`, затем число `3`. Первый вызов соединяет два
заданных списка. Второй ищет все разбиения `[1,2]`: `[]/[1,2]`, `[1]/[2]`,
`[1,2]/[]`. `solutions` собирает решения; пробелы печати зависят от реализации.

**Изменение:** объявить обратный режим как `det` вместо `multi` — ожидается
диагностика детерминизма. `det` описывает число результатов возвращающегося
вызова, а не доказывает завершение. Статус: без запуска.

[Исходник](src/mercury/modes.m) · [Mercury determinism](https://www.mercurylang.org/information/doc-release/mercury_ref/Determinism-categories.html).

## 6. Datalog: цикл в графе, конечное замыкание {#datalog}

Концепции: [неподвижная точка](../../languages/concepts.md#computation-rule-semantics),
[множество](../../languages/concepts.md#data-collection-multiplicity).

```prolog
--8<-- "src/datalog/reach.dl"
```

Soufflé: `souffle -D - reach.dl`.
**Ожидаемое множество:** `(a,a)`, `(a,b)`, `(a,c)`, `(b,a)`, `(b,b)`, `(b,c)`.
Порядок строк не фиксируется. Самодостижимость a и b появляется из цикла;
`(c,c)` не появляется, поскольку здесь достижимость путём длины **не менее 1**.

**Изменение:** повторить факт `edge("a","b")` — результат не удваивается.
Повторять вывод уже известного факта не требуется. Завершение относится к
этому положительному конечному примеру, не ко всем расширениям Soufflé.
Статус: без запуска; множество рассчитано вручную.

[Исходник](src/datalog/reach.dl) · [Soufflé tutorial](https://souffle-lang.github.io/tutorial).

## 7. SQL: одинаковые строки не исчезают сами {#sql}

Концепция: [кратность](../../languages/concepts.md#data-collection-multiplicity).

```sql
--8<-- "src/sql/multiplicity.sql"
```

```sh
sqlite3 -batch -noheader :memory: < multiplicity.sql
# Альтернатива для уже настроенного PostgreSQL:
# psql -X -A -t -v ON_ERROR_STOP=1 -f multiplicity.sql
```

**Получено в SQLite:** `1`, `1`, `2`; затем `1`, `2`; затем `unknown`.
`ALL` сохраняет кратность; `DISTINCT` удаляет дубликаты. `ORDER BY` нужен
для воспроизводимого порядка выдачи, а не для устранения дубликатов.

**Изменение:** убрать `DISTINCT` — одинаковые строки вернутся.
`NULL = NULL` не истинно и не ложно: пример дополнительно выявляет
трёхзначную логику. Она ещё не выделена отдельной осью онтологии.
Запуск SQLite не засчитывается как запуск PostgreSQL.

[Исходник](src/sql/multiplicity.sql) · [PostgreSQL SELECT](https://www.postgresql.org/docs/18/queries-select-lists.html),
[SQLite SELECT](https://www.sqlite.org/lang_select.html).

## 8. Standard ML: одинаковое представление, разные типы {#sml}

Концепции: [абстрактная идентичность](../../languages/concepts.md#typing-abstract-type-identity),
[модульные функторы](../../languages/concepts.md#abstraction-modules).

```sml
--8<-- "src/sml/opaque.sml"
```

`poly --script opaque.sml` печатает **`7`**.
Теперь отдельная программа:

```sml
--8<-- "src/sml/reject.sml"
```

`poly --script reject.sml` сначала печатает `7` из загруженного файла,
затем завершается с ошибкой типов: **нельзя унифицировать `B.t` и `A.t`**.
Каждое применение `Fresh()` создаёт свежую абстрактную идентичность.

**Контроль:** в [transparent.sml](src/sml/transparent.sml) заменено `:>` на `:`.
`poly --script transparent.sml` принимает межмодульный вызов и печатает `7`:
прозрачное согласование сохраняет равенство обоих типов с `int`.

[opaque.sml](src/sml/opaque.sml) · [reject.sml](src/sml/reject.sml) ·
[SML ’97 §1.3.9](https://www.smlnj.org/doc/Conversion/modules.html).

## 9. Idris 2: длина связана с допустимым индексом {#idris}

Концепции: [зависимые типы](../../languages/concepts.md#typing-value-dependency),
[тотальность](../../languages/concepts.md#verification-totality).

```idris
--8<-- "src/idris/Index.idr"
```

`idris2 --check Index.idr` должен принять определение;
в REPL `idris2 Index.idr` команда `:exec main` должна вывести `20`.
`FS FZ` — индекс 1, нумерация с нуля. Ветвь для пустого вектора не нужна:
аргумент `Fin 0` невозможно построить обычными конструкторами.

**Контроль:** `idris2 --check BadIndex.idr` должен отвергнуть индекс 3
для трёх элементов. [BadIndex.idr](src/idris/BadIndex.idr) содержит именно
такой вызов. `%default total` отдельно требует полноту/завершение определений:
зависимая типизация сама по себе не означает тотальность.
Статус: обе программы ещё не запускались.

[Index.idr](src/idris/Index.idr) · [Idris: Vect, Fin, totality](https://idris2.readthedocs.io/en/latest/tutorial/typesfuns.html).

## 10. Eiffel: контракт сильнее сигнатуры {#eiffel}

Концепция: [поведенческие контракты](../../languages/concepts.md#verification-behavioral-contracts).

```eiffel
--8<-- "src/eiffel/account.e"
```

В EiffelStudio создайте console-проект с корнем `APPLICATION.make`, добавьте
[application.e](src/eiffel/application.e) и [account.e](src/eiffel/account.e).
В настройках assertions включите preconditions, postconditions и invariants.
**Ожидается:** после `deposit(10)` баланс `10`.

**Контроль 1:** раскомментировать `a.deposit (-1)` — нарушение предусловия
`positive` при включённой проверке. **Контроль 2:** заменить `+ amount` на
`- amount` — положительный депозит нарушит постусловие `credited`.
`old balance` означает значение на входе в вызов, а не предыдущее присваивание.
Числа малы, переполнение INTEGER в этом опыте не исследуется.

Статус: по документации, проект не компилировался. Runtime-monitoring
контрактов не является статическим доказательством.
Источник: [Eiffel Design by Contract](https://www.eiffel.org/doc/eiffel/ET-_Design_by_Contract_%28tm%29%2C_Assertions_and_Exceptions).

## 11. COBOL: позиции, а не двоичная дробь {#cobol}

Концепции: [radix](../../languages/concepts.md#data-numeric-radix),
[precision](../../languages/concepts.md#data-numeric-precision).

```cobol
--8<-- "src/cobol/decimal.cob"
```

`cobc -x -free -o decimal decimal.cob`, затем `./decimal`.
**Получено:** `012.3`, `012.4`, `overflow`.
В `PIC 9(3)V9` четыре цифровые позиции и один дробный разряд. `V` не хранит
символ точки; для вывода применён отдельный edited picture `999.9`.
Значение 1012.4 не помещается, срабатывает `ON SIZE ERROR`.

**Изменение:** расширить поле до `9(4)V9` и формат до `9999.9` — добавление
1000 перестаёт переполнять поле. Пример про десятичное поле, не про все
числовые представления COBOL. Масштаб и точность — разные свойства.

[Исходник](src/cobol/decimal.cob) · [GnuCOBOL: PICTURE и arithmetic](https://gnucobol.sourceforge.io/HTML/gnucobpg.html).

## 12. Pony: read-only не означает immutable {#pony}

Концепции: [права ссылки](../../languages/concepts.md#memory-reference-permissions),
[перемещение](../../languages/concepts.md#memory-transfer).

```text
--8<-- "src/pony/main.pony"
```

В каталоге с `main.pony`: `ponyc -o build -b capabilities`, затем
`./build/capabilities`. **Ожидаются строки:** `1`, `0`, `1`.
Ссылка `view: box` видит изменение через `writable: ref`, хотя сама не может
вызывать изменяющий метод. `val` описывает разделяемый неизменяемый объект.
`consume` переносит доступ через изолированную ссылку.

**Контроли:** раскомментировать по одной из трёх строк. Ожидаются отказы
компиляции: вызов `ref`-метода через `box`; изменение через `val`; использование
поглощённой переменной. Изоляция не является обещанием отсутствия любых
внутренних ссылок в графе. Статус: компилятором не проверено.

[Исходник](src/pony/main.pony) · [Pony capabilities](https://tutorial.ponylang.io/reference-capabilities/reference-capabilities.html).

## 13. Lustre: значение — поток {#lustre}

Концепции: [логические такты](../../languages/concepts.md#computation-time-domain),
[уравнения потоков](../../languages/concepts.md#computation-equation-causality).

```text
--8<-- "src/lustre/integr.lus"
```

**Ручная трасса**, не результат запуска компилятора:

| Такт | 0 | 1 | 2 | 3 |
|---|---:|---:|---:|---:|
| `a` | 10 | 2 | 3 | 4 |
| `i` | 0 | 2 | 5 | 9 |

`->` выбирает левую часть в первый такт, правую — далее. Поэтому первый вход
10 не прибавляется. `pre(i)` — значение на предыдущем логическом такте.
**Изменение:** заменить начальный `0` на `a`: трасса станет `10,12,15,19`.
Удаление инициализирующей стрелки оставляет `pre(i)` неопределённым в первый такт.

Для проверки загрузите узел `integr` в симулятор выбранной версии Lustre,
задайте четыре такта входа и сравните трассу. Универсальной CLI-команды для
V4/V6/SCADE здесь не заявляется. Логический такт не обязан длиться секунду.

[Исходник](src/lustre/integr.lus) · [Verimag: пример integr](https://www-verimag.imag.fr/The-Lustre-Programming-Language-and.html).

## 14. Modelica: неизвестная может быть с любой стороны {#modelica}

Концепция: [ненаправленные уравнения](../../languages/concepts.md#computation-equation-causality).

```modelica
--8<-- "src/modelica/Ohm.mo"
```

**Ожидается по ручному расчёту:** в первой модели `i = 5`, во второй `v = 6`.
Одно и то же `v = R*i` используется в разных направлениях в зависимости от
остальных уравнений. `R=2`, поэтому решение каждого примера однозначно.

Для OpenModelica подготовлен [run.mos](src/modelica/run.mos): запуск `omc run.mos`
должен сначала симулировать первую модель и запросить `i`, затем вторую и `v`.
Статус: OpenModelica не запускалась, команды и числовые результаты ещё не проверены в ней.

**Контроль:** добавить во вторую модель также `v = 10`. Это не последовательное
переприсваивание: система переопределена и противоречива. Перестановка равенств
не означает порядок выполнения. Пример не утверждает разрешимость любой модели.

[Исходник](src/modelica/Ohm.mo) · [Modelica 3.6 §8](https://specification.modelica.org/maint/3.6/equations.html).

## 15. Verilog: вычислить сейчас, обновить позже {#verilog}

Концепция: [планирование обновлений](../../languages/concepts.md#computation-update-scheduling).

```verilog
--8<-- "src/verilog/swap.v"
```

```sh
iverilog -g2012 -s swap -o swap swap.v
vvp swap
```

**Получено:**

```text
active: a=1 b=2 x=2 y=2
settled: a=2 b=1 x=2 y=2
```

Icarus дополнительно печатает служебное сообщение `$finish`.
`<=` вычисляет правые части с прежними `a,b`, а изменения применяет позже.
`=` меняет `x` сразу, поэтому следующий оператор копирует уже новое значение.
`$strobe` наблюдает установившиеся значения в конце текущего временного шага.

**Изменение:** заменить оба `<=` на `=` — пара `a,b` тоже станет `2,2`.
У переменных один процедурный writer, поэтому здесь нет гонки между двумя
`always`. Это тест симуляционной семантики; синтез схемы не выполнялся.

[Исходник](src/verilog/swap.v) · [Icarus simulation](https://steveicarus.github.io/iverilog/usage/simulation.html).

## Как повторить проверенные запуски {#reproduce}

Для шести проверенных пакетов нужны `guile`, `poly`, `icont`/`iconx`, `cobc`,
`iverilog`/`vvp` и `sqlite3`. Установка в Ubuntu 24.04:

```sh
apt-get update
apt-get install python3 guile-3.0 polyml icont iconx gnucobol iverilog sqlite3
python3 tools/check-concept-examples.py
```

Python-скрипт запускается **из репозитория**, копирует примеры во временную
папку и сравнивает stdout. Для SML проверяется также ненулевой код и конкретная
ошибка несовместимости `A.t`/`B.t`. Отсутствующие инструменты отмечаются как
пропуски; `--require-all` делает такой пропуск ошибкой. Девять непроверенных
пакетов в этот runner не включены; их команды приведены в разделах выше.

Зафиксированные версии пакетов Ubuntu:

| Пакет | Версия |
|---|---|
| guile-3.0 | 3.0.9-1build2 |
| polyml | 5.7.1-5build1 |
| icont / iconx | 9.4.3-7ubuntu1 |
| gnucobol3 | 3.1.2-5.1ubuntu1 |
| iverilog | 12.0-2build2 |
| sqlite3 | 3.45.1-1ubuntu2.8 |

Проверка сборки сайта проверяет включение исходников и ссылки, но **не запускает
компиляторы всех языков**. Не меняйте статус на «запущено» только потому,
что MkDocs собрал страницу.
