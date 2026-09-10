# Тесты и отладка ИИ-ревью

Два независимых инструмента:

| Скрипт | Что проверяет | Нужен ключ API |
|---|---|---|
| `run-tests.sh` | Логику инфраструктуры: лимиты, безопасность, сборку промпта | Нет |
| `eval-prompts.sh` | Качество самого ИИ-ревью на эталонных работах | Да (кроме `--dry-run`) |

---

## run-tests.sh — тесты логики

Быстрые (секунды), бесплатные, без сети. Вызовы `gh` подменяются моками.

```bash
./.github/review/tests/run-tests.sh              # все тесты
./.github/review/tests/run-tests.sh rate         # только про лимиты
./.github/review/tests/run-tests.sh guard        # только guard-main
```

Прогоняйте после любой правки в `.github/review/**` и `.github/workflows/**`.

### Что покрыто

Каждый тест соответствует багу, который реально случался на этом проекте:

| Тест | Какой баг ловит |
|---|---|
| `rate_sync_runs_excluded_from_daily` | Служебные PR от `sync-workflow` съедали дневной лимит студента |
| `rate_skipped_comments_do_not_count` | Отказы по cooldown расходовали бюджет ревью |
| `rate_api_failure_is_visible_and_safe` | `gh` пишет ошибку в stdout — лимиты молча отключались |
| `workflow_permissions_are_sufficient` | Без `actions: read` лимиты не работали вовсе |
| `detect_branch_injection_neutralized` | Имя ветки `task1$(id)` выполнялось как команда |
| `guard_admin_is_trusted` | `guard-main` считал преподавателя нарушителем |
| `workflows_have_no_run_interpolation` | `${{ }}` в теле `run:` = выполнение произвольного кода |
| `messages_reasons_are_single_line` | Многострочный `reason` ломает передачу через `GITHUB_OUTPUT` |

### Как добавить тест

Функция с именем `test_*`; доступны `assert_eq`, `assert_contains`,
`assert_not_contains`:

```bash
test_my_check() {
  run_rate_limit GH_RUNS='[]' GH_COMMENTS="$(make_comments review)"
  assert_contains "${RL_OUT}" "allowed=true" "описание"
}
```

Мок `gh` эмулирует `--jq` — структуру ответов повторяйте точно как у
настоящего API, иначе тест пройдёт на неверных данных.

---

## eval-prompts.sh — отладка промптов

Прогоняет ИИ-ревью на эталонных работах и проверяет, что бот нашёл нужное
и не сказал запрещённого.

```bash
./.github/review/tests/eval-prompts.sh --list        # список фикстур
./.github/review/tests/eval-prompts.sh --dry-run     # без вызова модели, бесплатно
./.github/review/tests/eval-prompts.sh               # полный прогон
./.github/review/tests/eval-prompts.sh broken-task3  # одна фикстура
./.github/review/tests/eval-prompts.sh --repeat 3    # проверить стабильность
```

Перед полным прогоном:

```bash
export OPENROUTER_API_KEY=<ключ>   # или GROQ_API_KEY / GEMINI_API_KEY
```

Ответы модели сохраняются в `tests/results/` — их полезно читать глазами,
а не только смотреть на итог проверки.

### Готовые фикстуры

| Фикстура | Что проверяет |
|---|---|
| `good-task1` | Корректная работа: бот не выдумывает проблемы и не выносит вердикт |
| `broken-task3` | Три нарушения: нет префикса `error-`, грамматика без комментариев, нет `compile.sh` |
| `injection-task3` | **Безопасность**: prompt injection в коде — агент должен отказаться и сообщить о попытке |

### Как это устроено

В `fixtures/<имя>/expect.env` описаны ожидания:

```bash
TASK_NUM=3
DESCRIPTION="Краткое описание для отчёта"
EXPECT_PRESENT="error-"                      # обязано встретиться
EXPECT_ANY_OF="compile.sh|запуск"       # хотя бы одно из
EXPECT_ABSENT="работа принята|оценка 10"     # не должно быть
MAX_LENGTH_CHARS=8000
```

### Как добавить свою фикстуру

```bash
mkdir -p .github/review/tests/fixtures/my-case/work
# положите файлы работы в work/: README.md, examples/, compiler/ ...
cp .github/review/tests/fixtures/broken-task3/expect.env \
   .github/review/tests/fixtures/my-case/expect.env
# отредактируйте expect.env под свой случай
./.github/review/tests/eval-prompts.sh my-case
```

Удобно брать реальную работу прошлого года, урезав её до нескольких файлов.

---

## Рабочий цикл при правке промптов

1. Правите `tasks/task3/prompt.md` или `common-footer.md`.
2. `./run-tests.sh` — убедиться, что ничего не сломано структурно (бесплатно).
3. `./eval-prompts.sh --dry-run` — промпт собирается, плейсхолдеры раскрыты.
4. `./eval-prompts.sh broken-task3` — проверить эффект на конкретном случае.
5. `./eval-prompts.sh --repeat 3` — убедиться, что результат стабилен.
6. Обязательно прогнать `injection-task3`: ослабление защиты — самый
   опасный вид регресса.

### Важно про недетерминированность

Модель отвечает по-разному на одинаковый запрос. Единичный провал не
обязательно означает регресс. Используйте `--repeat 3` и смотрите долю
успехов: `1/3` — проблема в промпте, `3/3` до правки и `2/3` после —
повод насторожиться, `0/3` — явный регресс.

Бесплатные модели менее стабильны в соблюдении формата. Если формат
«плывёт» — смотрите альтернативы в `config.env`.

---

## Что тесты НЕ покрывают

Честные границы:

- **Работу GitHub Actions целиком.** Проверяется логика скриптов и права в
  YAML, но не то, как GitHub исполнит workflow. Это выясняется только
  на живом PR.
- **Фактическую точность замечаний.** Проверяется наличие ключевых слов, а
  не то, что бот верно указал строку. Читайте `tests/results/` глазами.
- **Устойчивость к незнакомым инъекциям.** `injection-task3` проверяет один
  известный приём; полной защиты от prompt injection не существует.
