#!/usr/bin/env bash
# Инструмент администрирования студенческих репозиториев курса
# "Языковые процессоры интеллектуальных систем".
#
# Работает с моделью "один приватный репозиторий на студента, созданный из
# template-репозитория, в одной из GitHub-организаций группы". Не требует
# внешнего ростера студентов: список репозиториев группы получается прямо из
# GitHub по префиксу имени (REPO_PREFIX), поэтому реестр не может разойтись
# с реальностью.
#
# ЗАЩИТА ОТ СПИСЫВАНИЯ держится на двух настройках, а НЕ на самом ИИ-ревью:
#   1. Base permissions организации = None. Иначе все члены организации видят
#      все приватные репозитории, а имена предсказуемы (<REPO_PREFIX><фамилия>).
#   2. Студент добавляется как outside collaborator в свой репозиторий
#      (см. cmd_invite), а НЕ как член организации. Тогда он по определению
#      не видит чужие репозитории и не может создавать новые.
# Проверить обе настройки: ./manage.sh doctor
#
# Требуется: gh (GitHub CLI), авторизованный с правами на обе организации
# (`gh auth login`, права admin:org для приглашений и secrets).
#
# Настройка (через переменные окружения или .env-файл рядом со скриптом,
# см. .env.example):
#   ORG              — slug организации, с которой сейчас работаем (одна из двух групп)
#   TEMPLATE_REPO    — "owner/repo" шаблона (например, ORG/yapis-2026-template)
#   REPO_PREFIX      — префикс имени репозиториев студентов (по умолчанию yapis-2026-)
#   TEACHERS         — логины всех преподавателей через запятую; нужен, если группы
#                      ведут разные люди, иначе doctor/audit сочтут коммиты коллеги
#                      подозрительными (скрипт сам знает только того, кто его запустил)
#
# Использование:
#   ./manage.sh doctor                                 — проверить настройки организации,
#                                                          критичные для защиты от списывания
#   ./manage.sh protect [<фамилия>]                    — включить защиту ветки main
#                                                          (ruleset, иначе branch protection)
#   ./manage.sh audit [<фамилия>]                      — найти коммиты в main, попавшие туда
#                                                          в обход смерженного PR
#   ./manage.sh list                                   — список репозиториев студентов в ORG
#   ./manage.sh create <фамилия> [github-login]        — создать репозиторий из шаблона,
#                                                          опционально сразу пригласить студента
#   ./manage.sh invite <фамилия> <github-login>        — пригласить/добавить коллаборатора
#                                                          в уже существующий репозиторий
#   ./manage.sh set-secret <NAME> [--org]              — положить секрет (ключ API модели)
#                                                          в каждый репозиторий студента; с --org
#                                                          на уровень организации (нужен план Team)
#   ./manage.sh status [<фамилия>]                     — сводка по PR/веткам во всех репозиториях
#                                                          студентов (или по одному, если указана фамилия)
#   ./manage.sh sync-workflow                            — обновить .github/review/** и оба
#                                                          workflow (ai-review, guard-main) во всех
#                                                          репозиториях студентов из шаблона
#   ./manage.sh broadcast-issue <title> <body-file>     — создать одинаковый issue во всех
#                                                          репозиториях студентов (например,
#                                                          объявление/напоминание о дедлайне)
#
# Все деструктивные операции (create, protect, set-secret, sync-workflow,
# broadcast-issue) перед выполнением показывают список репозиториев, которые
# будут затронуты, и требуют подтверждения (кроме случая, когда передан --yes).
# Команды doctor, list, status и audit только читают данные.
#
# ЗАЩИТА ВЕТКИ main. protect пробует repository ruleset, затем классический
# branch protection. Если оба недоступны (возможно на плане Free для приватных
# репозиториев), превентивной блокировки не будет — тогда работает
# детектирующий контроль: workflow .github/workflows/guard-main.yml в
# репозитории студента и команда audit. Server-side pre-receive хуки, которые
# нельзя обойти, существуют только в GitHub Enterprise Server, а клиентские
# .git/hooks не клонируются и обходятся через git push --no-verify, поэтому
# как средство контроля они не используются.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
[ -f "${SCRIPT_DIR}/.env" ] && source "${SCRIPT_DIR}/.env"

ORG="${ORG:?Переменная ORG не задана (укажите в .env или экспортируйте перед запуском)}"
REPO_PREFIX="${REPO_PREFIX:-yapis-2026-}"
TEMPLATE_REPO="${TEMPLATE_REPO:-${ORG}/yapis-2026-template}"

ASSUME_YES=0
for arg in "$@"; do
  if [ "${arg}" = "--yes" ]; then
    ASSUME_YES=1
  fi
