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
#   TEMPLATE_REPO    — "owner/repo" шаблона (например, rserdyukov/yapis-2026-template)
#   REVIEWER_REPO    — "owner/repo" приватного репозитория ревьюера
#                      (по умолчанию rserdyukov/yapis-2026-reviewer)
#   REPO_PREFIX      — префикс имени репозиториев студентов (по умолчанию yapis-2026-)
#   TEACHERS         — логины всех преподавателей через запятую; нужен, если группы
#                      ведут разные люди, иначе doctor/audit сочтут коммиты коллеги
#                      подозрительными (скрипт сам знает только того, кто его запустил)
#
# Использование:
#   ./manage.sh doctor                                 — проверить настройки организации и
#                                                          ревьюера, критичные для защиты
#   ./manage.sh protect [<фамилия>]                    — включить защиту ветки main
#                                                          (ruleset, иначе branch protection)
#   ./manage.sh stats [--days N] [--json]              — расход минут Actions, квота модели,
#                                                          доля неудачных ревью, проблемы
#   ./manage.sh audit [<фамилия>]                      — найти коммиты в main, попавшие туда
#                                                          в обход смерженного PR
#   ./manage.sh list                                   — список репозиториев студентов в ORG
#   ./manage.sh create <фамилия> [github-login]        — создать репозиторий из шаблона,
#                                                          опционально сразу пригласить студента
#   ./manage.sh invite <фамилия> <github-login>        — пригласить/добавить коллаборатора
#                                                          в уже существующий репозиторий
#   ./manage.sh set-secret <NAME>                      — положить секрет (ключ API модели)
#                                                          в репозиторий ревьюера
#   ./manage.sh status [<фамилия>]                     — сводка по PR/веткам во всех репозиториях
#                                                          студентов (или по одному, если указана фамилия)
#   ./manage.sh review [<репозиторий>[:<PR>]] [--dry-run]
#                                                        — запустить ревьюер вне расписания
#   ./manage.sh sync-reviewer                            — раскатать движок ревью в приватный
#                                                          репозиторий ревьюера (состав —
#                                                          admin/reviewer-manifest.txt)
#   ./manage.sh sync-template                            — раскатать этот репозиторий в шаблон
#                                                          (состав — admin/template-manifest.txt);
#                                                          выполняется ПЕРЕД sync-workflow
#   ./manage.sh sync-workflow                            — раскатать шаблон по репозиториям
#                                                          студентов (TASK.md, GUIDE.md,
#                                                          review-local.sh); README не трогает
#   ./manage.sh broadcast-issue <title> <body-file>     — создать одинаковый issue во всех
#                                                          репозиториях студентов (например,
#                                                          объявление/напоминание о дедлайне)
#
# Все деструктивные операции (create, protect, set-secret, sync-*, review,
# broadcast-issue) перед выполнением показывают, что будет затронуто, и
# требуют подтверждения (кроме случая, когда передан --yes).
# Команды doctor, list, status и audit только читают данные.
#
# ГДЕ ВЫПОЛНЯЕТСЯ ИИ-РЕВЬЮ. Не в репозиториях студентов, а централизованно —
# в приватном репозитории REVIEWER_REPO по расписанию (см. reviewer/ и
# SETUP.md). Поэтому ключ модели хранится в одном месте и недоступен
# студентам, а лимиты считаются по всему курсу сразу.
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
# Приватный репозиторий с workflow ревьюера. Держится ВНЕ организации
# студентов: там секреты и логи с фрагментами их кода.
REVIEWER_REPO="${REVIEWER_REPO:-}"

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

  # Ревьюер: приватность репозитория, секрет ключа модели, настройки
  # GitHub App и свежесть раскатанного движка. Без этого ИИ-ревью либо не
  # запустится вовсе, либо упадёт на каждом PR, а студент увидит только
  # комментарий о технической ошибке.
  echo "=== Ревьюер (централизованное ИИ-ревью) ==="
  if [ -z "${REVIEWER_REPO}" ]; then
    echo "  ПРОБЛЕМА: не задан REVIEWER_REPO в admin/.env."
    echo "  Без него ИИ-ревью не выполняется. См. admin/SETUP.md."
    problems=$((problems + 1))
    echo
  elif ! gh repo view "${REVIEWER_REPO}" >/dev/null 2>&1; then
    echo "  ПРОБЛЕМА: репозиторий ревьюера ${REVIEWER_REPO} недоступен."
    echo "  Создайте его: gh repo create ${REVIEWER_REPO} --private --add-readme"
    echo "  и раскатайте движок: ./manage.sh sync-reviewer"
    problems=$((problems + 1))
    echo
  else
    echo "  Репозиторий: ${REVIEWER_REPO}"

    local rv_visibility
    rv_visibility="$(gh repo view "${REVIEWER_REPO}" --json visibility --jq '.visibility' 2>/dev/null || echo "unknown")"
    if [ "${rv_visibility}" != "PRIVATE" ]; then
      echo "  КРИТИЧНО: репозиторий ревьюера не приватный (${rv_visibility})."
      echo "  Там лежат ключ модели, приватный ключ GitHub App и логи с кодом студентов."
      echo "  Исправить: gh repo edit ${REVIEWER_REPO} --visibility private"
      problems=$((problems + 1))
    else
      echo "  Приватный — хорошо."
    fi

    # Переменные и секреты, которые использует workflow review.yml.
    local rv_vars rv_secrets
    rv_vars="$(gh variable list --repo "${REVIEWER_REPO}" --json name --jq '.[].name' 2>/dev/null || true)"
    rv_secrets="$(gh secret list --repo "${REVIEWER_REPO}" --json name --jq '.[].name' 2>/dev/null || true)"

    local required_var
    for required_var in ORG REPO_PREFIX APP_CLIENT_ID; do
      if ! echo "${rv_vars}" | grep -qxF "${required_var}"; then
        echo "  ПРОБЛЕМА: не задана переменная ${required_var}."
        echo "  Исправить: gh variable set ${required_var} --repo ${REVIEWER_REPO}"
        problems=$((problems + 1))
      fi
    done

    if ! echo "${rv_secrets}" | grep -qxF "APP_PRIVATE_KEY"; then
      echo "  ПРОБЛЕМА: не задан секрет APP_PRIVATE_KEY (приватный ключ GitHub App)."
      echo "  Без него ревьюер не сможет комментировать PR. См. admin/SETUP.md."
      problems=$((problems + 1))
    fi

    # Имя секрета с ключом модели выводится из MODEL теми же функциями, что
    # использует ревьюер, чтобы проверка не разошлась с реальностью.
    local review_root="${SCRIPT_DIR}/../.github/review"
    if [ ! -f "${review_root}/config.env" ] || [ ! -f "${review_root}/lib/provider.sh" ]; then
      echo "  Не найден config.env или lib/provider.sh — проверка ключа модели пропущена."
    else
      local model provider required_key key_url
      # Читаем в субшелле: config.env определяет MODEL и не должен
      # перетирать переменные этого скрипта.
      model="$(
        # shellcheck source=/dev/null
        source "${review_root}/config.env" >/dev/null 2>&1
        printf '%s' "${MODEL:-}"
      )"
      provider="$(
        # shellcheck source=/dev/null
        source "${review_root}/lib/provider.sh" >/dev/null 2>&1
        provider_for "${model}"
      )"
      required_key="$(
        # shellcheck source=/dev/null
        source "${review_root}/lib/provider.sh" >/dev/null 2>&1
        key_var_for "${provider}"
      )"

      echo "  Модель:    ${model:-<не задана>}"
      echo "  Провайдер: ${provider:-<не определён>}"

      if [ -z "${model}" ]; then
        echo "  ПРОБЛЕМА: в .github/review/config.env не задан MODEL."
        problems=$((problems + 1))
      elif [ -z "${required_key}" ]; then
        echo "  Ключ не требуется: провайдер работает локально."
      elif echo "${rv_secrets}" | grep -qxF "${required_key}"; then
        echo "  Секрет ${required_key} задан — хорошо."
      else
        echo "  ПРОБЛЕМА: не задан секрет ${required_key} для модели ${model}."
        echo "  Исправить: ./manage.sh set-secret ${required_key}"
        key_url="$(
          # shellcheck source=/dev/null
          source "${review_root}/lib/provider.sh" >/dev/null 2>&1
          key_url_for "${provider}"
        )"
        echo "  Получить ключ: ${key_url}"
        problems=$((problems + 1))
      fi
    fi

    # Ключ модели в репозиториях студентов — след прежней схемы. Сейчас он
    # там не нужен и представляет риск: студент с правом write может
    # добавить свой workflow и прочитать секрет.
    local leftover_secrets="" repo
    if [ -n "${repos_for_check}" ]; then
      while IFS= read -r repo; do
        [ -z "${repo}" ] && continue
        if [ -n "$(gh secret list --repo "${ORG}/${repo}" --json name --jq '.[].name' 2>/dev/null || true)" ]; then
          leftover_secrets="${leftover_secrets}  - ${repo}"$'\n'
        fi
      done <<< "${repos_for_check}"
    fi
    if [ -n "${leftover_secrets}" ]; then
      echo
      echo "  ПРОБЛЕМА: в репозиториях студентов остались секреты:"
      echo "${leftover_secrets}" | sed '/^$/d'
      echo "  Ревью выполняется централизованно, ключ модели им больше не нужен."
      echo "  Удалить: gh secret delete <ИМЯ> --repo ${ORG}/<репозиторий>"
      problems=$((problems + 1))
    fi

    # Когда ревьюер работал в последний раз. Пустая история обычно значит,
    # что движок не раскатан (./manage.sh sync-reviewer) или выключен cron.
    local last_run
    last_run="$(gh run list --repo "${REVIEWER_REPO}" --workflow review.yml --limit 1 \
      --json createdAt,conclusion --jq '.[0] | "\(.createdAt) (\(.conclusion // "в процессе"))"' 2>/dev/null || true)"
    if [ -z "${last_run}" ] || [ "${last_run}" = "null" ]; then
      echo
      echo "  ПРОБЛЕМА: workflow review ни разу не запускался."
      echo "  Раскатайте движок: ./manage.sh sync-reviewer"
      echo "  и проверьте вручную: ./manage.sh review --dry-run"
      problems=$((problems + 1))
    else
      echo "  Последний запуск ревью: ${last_run}"
    fi
    echo
  fi


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
# Сводка по расходу бесплатных квот и состоянию курса.
#
# Только чтение: данные берутся из GitHub API (gh уже авторизован) и, если
# в окружении есть OPENROUTER_API_KEY, из OpenRouter. Внешние сервисы
# мониторинга не нужны — всё, что важно для этого проекта (минуты Actions,
# квота модели, доля неудачных ревью), доступно бесплатно.
#
# Использование: stats [--days N] [--json]
cmd_stats() {
  require_gh_auth

  local collector="${SCRIPT_DIR}/lib/collect-stats.py"
  if [ ! -f "${collector}" ]; then
    echo "Не найден ${collector}." >&2
    exit 1
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "Нужен python3 — агрегация статистики выполняется им." >&2
    exit 1
  fi

  local days=30 as_json=0 arg
  while [ $# -gt 0 ]; do
    arg="$1"
    case "${arg}" in
      --days) shift; days="${1:-30}" ;;
      --days=*) days="${arg#*=}" ;;
      --json) as_json=1 ;;
      --yes) ;;
      *) echo "Неизвестный аргумент stats: ${arg}" >&2; exit 1 ;;
    esac
    shift || true
  done

  case "${days}" in
    ''|*[!0-9]*) echo "--days ожидает число, получено: ${days}" >&2; exit 1 ;;
  esac

  local extra=()
  [ "${as_json}" -eq 1 ] && extra+=(--json)
  # Минуты ИИ-ревью расходуются в репозитории ревьюера, а не у студентов,
  # поэтому его нужно учитывать отдельной строкой.
  [ -n "${REVIEWER_REPO}" ] && extra+=(--reviewer-repo "${REVIEWER_REPO}")

  python3 "${collector}" \
    --org "${ORG}" \
    --prefix "${REPO_PREFIX}" \
    --days "${days}" \
    "${extra[@]+"${extra[@]}"}"
}

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

