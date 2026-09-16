# ЯПИС 2026 — материалы курса

Преподавательский репозиторий лабораторного практикума по курсу
«Языковые процессоры интеллектуальных систем».

Здесь лежат задания, инфраструктура автоматической проверки и инструменты
администрирования студенческих репозиториев. **Работы студентов сюда не
попадают** — у каждого студента свой приватный репозиторий, созданный из
шаблона.

## Модель курса

Одна GitHub-организация на группу, внутри — по одному приватному
репозиторию на студента. Студенты добавляются как outside collaborators и
поэтому не видят работы друг друга.

Работа сдаётся через Pull Request из ветки `task<номер>`. В PR
автоматически запускается предварительное ИИ-ревью; финальное решение
принимает преподаватель.

Открытый PR автоматически назначается на преподавателя своей группы, так
что работы собираются в одну очередь — [Review requests](https://github.com/pulls/review-requested).
Кто какую группу ведёт — `TEACHER_BY_GROUP` в
[`.github/review/config.env`](.github/review/config.env); подробнее —
`admin/SETUP.md`, раздел 10.2.

## Что где лежит

| Путь | Назначение |
|---|---|
| [`TASKS.md`](TASKS.md) | Где что лежит: источники текста задания и сборка производных документов |
| [`docs/`](docs/) | Сайт курса для студентов: практикум, варианты, лекции, допматериалы |
| [`admin/SETUP.md`](admin/SETUP.md) | Пошаговое развёртывание системы для новой группы |
| [`admin/manage.sh`](admin/manage.sh) | Управление репозиториями: создание, доступы, статистика, аудит, синхронизация |
| [`admin/PORTING.md`](admin/PORTING.md) | Перенос системы на другой курс — для коллег |
| [`admin/PROMPTS.md`](admin/PROMPTS.md) | Как устроены и отлаживаются промпты ИИ-ревью |
| [`admin/template-*.md`](admin/) | Документы, уходящие в шаблон студента |
| [`.github/review/`](.github/review/) | Движок ИИ-ревью: промпты, проверки, лимиты |
| [`.github/workflows/`](.github/workflows/) | `tests`, `guard-main` и `pages` |
| [`tools/`](tools/) | Сборка производных документов и слайдов |

## Быстрый старт

```bash
cd admin
cp .env.example .env        # заполнить ORG и TEMPLATE_REPO
./manage.sh doctor          # проверить настройки организации
./manage.sh prs             # открытые PR: что дольше всех ждёт проверки
./manage.sh stats           # расход квот и проблемные репозитории
```

Полная инструкция — [`admin/SETUP.md`](admin/SETUP.md).

## Шаблон репозитория студента

Студенческие репозитории создаются из отдельного template-репозитория
(см. `TEMPLATE_REPO` в `admin/.env`). Его содержимое — это `.github/**`
из этого репозитория плюс три документа:

| Источник здесь | Имя в шаблоне |
|---|---|
| `admin/template-README.md` | `README.md` |
| `admin/template-TASK.md` | `TASK.md` |
| `admin/template-GUIDE.md` | `GUIDE.md` |

Состав шаблона задан в
[`admin/template-manifest.txt`](admin/template-manifest.txt).

Правки вносятся только здесь и расходятся по цепочке:

```bash
cd admin
./manage.sh sync-template     # источник -> шаблон
./manage.sh sync-workflow     # шаблон -> репозитории студентов
```

Подробнее — [`admin/STUDENT_GUIDE.md`](admin/STUDENT_GUIDE.md).

## Сайт курса

Публикуется на GitHub Pages: <https://rserdyukov.github.io/yapis-2026/>
Собирается workflow `pages` из каталога [`docs/`](docs/) при push в `main`.

| Что | Источник |
|---|---|
| Требования практикума | `docs/_partials/` → сайт **и** `TASK.md` студента |
| Варианты заданий | `docs/labs/variants.md` |
| Лекции | `docs/lectures/slides/*.md` (Marp) → HTML |
| Дополнительные материалы | `docs/materials/` |

Текст задания хранится в одном экземпляре: `admin/template-TASK.md` и
`docs/labs/index.md` **собираются из партиалов** и руками не правятся.

```bash
python3 tools/build-docs.py     # пересобрать документы из docs/_partials/
python3 tools/build-slides.py   # индекс лекций + HTML слайдов (Docker или npx)

pip install -r docs/requirements.txt
mkdocs serve                    # локальный просмотр сайта
```

## Тесты

Логика проверок покрыта тестами, не обращающимися к API модели:

```bash
bash .github/review/tests/run-tests.sh
```