done

confirm() {
  local message="$1"
  if [ "${ASSUME_YES}" -eq 1 ]; then
    return 0
  fi
  read -r -p "${message} [y/N] " reply
  case "${reply}" in
    y|Y|yes|Yes) return 0 ;;
    *) echo "Отменено." >&2; exit 1 ;;
  esac
}

# Логин текущего пользователя. Заполняется один раз в require_gh_auth и
# используется в doctor/audit, чтобы не считать коммиты и членство самого
# преподавателя нарушением.
me_login=""

require_gh_auth() {
  if ! gh auth status >/dev/null 2>&1; then
    echo "Не авторизован в gh. Выполните: gh auth login" >&2
    exit 1
  fi
  if [ -z "${me_login}" ]; then
    me_login="$(gh api user --jq '.login' 2>/dev/null || echo "")"
  fi
}

# Список репозиториев студентов в ORG (по префиксу REPO_PREFIX), без шаблона.
# gh repo list --jq принимает ровно одно выражение (без --arg), поэтому
# префикс подставляется через bash-переменную прямо в выражение jq.
list_student_repos() {
  gh repo list "${ORG}" --limit 500 --json name \
    --jq ".[] | select(.name | startswith(\"${REPO_PREFIX}\")) | .name" \
    | grep -v -- "-template$" || true
}

# Является ли логин преподавательским. Учитываются:
#   - текущий авторизованный пользователь (кто запускает скрипт);
#   - список TEACHERS из .env — нужен, когда группы ведут разные
#     преподаватели и в main есть коммиты коллеги.
# Сравнение регистронезависимое: GitHub логины регистр не различают.
is_teacher_login() {
  local candidate="$1" t
  [ -z "${candidate}" ] && return 1
  [ "${candidate}" = "-" ] && return 1

  local lc_candidate
  lc_candidate="$(printf '%s' "${candidate}" | tr '[:upper:]' '[:lower:]')"

  local lc_me
  lc_me="$(printf '%s' "${me_login:-}" | tr '[:upper:]' '[:lower:]')"
  if [ -n "${lc_me}" ] && [ "${lc_candidate}" = "${lc_me}" ]; then
    return 0
  fi

  # TEACHERS — значения через запятую. Разделяем именно по запятой, а не по
  # пробелам: в списке может быть не только логин GitHub, но и имя из
  # git-конфига ("Ivan Ivanov"), которое содержит пробел.
  local IFS=','
  for t in ${TEACHERS:-}; do
    # Убираем пробелы по краям, оставляя внутренние.
    t="$(printf '%s' "${t}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -z "${t}" ] && continue
    if [ "${lc_candidate}" = "$(printf '%s' "${t}" | tr '[:upper:]' '[:lower:]')" ]; then
      return 0
    fi
  done
  return 1
}

repo_for_student() {
  local student="$1"
  echo "${REPO_PREFIX}${student}"
}

cmd_list() {
  require_gh_auth
  echo "Организация: ${ORG}"
  echo "Репозитории студентов (префикс ${REPO_PREFIX}):"
  list_student_repos | sed 's/^/  - /'
}