# Требует, чтобы был задан REVIEWER_REPO, и печатает понятную подсказку.
require_reviewer_repo() {
  if [ -z "${REVIEWER_REPO}" ]; then
    echo "Не задан REVIEWER_REPO — приватный репозиторий с workflow ревьюера." >&2
    echo "Укажите его в admin/.env, например:" >&2
    echo "  REVIEWER_REPO=rserdyukov/yapis-2026-reviewer" >&2
    echo "Как его создать и настроить — admin/SETUP.md, раздел \"Ревьюер\"." >&2
    exit 1
  fi
}

# Установка секрета с ключом API модели.
#
# Секрет кладётся ТОЛЬКО в приватный репозиторий ревьюера: именно там
# запускается ИИ-ревью. В репозитории студентов ключ не попадает, поэтому
# студент не может его прочитать, добавив свой workflow.
#
# Раньше (пока ревью шло в репозитории студента) ключ приходилось класть в
# каждый из них: organization secrets с visibility=all на плане Free для
# ПРИВАТНЫХ репозиториев создаются, но не привязываются ни к одному
# репозиторию (orgs/.../secrets/NAME/repositories -> total_count = 0), и в
# workflow приходила пустая строка. Централизованный ревьюер снял этот вопрос.
cmd_set_secret() {
  local name="" arg
  for arg in "$@"; do
    case "${arg}" in
      --yes)  ;;
      --org)
        echo "Режим --org больше не поддерживается: ключ модели хранится" >&2
        echo "в приватном репозитории ревьюера, а не в организации." >&2
        exit 1 ;;
      *)      [ -z "${name}" ] && name="${arg}" ;;
    esac
  done
  : "${name:?Укажите имя секрета, например OPENROUTER_API_KEY}"
  require_gh_auth
  require_reviewer_repo

  if ! gh repo view "${REVIEWER_REPO}" >/dev/null 2>&1; then
    echo "Репозиторий ревьюера ${REVIEWER_REPO} недоступен." >&2
    echo "Создайте его и раскатайте движок: ./manage.sh sync-reviewer" >&2
    exit 1
  fi

  echo "Секрет ${name} будет установлен в репозиторий ревьюера ${REVIEWER_REPO}."
  echo "В репозитории студентов он не попадёт: ИИ-ревью выполняется"
  echo "централизованно, и ключ модели студентам не виден."
  confirm "Продолжить?"

  local secret_value
  read -r -s -p "Введите значение секрета ${name}: " secret_value
  echo
  if [ -z "${secret_value}" ]; then
    echo "Пустое значение — отменено." >&2
    exit 1
  fi

  if ! printf '%s' "${secret_value}" | gh secret set "${name}" --repo "${REVIEWER_REPO}"; then
    echo "Не удалось установить секрет." >&2
    exit 1
  fi
  echo "Секрет ${name} установлен в ${REVIEWER_REPO}."
  echo "Проверить настройку целиком: ./manage.sh doctor"
}

