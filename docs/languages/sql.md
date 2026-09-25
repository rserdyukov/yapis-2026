---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# SQL

SQL — декларативный язык запросов и описания данных: запрос задаёт требуемый результат над таблицами, а план выполнения выбирает СУБД. Таблицы и результаты запросов — мультимножества строк; `NULL` порождает трёхзначную логику с `UNKNOWN`, а `WITH RECURSIVE` вычисляет замыкание отношений. Базовый профиль — ISO/IEC 9075:2023 (Foundation, текст платный, поэтому утверждения опираются на документацию СУБД, где она ссылается на стандарт); поведение SQLite и PostgreSQL отмечено как диалект реализации, процедурные расширения (SQL/PSM, PL/pgSQL) — отдельно.

*Карточка сравнительная: 35/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1974 — [Wikidata P571](https://www.wikidata.org/wiki/Q47607) (получено 2026-09-25) |
| Авторы | [Дональд Чемберлин](people.md#chamberlin), [Рэймонд Бойс](people.md#boyce) |
| Организации | IBM, ISO/IEC JTC 1/SC 32 |
| Сайт | <https://www.iso.org/standard/76583.html> |
| Спецификация | <https://www.iso.org/standard/76583.html> |
| Внешние каталоги | [Wikidata Q47607](https://www.wikidata.org/wiki/Q47607) |

## Статьи { #articles }

- [SQL: декларативность](../garden/sql-declarative.md)

## Люди { #people }

- [Дональд Чемберлин](people.md#chamberlin) — Соавтор языка SEQUEL (впоследствии SQL), созданного в IBM Research для System R.
- [Рэймонд Бойс](people.md#boyce) — Соавтор SEQUEL/SQL и нормальной формы Бойса — Кодда.

## Публикации { #publications }

- Эдгар Кодд. *A Relational Model of Data for Large Shared Data Banks*. Communications of the ACM 13(6), 1970. DOI: [10.1145/362384.362685](https://doi.org/10.1145/362384.362685). Реляционная модель — отношения как множества кортежей; теоретическая основа SQL. ([в источниках](sources.md#codd-1970))
- Дональд Чемберлин, Рэймонд Бойс. *SEQUEL: A Structured English Query Language*. ACM SIGFIDET Workshop, 1974. DOI: [10.1145/800296.811515](https://doi.org/10.1145/800296.811515). Первое описание языка, ставшего SQL; декларативный запрос вместо навигации по записям. ([в источниках](sources.md#sequel-1974))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **iso2023** — ISO/IEC 9075-2:2023 SQL/Foundation: запросы (DML) и описание схемы (DDL). Стандарт платный; утверждения подтверждаются открытыми вторичными источниками — документацией PostgreSQL и SQLite в местах, где она явно описывает стандарт. Процедурная часть SQL/PSM (ISO/IEC 9075-4) в профиль не входит.
- **sqlite** — Диалект SQLite 3 по SQL As Understood By SQLite (https://www.sqlite.org/lang.html); слой реализации. Различающий пример проверен на SQLite 3.45.1, статья сада — на 3.51.0; прочие утверждения относятся к текущей документации без фиксации выпуска.
- **postgresql** — Диалект PostgreSQL по текущей документации (https://www.postgresql.org/docs/current/), включая CREATE FUNCTION и PL/pgSQL там, где это указано; слой реализации, выпуск не фиксируется.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: iso2023)** — Псевдонимы `AS`, имена CTE и объекты схемы (`CREATE TABLE`, `CREATE VIEW`) вводятся явно; переменных в запросе нет, параметры подставляются клиентом.

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Неизменяемое (layer: language, profile: iso2023, applies_to: псевдонимы и имена CTE внутри запроса)** — Имя, введённое в запросе, нельзя перепривязать. Изменение данных таблиц операторами `INSERT`/`UPDATE`/`DELETE` — изменение состояния базы, а не перепривязка имени.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: iso2023, applies_to: UPDATE … SET column = expr)** — Все правые части в `SET` вычисляются по старым значениям строки, поэтому `SET a = b, b = a` меняет значения местами. ([PostgreSQL — UPDATE](https://www.postgresql.org/docs/current/sql-update.html))
- **Распаковка при присваивании (layer: language, profile: iso2023, applies_to: UPDATE … SET (a, b) = (expr1, expr2))** — Присваивание списка столбцов из конструктора строки или подзапроса. ([PostgreSQL — UPDATE: column list assignment](https://www.postgresql.org/docs/current/sql-update.html); [SQLite — UPDATE: column-name-list](https://www.sqlite.org/lang_update.html))

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: iso2023)** — Имена столбцов и псевдонимов таблиц разрешаются по вложенности текста запроса: коррелированный подзапрос видит псевдонимы внешнего запроса, внешний не видит имён подзапроса. ([PostgreSQL — Table Expressions: table aliases and subqueries](https://www.postgresql.org/docs/current/queries-table-expressions.html))

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Блок (layer: language, profile: iso2023, applies_to: запрос и подзапрос (FROM, WHERE, SELECT))** — Каждый запросный блок вводит область псевдонимов таблиц из своего `FROM`; ссылка из подзапроса на внешний столбец делает подзапрос коррелированным.
- **Форма связывания let/where (layer: language, profile: iso2023, applies_to: WITH)** — Предложение `WITH` связывает имена CTE для следующего за ним запроса, подобно `let`; с `RECURSIVE` имя видно и в собственном определении. ([SQLite — WITH clause](https://www.sqlite.org/lang_with.html))

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

*Name shadowing* · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: iso2023)** — Неуточнённое имя столбца разрешается в ближайшем охватывающем запросном блоке, где оно определено; одноимённый столбец внешнего запроса скрывается. Опечатка в имени столбца подзапроса может молча сослаться на внешний столбец.

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Статическая (layer: language, profile: iso2023)** — Тип значения определяется столбцом или выражением: несовместимость типов в запросе обнаруживается при его подготовке (анализе), до чтения строк. ([SQLite — Datatypes: other engines use static, rigid typing](https://www.sqlite.org/datatype3.html))
- **Статическая (layer: implementation, profile: postgresql, implementation: PostgreSQL)** — Разрешение операторов, функций и типов столбцов результата выполняется при анализе запроса по правилам преобразования типов. ([PostgreSQL — Type Conversion](https://www.postgresql.org/docs/current/typeconv.html))
- **Динамическая (layer: implementation, profile: sqlite, implementation: SQLite)** — В SQLite тип принадлежит значению, а не столбцу: объявленный тип задаёт лишь affinity (предпочтительный класс хранения). Таблицы `STRICT` включают проверку типов столбцов при записи. ([SQLite — Datatypes In SQLite: dynamic typing and type affinity](https://www.sqlite.org/datatype3.html); [SQLite — STRICT Tables](https://www.sqlite.org/stricttables.html))

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Обязательны (layer: language, profile: iso2023, applies_to: столбцы CREATE TABLE, CAST, объявления доменов)** — В стандарте определение столбца содержит тип данных или домен; типы выражений запроса и столбцов представлений выводятся из операндов без аннотаций.
- **Необязательны (layer: implementation, profile: sqlite, implementation: SQLite, applies_to: столбцы CREATE TABLE)** — Имя типа в определении столбца необязательно; столбец без объявленного типа получает affinity BLOB. ([SQLite — CREATE TABLE: column-def and type-name](https://www.sqlite.org/lang_createtable.html); [SQLite — affinity for no datatype specified](https://www.sqlite.org/datatype3.html))

#### Вывод статических типов { #typing-inference }

*Static type inference* · [в онтологии](concepts.md#typing-inference)

- **да (layer: implementation, profile: postgresql, implementation: PostgreSQL, scope: prepared statement parameters)** — Тип неуказанного параметра `$n` в `PREPARE` выводится из контекста использования. Это вывод типов отдельных выражений при анализе запроса, а не полиморфный вывод типов программы. ([PostgreSQL — PREPARE: parameter type inferred from context](https://www.postgresql.org/docs/current/sql-prepare.html))

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Явные (layer: language, profile: iso2023, applies_to: CAST(expr AS type))** — `CAST` — стандартная явная конверсия; недопустимое значение (например, нечисловая строка в INTEGER) даёт ошибку в стандарте и PostgreSQL. ([PostgreSQL — Value Expressions: Type Casts](https://www.postgresql.org/docs/current/sql-expressions.html))
- **Неявные (layer: language, profile: iso2023)** — Числовые типы разной точности приводятся в арифметике, сравнении и присваивании столбцу; набор неявных преобразований у СУБД различается. ([PostgreSQL — Type Conversion](https://www.postgresql.org/docs/current/typeconv.html))
- **Неявные (layer: implementation, profile: sqlite, implementation: SQLite)** — Affinity столбца преобразует записываемое значение, если это возможно без потерь: текст `'42'` в столбце INTEGER сохраняется как целое; `CAST` в SQLite не ошибается, а возвращает приближение (например, 0). ([SQLite — Type Affinity](https://www.sqlite.org/datatype3.html); [SQLite — CAST expressions](https://www.sqlite.org/lang_expr.html))

#### Совместимость типов { #typing-compatibility }

*Type compatibility* · [в онтологии](concepts.md#typing-compatibility)

- **Структурная (layer: language, profile: iso2023, applies_to: результаты UNION/INTERSECT/EXCEPT, INSERT … SELECT)** — Строки сопоставляются по позиции: число столбцов должно совпадать, типы соответствующих столбцов — быть совместимыми; имена столбцов не участвуют. ([PostgreSQL — union compatible queries](https://www.postgresql.org/docs/current/queries-union.html))

#### Типы-произведения { #typing-product-types }

*Product types* · [в онтологии](concepts.md#typing-product-types)

- **Записи и структуры (layer: language, profile: iso2023, applies_to: строки таблиц, составные типы, ROW)** — Строка — запись именованных столбцов; стандарт также определяет row types и structured types. В PostgreSQL каждая таблица задаёт одноимённый составной тип. ([PostgreSQL — Composite Types](https://www.postgresql.org/docs/current/rowtypes.html))
- **Кортежи (layer: language, profile: iso2023, applies_to: конструктор строки ROW(a, b) и (a, b))** — Анонимный конструктор строки сравнивается поэлементно по позиции, например `(a, b) < (c, d)`. ([PostgreSQL — Row Constructors](https://www.postgresql.org/docs/current/sql-expressions.html))

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Nullable-ссылки по умолчанию (layer: language, profile: iso2023)** — Значение любого типа может быть `NULL`, пока столбец или домен не ограничен `NOT NULL`; это ограничение, а не отдельный nullable-тип. Сравнение с `NULL` даёт `UNKNOWN`: в примере сайта `CASE` при `NULL = NULL` уходит в ветку `ELSE` ('unknown'). `IS NULL` и `IS [NOT] DISTINCT FROM` сравнивают с учётом `NULL`. ([PostgreSQL — Comparison Functions and Operators: IS DISTINCT FROM](https://www.postgresql.org/docs/current/functions-comparison.html); [PostgreSQL — Constraints: Not-Null Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html); [SQLite — NULL Handling in SQLite Versus Other Database Engines](https://www.sqlite.org/nulls.html))

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условное выражение (layer: language, profile: iso2023, applies_to: CASE, COALESCE, NULLIF)** — `CASE WHEN … THEN … ELSE … END` — выражение со значением; без `ELSE` результат `NULL`. Условие, давшее `UNKNOWN`, не выбирает ветку. Оператор `IF` есть только в процедурных расширениях (SQL/PSM, PL/pgSQL). ([PostgreSQL — Conditional Expressions](https://www.postgresql.org/docs/current/functions-conditional.html))
- **Охранные условия (layer: language, profile: iso2023, applies_to: WHERE, HAVING, ON, FILTER)** — Предикат отбирает строки: проходят только строки с `TRUE`; `FALSE` и `UNKNOWN` отбрасываются одинаково. ([PostgreSQL — The WHERE Clause](https://www.postgresql.org/docs/current/queries-table-expressions.html))

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: iso2023, applies_to: простая форма CASE expr WHEN value THEN …)** — Простая форма `CASE` сравнивает одно выражение со списком значений; это выражение, а не оператор с проваливанием. `CASE x WHEN NULL` никогда не срабатывает, так как сравнение использует `=`. ([PostgreSQL — CASE (simple form)](https://www.postgresql.org/docs/current/functions-conditional.html))

#### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **нет (layer: language, profile: iso2023)** — `LIKE`, `SIMILAR TO` и регулярные выражения сопоставляют строки с шаблоном, но не разбирают структуру значения со связыванием переменных. `MATCH_RECOGNIZE` (распознавание образцов в последовательностях строк) — отдельная необязательная возможность стандарта, не рассмотренная здесь.

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **неприменимо (n/a) (layer: language, profile: iso2023)** — В языке запросов нет операторов цикла: обработка всех строк следует из семантики отношений, а повторение — из `WITH RECURSIVE`. Циклы `LOOP`/`WHILE`/`FOR` принадлежат SQL/PSM и PL/pgSQL, не SQL/Foundation.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **да (layer: implementation, profile: postgresql, implementation: PostgreSQL, applies_to: CREATE FUNCTION)** — Функции с одинаковым именем различаются типами входных аргументов. В языке запросов подпрограмм нет — это свойство определяемых пользователем функций. ([PostgreSQL — Function Overloading](https://www.postgresql.org/docs/current/xfunc-overload.html))

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **нет (layer: language, profile: iso2023)** — Анонимных функций как значений в SQL/Foundation нет; ближайшие средства — подзапросы и CTE, которые являются выражениями-таблицами, а не функциями.

#### Аргументы по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **да (layer: implementation, profile: postgresql, implementation: PostgreSQL, applies_to: CREATE FUNCTION … DEFAULT)** ([PostgreSQL — SQL Functions with Default Values for Arguments](https://www.postgresql.org/docs/current/xfunc-sql.html))

#### Именованные аргументы { #subprograms-named-args }

*Named arguments* · [в онтологии](concepts.md#subprograms-named-args)

- **да (layer: implementation, profile: postgresql, implementation: PostgreSQL, applies_to: вызов функций с именованными параметрами)** — Нотация `f(a => 1)` и смешанная позиционно-именованная форма. ([PostgreSQL — Calling Functions: Named Notation](https://www.postgresql.org/docs/current/sql-syntax-calling-funcs.html))

### Полиморфизм и организация { #abstraction }

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Пространства имён и пакеты (layer: language, profile: iso2023)** — Схемы (schema) — пространства имён таблиц, представлений и подпрограмм внутри каталога; имя уточняется как `schema.table`. `INFORMATION_SCHEMA` — стандартная схема метаданных. ([PostgreSQL — Schemas](https://www.postgresql.org/docs/current/ddl-schemas.html))
- **Пространства имён и пакеты (layer: implementation, profile: sqlite, implementation: SQLite)** — Имя схемы — `main`, `temp` или имя присоединённой через `ATTACH` базы; вложенных схем внутри одной базы нет. ([SQLite — Database Object Name Resolution](https://www.sqlite.org/lang_naming.html); [SQLite — ATTACH DATABASE](https://www.sqlite.org/lang_attach.html))

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **неприменимо (n/a) (layer: language, profile: iso2023)** — Язык задаёт результат, а не порядок вычисления: оптимизатор выбирает план, подвыражения могут вычисляться в любом порядке или не вычисляться вовсе. Поэтому ни strict, ни non-strict не описывают SQL без оговорок; порядок гарантирует лишь `CASE` (с исключениями для констант). ([PostgreSQL — Expression Evaluation Rules](https://www.postgresql.org/docs/current/sql-expressions.html))

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Код ошибки (layer: language, profile: iso2023)** — Результат выполнения оператора сообщается пятисимвольным кодом `SQLSTATE`: класс из двух символов и подкласс (например, `22012` — деление на ноль). Коды классов определены стандартом. ([PostgreSQL — Appendix A. Error Codes (SQLSTATE per SQL standard)](https://www.postgresql.org/docs/current/errcodes-appendix.html))
- **Код ошибки (layer: implementation, profile: sqlite, implementation: SQLite)** — C API SQLite возвращает целочисленные коды результата (`SQLITE_CONSTRAINT` и расширенные коды), а не `SQLSTATE`. ([SQLite — Result and Error Codes](https://www.sqlite.org/rescode.html))
- **Исключения (layer: implementation, profile: postgresql, implementation: PL/pgSQL, applies_to: процедурное расширение PL/pgSQL (аналог обработчиков SQL/PSM))** — Блок `BEGIN … EXCEPTION WHEN … THEN` перехватывает ошибку по имени условия или `SQLSTATE`; это не часть декларативного языка запросов. ([PostgreSQL — PL/pgSQL: Trapping Errors](https://www.postgresql.org/docs/current/plpgsql-control-structures.html))

### Ресурсы и взаимодействие { #resources }

<a id="req-4"></a>

#### Интерфейс ввода-вывода { #resources-io }

*I/O interface* · [в онтологии](concepts.md#resources-io)

- **неприменимо (n/a) (layer: language, profile: iso2023)** — Язык не содержит операций ввода-вывода: результат запроса передаётся клиенту через интерфейс СУБД (встроенный SQL, CLI, драйвер). Команды вроде `COPY` PostgreSQL — расширения реализации.

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: iso2023)** — Подзапросы и группы выражений ограничиваются скобками; предложения запроса (`SELECT`, `FROM`, `WHERE`…) начинаются ключевыми словами. `BEGIN … END` — конструкция процедурных расширений.

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Точка с запятой (layer: language, profile: iso2023)** — Операторы в скрипте разделяются `;`. Отдельный оператор, переданный через API, может обходиться без неё. ([SQLite — sql-stmt-list: semicolon-separated statements](https://www.sqlite.org/lang.html))

#### Чувствительность имён к регистру { #syntax-case-sensitive }

*Identifier case sensitivity* · [в онтологии](concepts.md#syntax-case-sensitive)

- **нет (layer: language, profile: iso2023, applies_to: ключевые слова и неквотированные идентификаторы)** — Стандарт приводит неквотированные идентификаторы к верхнему регистру, PostgreSQL — к нижнему; квотированные `"Foo"` чувствительны к регистру. В SQLite идентификаторы нечувствительны к регистру, строковые литералы пишутся в `'…'`, а не в двойных кавычках. ([PostgreSQL — Lexical Structure: identifier case folding vs SQL standard](https://www.postgresql.org/docs/current/sql-syntax-lexical.html); [SQLite — SQL Keywords and quoting](https://www.sqlite.org/lang_keywords.html))

#### Метапрограммирование { #syntax-metaprogramming }

*Metaprogramming* · [в онтологии](concepts.md#syntax-metaprogramming)

- **Рефлексия (layer: language, profile: iso2023, applies_to: INFORMATION_SCHEMA)** — Метаданные схемы доступны обычными запросами к стандартным представлениям `INFORMATION_SCHEMA`. ([PostgreSQL — The Information Schema (defined in the SQL standard)](https://www.postgresql.org/docs/current/information-schema.html))
- **Построение и выполнение кода (layer: language, profile: iso2023, applies_to: динамический SQL (PREPARE/EXECUTE))** — Текст оператора собирается строкой и подготавливается во время выполнения; в стандарте это встроенный (embedded) и процедурный SQL, в PostgreSQL — `PREPARE` и `EXECUTE` в PL/pgSQL. ([PostgreSQL — PREPARE: compatibility with embedded SQL](https://www.postgresql.org/docs/current/sql-prepare.html))

#### Нотация исходной программы { #syntax-program-representation }

*Source program notation* · [в онтологии](concepts.md#syntax-program-representation)

- **Текстовая нотация (layer: language, profile: iso2023)**

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Декларативная (layer: language, profile: iso2023)** — Запрос описывает результат через отношения, предикаты и агрегаты; порядок соединений, индексы и алгоритмы выбирает оптимизатор. Последовательность операторов в скрипте и транзакции — процедурная оболочка над декларативными запросами.

### Семантика данных { #data }

#### Кратность элементов коллекции { #data-collection-multiplicity }

*Collection multiplicity* · [в онтологии](concepts.md#data-collection-multiplicity)

- **Мультимножество с кратностями (layer: language, profile: iso2023, applies_to: таблицы без ключа, результаты SELECT и SELECT ALL, UNION ALL)** — Одинаковые строки сохраняют кратность: `SELECT ALL` — поведение по умолчанию. Пример сайта (раздел «SQL» страницы примеров) на `VALUES (1), (1), (2)` выдаёт `1`, `1`, `2`. Первичный ключ или `UNIQUE` лишь запрещают дубли в конкретной таблице и не меняют модель результата запроса. ([PostgreSQL — Select Lists: ALL and DISTINCT](https://www.postgresql.org/docs/current/queries-select-lists.html); [SQLite — SELECT](https://www.sqlite.org/lang_select.html))
- **Множество без дубликатов (layer: language, profile: iso2023, applies_to: SELECT DISTINCT, UNION, INTERSECT, EXCEPT без ALL)** — `DISTINCT` и теоретико-множественные операции без `ALL` устраняют дубли; в примере сайта `SELECT DISTINCT` даёт `1`, `2`. Для сравнения строк при устранении дублей два `NULL` считаются неразличимыми, хотя `NULL = NULL` даёт `UNKNOWN`. ([PostgreSQL — Combining Queries: UNION eliminates duplicates unless ALL](https://www.postgresql.org/docs/current/queries-union.html))
- **Последовательность позиционных вхождений (layer: language, profile: iso2023, applies_to: результат с ORDER BY верхнего уровня при выдаче клиенту)** — Порядок строк гарантирует только внешний `ORDER BY`; он упорядочивает выдачу, но не устраняет дубли. Без него порядок зависит от плана и не превращает мультимножество в последовательность. ([PostgreSQL — Sorting Rows (ORDER BY)](https://www.postgresql.org/docs/current/queries-order.html))

#### Основание числового представления { #data-numeric-radix }

*Numeric representation radix* · [в онтологии](concepts.md#data-numeric-radix)

- **Десятичное (layer: language, profile: iso2023, applies_to: DECIMAL, NUMERIC)** — Точные числовые типы хранят десятичные разряды: `0.1 + 0.2 = 0.3` для `NUMERIC` истинно. ([PostgreSQL — Numeric Types: Arbitrary Precision Numbers](https://www.postgresql.org/docs/current/datatype-numeric.html))
- **Двоичное (layer: language, profile: iso2023, applies_to: REAL, DOUBLE PRECISION, FLOAT)** — Приближённые типы; в PostgreSQL — IEEE 754 одинарной и двойной точности. ([PostgreSQL — Floating-Point Types](https://www.postgresql.org/docs/current/datatype-numeric.html))
- **Двоичное (layer: implementation, profile: sqlite, implementation: SQLite, applies_to: столбцы DECIMAL/NUMERIC)** — Объявление `DECIMAL(10,5)` даёт affinity NUMERIC: значение хранится как INTEGER или 8-байтовое REAL, десятичного типа хранения нет. ([SQLite — Storage Classes and NUMERIC affinity](https://www.sqlite.org/datatype3.html))

#### Ограничение числовой точности { #data-numeric-precision }

*Numeric precision bound* · [в онтологии](concepts.md#data-numeric-precision)

- **Фиксированная разрядность типа или поля (layer: language, profile: iso2023, applies_to: DECIMAL(p, s), NUMERIC(p, s), целые типы)** — Точность и масштаб объявляются в типе; значение, не помещающееся в точность, вызывает ошибку. По стандарту `NUMERIC` без масштаба имеет масштаб 0. ([PostgreSQL — Numeric Types (SQL standard default scale 0)](https://www.postgresql.org/docs/current/datatype-numeric.html))
- **Нефиксированная заранее разрядность (layer: implementation, profile: postgresql, implementation: PostgreSQL, applies_to: NUMERIC без точности и масштаба)** — «Unconstrained numeric» хранит значения любой длины до пределов реализации (до 131072 цифр до точки) и не приводит их к фиксированному масштабу — отклонение от стандартного масштаба 0. ([PostgreSQL — Arbitrary Precision Numbers](https://www.postgresql.org/docs/current/datatype-numeric.html))

### Правила вычисления и модели времени { #computation }

#### Смысл применения правил { #computation-rule-semantics }

*Rule application semantics* · [в онтологии](concepts.md#computation-rule-semantics)

- **Наименьшее замыкание отношений (layer: language, profile: iso2023, applies_to: WITH RECURSIVE с UNION над конечными данными без порождения новых значений)** — Нерекурсивная часть задаёт начальные строки, рекурсивная итерируется до пустого приращения. С `UNION` и монотонным телом (например, транзитивное замыкание графа с циклом) результат — наименьшая неподвижная точка. `UNION ALL` и порождение значений (`n + 1`) могут не завершиться без условия остановки; стандарт ограничивает форму рекурсии (например, запрещает агрегаты в рекурсивной части). ([PostgreSQL — WITH Queries: Recursive Query Evaluation](https://www.postgresql.org/docs/current/queries-with.html))
- **Наименьшее замыкание отношений (layer: implementation, profile: sqlite, implementation: SQLite, applies_to: WITH RECURSIVE)** — SQLite требует составного SELECT: нерекурсивные части перед рекурсивными, разделитель `UNION` или `UNION ALL`; рекурсивные SELECT не могут использовать агрегатные и оконные функции. Реализация выполняет рекурсию через очередь строк. ([SQLite — WITH clause: Recursive Common Table Expressions](https://www.sqlite.org/lang_with.html))
- **Наименьшее замыкание отношений (layer: implementation, profile: postgresql, implementation: PostgreSQL, applies_to: WITH RECURSIVE)** — Рабочая таблица итерируется, пока приращение не станет пустым; при `UNION` (не `UNION ALL`) дубли отбрасываются на каждом шаге, что обеспечивает завершение на конечном замыкании. ([PostgreSQL — WITH Queries: Recursive Query Evaluation](https://www.postgresql.org/docs/current/queries-with.html))