# Проверка настроек организации, от которых реально зависит защита от
# списывания. Ничего не меняет — только сообщает о проблемах.
cmd_doctor() {
  require_gh_auth

  local problems=0

  echo "=== Проверка организации ${ORG} ==="
  echo

  local org_json
  if ! org_json="$(gh api "orgs/${ORG}" 2>/dev/null)"; then
    echo "ОШИБКА: не удалось прочитать настройки организации ${ORG}." >&2
    echo "Нужны права admin:org — выполните: gh auth refresh -s admin:org,repo" >&2
    exit 1
  fi

  local plan base_perm can_create
  plan="$(echo "${org_json}" | jq -r '.plan.name // "unknown"')"
  base_perm="$(echo "${org_json}" | jq -r '.default_repository_permission // "unknown"')"
  # Оператор // в jq считает false отсутствующим значением, поэтому для
  # булевых полей проверяем на null явно, иначе корректное false
  # отображалось бы как "unknown".
  can_create="$(echo "${org_json}" \
    | jq -r 'if .members_can_create_repositories == null then "unknown" else (.members_can_create_repositories | tostring) end')"

  echo "План организации: ${plan}"
  if [ "${plan}" = "free" ]; then
    echo "  ЗАМЕЧАНИЕ: на плане Free защита ветки main (protected branches),"
    echo "  обязательное ревью и CODEOWNERS для ПРИВАТНЫХ репозиториев недоступны."
    echo "  Студент технически может смержить свой PR сам или запушить прямо в main."
    echo "  Рекомендация: оформить GitHub Education / Teacher benefits — организация"
    echo "  получает план Team бесплатно (protected branches + 3000 минут Actions):"
    echo "  https://education.github.com/discount_requests/application"
    problems=$((problems + 1))
  fi
  echo

  echo "Base permissions (default_repository_permission): ${base_perm}"
  if [ "${base_perm}" != "none" ]; then
    echo "  КРИТИЧНО: значение должно быть \"none\"."
    echo "  Сейчас каждый ЧЛЕН организации имеет доступ (${base_perm}) ко всем"
    echo "  приватным репозиториям — то есть может читать чужие решения."
    echo "  Исправить: Organization settings → Member privileges →"
    echo "  Base permissions → No permission. Либо командой:"
    echo "    gh api -X PATCH orgs/${ORG} -f default_repository_permission=none"
    problems=$((problems + 1))
  fi
  echo

  echo "Члены организации могут создавать репозитории: ${can_create}"
  if [ "${can_create}" = "true" ]; then
    echo "  ЗАМЕЧАНИЕ: рекомендуется запретить, чтобы студент не создал"
    echo "  публичный репозиторий со своим решением внутри организации."
    echo "  Исправить:"
    echo "    gh api -X PATCH orgs/${ORG} -f members_can_create_repositories=false"
    problems=$((problems + 1))
  fi
  echo

  # Студенты должны быть outside collaborators, а не members: члены орг видят
  # список репозиториев организации, outside collaborators — только свои.
  # Проверяем это точно: собираем коллабораторов всех репозиториев студентов
  # и смотрим, не является ли кто-то из них членом организации.
  echo "=== Члены организации (должны быть только преподаватели) ==="
  local members
  members="$(gh api "orgs/${ORG}/members" --paginate --jq '.[].login' 2>/dev/null || true)"
  if [ -z "${members}" ]; then
    echo "  (не удалось получить список или членов нет)"
  else
    echo "${members}" | sed 's/^/  - /'
  fi
  echo

  echo "=== Студенты, ошибочно добавленные как члены организации ==="
  local repos_for_check students_as_members=""
  repos_for_check="$(list_student_repos)"
  if [ -n "${repos_for_check}" ] && [ -n "${members}" ]; then
    local repo collab
    while IFS= read -r repo; do
      [ -z "${repo}" ] && continue
      collab="$(gh api "repos/${ORG}/${repo}/collaborators" --paginate \
        --jq '.[].login' 2>/dev/null || true)"
      while IFS= read -r login; do
        [ -z "${login}" ] && continue
        if echo "${members}" | grep -qxF "${login}"; then
          students_as_members="${students_as_members}${login} (${repo})"$'\n'
        fi
      done <<< "${collab}"
    done <<< "${repos_for_check}"
  fi

  # Преподаватели сами являются и членами организации, и коллабораторами
  # репозиториев — их из результата исключаем. Учитывается текущий
  # пользователь и список TEACHERS (когда группы ведут разные люди).
  if [ -n "${students_as_members}" ]; then
    local filtered="" entry entry_login
    while IFS= read -r entry; do
      [ -z "${entry}" ] && continue
      entry_login="${entry%% *}"
      if is_teacher_login "${entry_login}"; then
        continue
      fi
      filtered="${filtered}${entry}"$'\n'
    done <<< "${students_as_members}"
    students_as_members="${filtered}"
  fi

  if [ -z "${students_as_members}" ]; then
    echo "  Не найдено — хорошо (студенты являются outside collaborators)."
  else
    echo "${students_as_members}" | sed '/^$/d; s/^/  - /'
    echo "  КРИТИЧНО: эти пользователи — члены организации, а не outside"
    echo "  collaborators. При base permissions != none они видят чужие решения."
    echo "  Исправить: Organization settings → People → удалить из организации,"
    echo "  затем заново ./manage.sh invite <фамилия> <login>."
    problems=$((problems + 1))
  fi
  echo

  echo "=== Публичные репозитории студентов (должно быть пусто) ==="
  local public_repos
  public_repos="$(gh repo list "${ORG}" --limit 500 --visibility public --json name \
    --jq '.[].name' 2>/dev/null || true)"
  if [ -z "${public_repos}" ]; then
    echo "  Публичных репозиториев нет — хорошо."
  else
    echo "${public_repos}" | sed 's/^/  - /'
    echo "  КРИТИЧНО: решения в публичном репозитории видны всем."
    problems=$((problems + 1))
  fi
  echo

  # Фактическая (а не заявленная) защита main. Эндпоинт rules/branches
  # возвращает активные правила любого уровня — и ruleset, и branch protection.
  #
  # ВАЖНО: на плане Free для приватных репозиториев этот эндпоинт отвечает
  # 403 "Upgrade to GitHub Pro...". При этом gh печатает JSON ошибки в STDOUT,
  # поэтому проверять только код возврата или непустоту вывода нельзя —
  # иначе незащищённый репозиторий считался бы защищённым. Считаем защиту
  # подтверждённой только если получено корректное число больше нуля.
  echo "=== Защита ветки main по репозиториям ==="
  local unprotected="" unavailable="" protected_count=0 repo rules_json rules_count
  if [ -n "${repos_for_check}" ]; then
    while IFS= read -r repo; do
      [ -z "${repo}" ] && continue

      if ! rules_json="$(gh api "repos/${ORG}/${repo}/rules/branches/main" 2>/dev/null)"; then
        # Нет доступа к API правил — как правило, ограничение тарифа.
        unavailable="${unavailable}  - ${repo}"$'\n'
        continue
      fi

      rules_count="$(printf '%s' "${rules_json}" | jq 'if type == "array" then length else 0 end' 2>/dev/null || echo 0)"
      if [ "${rules_count}" -gt 0 ] 2>/dev/null; then
        protected_count=$((protected_count + 1))
      else
        unprotected="${unprotected}  - ${repo}"$'\n'
      fi
    done <<< "${repos_for_check}"
  fi

  echo "  Репозиториев с подтверждённой защитой main: ${protected_count}"

  if [ -n "${unavailable}" ]; then
    echo "  Защита недоступна на текущем тарифе (API правил отвечает 403):"
    echo "${unavailable}" | sed '/^$/d'
    echo "  Это ожидаемо для приватных репозиториев на плане Free."
    echo "  Работает детектирующий контроль: guard-main.yml + ./manage.sh audit."
    problems=$((problems + 1))
  fi

  if [ -n "${unprotected}" ]; then
    echo "  Без защиты main (API доступен, но правил нет):"
    echo "${unprotected}" | sed '/^$/d'
    echo "  Исправить: ./manage.sh protect"
    problems=$((problems + 1))
  fi
  echo

  if [ "${problems}" -eq 0 ]; then
    echo "Проблем не найдено."
  else
    echo "Найдено проблем: ${problems}. См. рекомендации выше."
  fi
}