# Ручной запуск ревьюера вне расписания.
#
# Полезно, когда студент ждёт ревью прямо сейчас (на занятии) или когда надо
# перепроверить один PR после правки промптов.
cmd_review() {
  local only="" dry_run=0 arg
  for arg in "$@"; do
    case "${arg}" in
      --dry-run) dry_run=1 ;;
      --yes)     ;;
      *)         [ -z "${only}" ] && only="${arg}" ;;
    esac
  done
  require_gh_auth
  require_reviewer_repo

  # Фамилию принимаем наравне с именем репозитория: ./manage.sh review ivanov
  if [ -n "${only}" ] && [[ "${only}" != "${REPO_PREFIX}"* ]]; then
    only="${REPO_PREFIX}${only}"
  fi

  if [ -n "${only}" ]; then
    echo "Будет запущено ревью только для: ${only}"
  else
    echo "Будет запущен полный обход репозиториев ${ORG}."
  fi
  [ "${dry_run}" -eq 1 ] && echo "Режим dry-run: комментарии публиковаться не будут."
  confirm "Запустить workflow review в ${REVIEWER_REPO}?"

  local args=(workflow run review.yml --repo "${REVIEWER_REPO}")
  [ -n "${only}" ] && args+=(-f "only=${only}")
  [ "${dry_run}" -eq 1 ] && args+=(-f "dry_run=true")

  if ! gh "${args[@]}"; then
    echo "Не удалось запустить workflow." >&2
    exit 1
  fi
  echo "Запущено. Посмотреть ход выполнения:"
  echo "  gh run watch --repo ${REVIEWER_REPO}"
  echo "  gh run list --repo ${REVIEWER_REPO} --workflow review.yml --limit 5"
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

