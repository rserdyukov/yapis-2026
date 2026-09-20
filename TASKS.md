# Лабораторный практикум

Курс «Языковые процессоры интеллектуальных систем».

Текст задания больше не хранится в этом файле: он живёт в одном экземпляре
и раскладывается по потребителям автоматически.

| Что | Где источник | Куда попадает |
|---|---|---|
| Требования практикума (последовательность работ, отчёт, требования к языку) | [`docs/_partials/`](docs/_partials/) | сайт курса и `TASK.md` студента |
| Варианты заданий и таблица распределения | [`docs/labs/variants.md`](docs/labs/variants.md) | сайт курса |
| Каталог языков программирования (как свойства варианта решены в реальных языках) | [`docs/languages/_data/`](docs/languages/_data/) | сайт курса, `docs/languages/*.md` |

Сборка производных документов:

```bash
python3 tools/build-docs.py          # обновить admin/template-TASK.md и docs/labs/index.md
python3 tools/build-docs.py --check  # проверить, что они не разошлись с источником
```

`admin/template-TASK.md` и `docs/labs/index.md` **редактировать руками нельзя** —
правки затрёт следующая сборка. Меняйте партиалы в `docs/_partials/`.
Расхождение ловит тест `generated_docs_are_up_to_date`.

То же для каталога языков: `python3 tools/build-catalog.py` собирает
`docs/languages/*.md` из `docs/languages/_data/`, `--check` проверяет
данные по онтологии и актуальность страниц (тест `generated_catalog_is_up_to_date`).

Сайт курса: <https://rserdyukov.github.io/yapis-2026/>