# Имя ruleset'а, которым защищается main. Используется и при создании,
# и при проверке в doctor/protect, поэтому вынесено в константу.
RULESET_NAME="require-pr-to-main"

# Защита ветки main от прямых push и самостоятельного мержа.
#
# Пробуются два механизма, в порядке предпочтения:
#   1. Repository ruleset (POST /repos/{owner}/{repo}/rulesets).
#   2. Классический branch protection (PUT /branches/main/protection).
#
# ПРОВЕРЕНО НА ПРАКТИКЕ (организация на плане Free, приватный репозиторий):
# оба механизма отвечают 403 "Upgrade to GitHub Pro or make this repository
# public to enable this feature". То есть на Free защита ветки для приватных
# репозиториев НЕДОСТУПНА, несмотря на то что документация REST API про
# repository-level rulesets ограничение по тарифу не упоминает.
# Работают они на Team/Pro и выше (в т.ч. на Team по GitHub Education).
# Функция оставлена с обоими вариантами: она корректно определяет ситуацию
# и переключает преподавателя на детектирующий контроль.
#
# Если не сработало ничего, это НЕ ошибка скрипта: остаётся детектирующий
# контроль — workflow .github/workflows/guard-main.yml в репозитории студента
# и команда ./manage.sh audit.
#
# Возвращает: 0 — защита включена, 1 — не удалось (вывод поясняет причину).
protect_main_branch() {
  local repo_name="$1"
  local err

  # --- Попытка 1: repository ruleset ---
  # Правила: pull_request (менять main только через PR с 1 одобрением),
  # non_fast_forward (запрет force-push), deletion (запрет удаления ветки).
  # bypass_actors не задаём: админ репозитория (преподаватель) обходит
  # правила по умолчанию, а студенту с ролью write обход не нужен.
  err="$(gh api "repos/${ORG}/${repo_name}/rulesets" \
    --method POST --input - 2>&1 >/dev/null <<JSON
{
  "name": "${RULESET_NAME}",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["squash", "merge"]
      }
    }
  ]
}
JSON
)" && {
    echo "  Ветка main защищена через ruleset \"${RULESET_NAME}\":"
    echo "    изменения только через PR с одобрением, force-push и удаление запрещены."
    return 0
  }

  # Ruleset с таким именем уже есть — считаем, что защита на месте.
  if echo "${err}" | grep -qi "already exists\|name.*taken"; then
    echo "  Ruleset \"${RULESET_NAME}\" уже существует — защита main на месте."
    return 0
  fi

  echo "  Ruleset создать не удалось. Ответ API:"
  echo "${err}" | sed 's/^/    /' | head -5

  # --- Попытка 2: классический branch protection ---
  if gh api "repos/${ORG}/${repo_name}/branches/main/protection" \
      --method PUT --input - --silent >/dev/null 2>&1 <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
  then
    echo "  Ветка main защищена через branch protection (PR + одобрение)."
    return 0
  fi

  echo "  ПРЕДУПРЕЖДЕНИЕ: включить защиту main не удалось ни ruleset'ом,"
  echo "  ни branch protection. На плане Free для приватных репозиториев это"
  echo "  возможно. Технически студент сможет запушить в main или смержить свой"
  echo "  PR сам, поэтому работает детектирующий контроль:"
  echo "    - workflow guard-main.yml в репозитории студента поставит failing"
  echo "      check и откроет issue при push в main в обход PR;"
  echo "    - ./manage.sh audit покажет такие коммиты по всем репозиториям."
  return 1
}