# Манифесты состава репозиториев (единый источник правды, см. сами файлы).
TEMPLATE_MANIFEST="${SCRIPT_DIR}/template-manifest.txt"
REVIEWER_MANIFEST="${SCRIPT_DIR}/reviewer-manifest.txt"

# Разбирает манифест и печатает строки "источник<TAB>назначение".
# Строки !EXCLUDE и !STUDENT_KEEP отдаются отдельными функциями.
#   parse_manifest [путь к манифесту]
parse_manifest() {
  awk -F'->' '
    /^[[:space:]]*#/    { next }
    /^[[:space:]]*$/    { next }
    /^[[:space:]]*!/    { next }
    NF == 2 {
      src = $1; dst = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", src)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", dst)
      if (src != "" && dst != "") print src "\t" dst
    }
  ' "${1:-${TEMPLATE_MANIFEST}}"
}

# Печатает пути, которые не должны попадать в целевой репозиторий.
parse_excludes() {
  awk '/^[[:space:]]*!EXCLUDE[[:space:]]+/ { $1=""; sub(/^[[:space:]]+/,""); print }' \
    "${1:-${TEMPLATE_MANIFEST}}"
}

# Совместимость с прежними именами (используются в тестах и документации).
parse_template_manifest() { parse_manifest "${TEMPLATE_MANIFEST}"; }
parse_template_excludes()  { parse_excludes "${TEMPLATE_MANIFEST}"; }

