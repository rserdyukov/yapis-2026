# Каталог языков программирования на сайте курса

**Статус:** draft
**Дата:** 2026-09-18
**Задача:** запрос преподавателя в чате (трекера нет)
**Ветка:** новая от `github_pages` (название — см. открытые вопросы)
**Классификация:** architectural
**Скил:** task-kickoff @ SKILL.md 2026-09-17 (репо скиллов не под git)
**HTML-отчёт:** `$TMPDIR/kickoff-language-catalog.html` (производный, не коммитится)

Каталог `docs/_design/` добавляется в `exclude_docs` (`mkdocs.yml:77-80`): документ
не публикуется на сайте, не уезжает студентам (`admin/template-manifest.txt` —
allowlist) и не входит в переносимый набор `admin/` (`admin/PORTING.md:291`).

## 1. Задача

В репозитории курса ЯПИС-2026 добавить раздел сайта «Каталог языков
программирования». Для каждого языка — метаданные (появление, авторы, версии,
публикации, внешние идентификаторы Wikidata/PLDB/HOPL), значения концепций из
**общей** онтологии (один словарь на каталог, чтобы языки были сравнимы),
фрагменты грамматики в ANTLR4-нотации со ссылкой на источник, примеры программ.
Каталог генерируется из YAML и рендерится на GitHub Pages вместе с существующим
MkDocs-сайтом. Первая версия — Python, Java, Rust; далее — Kotlin, C#, Go,
Swift, TypeScript (семёрка лекции 20 плюс языки реализации студентов).

**Цель:** справочный контекст к вариантам заданий (`docs/labs/variants.md:12-39`)
и к дополнительному заданию лекции 20 (`docs/lectures/slides/20-kriterii-ocenki-yazykov-programmirovaniya.md:336-338`).
Не «опора ЛР1»: ни одна проверка ЛР1 (`.github/review/tasks/task1/prompt.md:11-20`)
от каталога не зависит.