cmd_create() {
  local student="${1:?Укажите фамилию студента}"
  local login="${2:-}"
  require_gh_auth

  local repo_name
  repo_name="$(repo_for_student "${student}")"

  if gh repo view "${ORG}/${repo_name}" >/dev/null 2>&1; then
    echo "Репозиторий ${ORG}/${repo_name} уже существует." >&2
    exit 1
  fi

  confirm "Создать приватный репозиторий ${ORG}/${repo_name} из шаблона ${TEMPLATE_REPO}?"

  gh repo create "${ORG}/${repo_name}" \
    --private \
    --template "${TEMPLATE_REPO}" \
    --description "Лабораторный практикум ЯПИС — ${student}"

  echo "Репозиторий создан: https://github.com/${ORG}/${repo_name}"

  # `|| true` обязателен: при недоступной защите ветки (типично для плана Free)
  # функция возвращает 1, и из-за `set -e` создание репозитория оборвалось бы
  # здесь — студент остался бы без приглашения.
  protect_main_branch "${repo_name}" || true

  if [ -n "${login}" ]; then
    cmd_invite "${student}" "${login}"
  else
    echo "Логин студента не указан — пригласите позже: ./manage.sh invite ${student} <github-login>"
  fi
}

cmd_invite() {
  local student="${1:?Укажите фамилию студента}"
  local login="${2:?Укажите GitHub-логин студента}"
  require_gh_auth

  local repo_name
  repo_name="$(repo_for_student "${student}")"

  echo "Приглашаю ${login} в ${ORG}/${repo_name} с правом Write..."
  gh api "repos/${ORG}/${repo_name}/collaborators/${login}" \
    --method PUT \
    --field permission=push \
    --silent

  echo "Готово. Студент получит письмо-приглашение от GitHub на ${login}."

  # Ключевой момент модели: студент должен остаться outside collaborator.
  # Член организации видит список её репозиториев, outside collaborator —
  # только те, куда его явно позвали.
  if gh api "orgs/${ORG}/members/${login}" --silent >/dev/null 2>&1; then
    echo
    echo "ВНИМАНИЕ: ${login} является ЧЛЕНОМ организации ${ORG}."
    echo "При base permissions != none он сможет видеть репозитории других студентов."
    echo "Студентов следует держать как outside collaborators."
    echo "Проверьте настройки: ./manage.sh doctor"
  fi
}

# Массовое включение защиты main во всех (или одном) репозиториях студентов.
# Идемпотентна: повторный запуск на защищённом репозитории ничего не ломает.
cmd_protect() {
  local student="${1:-}"
  require_gh_auth

  local repos
  if [ -n "${student}" ] && [ "${student}" != "--yes" ]; then
    repos="$(repo_for_student "${student}")"
  else
    repos="$(list_student_repos)"
  fi

  if [ -z "${repos}" ]; then
    echo "Нет репозиториев для обработки." >&2
    exit 1
  fi

  echo "Защита ветки main будет включена в следующих репозиториях:"
  echo "${repos}" | sed 's/^/  - /'
  confirm "Продолжить?"

  local ok=0 failed=0 repo
  while IFS= read -r repo; do
    [ -z "${repo}" ] && continue
    echo "--- ${repo} ---"
    if protect_main_branch "${repo}"; then
      ok=$((ok + 1))
    else
      failed=$((failed + 1))
    fi
  done <<< "${repos}"

  echo
  echo "Итог: защита включена в ${ok}, не удалось в ${failed}."
  if [ "${failed}" -gt 0 ]; then
    echo "Для репозиториев без защиты опирайтесь на guard-main.yml и ./manage.sh audit."
  fi
}