# Печатает пути (в терминах шаблона), которые нельзя перезаписывать в
# репозиториях студентов: там уже их собственная работа.
parse_student_keep() {
  awk '/^[[:space:]]*!STUDENT_KEEP[[:space:]]+/ { $1=""; sub(/^[[:space:]]+/,""); print }' \
    "${TEMPLATE_MANIFEST}"
}

# Печатает пути, которые sync-workflow должен УДАЛИТЬ из репозиториев
# студентов (остатки прежней схемы, см. комментарий в манифесте).
parse_student_remove() {
  awk '/^[[:space:]]*!STUDENT_REMOVE[[:space:]]+/ { $1=""; sub(/^[[:space:]]+/,""); print }' \
    "${TEMPLATE_MANIFEST}"
}

# Пути в шаблоне, которые sync-workflow раскатывает студентам:
# все назначения из манифеста, кроме перечисленных в !STUDENT_KEEP.
template_paths_for_students() {
  local keep dst
  keep="$(parse_student_keep)"
  while IFS=$'\t' read -r _src dst; do
    [ -z "${dst}" ] && continue
    if [ -n "${keep}" ] && echo "${keep}" | grep -qxF "${dst}"; then
      continue
    fi
    echo "${dst}"
  done < <(parse_manifest "${TEMPLATE_MANIFEST}")
}

