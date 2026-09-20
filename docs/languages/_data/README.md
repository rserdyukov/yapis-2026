# Данные каталога языков

Для готовой карточки укажите `publish: true` рядом с `id` в
`languages/<id>.yaml`. Без свойства или с `false` карточка остаётся черновиком:
генератор переносит флаг в Markdown, исключает язык из списка и публичной
матрицы. MkDocs не публикует его страницу. Проверки полноты исходной базы
при этом продолжают учитывать все карточки.

В `docs/languages/index.md` и `concepts.md` флаг задаётся в начальном YAML-блоке;
генератор сохраняет этот блок. Не меняйте `publish` в сгенерированной карточке
`<id>.md`: его источник — YAML языка.

Из этого каталога `tools/build-catalog.py` собирает страницы
`docs/languages/*.md`. Сюда ничего не публикуется напрямую: каталог
исключён из сборки MkDocs (`exclude_docs` в `mkdocs.yml`), а код примеров и
грамматик попадает на страницы через `pymdownx.snippets`.

```
_data/
  ontology.yaml              общий словарь концепций (один на каталог)
  languages/<id>.yaml        карточка языка
  examples/<id>/showcase.*   пример-витрина с секциями-маркерами
  grammar/<id>/*.fragments.g4  фрагменты ANTLR-грамматики с лицензией источника
```

Проверка и сборка:

```
python3 tools/build-catalog.py           # пересобрать docs/languages/
python3 tools/build-catalog.py --check   # проверить данные и актуальность страниц
```

`--check` выполняет **полную валидацию**, а не только сравнение файлов:
испорченный маркер в showcase упадёт здесь, а не на сайте.

При `mkdocs serve` правка файлов в `_data/` пересобирает сайт, но страницы
не меняются, пока не запущен генератор — это особенность MkDocs (он следит
за всем `docs/`). Держите второй терминал с
`python3 tools/build-catalog.py --watch`.

## Как добавить язык

1. `languages/<id>.yaml` по образцу `python.yaml`. `id` — латиница, он же
   имя страницы `/languages/<id>/`.
2. `examples/<id>/showcase.<ext>` — одна программа с комментариями. Для
   каждой концепции с `showcase: required` в онтологии — секция:

   ```python
   # --8<-- [start:variants-3]
   a, b = 1, 2
   # --8<-- [end:variants-3]
   ```

   Имя секции — `slug` концепции (точки в именах snippets запрещены).
   Маркер работает в любом комментарии: `#`, `//`, `/* */`. Секции могут
   быть вложены. Если конструкции в языке нет (`until`), секция показывает
   эквивалент, а в YAML у значения пишется `note`. Если концепция
   неприменима (`n/a`), секция не нужна.

   Showcase демонстрирует **пункты онтологии**, а не все конструкции языка.
3. `grammar/<id>/<File>.fragments.g4` — секция `notice` с заголовком
   лицензии из оригинального файла грамматики (дословно: BSD и MIT требуют
   воспроизвести его) и секции с именами правил. Правило копируется из
   источника по зафиксированному `commit`.
4. `python3 tools/build-catalog.py`, посмотреть `mkdocs build`, закоммитить
   YAML **и** сгенерированные `docs/languages/*.md`.

## Схема карточки

```yaml
id: java
meta:
  name: Java
  ru: Java
  wikidata: Q251          # внешние идентификаторы — только ссылки
  pldb: java
  hopl: 2131
  appeared: {value: 1995, sources: [{url: ..., retrieved: 2026-09-18}]}
  designers: [James Gosling]
  organizations: [Sun Microsystems, Oracle]
  website: https://...
  spec: https://...
  summary: одно-два предложения

versions:                  # вехи: те, на которые ссылается since/until,
  - id: "1.0"              # плюс role: first и role: latest
    label: Java 1.0
    date: 1996-01-23
    kind: release          # release | edition
    role: first
    sources: [{url: ..., retrieved: ...}]
  - {id: "2018", label: Rust 2018, date: 2018-12-06, kind: edition, release: "1.31", sources: [...]}

publications:              # руками; внешние базы публикаций некурированы
  - {authors: [...], title: ..., year: 2014, venue: ..., url: ...}

concepts:                  # ключ — id концепции из ontology.yaml
  variants.1:              # значение — список записей
    - {value: explicit}
    - {value: implicit, since: "10", applies_to: локальные переменные, note: "var, JEP 286"}
  variants.9:
    - {value: n/a, note: почему неприменимо}   # n/a допустим только с note
  typing.inference:        # kind: bool
    - {value: true, since: "10", note: ...}

grammar:
  spec_url: https://...    # официальная грамматика в её нотации
  sources:                 # один на файл грамматики
    - {id: parser, repo: antlr/grammars-v4, path: java/java/JavaParser.g4,
       commit: <sha>, license: BSD-3-Clause}
  fragments:               # текст — секция с именем rule в .fragments.g4
    - {rule: localVariableDeclaration, source: parser, line: 478, file: JavaParser.fragments.g4}

examples:
  - {role: showcase, file: showcase.java}

assessment:                # опционален; если есть — все четыре ключа
  readability:  {text: ..., concepts: [variants.5]}
  writability:  {text: ..., concepts: []}
  reliability:  {text: ..., concepts: [typing.checking, errors.model]}
  cost:         {text: ...}
```

Поля записи значения: `value` (обязательно; id из онтологии, `true/false`
для `bool`, `n/a`), `since`, `until` (id из `versions`), `applies_to` (к
чему относится: типы, контекст), `status` (`stable | preview |
experimental | deprecated`), `note`, `example` (`{file, section}` — только
если нужна не секция `slug` showcase), `sources`.

## Что проверяет генератор

- концепция и значение существуют в онтологии; `max_values` не превышен;
- `since`/`until` ссылаются на запись `versions`; неиспользуемая версия без
  `role` — предупреждение;
- каждая концепция с `showcase: required` и значением, отличным от `n/a`,
  имеет секцию в showcase; маркер с именем не из онтологии — ошибка
  (snippets такой маркер не вырезает и он уйдёт на страницу как код);
- лицензия источника грамматики из списка `MIT`, `Apache-2.0`,
  `BSD-3-Clause`; `commit` указан; в `.fragments.g4` есть секция `notice` и
  секция каждого `rule`;
- `assessment`, если есть, — четыре ключа с непустым текстом и
  существующими концепциями;
- покрытие значений `kind: choice` не ниже `coverage_threshold`;
  непокрытое значение допустимо только с `coverage.pending.note` в онтологии;
- сгенерированные страницы совпадают с данными; лишний `docs/languages/*.md`
  без YAML — ошибка.

Подсветка `antlr` в Pygments рассчитана на ANTLR3: конструкции `<assoc=right>`
и `tokens {A, B}` остаются без цвета. Это не ошибка сборки.