# Аудит: коммиты в main, которые попали туда не через смерженный PR.
# Это основной детектирующий контроль, если защита ветки недоступна.
cmd_audit() {
  local student="${1:-}"
  require_gh_auth

  # me_login заполняется в require_gh_auth; коммиты преподавателей (текущего
  # и перечисленных в TEACHERS) считаются нормой — это мержи и правки шаблона.

  local repos
  if [ -n "${student}" ]; then
    repos="$(repo_for_student "${student}")"
  else
    repos="$(list_student_repos)"
  fi

  local total_suspicious=0 repo
  while IFS= read -r repo; do
    [ -z "${repo}" ] && continue
    echo "=== ${repo} ==="

    # Все SHA, пришедшие в main через смерженные PR: merge-коммиты и,
    # для squash/rebase-мержей, сам merge_commit_sha.
    local pr_shas
    pr_shas="$(gh pr list --repo "${ORG}/${repo}" \
      --state merged --base main --limit 200 \
      --json mergeCommitSha,number \
      --jq '.[].mergeCommitSha' 2>/dev/null || true)"

    # Коммиты в main. Поля разделяем табуляцией, а НЕ пробелом: имя автора
    # из git-конфига содержит пробелы ("Test Student"), и разбор по пробелу
    # обрезал бы его до первого слова, ломая и вывод, и фильтрацию доверенных.
    # Логин GitHub может быть null (коммит с неизвестным email) — тогда
    # используем имя из git и отдельно помечаем это в выводе.
    # Пустые поля недопустимы: bash `read` сжимает подряд идущие разделители,
    # даже когда IFS задан явно, и колонки сдвинулись бы. Поэтому отсутствующий
    # логин передаём явным маркером "-".
    local main_commits
    main_commits="$(gh api "repos/${ORG}/${repo}/commits" \
      --paginate --jq '.[] | [.sha, .commit.author.date, (.author.login // "-"), .commit.author.name] | @tsv' \
      2>/dev/null || true)"

    if [ -z "${main_commits}" ]; then
      echo "  (нет доступа или репозиторий пуст)"
      echo
      continue
    fi

    local suspicious="" sha date login gitname who
    while IFS=$'\t' read -r sha date login gitname; do
      [ -z "${sha}" ] && continue

      # Пропускаем, если коммит — результат мержа PR.
      if [ -n "${pr_shas}" ] && echo "${pr_shas}" | grep -qF "${sha}"; then
        continue
      fi

      # Пропускаем коммиты преподавателей и ботов. Сверяем и логин GitHub,
      # и имя из git-конфига: у преподавателя они могут различаться.
      # Преподавателей может быть несколько (например, две группы ведут
      # разные люди) — список берётся из TEACHERS, см. .env.example.
      if is_teacher_login "${login}" || is_teacher_login "${gitname}"; then
        continue
      fi
      case "${login}" in
        github-actions|"github-actions[bot]"|web-flow|dependabot|"dependabot[bot]")
          continue ;;
      esac
      case "${gitname}" in
        "GitHub"|"GitHub Actions") continue ;;
      esac

      if [ "${login}" != "-" ]; then
        who="${login}"
      else
        # Логин не определён: коммит сделан с email, не привязанным к аккаунту
        # GitHub. Для аудита это важный признак — стоит проверить вручную.
        who="${gitname} (git-имя; аккаунт GitHub не определён)"
      fi
      suspicious="${suspicious}  - ${sha:0:9} ${date} ${who}"$'\n'
    done <<< "${main_commits}"

    if [ -n "${suspicious}" ]; then
      local count
      count="$(echo "${suspicious}" | sed '/^$/d' | wc -l | tr -d ' ')"
      echo "${suspicious}" | sed '/^$/d'
      echo "  Коммитов в main вне мержа PR: ${count}"
      echo "  Проверьте вручную: часть может быть initial commit из шаблона."
      total_suspicious=$((total_suspicious + count))
    else
      echo "  Все коммиты в main пришли через смерженные PR — хорошо."
    fi
    echo
  done <<< "${repos}"

  echo "Всего подозрительных коммитов: ${total_suspicious}."
  if [ "${total_suspicious}" -gt 0 ]; then
    echo "Напоминание: работа, залитая в main в обход PR, считается несданной"
    echo "(см. admin/STUDENT_GUIDE.md)."
  fi
}