# Общая часть sync-template и sync-reviewer: клонирует целевой репозиторий,
# копирует в него пути по манифесту, убирает исключения, коммитит и пушит.
#   sync_repo_from_manifest <манифест> <owner/repo> <текст коммита>
sync_repo_from_manifest() {
  local manifest="${1:?manifest}" target="${2:?target repo}" message="${3:?commit message}"
  local src_root
  src_root="$(cd "${SCRIPT_DIR}/.." && pwd)"

  if [ ! -f "${manifest}" ]; then
    echo "Не найден манифест ${manifest}." >&2
    exit 1
  fi

  echo "Источник:    ${src_root}"
  echo "Назначение:  ${target}"
  echo
  echo "Будет скопировано (по ${manifest}):"
  local src dst
  while IFS=$'\t' read -r src dst; do
    [ -z "${src}" ] && continue
    if [ ! -e "${src_root}/${src}" ]; then
      echo "  ОШИБКА: нет ${src}" >&2
      exit 1
    fi
    echo "  ${src} -> ${dst}"
  done < <(parse_manifest "${manifest}")

  local excludes
  excludes="$(parse_excludes "${manifest}")"
  if [ -n "${excludes}" ]; then
    echo
    echo "Не попадёт в ${target}:"
    echo "${excludes}" | sed 's/^/  /'
  fi
  echo
  confirm "Продолжить?"

  SYNC_DIR="$(mktemp -d)"
  trap 'rm -rf "${SYNC_DIR:-}"' EXIT
  local work="${SYNC_DIR}/target"

  echo "Клонирую ${target}..."
  gh repo clone "${target}" "${work}" -- --quiet

  while IFS=$'\t' read -r src dst; do
    [ -z "${src}" ] && continue
    mkdir -p "$(dirname "${work}/${dst}")"
    if [ -d "${src_root}/${src}" ]; then
      rm -rf "${work:?}/${dst}"
      cp -R "${src_root}/${src}" "${work}/${dst}"
    else
      cp "${src_root}/${src}" "${work}/${dst}"
    fi
  done < <(parse_manifest "${manifest}")

  local ex
  while IFS= read -r ex; do
    [ -z "${ex}" ] && continue
    rm -rf "${work:?}/${ex}"
  done <<< "${excludes}"

  find "${work}" -name '.DS_Store' -delete 2>/dev/null || true

  (
    cd "${work}"
    git add -A
    if git diff --cached --quiet; then
      echo "Репозиторий ${target} уже актуален, изменений нет."
      exit 0
    fi

    echo
    echo "Изменения:"
    git diff --cached --stat | tail -n 20
    echo

    git -c user.name="${GIT_AUTHOR_NAME:-yapis-admin}" \
        -c user.email="${GIT_AUTHOR_EMAIL:-yapis-admin@users.noreply.github.com}" \
        commit -qm "${message}"
    git push -q origin HEAD
    echo "Репозиторий ${target} обновлён и запушен."
  )
}