**Метрика успеха** (пересмотрена в раунде 4):
- автопроверяемая — генератор печатает «покрыто K из M значений (P%)» по каждой
  категории; пороги в `ontology.yaml` (`coverage_threshold`): v1 — `variants` ≥ 80 %
  (после расширения 8 и 9 в онтологии 24 choice-значения; тройка покрывает 20/24 = 83 %
  при Java `variants.9 = class_members_only`; непокрыты `by_result` (Ada/C#), `by_ref`
  (C++/C#; Rust `&mut` — это `borrow_mut`, не двойной учёт), `if_only` (Lua/Bash),
  `program_start` (Pascal) — все с `pending.note`), `requirements` 100 % (7/7 choice-значений
  при Java `req.8.2 = no_globals` + note «static-поля», не `n/a`); покрытие считается
  только по `kind: choice`; непокрытое
  значение допустимо только с `coverage: {pending: true, note: "какой язык покроет"}`;
  без `note` `--check` падает;
- качественная — по матрице v1 преподаватель может показать ≥2 из 5 кейсов
  доп. задания лекции 20 на паре Python↔Rust: `errors.model` exceptions/result,
  `memory.management` gc/ownership, `typing.nullability` None/Option,
  `typing.checking` dynamic/static, `variants.5` implicit/explicit (не `variants.7` —
  у обоих перегрузки нет); доп. задание лекции 08 (`08:90`, UB в C++) — не цель
  v1/v2, C++ в плане нет; полная поддержка задания — после Kotlin, Go, C++
  (v2). **Конфликт целей зафиксирован:** Java выбрана по практике студентов
  (`reviewer/Dockerfile:6`), а не по лекции 20 (`20:337`) и лекции 08 (`08:90`),
  где Java нет.

**Не входит в v1:** интерактивный запуск примеров; автосинхронизация с
Wikidata/PLDB при сборке; версии как отдельные страницы; популярность
TIOBE/GitHut; генерация раздела `variants.md` из онтологии; русские названия
секций в сайдбаре (требует `nav` или плагина).

## 2. Контекст

### Сайт и сборка

- Инфраструктура сайта (`docs/`, `mkdocs.yml`, `tools/`, `.github/workflows/pages.yml`)
  существует **только в ветке `github_pages`** (3 коммита сверх `main`, fast-forward
  возможен; локальная = `origin/github_pages`). Деплой — только с `main`
  (`pages.yml:13,81`) → сайт ещё ни разу не деплоился; настройка Pages source =
  Actions из репо не проверяема.
- `mkdocs.yml`: нет `nav` — автонавигация по дереву `docs/`, имена секций из имён
  каталогов латиницей (`Labs`, `Lectures`, `Materials`); `strict: true` (`:13`);
  плагин только `search` (`:46-48`); `exclude_docs` — `_partials/`, `lectures/slides/`,
  `lectures/theme/` (`:77-80`) — конвенция «исходники сборки внутри `docs/` под
  `exclude_docs`» (`:73-76`). `exclude_docs` исключает **все** файлы, не только md
  (`mkdocs/structure/files.py:527-543`, пробная сборка).
- `validation.links.anchors` по умолчанию `info` (`mkdocs/config/defaults.py:194`)
  → `strict` **не ловит битые якоря**. Включение `warn` проверено на копии `docs/`:
  существующие страницы не ломает (единственные якоря — `variants.md:4,89-92`,
  все объявлены).
- MkDocs 1.6.1 поддерживает `hooks:` (`defaults.py:162`) и `File.generated` —
  вариант D возможен без зависимостей.
- Зависимости: `mkdocs==1.6.1`, `mkdocs-material==9.5.49` (`docs/requirements.txt:3-4`).
  PyYAML — прямая зависимость mkdocs (`pip show mkdocs`). Pygments 2.21.0
  содержит лексеры `python`, `java`, `rust`, `kotlin`, `antlr`, `ebnf`.
- Прецедент генерации: `tools/build-docs.py:152-155` реестр `TARGETS`, результат
  коммитится, `--check` в CI (`pages.yml:59-61`) и в тесте
  (`.github/review/tests/run-tests.sh:1427-1435`). `build-docs.py:25-26` привязан
  к `ROOT` — для негативных тестов генератору нужен параметр `--data <dir>`.
  Второй генератор `build-slides.py:63-84` — индекс коммитится, но
  перезаписывается в CI (`pages.yml:66-68`), тест только по количеству
  (`run-tests.sh:1467-1477`).
- `pages.yml:14-26` — триггер по путям; новый скрипт `tools/build-*.py` нужно
  добавлять в оба списка, иначе его правки не пересоберут сайт.
- `tests.yml:24-46` — `run-tests.sh` без mkdocs, с `pyyaml`; негативные тесты с
  rc≠0 есть (`run-tests.sh:1856-1867`, `:1227-1236`).
- Конвенции: русский язык везде, английские термины в скобках
  (`20-…md:313 (ownership, lifetimes)`); транслит в именах файлов; явные якоря
  `{ #id }`; `GENERATED_NOTICE` в сгенерированных файлах (`build-docs.py:28-31`);
  обоснования решений — в теле коммита (`c2b0400`) и docstring
  (`build-docs.py:2-19`), ADR как жанр в репо отсутствует.

### Материалы курса, задающие оси онтологии

- 9 свойств проектируемого языка: `docs/labs/variants.md:12-39`.
- 8 обязательных требований к языку: `docs/_partials/language-requirements.md:5-21`.
- ЛР1: три примера — предметная область (≥50 строк), **все синтаксические
  конструкции с комментариями**, маленький для отладки (`docs/_partials/labs-sequence.md:4-8`).
- ЛР2: грамматика в **ANTLR** (`labs-sequence.md:12`); лекция 05 показывает БНФ,
  EBNF, ANTLR как равноправные нотации (`05-…md:18-52`); `materials/index.md:24-25`
  рекомендует grammars-v4 как справочник по стилю.
- Лекция 20: критерии (читабельность, лёгкость создания, надёжность, стоимость —
  `:24-28`) — **оценки**, выводимые из характеристик (`:46,76,250`); характеристики
  (`:31-40`) — частично концепции (проверка типов, исключения, совмещение имён),
  частично оценки (простота, выразительность). Доп. задание `:336-338`: 7 языков.
- Лекция 02: парадигмы (`:38-46`), типизация статическая/динамическая, сильная/слабая
  (`:35-36`). Непоследовательность терминов: «сильная» vs «строгая» (`20:126/325`),
  «совмещение» vs «совпадение имён» (`20:277/283`), «Шаблоны» для generics (`03:161-202`).
- Языки реализации студентов 2025: Python 10, Java 7, C# 2, TypeScript 1
  (`reviewer/Dockerfile:6`). Code fences в лекциях: python 8, rust 3, java 2,
  kotlin 0.

### Внешние аналоги (WebFetch, статус указан)

| Ресурс | Статус | Лицензия | Что берём |
|---|---|---|---|
| PLDB (pldb.io) | fetched | public domain (`pages/about.html`) | словарь фич как источник идей; формат «значение + пример + примечание»; внешние id (hoplId, wikipedia, antlr) |
| Wikidata | fetched | CC0 | P287 designer, P571 inception, **P348 versions с датами** (Python 300 / Kotlin 58 / Rust 151), P7078 typing (multi-value: Python 3, Rust 5), P3966 paradigm; публикаций (P1343/P50) — 0; `labels.ru` — None |
| Grammar Zoo (SLEBoK) | fetched | CC-BY | модель provenance грамматики: источник, метод, формат, инструмент |
| grammars-v4 | fetched | Kotlin Apache-2.0 (839 строк), Rust MIT (1198), Python `python3_14` MIT (921); `python3_12` — 404 | фрагменты `.g4` с атрибуцией |
| Официальные грамматики | fetched | Python — PEG (PSF); Kotlin — **ANTLR4** (`kotlinlang.org/grammar`, Apache-2.0); Rust — своя PEG-подобная нотация (MIT/Apache) | ссылки; EBNF ни у кого |
| Rosetta Code | fetched | GFDL 1.3 | 7 фасетов типизации/исполнения; примеры по задачам — ссылки |
| Wikipedia comparison / by type system / by type | fetched | CC BY-SA 4.0 | 4 оси типизации; 5 значений memory management; ~35 подстатей конструкций |
| Progopedia | fetch-failed (сайт мёртв; Wayback) | неизвестна | модель `implementation → version`, примеры по версиям — только модель |
| HOPL | fetched | «Do not copy» | только ссылки по id |
| Learn X in Y | fetched | CC BY-SA 3.0 | ссылки |
| DBpedia | fetched | CC BY-SA | не используем (парадигмы строками) |
| ISO/IEC 2382, ACM CCS | fetch-failed (403) | — | из общих знаний, не подтверждено |

## 3. Use cases

Baseline снят с кода (47 сценариев); здесь — релевантные. Полный список UC-1…UC-47
в отчёте субагента use-cases не воспроизводится: остальные `unchanged`.

| ID | Актор | Предусловие | Действие | Результат сейчас | Где | Статус | Результат после |
|----|-------|-------------|----------|------------------|-----|--------|-----------------|
| UC-1 | GitHub Actions | `pages.yml` в `main`; push по `docs/**`, `mkdocs.yml`, `tools/build-docs.py`, `tools/build-slides.py` | push в `main` | build + deploy артефактом | `pages.yml:11-19,80-93` | changed | + путь `tools/build-catalog.py`; + шаг `build-catalog.py --check` перед `mkdocs build` |
| UC-2 | GitHub Actions | push в `main` вне paths | push | сайт не пересобирается | `pages.yml:14-19` | changed | множество «вне» сужается на `tools/build-catalog.py`; данные в `docs/languages/_data/` уже под `docs/**` |
| UC-4 | преподаватель | ветка `github_pages` | push | ничего | `pages.yml:13` | unchanged | — |
| UC-5 | GitHub Actions | PR по paths | PR | только build | `pages.yml:20-26,81` | changed | build включает `--check` каталога |
| UC-10 | GitHub Actions | генерированный md разошёлся с `_partials` | `build-docs.py --check` | rc=1, деплоя нет | `build-docs.py:171-188` | unchanged | — (каталог — отдельный скрипт) |
| UC-28 | CI / локально | битая ссылка на файл | `mkdocs build` | strict валит | `mkdocs.yml:13` | changed | + битый якорь `page.md#id` тоже валит (`validation.links.anchors: warn`) |
| UC-32 | студент | сайт задеплоен | открыть `/` | сайдбар: Labs, Lectures, Materials | `mkdocs.yml` (нет nav) | changed | + секция `Languages` между Labs и Lectures; карточка на главной |
| UC-36 | студент | — | поиск | индекс ru | `mkdocs.yml:46-48` | unchanged | новые страницы индексируются автоматически |
| UC-38 | студент | — | открыть `/requirements.txt` | файл отдаётся | `mkdocs.yml:77-80` | unchanged | `_data/` в `exclude_docs` → YAML/примеры **не** публикуются как статика |
| UC-43 | преподаватель | новый `docs/foo.md` | push | автоматически в nav | нет nav | unchanged | `docs/languages/*.md` — тот же механизм |
| UC-46 | GitHub Actions | `tests.yml` | push/PR | `run-tests.sh` без mkdocs | `tests.yml:24-46` | changed | + тесты каталога (pyyaml уже есть) |
| UC-47 | преподаватель | ручная правка генерированного md | push | тест падает, правка затирается | `run-tests.sh:1427` | changed | + то же для `docs/languages/*.md` |
| UC-new-1 | преподаватель | онтология есть | добавить `docs/languages/_data/languages/<lang>.yaml` + `examples/`, запустить `build-catalog.py`, закоммитить YAML + md | — | новый | new | страница `/languages/<lang>/`, строка в индексе, столбец в матрице; забыл сгенерировать → `--check` rc=1 |
| UC-new-2 | скрипт | YAML языка содержит значение вне перечисления / неизвестную концепцию / отсутствует обязательный `example` для `n/a`-исключений | `build-catalog.py` | — | новый | new | rc≠0, stderr: файл, концепция, значение, допустимые значения; CI красный |
| UC-new-3 | скрипт | файл примера / грамматики, указанный в YAML, не существует | `build-catalog.py` | — | новый | new | rc≠0 с внятным сообщением (не traceback) |
| UC-new-4 | скрипт | YAML языка удалён, `docs/languages/<lang>.md` остался | `--check` | — | новый | new | rc≠0: «лишний файл» (детекция сирот) |
| UC-new-5 | скрипт | ссылка карточки на `concepts.md#<id>` | генерация | — | новый | new | генератор ставит явные латинские `{ #id }` и ссылается только на существующие id; `mkdocs build` с `anchors: warn` подтверждает |
| UC-new-6 | преподаватель | значение перечисления без языка и без `coverage: pending` | `--check` | — | новый | new | rc≠0 + таблица непокрытых значений; с `pending` — только таблица, rc=0 |
| UC-new-7 | студент | сайт собран | открыть `/languages/concepts/` | — | новый | new | онтология (категория → концепция → значения с русским термином и `en`) + матрица «концепция × язык» с `since` и сноской `note` |
| UC-new-8 | студент | сайт собран | открыть `/languages/rust/` | — | новый | new | метаданные, версии (stable, с датами и `source`), таблица концепций (multi-value, `since`, примечания), фрагменты ANTLR с атрибуцией, пример-витрина с комментариями по 9 свойствам + 8 требованиям, раздел «Оценка по критериям лекции 20» (текст) |
| UC-new-9 | преподаватель | — | `python3 tools/import-versions.py rust` (вне CI) | — | новый | new | в YAML появляется/обновляется `versions:` из Wikidata P348 (stable, без патчей) с `source: {url, retrieved}`; конфликтов с ручными полями не создаёт |

## 4. Требования

### Функциональные
- F1. Онтология: `category → concept → values[]`; каждое значение — `{id, ru, en, aliases?, note?, showcase?: required}`; концепция имеет `kind: choice | bool` (`text` снят в круге 3: ни одна концепция лекций 02/20 не свободный текст) и опциональный `max_values: 1` там, где исключительность — утверждение о предметной области (`variants.5`, `variants.7`); `coverage_threshold` по категориям (→ UC-new-7). *Раунд 4: дихотомия `enum|multi` снята — enum выдерживали 2 из 9 свойств.*
- F2. Значение концепции у языка — **список** записей `{value, since?, until?, applies_to?, status?, note?, example?, sources?}`; `since/until` ссылаются на `id` записи `versions[]` любого `kind` (поле `edition` снято в круге 3 как дубликат — Rust 2018 это запись `versions[]` с `kind: edition`; рендер `since` через `label`); `example?` по умолчанию `{showcase, slug}`, указывается только для нестандартной секции; допустимо `n/a` с обязательным `note` (→ UC-new-2, UC-new-8). *Раунд 4: `applies_to` — Java `var` только локальные, параметры примитивов by-value / объектов by-sharing.*
- F3. 9 свойств `variants.md:12-39` присутствуют в онтологии с ключами `variants.N`; свойство 8 расширено значениями `by_sharing`, `move`, `borrow`, `borrow_mut`; свойство 9 — значением `class_members_only` (Java). Требования `language-requirements.md` — категория `requirements` **только различающими** концепциями: `req.4` io ∈ {builtin, stdlib, macro}; `req.7.2` → `while`, `until`, `do_while` (bool); `req.7.3` → {c_style, foreach}; `req.8.2` → {globals, no_globals}. Тривиально истинные (1, 3, 5, 6, 7.1, 8.1) не заводятся.
- F4. Критерии лекции 20 (`:24-28`) — раздел `assessment?` (опционален на уровне языка, чтобы этапы 4–6 проходили `--check`; отсутствие — warning, ошибка при `coverage_threshold.assessment: 1.0` на этапе 7) с **4 фиксированными ключами** `{readability, writability, reliability, cost}`, каждый `{text (непустой), concepts?: [id]}`; валидатор проверяет существование id; генератор строит таблицу «критерий × язык» на `concepts.md` (→ UC-new-8). *Раунд 4: свободный текст терял сравнимость.*
- F5. Карточка языка содержит: `meta` (name, ru, wikidata, pldb, hopl, appeared с `sources[]`, designers[], organizations[], website, spec), `versions[]` записей `{id, label, date (обязательна), kind: release | edition, role?: first | latest, release? (для edition — id релиза), sources[]}` — критерий вехи: id используется в `since/until` либо `role`; неиспользуемая без `role` — warning (`standard` снят до C#), `publications[]` (руками), `concepts`, `grammar` — `sources[] {id, repo, path, commit, license ∈ {MIT, Apache-2.0, BSD-3-Clause}}` на уровне языка (лицензионный notice — секция `[start:notice]` в `_data/grammar/<lang>/<File>.fragments.g4`, обязательна (валидатор), воспроизводится один раз на карточке fence `text`: BSD-3 п.1 требует retain notice при redistribution исходника, файлов LICENSE в каталогах grammars-v4 нет — 404); `fragments[] {rule, source, line}` — текст правила лежит секцией snippets в `.fragments.g4`, `url` строится генератором `blob/{commit}/{path}#L{line}`, `nonterminals` вычисляются regex; `spec_url`; пометка «community grammar, не нормативна», `examples[]` (обязательный `role: showcase`, опциональные `role: task/<id>`).
- F6. Генератор пишет `docs/languages/index.md` (таблица + grid cards), `concepts.md`, `<lang>.md`; все с `GENERATED_NOTICE`; **вычисляемое** (таблицы, матрица) инлайнится, **код** (showcase, фрагменты `.g4`) подключается через `pymdownx.snippets` `--8<-- "…"` с `base_path` += `docs/languages/_data` (работает из `exclude_docs`, `check_paths` ловит битые пути — пробная сборка); `--check` = **полная валидация F7 + сравнение byte-exact + сироты** (не только сравнение, как в `build-docs.py:168-175`: правка `_data/examples/*` не меняет md со `--8<--`, и невалидный маркер иначе дойдёт до деплоя) (→ UC-new-1, UC-new-4). Код вставляется **один раз на концепцию** (секция `slug`); `example` у значения — только override. Правило матрицы `concepts.md`: ячейка = значения `ru` через «; » с `(since)`; `applies_to`/`note`/`until`/`n/a` — не в ячейке, а ссылкой на `<lang>.md#<slug>`.
- F7. Генератор валидирует: неизвестная концепция/значение, нарушение `max_values`, `since/until/edition` на несуществующий `versions[].id`, `assessment.*.concepts` на несуществующий id, лицензия фрагмента вне списка, отсутствие `commit`, отсутствие файла примера/грамматики, отсутствие showcase, **полнота секций showcase** (каждая концепция с `showcase: required` и хотя бы одним значением ≠ `n/a` имеет секцию `--8<-- [start:<slug>]` в showcase языка; маркер, не совпадающий с `^[a-z][-_0-9a-z]*$` или с известным `slug`, — ошибка: snippets такой маркер не вырезает и публикует как код — пробная сборка), секция `rule` существует в `.fragments.g4`, покрытие по порогу **только для `kind: choice`** (`bool` не участвует: `until: false` у всех — факт о языках, не пробел онтологии) (→ UC-new-2, UC-new-3, UC-new-6).
- F8. Генератор принимает `--data <dir>` и `--out <dir>` для тестов (→ T-10…T-13).
- F9. ~~Импорт версий скриптом~~ — **отложен до 5+ языков** (раунд 4): Wikidata P348 неполна для вех (Java — только 8, 10, 11, 14–26; Python — нет 3.0–3.2), форматы разнородны, editions не хранит; прототип 33 строки > 21 строка данных руками; round-trip YAML требует `ruamel`. Wikidata — источник **дат** для ручных записей (`sources[]`).
- F10. Маркеры секций в showcase — синтаксис snippets в комментариях: `# --8<-- [start:variants-3]` … `[end:variants-3]`; имя секции `[a-z][-_0-9a-z]*` (точка запрещена regex `RE_SNIPPET_SECTION`) → у концепции поле `slug`. Отсутствующая конструкция (`until: false`, `no_globals`) — секция с эквивалентом + `note`; `n/a` — секция не требуется. Rust `// --8<--` и `/* --8<-- */` работают (`pre` = `.*?`). В `mkdocs.yml` — `snippets.dedent_subsections: true` (иначе секции из тела функции с отступом). Python `variants.5.2`: фрагменты `tokens {INDENT, DEDENT}` (лексер) + `block : NEWLINE INDENT statements DEDENT` (`PythonParser.g4:185-186`) с note о `PythonLexerBase`.

### Данные и совместимость
- `schema_version` в `ontology.yaml`; генератор отказывается работать с неизвестной версией.
- Идентификаторы концепций и значений — латиница `snake_case`, стабильны (переименование — через `aliases`).
- Каждое заимствованное значение/фрагмент имеет `sources[]` с лицензией.

### Интерфейсы
- Новый CLI `tools/build-catalog.py [--check] [--data DIR] [--out DIR]` — та же семантика, что `build-docs.py`.
- Схема YAML — контракт для авторов языков; документируется в `docs/languages/_data/README.md` и в README репо.

### Платформы и среда
- Python 3.12 (CI) и 3.14 (локально); только stdlib + PyYAML. PyYAML добавить явно в `docs/requirements.txt` с пином (сейчас транзитивно).

### Нефункциональные
- Генерация детерминирована (сортировка ключей, стабильный порядок) — иначе `--check` шумит.
- Сообщения об ошибках — на русском, с путём к YAML и ключом.

## 5. Варианты

### Вариант A — собственный генератор `tools/build-catalog.py` (выбран)

Данные в `docs/languages/_data/` (под `exclude_docs`), генератор валидирует по
онтологии и пишет `docs/languages/*.md`; md коммитятся, `--check` в `pages.yml`
и `run-tests.sh` по образцу `build-docs.py`.

| UC | Статус | Что меняется |
|----|--------|--------------|
| UC-1, UC-2, UC-5 | changed | путь и шаг в `pages.yml` |
| UC-28 | changed | `anchors: warn` |
| UC-32 | changed | секция `Languages`, карточка на главной |
| UC-46, UC-47 | changed | новые тесты, второй генератор под `--check` |
| UC-10, UC-36, UC-38, UC-43 | unchanged | — |
| UC-new-1…9 | new | см. §3 |

**Blast radius:** 5 существующих файлов (`pages.yml`, `run-tests.sh`, `docs/index.md`,
`README.md`, `TASKS.md`) + `mkdocs.yml` (`exclude_docs`, `validation`) +
`docs/requirements.txt` (pyyaml). Студенты видят новую секцию и страницы.
**Обратимость:** один аддитивный коммит; удаление `docs/languages/` + шаг + тест +
карточка; внешние ссылки на `/languages/` → 404.
**Плюсы:** валидация доступна и в `tests.yml` без mkdocs; 0 новых зависимостей;
видимый diff страниц в PR; отладка обычным скриптом. **Минусы / долг:** файлов
под `--check` 2 → 2+N+2; дублирование `variants.md:12-39` ↔ онтология (без
связи, кроме теста-grep по ключам). **Объём:** M.

### Вариант B — плагины `mkdocs-gen-files` (+ `mkdocs-macros`)

Виртуальные страницы при `mkdocs build`, ничего не коммитится.
Факты: gen-files 0.6.1 требует `properdocs>=1.6.5` (форк MkDocs, warning в stderr)
и `mkdocs<=1.6.1`; 0.6.0 без этого, но заморожен. macros — глобальный Jinja над
всеми страницами (сейчас `{{` вне `_partials` нет). Валидация только внутри
`mkdocs build`; в `tests.yml` нужен отдельный слой lib + обёртка. Запуск
gen-скрипта вне mkdocs пишет реальные md в `docs/`.
**Отвергнут:** зависимость от форка MkDocs и заморозка версии; непинованные
транзитивки против `requirements.txt:2`. **Объём:** M.

### Вариант C — рукописный Markdown

5 md по шаблону, онтология списками, матрица руками. Стоимость наращивания:
+1 язык = K+2 правок, +1 концепция = 2N+1 правок в N+1 файлах, O(N·K) без
автоматической страховки (strict не ловит ни якоря, ни несогласованность имён).
**Отвергнут:** цель «наращивать объём» несовместима. **Объём:** S инфра / M контент.

### Вариант D — `hooks:` в `mkdocs.yml` + `File.generated` (найден при опровержении)

0 зависимостей, 0 закоммиченных md, валидация внутри strict-сборки
(`defaults.py:162`; проверено в песочнице). Минусы: нет diff страниц в PR;
отладка внутри процесса mkdocs; `tests.yml` должен ставить `docs/requirements.txt`
(+7 с) или пропускать тест. **Резерв:** если коммиты сгенерированных md станут
раздражать — переход на D не меняет схему данных и генератор (меняется только
точка вызова).

## 6. Решение

Выбран **вариант A** с уточнениями раунда 3: multi-value модель значения с
`since`/`note`/`example`; критерии лекции 20 — отдельный текстовый раздел;
языки v1 — Python, Java, Rust; грамматика — фрагменты ANTLR4 из свободных
источников с атрибуцией; пример-витрина по формату примера 2 ЛР1; данные в
`docs/languages/_data/`; импорт только версий из Wikidata отдельным скриптом.

Отвергнуты: B — форк MkDocs в зависимостях, валидация недоступна вне сборки;
C — O(N·K) ручной синхронизации; D — оставлен резервом (теряется diff страниц в
PR, что важно для ревью контента); `hooks: on_serve` из D может быть взят точечно
для R10 без отказа от коммита md.

Схема данных после двух кругов опровержения — §13a (D22–D26): multi-value с
`applies_to`/`edition`, `kind: choice` + `max_values`, `assessment` 4 ключа,
`requirements` только различающие, версии-вехи руками с `kind`, код через
snippets, маркеры секций в showcase.

**ADR:** отдельный файл не пишется. Обоснование выбора (генератор vs плагин,
коммит md, списки значений) — в теле первого коммита (как `c2b0400`) и в этом
документе, который де-факто и есть ADR; docstring генератора — модель данных и
контракт CLI (как `build-docs.py:2-19`, где «почему» — только про токены).

## 7. Decision log

Все решения — `accepted-recommendation` (пользователь трижды ответил «делаем по
твоим рекомендациям»). Все прошли опровержение; REFUTED/WEAKENED пересмотрены в
раунде 3 (D14–D21), пересмотренные версии — со ссылкой на исходное.

| # | Вопрос | Источник | Варианты | Выбрано | Тип | Основание | Опровержение |
|---|--------|----------|----------|---------|-----|-----------|--------------|
| D1 | Пересказ; онтология общая на каталог | §1 | подтвердить / поправить | подтверждено; одна онтология | accepted-recommendation | PLDB, Wikidata (fetched) — общий словарь | HOLDS (неявно, через D5/D14) |
| D2 | Цель и метрика | §1 | a ЛР1 / b лекция 20 / c самостоятельная / d несколько | a+b | accepted-recommendation | `variants.md:12-39`; `20-…md:336-338` | **WEAKENED** → D20: ЛР1 не требует реальных языков (`task1/prompt.md:11-20`); метрика непокрываема 3 языками |
| D3 | Языки v1 | §1 | Python, Rust, Kotlin | — | accepted-recommendation | `20-…md:337` | **WEAKENED** → D15: `Dockerfile:6` Python 10/Java 7/C# 2/TS 1, Rust и Kotlin 0; Rust≈Kotlin по 6 из 9 свойств; CIL/WASM не покрыты |
| D4 | Источник данных | §3 | a руками / b импорт при сборке / c гибрид | c | accepted-recommendation | PLDB PD, Wikidata CC0 (fetched); `pages.yml` без сетевых шагов | **WEAKENED** → D21: PLDB — булевы, версий нет; Wikidata — публикаций 0, `labels.ru` None; импорт оправдан только для P348 |
| D5 | Устройство онтологии | §2 | a булевы PLDB / b иерархия + закрытые enum single-value / c Wikidata | b | accepted-recommendation | `variants.md:33-36` — три варианта | **REFUTED** → D14: #8 не применимо ни к одному из трёх языков; #1,#2 «оба»; #3,#6 зависят от версии; P7078 Python — 3 значения; критерии лекции 20 — оценки, не свойства (`20:46,76,250`) |
| D6 | Грамматика | §2 | a ссылки / b полная .g4 / c ссылки + EBNF-фрагмент | c | accepted-recommendation | размер грамматик; лицензии | **WEAKENED** → D16: официальные грамматики — PEG/ANTLR/своя, EBNF ни у кого (fetched); ЛР2 — ANTLR (`labs-sequence.md:12`); `python3_12` — 404 |
| D7 | Границы v1 (в т.ч. версии — только список) | §1 | — | исключения приняты | accepted-recommendation | — | ветка: HOLDS (локальная = origin); «версии списком»: **REFUTED** → D14: Python 3.10 match, Rust 1.39 async, Kotlin 2.2 context parameters (fetched) |
| D8 | Формат примеров | §2 | a канонические задачи / b свободные | a | accepted-recommendation | Rosetta/Progopedia | **WEAKENED** → D17: ЛР1 требует пример «все конструкции с комментариями» (`labs-sequence.md:4-8`), канонические задачи не совпадают ни с одним из трёх |
| D9 | Язык контента | §6 | русский + `en` / английский | русский, id латиницей, поле `en` | accepted-recommendation | `mkdocs.yml:17`; 0 английской прозы в `docs/` | HOLDS; риск R8 терминология (`20:126/325`, `20:277/283`) |
| D10 | Расположение данных | §3 | a `catalog/` в корне / b `docs/languages/_data/` + `exclude_docs` | a | accepted-recommendation | «данные уедут в site/» | **REFUTED** (обоснование) → D19: `exclude_docs` исключает все файлы (`files.py:527-543`, пробная сборка); конвенция `_partials/` |
| D11 | Критерии готовности | §8 | список из 6 | принят | accepted-recommendation | `run-tests.sh:1427`; `defaults.py:194` | WEAKENED → §13: «на сайте» → «локально и в PR-check»; негативный тест требует `--data` (`build-docs.py:25-26` привязан к ROOT); `anchors: warn` HOLDS |
| D12 | ADR | §7 | писать / нет | писать `admin/adr/0001` | accepted-recommendation | три критерия | **WEAKENED** → D19: конвенция репо — коммит + docstring (`c2b0400`, `build-docs.py:2-19`); `admin/adr/` не существует |
| D13 | Путь kickoff-документа | §7 | a `docs/design/` + exclude / b `admin/design/` | b | accepted-recommendation | `README.md:29-40` | **WEAKENED** → D19: `PORTING.md:291` переносит `admin/` целиком коллегам |
| D14 | Модель значения (замена D5, D7) | refuter | multi-value список `{value, since, until, status, note, example, sources}`, `n/a`; критерии лекции 20 — вне онтологии | принять | accepted-recommendation | PLDB формат «значение + пример + примечание» (fetched `kotlin.scroll`, `rust.scroll`); Wikidata P7078 multi-value; `20:46,76,250` | **WEAKENED** (круг 2) → D22: Java `var` только локальные, параметры by-value/by-sharing по типу → `applies_to`; Rust `async` по edition 2018 → `edition`; `enum` выдерживают 2 из 9 → `kind: choice` + `max_values`; `assessment` свободным текстом теряет сравнимость → 4 ключа × `{text, concepts}`; `until` HOLDS (Python `async` until 3.7, Java `_` until 9, JEP 213 fetched) |
| D15 | Языки v1 (замена D3) | refuter | a Python, Java, C# / b Python, Rust, Kotlin / c Python, Java, Rust | c | accepted-recommendation | `Dockerfile:6`; контраст Rust по #7, #8, исключениям, памяти | **WEAKENED** (круг 2): Java vs Python — 6 из 9 различий (HOLDS); покрытие 19 значений: {Py,Java,Rust} 17 = {Py,Rust,Kotlin} 17 > Go-тройки 16 (HOLDS); но Java нет ни в `20:337`, ни в `08:90` (второе доп. задание — 6 языков) → метрика переписана (D20); аргумент «CIL/WASM не покрыты» из опровержения D3 нерелевантен (платформа назначается независимо, `variants.md:94-125`) — снят; состав **сохранён** |
| D16 | Грамматика (замена D6) | refuter | фрагменты ANTLR4 из свободных грамматик с атрибуцией + ссылки на спецификацию и Grammar Zoo | принять | accepted-recommendation | `kotlinlang.org/grammar` ANTLR4 Apache-2.0; grammars-v4 Rust/Python MIT (fetched); `labs-sequence.md:12` | **WEAKENED** (круг 2) → D23: `java/java20` без лицензии (404 LICENSE) → использовать `java/java` BSD-3-Clause (fetched, 828 строк); транзитивное замыкание `localVariableDeclaration` = 120 из 129 правил → формат «правило + список нетерминалов + ссылка на строку по commit»; Python `variants.5.2` (отступы) в `.g4` не выражено — в `PythonLexerBase`; официальной ANTLR-грамматики нет ни у одного языка v1 → риск R9 |
| D17 | Примеры (замена D8) | refuter | showcase-пример по формату примера 2 ЛР1 + опциональные задачи | принять | accepted-recommendation | `labs-sequence.md:4-8`; `language-requirements.md:5-21` | **REFUTED** (связь строк с концепциями не определена) → D24: маркеры `--8<-- [start:slug]` в комментариях (snippets поддерживает секции в комментариях, `RE_SNIPPET_SECTION` запрещает точку); `showcase: required` у концепции; валидатор полноты; `until` отсутствует у всех — секция с эквивалентом |
| D18 | Генерация (пересмотр D-A) | refuter | a свой генератор, md коммитятся / b hooks (вариант D) | a, с обоснованием «diff в PR, отладка скриптом, tests.yml без mkdocs по желанию» | accepted-recommendation | `defaults.py:162` hooks существует; `build-docs.py:152-188` | WEAKENED (исходное) → переформулировано; D — резерв; **дополнено** (круг 2): `mkdocs serve` следит за `docs_dir` целиком (`serve.py:89`, `livereload:150-161`) → правка `_data/*.yaml` пересобирает сайт без перегенерации — ловушка уже есть у `_partials/`; митигация R10 |
| D19 | Расположение (замена D10, D12, D13) | refuter | данные `docs/languages/_data/`; ADR → docstring + коммит; kickoff → `docs/_design/` в `exclude_docs` | принять | accepted-recommendation | `mkdocs.yml:73-80`; `c2b0400`; `PORTING.md:291` | **WEAKENED** (круг 2): `_design/` HOLDS (0 md-ссылок, rc=0 с exclude; без exclude публикуется → `exclude_docs` в этап 0); snippets читает из `exclude_docs` (пробная сборка) → F6 код через `--8<--`; docstring `build-docs.py:2-19` — «что» + одно «почему», альтернативы — только в коммите → формулировка исправлена: «почему/альтернативы — тело коммита + этот документ; docstring — модель данных и CLI» |
| D20 | Цель и метрика (замена D2) | refuter | справочный контекст; метрика: покрытие значений (авто) + качественный чеклист | принять | accepted-recommendation | `task1/prompt.md:11-20`; `variants.md:33-39` | **REFUTED** (метрика «≥1 или pending» тривиальна) → D25: процент с порогом в `ontology.yaml`; `pending` требует `note`; 19/21 достижимо тройкой; качественная — ≥2 из 5 кейсов на Python↔Rust |
| D21 | Импорт (замена D4) | refuter | только версии из Wikidata P348 отдельным скриптом; остальное руками с `sources[]` | принять | accepted-recommendation | P348: 300/58/151 (fetched); P1343/P50 = 0; PLDB `semanticScholar` шум | **WEAKENED** → D26: Java P348 = 19 (нет 1.0–7, 9, 12, 13), Python без 3.0–3.2 (fetched Q251, Q28865); прототип 33 строки > 21 строка данных; round-trip YAML требует `ruamel`; editions Wikidata не хранит → скрипт отложен, `versions[].kind: release | edition | standard` |
| D22 | Схема значения v2 (замена D14) | refuter круг 2 | `+ applies_to`, `+ edition`, `example: {file, section}`; `kind: choice` + `max_values`; `assessment` 4 ключа × `{text, concepts}`; `requirements` только различающие | принять | accepted-recommendation | JLS 8.4.1, JEP 286, JEP 441, edition-guide (fetched); `20:308-334` | **WEAKENED** (круг 3): `edition` дублирует `versions[].kind` — снят; `text` не нужен ни одной концепции — снят; `assessment` обязательный сломает этапы 4–6 — опционален; матрица с `applies_to` нечитаема — правило рендера; `max_values` HOLDS → D27 |
| D23 | Грамматика v2 (замена D16) | refuter круг 2 | `java/java` BSD-3; `license` из списка; `commit` обязателен; формат «правило + нетерминалы + ссылка»; пометка «не нормативна» | принять | accepted-recommendation | `JavaParser.g4:1-6` BSD (fetched 200); замыкание 120/129 | **WEAKENED** (круг 3): BSD-3 п.1 требует retain notice при redistribution исходника — ссылки мало; notice на уровне источника, не фрагмента; `url` вычисляем из `{repo, path, commit, line}`; `nonterminals` — regex, не руками; Python `INDENT/DEDENT` объявлены в `.g4` (`PythonLexer.g4 tokens{}`, `PythonParser.g4:185`) — фрагмент есть → D27 |
| D24 | Showcase v2 (замена D17) | refuter круг 2 | маркеры snippets в комментариях; `slug` у концепции; `showcase: required`; валидатор полноты | принять | accepted-recommendation | `pymdownx/snippets.py:69 RE_SNIPPET_SECTION`; `mkdocs.yml:63-66` | **HOLDS** (круг 3, пробная сборка rc=0): маркеры вырезаются, секции по имени и вложенные работают, подсветка есть, `//` и `/* */` работают; уточнения: невалидный маркер (`variants.9` с точкой) публикуется как код → валидатор; `dedent_subsections: true`; полнота при `n/a` не требуется → D27 |
| D25 | Метрика v2 (замена D20) | refuter круг 2 | процент + `coverage_threshold`; `pending` с `note`; качественная ≥2/5 на Py↔Rust | принять | accepted-recommendation | таблица 19 значений × 5 языков | **WEAKENED** (круг 3): `requirements: 1.0` недостижим, если `bool` участвует (`until` нет ни у одного языка плана) и если Java `req.8.2 = n/a` → покрытие только по `choice`, Java `no_globals`; 5 кейсов Py↔Rust — 4–5 реальных, `variants.7` снят (оба без перегрузки); лекция 08 — не цель → D27 |
| D26 | Версии руками (замена D21) | refuter круг 2 | `versions[]` вехи руками с `sources[]`, `kind`; скрипт → out of scope | принять | accepted-recommendation | Q251 P348 = 19 (fetched) | **WEAKENED** (круг 3): «вехи руками» без критерия произвольны → критерий «используется в since/until или role first/latest»; `kind: standard` не используется в v1 — снят; `date` обязательна (все планируемые записи её имеют) → D27 |
| D27 | Схема v3 (шлифовка D22–D26 по кругу 3) | refuter круг 3 | см. F1–F10, §13a | принять | accepted-recommendation | `snippets.py:69-77`, `:98,157`; `PythonParser.g4:185-186`; opensource.org BSD-3 п.1 (fetched) | **WEAKENED** (круг 4, числа и формулировки): порог `variants 0.9` ложный при 24 значениях → 0.8 (20/24); §13a Java `variants.9 n/a` противоречил F3 → `class_members_only`; «код один раз на концепцию» не было сказано явно; `--check` должен включать валидацию, иначе испорченный маркер пройдёт CI; план этапа 4 (версии 2.0/3.0/3.6/3.12) противоречил критерию вехи → `1.0/3.10/3.14`; notice — секция `[start:notice]` (пробная сборка rc=0, подсветка `antlr` без `.err`-стилей в Material — ANTLR4 `<assoc>`/`tokens{,}` просто без цвета). Архитектура и данные не меняются |

## 8. Assumption ledger

| # | Допущение | Откуда | Статус | Как проверить |
|---|-----------|--------|--------|---------------|
| A1 | Pages source в настройках репо = GitHub Actions; деплой с `main` заработает после мержа `github_pages` | разведка: из репо не видно | open | `gh api repos/rserdyukov/yapis-2026/pages` перед мержем |
| A2 | Лицензия Java-грамматики grammars-v4 | refuter D6 | confirmed | `java/java/JavaParser.g4:1-6` BSD-3-Clause (fetched); `java/java20` — без лицензии, не использовать; файлов LICENSE в каталогах нет (404) |
| A3 | ISO/IEC 2382 и ACM CCS содержат таксономию фич ЯП | WebFetch 403 | open | не блокирует; при желании — ручной доступ |
| A4 | Progopedia: модель «реализация → версия → примеры» | Wayback, лицензия неизвестна | confirmed (модель), контент не используется | — |
| A5 | Названия секций сайдбара латиницей приемлемы (как `Labs`, `Lectures`) | разведка | open | пользователь; иначе — `nav` в `mkdocs.yml` (отдельная задача) |
| A6 | D27 прошёл круг 4 — только числа/формулировки, исправлены в документе; дальнейшее опровержение — наполнением | процесс | open | `schema_version: 1`; `max_values` для `variants.5` реально проверится только на 4-м языке (Kotlin expression-body) |
| A7 | `origin/*` актуален (fetch в сессии не выполнялся) | refuter D7 | open | `git fetch` перед созданием ветки |
| A8 | ~~Java заполняется чище Kotlin~~ | D15 | refuted | круг 2: Java требует `applies_to` (variants.1, 2, 8) и `n/a` (variants.9, req.8.2) — не чище; состав языков сохранён по контрасту Java↔Python 6/9 |
| A9 | Лицензии grammars-v4 по-файлово; репо-уровневого LICENSE нет (`House_Rules.md:31`) | refuter D16 | confirmed | список допустимых {MIT, Apache-2.0, BSD-3-Clause} в валидаторе |

## 9. Риски

| # | Риск | UC | P | I | Сигнал | Митигация | Владелец |
|---|------|----|---|---|--------|-----------|----------|
| R1 | Схема онтологии «утекает» при 4–5-м языке → миграция всех YAML | UC-new-1 | M | H | Новое поле нужно в ≥2 языках подряд | `schema_version`; multi-value + `note` уже в схеме; генератор с миграцией по версии; A6 — опровержение схемы до наполнения | преподаватель |
| R2 | Битые якоря `concepts.md#id` проходят CI | UC-new-5 | H | M | 404 на сайте | `validation.links.anchors: warn`; генератор ссылается только на существующие id (T-14) | генератор |
| R3 | `variants.md:12-39` ↔ онтология расходятся формулировками | — | M | M | ревью | тест-grep: ключи `variants.1…9` есть в онтологии и их `ru` совпадает с первой строкой пункта (T-16) | преподаватель |
| R4 | Лицензии заимствованного: фрагменты `.g4`, примеры | UC-new-8 | L | H | претензия | `sources[]` с лицензией обязателен для `grammar.fragments` (валидатор, T-12); примеры — авторские | преподаватель |
| R5 | md-сирота после удаления языка | UC-new-4 | M | L | лишняя страница | детекция сирот в `--check` (T-11) | генератор |
| R6 | Сайт ни разу не деплоился; Pages source не проверен | UC-1 | M | H | первый push в main → deploy падает | A1 до мержа; каталог мержится вместе с сайтом | преподаватель |
| R7 | Терминология онтологии расходится с лекциями («сильная»/«строгая») → поиск и студенты путаются | UC-new-7 | H | L | ревью | `aliases` у значений; выбрать термины из лекций где есть (`02:35-36`, `03:161-202`), новые (ownership, null-safety) — с `en` | преподаватель |
| R8 | Rust требует значений вне перечислений (`move`, `borrow`) → расширение перечислений на старте | UC-new-2 | M | M | таблица непокрытых значений после первого прогона | сначала онтология + Python, затем Rust, затем Java; расширять перечисления до наполнения третьего языка | преподаватель |
| R9 | Корректность фрагментов `.g4` — ответственность community grammars-v4, не спецификации: `java/java` README «не соответствует JLS точно», Python 3.14.2 vs 3.14.6, Rust — производная от reference неизвестной версии; лексические свойства (отступы Python) — в base-классах вне `.g4` | UC-new-8 | M | M | ревью фрагмента против спецификации | `source.commit` обязателен; рядом `spec_url` на раздел спецификации в её нотации; пометка «community grammar, не нормативна»; для отступов Python — текст + ссылка на `PythonLexerBase` | преподаватель |
| R10 | `mkdocs serve` пересобирает сайт при правке `_data/*.yaml` без перегенерации → автор видит старые страницы (`serve.py:89`, `livereload:150-161`); та же ловушка уже у `_partials/` | UC-new-1 | H | L | «правка не сработала» при наполнении | README: «при `mkdocs serve` запускать `build-catalog.py --watch`» (или `hooks: on_serve` — точка входа варианта D без отказа от коммита md); решить на этапе 3 | исполнитель |

## 10. План внедрения

| Этап | Результат (проверяемый) | Зависимости | Rollout |
|------|-------------------------|-------------|---------|
| 0 | `git fetch`; A1 проверена; ветка от `github_pages`; **первым коммитом** — `exclude_docs: _design/` + этот документ (иначе промежуточный `mkdocs build` публикует его) | A7 | — |
| 1 | `docs/languages/_data/ontology.yaml` (`schema_version: 1`, `coverage_threshold`): категории `variants` (9, с `slug`, `max_values` для 5 и 7, `showcase: required`), `requirements` (только различающие, F3), `typing` (incl. `nullability`), `memory`, `paradigm`, `errors`, `subprograms`, `syntax`; каждое значение с `ru`/`en`/`aliases`; `_data/README.md` со схемой и scope showcase («17 пунктов, не все конструкции языка») | — | — |
| 2 | `tools/build-catalog.py`: docstring — модель данных и CLI; загрузка, валидация (F7 включая полноту секций showcase и ссылки `since→versions.id`), генерация 3 шаблонов с `--8<--` для кода, `--check`, сироты, `--data/--out`, процент покрытия; решение по `--watch` / `hooks: on_serve` (R10) | этап 1 | — |
| 3 | `mkdocs.yml`: `exclude_docs` + `languages/_data/`; `validation: links: anchors: warn`; `snippets.base_path` += `docs/languages/_data`, `dedent_subsections: true`; `docs/requirements.txt` + `pyyaml` пин; `pages.yml` paths + шаг; `run-tests.sh` тесты T-10…T-16, T-21…T-24; `docs/index.md` карточка; `README.md` (+ R10), `TASKS.md` | этап 2 | PR-check `pages` зелёный |
| 4 | Python: `python.yaml` (`versions[]` по критерию: `1.0` role first, `3.10` — since `variants.6`, `3.14` role latest, плюс те, на которые сослался `since` при заполнении `typing`; даты из Wikidata как `sources`), `examples/showcase.py` с маркерами секций, `grammar/python/*.fragments.g4` с notice (grammars-v4 `python3_14`, MIT, commit; лексер + парсер) + `spec_url` PEG | этап 2 | `mkdocs build` локально; первый прогон покрытия |
| 5 | Rust: то же (grammars-v4 MIT); `versions[]` с `kind: edition` 2015/2018/2021/2024; расширение перечислений по таблице непокрытых | этап 4 | — |
| 6 | Java: то же (`java/java` BSD-3-Clause); `applies_to` для variants.1, 2, 8; `n/a` для variants.9; `req.8.2 = no_globals` + note; первая полная матрица | этап 5 | — |
| 7 | `assessment` по критериям лекции 20 для трёх языков; ревью терминологии (R7) | этап 6 | — |
| 8 | PR `catalog` → `github_pages`; затем `github_pages` → `main` (A1) | этапы 3–7 | deploy с `main` |

Параллелить: этап 1 и каркас этапа 2; наполнение 4–6 с этапом 3.

## 11. Тестовые сценарии

| ID | UC | Предусловие | Действие | Ожидаемый результат | Как проверяем | Статус |
|----|----|-------------|----------|---------------------|---------------|--------|
| T-1 | UC-1 | `pages.yml` с новым путём и шагом | push в `main` только `tools/build-catalog.py` | workflow `pages` запускается | ручной, GitHub Actions (после мержа) | todo |
| T-2 | UC-2 | — | push в `main` только `README.md` | `pages` не запускается | ручной | todo |
| T-3 | UC-5 | PR с изменением `docs/languages/_data/python.yaml` без пересборки md | PR | job `build` падает на шаге `build-catalog.py --check`, deploy не выполняется | ручной, PR-check | todo |
| T-4 | UC-28 | `anchors: warn`; ссылка `concepts.md#net-takogo` в тестовой странице | `mkdocs build` | rc≠0, «Aborted with N warnings in strict mode» | локально | todo |
| T-5 | UC-28 (регресс) | `anchors: warn`; текущие страницы без изменений | `mkdocs build` | rc=0, 0 warnings | локально / PR-check | todo |
| T-6 | UC-32 | сайт собран | открыть `site/index.html` | секция `Languages` между `Labs` и `Lectures`; карточка «Каталог языков» в grid | ручной, браузер | todo |
| T-7 | UC-36 (регресс) | сайт собран | поиск «ownership» / «владение» | найдена страница Rust | ручной | todo |
| T-8 | UC-38 | сайт собран | `ls site/languages/` | нет `_data/`, нет `*.yaml`, нет `examples/` | локально | todo |
| T-9 | UC-47 | ручная правка `docs/languages/python.md` | `run-tests.sh` | `test_generated_catalog_is_up_to_date` падает | `run-tests.sh` | todo |
| T-10 | UC-new-1 | валидные YAML трёх языков | `build-catalog.py` затем `--check` | 5 файлов записаны с `GENERATED_NOTICE`; `--check` rc=0 | `run-tests.sh` через `--data` во временный каталог | todo |
| T-11 | UC-new-4 | `--out` содержит `haskell.md` без `haskell.yaml` | `--check` | rc≠0, stderr содержит `haskell.md` и слово «лишний» | `run-tests.sh` | todo |
| T-12 | UC-new-2 | временный YAML: `variants.5: [ {value: fuzzy} ]` | `build-catalog.py --data TMP` | rc≠0, stderr: файл, `variants.5`, `fuzzy`, список допустимых | `run-tests.sh` | todo |
| T-12b | UC-new-2 | концепция с `max_values: 1` и двумя значениями | `build-catalog.py` | rc≠0, сообщение «допускает одно значение» | `run-tests.sh` | todo |
| T-12c | UC-new-2 | `grammar.fragments[0]` с `license: GPL-3.0` или без `commit` | `build-catalog.py` | rc≠0, сообщение со списком допустимых лицензий / «commit обязателен» | `run-tests.sh` | todo |
| T-13 | UC-new-3 | YAML ссылается на `examples/missing.py` | `build-catalog.py` | rc≠0, сообщение с путём файла, без traceback | `run-tests.sh` | todo |
| T-14 | UC-new-5 | сгенерированный `rust.md` | `mkdocs build` с `anchors: warn` | rc=0; все `concepts.md#…` резолвятся | локально / PR-check | todo |
| T-15 | UC-new-6 | `coverage_threshold.variants: 0.9`; тройка покрывает 20/24 = 83 %, непокрытые без `pending.note` | `--check` | rc≠0; stdout «variants: 20/24 (83 %) < 90 %» + список непокрытых | `run-tests.sh` | todo |
| T-15b | UC-new-6 | то же, непокрытые с `pending: {note: "Ada"}`; порог 0.8 | `--check` | rc=0; процент и таблица в stdout | `run-tests.sh` | todo |
| T-16 | R3 | онтология | grep ключей `variants.1…9`, `req.4`, `req.7.2`, `req.7.3`, `req.8.2` | все присутствуют | `run-tests.sh` | todo |
| T-17 | UC-new-8 | сайт собран | открыть `/languages/rust/` | разделы: метаданные; версии с датами, `sources` и edition 2018; концепции с `since` (`async` → `1.39`) и `edition`; фрагменты ANTLR с лицензией MIT, commit и пометкой «не нормативна»; showcase (через snippets) с секциями; `assessment` 4 критерия со ссылками на концепции | ручной | todo |
| T-18 | UC-new-9 | — | — | сценарий снят: импорт отложен (D26) | — | blocked |
| T-19 | UC-10 (регресс) | партиалы без изменений | `build-docs.py --check` | rc=0 — второй генератор не влияет | `run-tests.sh` | todo |
| T-20 | UC-new-7 | сайт собран | открыть `/languages/concepts/` | матрица 3 столбца; ячейка Python × `variants.6` содержит `match` со `since 3.10`; таблица «критерий × язык» | ручной | todo |
| T-21 | UC-new-2 | showcase Python без секции `variants-3` при `showcase: required` | `build-catalog.py` | rc≠0, «showcase python: нет секции variants-3» | `run-tests.sh` | todo |
| T-21b | UC-new-2 | md сгенерирован; затем в `_data/examples/showcase.py` маркер испорчен на `[start:variants.3]` без перегенерации | `--check` | rc≠0 (валидация входит в `--check`, хотя md не изменился) | `run-tests.sh` | todo |
| T-22 | UC-new-2 | значение с `since: "9.9"`, которого нет в `versions[]` | `build-catalog.py` | rc≠0, «since 9.9 не найден в versions» | `run-tests.sh` | todo |
| T-23 | UC-new-2 | `assessment.reliability.concepts: [net-takoy]` | `build-catalog.py` | rc≠0 | `run-tests.sh` | todo |
| T-24 | UC-new-8 | сгенерированный md с `--8<-- "examples/showcase.py"`; файл удалён | `mkdocs build` | rc≠0 (`check_paths: true`) | локально | todo |
| T-25 | UC-46 | `tests.yml` без mkdocs | `run-tests.sh` | тесты T-9…T-16, T-21…T-23 проходят с одним PyYAML | GitHub Actions | todo |

## 12. Зависимости

| От кого | Что | Статус | Срок |
|---------|-----|--------|------|
| преподаватель | A1: Pages source = Actions | не проверено | до этапа 8 |
| grammars-v4 (внешний) | лицензия Java-грамматики (A2) | не проверено | до этапа 6 |
| Wikidata (внешний) | доступность API для `import-versions.py` | вне CI, не блокирует | этап 4 |

## 13. Критерии готовности

- [ ] `python3 tools/build-catalog.py --check` rc=0 на ветке; тест `test_generated_catalog_is_up_to_date` в `run-tests.sh` (→ T-9, T-10, T-19)
- [ ] `mkdocs build` (strict, `anchors: warn`) локально и в PR-check `pages` даёт `site/languages/{index,concepts,python,java,rust}/index.html`; на сайте — после мержа в `main` (→ T-4, T-5, T-14)
- [ ] Онтология содержит `variants.1…9` и `requirements.1…8`; для трёх языков значения заполнены или `n/a` с `note` (→ T-16, T-20)
- [ ] Негативные тесты: значение вне перечисления, `max_values`, лицензия вне списка / без commit, отсутствующий файл, сирота, нет секции showcase, `since` на несуществующую версию, `assessment` на несуществующую концепцию — все rc≠0 (→ T-11…T-13, T-21…T-23)
- [ ] Процент покрытия печатается; `variants` ≥ 90 %, `requirements` 100 %; непокрытые без `pending.note` валят `--check` (→ T-15, T-15b)
- [ ] `_data/` не публикуется в `site/`; код подключён через snippets, битый путь валит сборку (→ T-8, T-24)
- [ ] README: раздел «Каталог языков» с командой добавления языка и предупреждением про `mkdocs serve` (R10); `_data/README.md` со схемой и scope showcase
- [ ] Docstring `build-catalog.py` — модель данных и CLI; обоснование выбора (генератор vs плагин, коммит md, списки значений) — в теле первого коммита и в этом документе

## 13a. Схема данных (эскиз после трёх кругов опровержения)

```yaml
# ontology.yaml
schema_version: 1
coverage_threshold: {variants: 0.8, requirements: 1.0}   # считается только по kind: choice; 20/24 тройкой
categories:
  - id: variants
    ru: Свойства проектируемого языка
    concepts:
      - id: variants.8
        slug: variants-8
        ru: Передача параметров в подпрограмму
        en: Parameter passing
        kind: choice            # choice | bool
        showcase: required
        values:
          - {id: by_value,   ru: По значению,              en: by value}
          - {id: by_result,  ru: По результату,            en: by result,  coverage: {pending: true, note: "Ada out, C# out"}}
          - {id: by_ref,     ru: По ссылке,                en: by reference}
          - {id: by_sharing, ru: По ссылке на объект,      en: call by sharing}
          - {id: move,       ru: Перемещение,              en: move}
          - {id: borrow,     ru: Заимствование,            en: shared borrow}
          - {id: borrow_mut, ru: Изменяемое заимствование, en: mutable borrow}
      - id: variants.5
        slug: variants-5
        kind: choice
        max_values: 1
      - id: req.7.2.until
        slug: req-7-2-until
        kind: bool               # не участвует в покрытии
        showcase: required       # при false — секция с эквивалентом

# languages/java.yaml
id: java
meta: {name: Java, ru: Java, wikidata: Q251, pldb: java, hopl: 2131,
       appeared: {value: 1995, sources: [{url: "https://www.wikidata.org/wiki/Q251", retrieved: 2026-09-18}]},
       designers: [James Gosling], organizations: [Sun Microsystems, Oracle], website: ..., spec: ...}
versions:                        # критерий вехи: используется в since/until или role
  - {id: "1.0", label: Java 1.0,   date: 1996-01-23, kind: release, role: first, sources: [...]}
  - {id: "10",  label: Java SE 10, date: 2018-03-20, kind: release, sources: [...]}
  - {id: "21",  label: Java SE 21, date: 2023-09-19, kind: release, role: latest, sources: [...]}
# Rust: - {id: "2018", label: Rust 2018, date: 2018-12-06, kind: edition, release: "1.31", sources: [...]}
concepts:
  variants.1:
    - {value: explicit}
    - {value: implicit, since: "10", applies_to: локальные переменные, note: "var, JEP 286"}
  variants.8:
    - {value: by_value,   applies_to: примитивные типы}
    - {value: by_sharing, applies_to: ссылочные типы, note: "JLS 8.4.1 формально by value", sources: [...]}
  variants.9:
    - {value: class_members_only, note: "методы только как члены класса; обход — лямбды/локальные классы"}
  req.8.2:
    - {value: no_globals, note: "static-поля класса как эквивалент"}                           # секция обязательна
  req.7.2.until:
    - {value: false, note: "эквивалент — do { } while (!c)"}                                    # секция обязательна
grammar:
  spec_url: https://docs.oracle.com/javase/specs/jls/se21/html/jls-19.html
  sources:                       # notice — заголовок файла _data/grammar/java/JavaParser.fragments.g4
    - {id: parser, repo: antlr/grammars-v4, path: java/java/JavaParser.g4, commit: "<sha>", license: BSD-3-Clause}
  fragments:                     # текст — секция snippets в .fragments.g4; url и nonterminals вычисляются
    - {rule: localVariableDeclaration, source: parser, line: 478}
examples:
  - {role: showcase, file: examples/Showcase.java}   # секции // --8<-- [start:variants-1] ... [end:variants-1]
assessment:                      # опционален до этапа 7; при наличии — 4 ключа с непустым text
  readability:  {text: "...", concepts: [variants.5, syntax.verbosity]}
  writability:  {text: "...", concepts: [variants.1]}
  reliability:  {text: "...", concepts: [typing.checking, errors.model]}
  cost:         {text: "...", concepts: []}
```

## 14. Открытые вопросы

| Вопрос | Кто отвечает | К какому этапу |
|--------|--------------|----------------|
| Название ветки (`catalog` / `languages`) | преподаватель | этап 0 |
| Принять латиницу `Languages` в сайдбаре или добавлять `nav` (A5) | преподаватель | этап 3 |
| Запускать ли второй круг опровержения на D14 (схема) и D15 (языки) до наполнения (A6) | преподаватель | этап 1 |
| Лицензия Java-грамматики grammars-v4 (A2) | исполнитель | этап 6 |