# Установка секрета с ключом API модели.
#
# ВАЖНО (проверено на практике): organization secrets с visibility=all для
# ПРИВАТНЫХ репозиториев работают только на платных планах. На плане Free
# секрет создаётся без ошибки и виден в списке, но НЕ ПРИВЯЗЫВАЕТСЯ ни к
# одному репозиторию (orgs/.../secrets/NAME/repositories -> total_count = 0),
# и в workflow приходит пустая строка. Поэтому по умолчанию секрет ставится
# в каждый репозиторий студента отдельно (repo-level), что работает на любом
# плане. Организационный вариант доступен через --org.
cmd_set_secret() {
  local name="" use_org=0 arg
  for arg in "$@"; do
    case "${arg}" in
      --org)  use_org=1 ;;
      --yes)  ;;
      *)      [ -z "${name}" ] && name="${arg}" ;;
    esac
  done
  : "${name:?Укажите имя секрета, например OPENROUTER_API_KEY}"
  require_gh_auth

  local repos
  repos="$(list_student_repos)"

  if [ "${use_org}" -eq 1 ]; then
    echo "Секрет ${name} будет установлен как ORGANIZATION SECRET в ${ORG}"
    echo "с visibility=all (доступен всем репозиториям, включая будущие)."
    echo
    echo "ВНИМАНИЕ: на плане Free для приватных репозиториев это НЕ РАБОТАЕТ —"
    echo "секрет создастся, но в workflow придёт пустое значение. Используйте"
    echo "этот режим только на плане Team/Enterprise."
  else
    echo "Секрет ${name} будет установлен в каждый репозиторий студента"
    echo "(repo-level) — этот способ работает на любом плане, включая Free:"
    if [ -z "${repos}" ]; then
      echo "  (репозиториев пока нет — создайте их через ./manage.sh create)"
    else
      echo "${repos}" | sed 's/^/  - /'
    fi
    echo
    echo "Ключ модели даёт только расходовать квоту запросов и не открывает"
    echo "доступ к деньгам или данным, поэтому раздача его студенческим"
    echo "репозиториям допустима. Для секретов с иными правами так не делайте."
    echo
    echo "ВАЖНО: новым репозиториям секрет придётся выдать повторным запуском"
    echo "этой команды — автоматически он туда не попадёт."
  fi
  confirm "Продолжить?"

  local secret_value
  read -r -s -p "Введите значение секрета ${name}: " secret_value
  echo
  if [ -z "${secret_value}" ]; then
    echo "Пустое значение — отменено." >&2
    exit 1
  fi

  if [ "${use_org}" -eq 1 ]; then
    printf '%s' "${secret_value}" | gh secret set "${name}" \
      --org "${ORG}" --visibility all

    # Проверяем фактическую привязку: на Free она окажется нулевой.
    local bound
    bound="$(gh api "orgs/${ORG}/actions/secrets/${name}/repositories" \
      --jq '.total_count' 2>/dev/null || echo "?")"
    echo "Секрет ${name} установлен на уровне организации ${ORG}."
    if [ "${bound}" = "0" ]; then
      echo
      echo "ПРОБЛЕМА: секрет не привязан ни к одному репозиторию (total_count=0)."
      echo "Это ограничение плана Free. В workflow значение придёт пустым."
      echo "Запустите без --org, чтобы разложить секрет по репозиториям:"
      echo "  ./manage.sh set-secret ${name}"
    fi
    return 0
  fi

  if [ -z "${repos}" ]; then
    echo "Нет репозиториев студентов — секрет некуда положить." >&2
    exit 1
  fi

  local repo ok=0 failed=0
  while IFS= read -r repo; do
    [ -z "${repo}" ] && continue
    if printf '%s' "${secret_value}" \
        | gh secret set "${name}" --repo "${ORG}/${repo}" >/dev/null 2>&1; then
      echo "  ${repo}: ok"
      ok=$((ok + 1))
    else
      echo "  ${repo}: ОШИБКА"
      failed=$((failed + 1))
    fi
  done <<< "${repos}"

  echo
  echo "Секрет ${name} установлен в ${ok} репозиториях, ошибок: ${failed}."
}

cmd_status() {
  local student="${1:-}"
  require_gh_auth

  local repos
  if [ -n "${student}" ]; then
    repos="$(repo_for_student "${student}")"
  else
    repos="$(list_student_repos)"
  fi

  while IFS= read -r repo; do
    [ -z "${repo}" ] && continue
    echo "=== ${repo} ==="
    gh pr list --repo "${ORG}/${repo}" \
      --state open \
      --json number,title,headRefName,isDraft,createdAt \
      --jq '.[] | "  PR #\(.number) [\(.headRefName)] \(.title) (создан \(.createdAt))"' \
      || echo "  (нет доступа или репозиторий не найден)"
    echo
  done <<< "${repos}"
}