# Раскатка: этот репозиторий (источник) -> приватный репозиторий ревьюера.
#
# Именно там выполняется ИИ-ревью, поэтому после любой правки промптов,
# проверок или скриптов ревьюера нужно запускать эту команду — иначе
# студенты продолжат проверяться старой версией.
cmd_sync_reviewer() {
  require_gh_auth
  require_reviewer_repo

  if ! gh repo view "${REVIEWER_REPO}" >/dev/null 2>&1; then
    echo "Репозиторий ревьюера ${REVIEWER_REPO} не найден." >&2
    echo "Создайте приватный репозиторий и повторите:" >&2
    echo "  gh repo create ${REVIEWER_REPO} --private --add-readme" >&2
    exit 1
  fi

  # Приватность проверяем каждый раз: в этом репозитории лежат ключ модели и
  # приватный ключ GitHub App, публичным он быть не должен ни при каких
  # обстоятельствах.
  local visibility
  visibility="$(gh repo view "${REVIEWER_REPO}" --json visibility --jq '.visibility' 2>/dev/null || echo "")"
  if [ "${visibility}" != "PRIVATE" ]; then
    echo "КРИТИЧНО: репозиторий ревьюера ${REVIEWER_REPO} не приватный (${visibility:-неизвестно})." >&2
    echo "Там хранятся секреты и логи с кодом студентов. Исправьте:" >&2
    echo "  gh repo edit ${REVIEWER_REPO} --visibility private" >&2
    exit 1
  fi

  sync_repo_from_manifest "${REVIEWER_MANIFEST}" "${REVIEWER_REPO}" \
    "sync: обновить движок ревью из репозитория курса"

  echo
  echo "Дальше при необходимости:"
  echo "  ./manage.sh review --dry-run    — проверить, что ревьюер видит PR"
  echo "  ./manage.sh doctor              — проверить секреты и настройки"
}

# Раскатка: этот репозиторий (источник) -> template-репозиторий.
#
# Порядок работы с изменениями:
#   1. правки вносятся ТОЛЬКО здесь, в репозитории курса;
#   2. ./manage.sh sync-reviewer  — движок ревью -> репозиторий ревьюера;
#   3. ./manage.sh sync-template  — документы студента -> шаблон;
#   4. ./manage.sh sync-workflow  — шаблон -> репозитории студентов.
#
# Шаг 3 отделён от шага 4 намеренно: между ними шаблон можно просмотреть
# глазами, а новые репозитории студентов сразу создаются из свежего шаблона.
cmd_sync_template() {
  require_gh_auth

  echo "В шаблоне README.md будет ПЕРЕЗАПИСАН заготовкой. На репозитории"
  echo "студентов это не влияет: sync-workflow их README не трогает."
  echo
  sync_repo_from_manifest "${TEMPLATE_MANIFEST}" "${TEMPLATE_REPO}" \
    "sync: обновить документы и инструменты студента из репозитория курса"

  echo "Дальше: ./manage.sh sync-workflow — раскатать по репозиториям студентов."
}

cmd_sync_workflow() {
  require_gh_auth

  local repos
  repos="$(list_student_repos)"

  if [ -z "${repos}" ]; then
    echo "Нет репозиториев студентов в ${ORG} (префикс ${REPO_PREFIX})." >&2
    exit 0
  fi

  if [ ! -f "${TEMPLATE_MANIFEST}" ]; then
    echo "Не найден манифест ${TEMPLATE_MANIFEST}." >&2
    exit 1
  fi

  # Что раскатывать — берём из манифеста, а не из захардкоженного списка:
  # иначе он разъедется с sync-template при добавлении новых файлов.
  local sync_paths keep_paths remove_paths
  sync_paths="$(template_paths_for_students)"
  keep_paths="$(parse_student_keep)"
  remove_paths="$(parse_student_remove)"

  if [ -z "${sync_paths}" ]; then
    echo "Манифест не содержит путей для раскатки студентам." >&2
    exit 1
  fi

  echo "Будут обновлены (из шаблона ${TEMPLATE_REPO}):"
  echo "${sync_paths}" | sed 's/^/  - /'
  if [ -n "${remove_paths}" ]; then
    echo
    echo "Будут УДАЛЕНЫ (остатки прежней схемы ревью):"
    echo "${remove_paths}" | sed 's/^/  - /'
  fi
  if [ -n "${keep_paths}" ]; then
    echo
    echo "НЕ будут тронуты (там работа студента):"
    echo "${keep_paths}" | sed 's/^/  - /'
  fi
  echo
  echo "В следующих репозиториях, путём открытия PR из ветки"
  echo "ci/sync-review-tooling в каждом (изменения не мержатся автоматически):"
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
      # -B, а не -b: ветка могла остаться от прошлого прогона (например,
      # если PR не смержили). Тогда `-b` падает с "already exists", а push —
      # с "non-fast-forward". Пересоздаём её от свежего main.
      git checkout -q -B ci/sync-review-tooling

      local p
      while IFS= read -r p; do
        [ -z "${p}" ] && continue
        [ -e "${tmp_dir}/template/${p}" ] || continue
        mkdir -p "$(dirname "./${p}")"
        if [ -d "${tmp_dir}/template/${p}" ]; then
          rm -rf "./${p:?}"
          cp -R "${tmp_dir}/template/${p}" "./${p}"
        else
          cp "${tmp_dir}/template/${p}" "./${p}"
        fi
        git add -A "./${p}"
      done <<< "${sync_paths}"

      # Удаляем пути, помеченные !STUDENT_REMOVE. git rm -r --ignore-unmatch
      # не падает, если файла уже нет (студент смержил прошлый PR).
      local rm_path
      while IFS= read -r rm_path; do
        [ -z "${rm_path}" ] && continue
        git rm -r -q --ignore-unmatch -- "./${rm_path}" 2>/dev/null || true
        rm -rf "./${rm_path:?}"
      done <<< "${remove_paths}"
      git add -A

      # Индексируем ДО проверки изменений: `git diff` не замечает новые
      # (untracked) файлы, поэтому при первом развёртывании инфраструктуры
      # проверка ложно сообщала бы "изменений нет".
      if git diff --cached --quiet; then
        echo "  Изменений нет, пропускаю."
        exit 0
      fi

      echo "  Изменения:"
      git diff --cached --name-only | sed 's/^/    /'

      git commit -m "ci: обновить инфраструктуру и документы курса из шаблона" --quiet
      # --force-with-lease: ветка служебная и пересоздаётся от main при каждом
      # прогоне. Обычный push отклоняется как non-fast-forward, если PR с
      # прошлого раза остался незакрытым.
      git push -u origin ci/sync-review-tooling --force-with-lease --quiet

      # PR мог остаться открытым с прошлого прогона — тогда он уже указывает
      # на обновлённую ветку, создавать второй не нужно.
      local existing
      existing="$(gh pr list --head ci/sync-review-tooling --state open \
        --json number --jq '.[0].number // empty' 2>/dev/null || true)"
      if [ -n "${existing}" ]; then
        echo "  Обновлён существующий PR #${existing}."
        exit 0
      fi

      gh pr create \
        --title "ci: обновить документы и инструменты курса" \
        --body "Автоматическое обновление из шаблона курса: документы практикума (\`TASK.md\`, \`GUIDE.md\`), скрипт локальной проверки (\`review-local.sh\`) и служебный workflow.

Ваш \`README.md\` не затронут — там описание вашего варианта.

Слейте PR после просмотра. Автоматическое ИИ-ревью этот PR не проверяет: ветка \`ci/sync-review-tooling\` исключена." \
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
    stats)             cmd_stats "$@" ;;
    audit)             cmd_audit "$@" ;;
    list)             cmd_list "$@" ;;
    create)            cmd_create "$@" ;;
    invite)            cmd_invite "$@" ;;
    set-secret)         cmd_set_secret "$@" ;;
    status)            cmd_status "$@" ;;
    review)             cmd_review "$@" ;;
    sync-reviewer)      cmd_sync_reviewer "$@" ;;
    sync-template)      cmd_sync_template "$@" ;;
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