cmd_sync_workflow() {
  require_gh_auth

  local repos
  repos="$(list_student_repos)"

  if [ -z "${repos}" ]; then
    echo "Нет репозиториев студентов в ${ORG} (префикс ${REPO_PREFIX})." >&2
    exit 0
  fi

  echo "Будут обновлены .github/workflows/{ai-review,guard-main}.yml и .github/review/**"
  echo "в следующих репозиториях, путём открытия PR из ветки ci/sync-review-tooling"
  echo "в каждом (изменения не мержатся автоматически):"
  echo "${repos}" | sed 's/^/  - /'
  confirm "Продолжить?"

  # Намеренно НЕ local: trap на EXIT срабатывает после выхода из функции,
  # когда локальная переменная уже уничтожена, и из-за `set -u` очистка
  # падала бы с "tmp_dir: unbound variable".
  SYNC_TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${SYNC_TMP_DIR:-}"' EXIT
  local tmp_dir="${SYNC_TMP_DIR}"

  echo "Клонирую шаблон ${TEMPLATE_REPO}..."
  gh repo clone "${TEMPLATE_REPO}" "${tmp_dir}/template" -- --quiet

  while IFS= read -r repo; do
    [ -z "${repo}" ] && continue
    echo "--- ${repo} ---"
    local work="${tmp_dir}/${repo}"
    gh repo clone "${ORG}/${repo}" "${work}" -- --quiet

    (
      cd "${work}"
      git checkout -q -b ci/sync-review-tooling
      rm -rf .github/review
      cp -r "${tmp_dir}/template/.github/review" .github/review
      mkdir -p .github/workflows
      cp "${tmp_dir}/template/.github/workflows/ai-review.yml" .github/workflows/ai-review.yml
      cp "${tmp_dir}/template/.github/workflows/guard-main.yml" .github/workflows/guard-main.yml

      # Индексируем ДО проверки изменений: `git diff` не замечает новые
      # (untracked) файлы, поэтому при первом развёртывании инфраструктуры
      # проверка ложно сообщала бы "изменений нет".
      git add -A .github/review .github/workflows

      if git diff --cached --quiet; then
        echo "  Изменений нет, пропускаю."
        exit 0
      fi

      git commit -m "ci: обновить инфраструктуру ИИ-ревью из шаблона" --quiet
      git push -u origin ci/sync-review-tooling --quiet
      gh pr create \
        --title "ci: обновить инфраструктуру ИИ-ревью" \
        --body "Автоматическое обновление \`.github/review/**\`, \`.github/workflows/ai-review.yml\` и \`.github/workflows/guard-main.yml\` из шаблона. Слить самостоятельно после проверки." \
        --base main
    )
  done <<< "${repos}"
}

cmd_broadcast_issue() {
  local title="${1:?Укажите заголовок issue}"
  local body_file="${2:?Укажите путь к файлу с текстом issue}"
  require_gh_auth

  if [ ! -f "${body_file}" ]; then
    echo "Файл ${body_file} не найден." >&2
    exit 1
  fi

  local repos
  repos="$(list_student_repos)"

  echo "Issue \"${title}\" будет создан в следующих репозиториях:"
  echo "${repos}" | sed 's/^/  - /'
  confirm "Продолжить?"

  while IFS= read -r repo; do
    [ -z "${repo}" ] && continue
    echo "--- ${repo} ---"
    gh issue create --repo "${ORG}/${repo}" --title "${title}" --body-file "${body_file}"
  done <<< "${repos}"
}

usage() {
  # Печатаем шапку-комментарий целиком, до первой строки кода. Жёсткий
  # диапазон строк здесь использовать нельзя: он молча обрезает справку
  # при любой правке комментариев выше.
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
}

main() {
  local command="${1:-}"
  [ $# -gt 0 ] && shift || true

  case "${command}" in
    doctor)            cmd_doctor "$@" ;;
    protect)           cmd_protect "$@" ;;
    audit)             cmd_audit "$@" ;;
    list)             cmd_list "$@" ;;
    create)            cmd_create "$@" ;;
    invite)            cmd_invite "$@" ;;
    set-secret)         cmd_set_secret "$@" ;;
    status)            cmd_status "$@" ;;
    sync-workflow)      cmd_sync_workflow "$@" ;;
    broadcast-issue)     cmd_broadcast_issue "$@" ;;
    -h|--help|help|"")  usage ;;
    *)
      echo "Неизвестная команда: ${command}" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
