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
# Группы студентов живут в ОДНОЙ организации и различаются частью имени
# репозитория (yapis-2026-g1-ivanov, yapis-2026-g2-petrov). Любую команду
# можно сузить до одной группы флагом --group:
#
#   ./manage.sh --group g1 status          только группа g1
#   ./manage.sh --group g1 create ivanov   создаст yapis-2026-g1-ivanov
#   ./manage.sh status                     все группы сразу
#
# Отдельные организации под группы не нужны: изоляция студентов держится на
# base permissions = none и статусе outside collaborator (работает внутри
# одной организации), минуты Actions расходуются в репозитории ревьюера, а
# лимит OpenRouter действует на аккаунт, а не на ключ.
#
# Использование:
#   ./manage.sh [--group <группа>] <команда> [аргументы]
#
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
#   ./manage.sh enroll <students.csv> [--apply]        — завести репозитории всей группы
#                                                          по списку (ФИО,Группа,Github);
#                                                          без --apply только показывает план,
#                                                          безопасна для повторных запусков
#   ./manage.sh invite <фамилия> <github-login>        — пригласить/добавить коллаборатора
#                                                          в уже существующий репозиторий
#   ./manage.sh set-secret <NAME>                      — положить секрет (ключ API модели)
#                                                          в репозиторий ревьюера
#   ./manage.sh status [<фамилия>]                     — сводка по PR/веткам во всех репозиториях
#                                                          студентов (или по одному, если указана фамилия)
#   ./manage.sh prs [<фамилия>]                        — все открытые PR одной таблицей: ссылка,
#                                                          дата создания и дата последнего коммита,
#                                                          число комментариев ИИ-ревьюера. Сортировка:
#                                                          группа, фамилия, дата коммита (старые сверху)
#   ./manage.sh review [<репозиторий>[:<PR>]] [--dry-run] [--force]
#                                                        — запустить ревьюер вне расписания;
#                                                          --force перепроверяет уже
#                                                          проверенный коммит (после сбоя)
#   ./manage.sh assign-reviewers [<репозиторий>[:<PR>]] [--dry-run]
#                                                        — назначить преподавателя ревьюером
#                                                          в открытых PR (кто какую группу
#                                                          ведёт — TEACHER_BY_GROUP в
#                                                          .github/review/config.env);
#                                                          в штатном режиме это делает
#                                                          ревьюер по расписанию
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
# Команды doctor, list, status, prs и audit только читают данные.
# assign-reviewers подтверждения не требует: она идемпотентна и обратима
# (лишний review request снимается кнопкой в PR), а её штатный вызов —
# автоматический, из ревьюера по расписанию. Для проверки есть --dry-run.
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
# Фильтр по группе. Группы живут в ОДНОЙ организации и различаются частью
# имени репозитория: yapis-2026-g1-ivanov, yapis-2026-g2-petrov. Разделять
# группы по разным организациям смысла нет: изоляция студентов держится на
# base permissions + outside collaborators и работает внутри одной
# организации, а минуты Actions и квота модели теперь общие в любом случае
# (ревью выполняется централизованно, лимит OpenRouter — на аккаунт).
#
# Пустое значение = все группы. См. также GROUP в .env.
GROUP="${GROUP:-}"

_prev_arg=""
for arg in "$@"; do
  case "${arg}" in
    --yes)     ASSUME_YES=1 ;;
    --group=*) GROUP="${arg#--group=}" ;;
  esac
  [ "${_prev_arg}" = "--group" ] && GROUP="${arg}"
  _prev_arg="${arg}"
done
unset _prev_arg

# Санитизация: значение уходит в имена репозиториев и в grep-шаблон.
GROUP="$(printf '%s' "${GROUP}" | tr -cd 'A-Za-z0-9._-')"

# Полный префикс с учётом группы. Именно он определяет, какие репозитории
# считаются «своими» для всех команд.
group_prefix() {
  printf '%s%s' "${REPO_PREFIX}" "${GROUP:+${GROUP}-}"
}

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
  local prefix
  prefix="$(group_prefix)"
  gh repo list "${ORG}" --limit 500 --json name \
    --jq ".[] | select(.name | startswith(\"${prefix}\")) | .name" \
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

# Имя репозитория студента. Если задана группа и фамилия ещё не содержит
# её префикс — подставляем: ./manage.sh --group g1 create ivanov создаёт
# yapis-2026-g1-ivanov.
repo_for_student() {
  local student="$1"
  case "${student}" in
    "${REPO_PREFIX}"*) echo "${student}"; return 0 ;;
  esac
  if [ -n "${GROUP}" ]; then
    case "${student}" in
      "${GROUP}-"*) : ;;
      *) student="${GROUP}-${student}" ;;
    esac
  fi
  echo "${REPO_PREFIX}${student}"
}

cmd_list() {
  require_gh_auth
  echo "Организация: ${ORG}"
  if [ -n "${GROUP}" ]; then
    echo "Группа: ${GROUP}"
  fi
  echo "Репозитории студентов (префикс $(group_prefix)):"
  local repos
  repos="$(list_student_repos)"
  if [ -z "${repos}" ]; then
    echo "  (ничего не найдено)"
    [ -n "${GROUP}" ] && echo "  Проверьте имя группы: ./manage.sh list — без фильтра."
    return 0
  fi
  echo "${repos}" | sed 's/^/  - /'
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
    echo "  Преподаватель назначается ревьюером не через CODEOWNERS, а ревьюером"
    echo "  по расписанию (см. TEACHER_BY_GROUP ниже и ./manage.sh assign-reviewers)."
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

    # Ключ модели. Курс работает с одним провайдером — OpenRouter, поэтому
    # имя секрета фиксировано. Без него ревью падает на последнем шаге, и
    # студент узнаёт об этом из комментария бота о технической ошибке.
    local review_root="${SCRIPT_DIR}/../.github/review"
    if [ ! -f "${review_root}/config.env" ]; then
      echo "  Не найден config.env — проверка модели пропущена."
    else
      local model
      # Читаем в субшелле: config.env определяет MODEL и не должен
      # перетирать переменные этого скрипта.
      model="$(
        # shellcheck source=/dev/null
        source "${review_root}/config.env" >/dev/null 2>&1
        printf '%s' "${MODEL:-}"
      )"

      echo "  Модель: ${model:-<не задана>}"

      if [ -z "${model}" ]; then
        echo "  ПРОБЛЕМА: в .github/review/config.env не задан MODEL."
        problems=$((problems + 1))
      elif [ "${model#openrouter/}" = "${model}" ]; then
        # Ревьюер умеет работать только с OpenRouter: ключ у него один.
        echo "  ПРОБЛЕМА: MODEL должен начинаться с openrouter/."
        echo "  Курс использует единственного провайдера — OpenRouter."
        problems=$((problems + 1))
      fi

      if echo "${rv_secrets}" | grep -qxF "OPENROUTER_API_KEY"; then
        echo "  Секрет OPENROUTER_API_KEY задан — хорошо."
      else
        echo "  ПРОБЛЕМА: не задан секрет OPENROUTER_API_KEY."
        echo "  Исправить: ./manage.sh set-secret OPENROUTER_API_KEY"
        echo "  Получить ключ: https://openrouter.ai/keys"
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
    # jq для пустого массива возвращает строку "null (...)", а не пусто:
    # .[0] даёт null, и интерполяция превращает его в текст. Поэтому
    # фильтруем пустой список явно через empty.
    last_run="$(gh run list --repo "${REVIEWER_REPO}" --workflow review.yml --limit 1 \
      --json createdAt,conclusion \
      --jq 'if length == 0 then empty else .[0] | "\(.createdAt) (\(.conclusion // "в процессе"))" end' 2>/dev/null || true)"
    if [ -z "${last_run}" ]; then
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


  # === Назначение преподавателя ревьюером ===
  #
  # Две реальные причины, по которым работа не попадёт в очередь
  # преподавателя: группа отсутствует в TEACHER_BY_GROUP и у назначенного
  # логина нет доступа к репозиториям (GitHub отклоняет review request от
  # не-коллаборатора). Обе видны только в логе ревьюера, поэтому проверяем.
  echo "=== Назначение преподавателя ревьюером PR ==="
  local review_cfg="${SCRIPT_DIR}/../.github/review/config.env"
  if [ ! -f "${review_cfg}" ]; then
    echo "  Не найден .github/review/config.env — проверка пропущена."
  else
    local teacher_map teacher_default
    teacher_map="$(
      # shellcheck source=/dev/null
      source "${review_cfg}" >/dev/null 2>&1
      printf '%s' "${TEACHER_BY_GROUP:-}"
    )"
    teacher_default="$(
      # shellcheck source=/dev/null
      source "${review_cfg}" >/dev/null 2>&1
      printf '%s' "${TEACHER_DEFAULT:-}"
    )"

    if [ -z "${teacher_map}" ] && [ -z "${teacher_default}" ]; then
      echo "  ПРОБЛЕМА: не задан ни TEACHER_BY_GROUP, ни TEACHER_DEFAULT."
      echo "  PR студентов не будут попадать в очередь преподавателя."
      echo "  Заполните .github/review/config.env и выполните ./manage.sh sync-reviewer"
      problems=$((problems + 1))
    else
      echo "  Преподаватели по группам: ${teacher_map:-<не задано>}"
      [ -n "${teacher_default}" ] && echo "  Для прочих групп: ${teacher_default}"

      # Группы, фактически присутствующие в организации. Правило разбора
      # имени обязано СОВПАДАТЬ с group_of_repo в
      # reviewer/lib/assign-reviewers.sh, иначе doctor отчитается об
      # успехе для группы, которую скрипт назначения молча пропустит.
      local groups_present="" repo_name rest
      if [ -n "${repos_for_check}" ]; then
        while IFS= read -r repo_name; do
          [ -z "${repo_name}" ] && continue
          rest="${repo_name#"${REPO_PREFIX}"}"
          case "${rest}" in
            [a-z][0-9]-*|[a-z][0-9][0-9]-*|[0-9]*-*)
              groups_present="${groups_present}${rest%%-*}"$'\n' ;;
          esac
        done <<< "${repos_for_check}"
        groups_present="$(printf '%s' "${groups_present}" | sort -u | sed '/^$/d')"
      fi

      local grp mapped pair uncovered=""
      while IFS= read -r grp; do
        [ -z "${grp}" ] && continue
        mapped=""
        for pair in ${teacher_map}; do
          case "${pair}" in "${grp}:"*) mapped="${pair#*:}" ;; esac
        done
        [ -z "${mapped}" ] && mapped="${teacher_default}"
        if [ -z "${mapped}" ]; then
          uncovered="${uncovered} ${grp}"
        fi
      done <<< "${groups_present}"

      if [ -n "${uncovered}" ]; then
        echo "  ПРОБЛЕМА: для групп${uncovered} преподаватель не задан."
        echo "  Их PR останутся без ревьюера. Добавьте в TEACHER_BY_GROUP."
        problems=$((problems + 1))
      fi

      # Репозитории, из имени которых группа не читается вовсе: скрипт
      # назначения их пропустит, и работы не попадут ни к кому.
      local unparsed=""
      while IFS= read -r repo_name; do
        [ -z "${repo_name}" ] && continue
        rest="${repo_name#"${REPO_PREFIX}"}"
        case "${rest}" in
          [a-z][0-9]-*|[a-z][0-9][0-9]-*|[0-9]*-*) ;;
          *) unparsed="${unparsed}  - ${repo_name}"$'\n' ;;
        esac
      done <<< "${repos_for_check}"
      # Без TEACHER_DEFAULT такие репозитории остаются без ревьюера; с ним
      # они штатно обслуживаются (схема курса с одним преподавателем).
      if [ -n "${unparsed}" ] && [ -z "${teacher_default}" ]; then
        echo "  ПРОБЛЕМА: из имени этих репозиториев не читается группа:"
        printf '%s' "${unparsed}"
        echo "  Их PR останутся без ревьюера. Либо приведите имя к схеме"
        echo "  <префикс><группа>-<фамилия>, либо задайте TEACHER_DEFAULT"
        echo "  в .github/review/config.env."
        problems=$((problems + 1))
      fi

      # Доступ назначаемых преподавателей к репозиториям. Проверяем на одном
      # репозитории каждой группы: права выдаются единообразно при enroll.
      local checked_logins="" login sample_repo perm
      while IFS= read -r grp; do
        [ -z "${grp}" ] && continue
        login=""
        for pair in ${teacher_map}; do
          case "${pair}" in "${grp}:"*) login="${pair#*:}" ;; esac
        done
        [ -z "${login}" ] && login="${teacher_default}"
        [ -z "${login}" ] && continue
        case " ${checked_logins} " in *" ${login} "*) continue ;; esac
        checked_logins="${checked_logins} ${login}"

        sample_repo="$(printf '%s\n' "${repos_for_check}" \
          | grep -m1 -E "^${REPO_PREFIX}${grp}-" || true)"
        [ -z "${sample_repo}" ] && continue

        perm="$(gh api "repos/${ORG}/${sample_repo}/collaborators/${login}/permission" \
          --jq '.permission' 2>/dev/null || echo "none")"
        case "${perm}" in
          admin|maintain|write)
            echo "  ${login}: доступ к репозиториям есть (${perm}) — хорошо." ;;
          *)
            echo "  ПРОБЛЕМА: у ${login} нет доступа к ${sample_repo} (${perm})."
            echo "  GitHub отклоняет запрос ревью у не-коллаборатора, и PR"
            echo "  группы ${grp} останутся без ревьюера."
            problems=$((problems + 1)) ;;
        esac
      done <<< "${groups_present}"
    fi
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

  # Ревьюер читает только OPENROUTER_API_KEY (единственный провайдер курса)
  # и APP_PRIVATE_KEY. Секрет с другим именем создастся, но останется
  # неиспользованным — об этом лучше предупредить сразу, чем искать потом,
  # почему ревью падает с «не задан секрет».
  case "${name}" in
    OPENROUTER_API_KEY|APP_PRIVATE_KEY) ;;
    *)
      echo "ВНИМАНИЕ: ревьюер использует только OPENROUTER_API_KEY и APP_PRIVATE_KEY."
      echo "Секрет ${name} будет создан, но никем не читается."
      ;;
  esac

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

# Массовое заведение репозиториев по списку студентов (CSV).
#
# Команда идемпотентна и рассчитана на многократный запуск: список
# заполняется постепенно, логины GitHub появляются не сразу. Каждый прогон
# доделывает недостающее и не трогает уже существующие репозитории.
# Подробности — admin/lib/enroll.py.
cmd_enroll() {
  local csv="" group_arg="" apply=0 as_json=0 arg prev=""
  for arg in "$@"; do
    case "${arg}" in
      --apply)   apply=1 ;;
      --json)    as_json=1 ;;
      --yes)     ;;
      --csv)     ;;                      # значение заберём по prev
      --csv=*)   csv="${arg#--csv=}" ;;
      *)
        if [ "${prev}" = "--csv" ]; then
          csv="${arg}"
        elif [ -z "${csv}" ]; then
          csv="${arg}"                   # позиционный путь к файлу
        fi
        ;;
    esac
    prev="${arg}"
  done

  : "${csv:?Укажите файл со списком: ./manage.sh enroll students.csv}"
  if [ ! -f "${csv}" ]; then
    echo "Файл со списком не найден: ${csv}" >&2
    exit 1
  fi

  local enroller="${SCRIPT_DIR}/lib/enroll.py"
  if [ ! -f "${enroller}" ]; then
    echo "Не найден ${enroller}." >&2
    exit 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Нужен python3." >&2
    exit 1
  fi

  require_gh_auth

  # Фильтр --group здесь означает номер группы из таблицы (321701).
  [ -n "${GROUP}" ] && group_arg="${GROUP}"

  local extra=()
  [ -n "${group_arg}" ] && extra+=(--group "${group_arg}")
  [ "${as_json}" -eq 1 ] && extra+=(--json)

  if [ "${apply}" -eq 0 ]; then
    # Сухой прогон: только план, без подтверждения — ничего не меняется.
    python3 "${enroller}" \
      --org "${ORG}" --prefix "${REPO_PREFIX}" --template "${TEMPLATE_REPO}" \
      --csv "${csv}" "${extra[@]+"${extra[@]}"}"
    return $?
  fi

  # Показываем план и спрашиваем подтверждение перед изменениями.
  python3 "${enroller}" \
    --org "${ORG}" --prefix "${REPO_PREFIX}" --template "${TEMPLATE_REPO}" \
    --csv "${csv}" "${extra[@]+"${extra[@]}"}" || return $?
  echo
  confirm "Выполнить перечисленные действия?"

  python3 "${enroller}" \
    --org "${ORG}" --prefix "${REPO_PREFIX}" --template "${TEMPLATE_REPO}" \
    --csv "${csv}" "${extra[@]+"${extra[@]}"}" --apply
}

# Ручной запуск ревьюера вне расписания.
#
# Полезно, когда студент ждёт ревью прямо сейчас (на занятии) или когда надо
# перепроверить один PR после правки промптов.
cmd_review() {
  local only="" dry_run=0 force=0 arg
  for arg in "$@"; do
    case "${arg}" in
      --dry-run) dry_run=1 ;;
      --force)   force=1 ;;
      --yes)     ;;
      *)         [ -z "${only}" ] && only="${arg}" ;;
    esac
  done

  # Повтор всех PR разом сжёг бы дневной лимит курса.
  if [ "${force}" -eq 1 ] && [ -z "${only}" ]; then
    echo "--force требует указать репозиторий: ./manage.sh review ivanov --force" >&2
    exit 1
  fi
  require_gh_auth
  require_reviewer_repo

  # Фамилию принимаем наравне с именем репозитория:
  #   ./manage.sh review ivanov              -> yapis-2026-ivanov
  #   ./manage.sh --group g1 review ivanov   -> yapis-2026-g1-ivanov
  #   ./manage.sh review yapis-2026-g1-ivanov:4
  if [ -n "${only}" ]; then
    local only_repo="${only%%:*}" only_pr=""
    case "${only}" in *:*) only_pr="${only#*:}" ;; esac
    only_repo="$(repo_for_student "${only_repo}")"
    only="${only_repo}${only_pr:+:${only_pr}}"
  fi

  if [ -n "${only}" ]; then
    echo "Будет запущено ревью только для: ${only}"
  elif [ -n "${GROUP}" ]; then
    echo "Будет запущен обход репозиториев группы ${GROUP} в ${ORG}."
  else
    echo "Будет запущен полный обход репозиториев ${ORG}."
  fi
  [ "${dry_run}" -eq 1 ] && echo "Режим dry-run: комментарии публиковаться не будут."
  [ "${force}" -eq 1 ] && echo "Режим force: отметка об уже проверенном коммите игнорируется."
  confirm "Запустить workflow review в ${REVIEWER_REPO}?"

  local args=(workflow run review.yml --repo "${REVIEWER_REPO}")
  [ -n "${only}" ] && args+=(-f "only=${only}")
  # Ревьюер фильтрует репозитории тем же префиксом, что и локальные команды.
  [ -n "${GROUP}" ] && args+=(-f "prefix=$(group_prefix)")
  [ "${dry_run}" -eq 1 ] && args+=(-f "dry_run=true")
  [ "${force}" -eq 1 ] && args+=(-f "force=true")

  if ! gh "${args[@]}"; then
    echo "Не удалось запустить workflow." >&2
    exit 1
  fi
  echo "Запущено. Посмотреть ход выполнения:"
  echo "  gh run watch --repo ${REVIEWER_REPO}"
  echo "  gh run list --repo ${REVIEWER_REPO} --workflow review.yml --limit 5"
}

# Назначить преподавателя ревьюером в открытых PR — локально, своим токеном.
#
# В штатном режиме это делает ревьюер по расписанию (job assign-reviewers в
# reviewer/workflow/review.yml). Команда нужна, когда результат нужен сразу:
# после заведения новой группы, правки TEACHER_BY_GROUP или разбора PR,
# который почему-то не попал в очередь.
#
# Запускается напрямую, а не через workflow_dispatch: преподаватель и так
# админ во всех репозиториях студентов, лишний прогон Actions не нужен.
cmd_assign_reviewers() {
  local only="" dry_run=0 arg
  for arg in "$@"; do
    case "${arg}" in
      --dry-run) dry_run=1 ;;
      --yes)     ;;
      *)         [ -z "${only}" ] && only="${arg}" ;;
    esac
  done

  require_gh_auth

  local script="${SCRIPT_DIR}/../reviewer/lib/assign-reviewers.sh"
  if [ ! -f "${script}" ]; then
    echo "Не найден ${script}." >&2
    exit 1
  fi

  # Фамилию принимаем наравне с именем репозитория — как в cmd_review.
  if [ -n "${only}" ]; then
    local only_repo="${only%%:*}" only_pr=""
    case "${only}" in *:*) only_pr="${only#*:}" ;; esac
    only_repo="$(repo_for_student "${only_repo}")"
    only="${only_repo}${only_pr:+:${only_pr}}"
  fi

  local args=("${ORG}" "$(group_prefix)")
  [ -n "${only}" ] && args+=(--only "${only}")
  [ "${dry_run}" -eq 1 ] && args+=(--dry-run)

  bash "${script}" "${args[@]}"
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

# Маркеры комментариев бота. Единственный источник правды —
# .github/review/messages.env: по этим же строкам ревьюер считает свои
# лимиты (reviewer/lib/discover.sh). Дублировать их здесь нельзя — при
# правке messages.env команда prs молча начала бы показывать нули.
#
# Читаем в субшелле: messages.env — обычный bash-файл, и его переменные
# не должны перетирать переменные этого скрипта.
load_review_markers() {
  local messages="${SCRIPT_DIR}/../.github/review/messages.env"
  if [ ! -f "${messages}" ]; then
    echo "Не найден ${messages} — без него не отличить комментарии бота." >&2
    exit 1
  fi
  MARKER_REVIEW="$(
    # shellcheck source=/dev/null
    source "${messages}" >/dev/null 2>&1
    printf '%s' "${MARKER_REVIEW:-}"
  )"
  MARKER_SKIPPED="$(
    # shellcheck source=/dev/null
    source "${messages}" >/dev/null 2>&1
    printf '%s' "${MARKER_SKIPPED:-}"
  )"
  MARKER_FAILED="$(
    # shellcheck source=/dev/null
    source "${messages}" >/dev/null 2>&1
    printf '%s' "${MARKER_FAILED:-}"
  )"
  if [ -z "${MARKER_REVIEW}" ] || [ -z "${MARKER_SKIPPED}" ] || [ -z "${MARKER_FAILED}" ]; then
    echo "В ${messages} не заданы MARKER_REVIEW/MARKER_SKIPPED/MARKER_FAILED." >&2
    exit 1
  fi
}

# Группа из имени репозитория: yapis-2026-g1-ivanov -> g1.
# Правило обязано СОВПАДАТЬ с group_of_repo в
# reviewer/lib/assign-reviewers.sh и с разбором в discover.sh: первый
# сегмент считается группой, только если похож на её идентификатор
# (g1, 2, 321701). Иначе двойная фамилия petrov-sidorov дала бы группу
# "petrov", и список разъехался бы с очередью ревью.
group_of_repo() {
  local rest="${1#"${REPO_PREFIX}"}"
  case "${rest}" in
    [a-z][0-9]-*|[a-z][0-9][0-9]-*|[0-9]*-*) printf '%s' "${rest%%-*}" ;;
    *) printf '%s' "" ;;
  esac
}

# Фамилия студента из имени репозитория: yapis-2026-g1-ivanov -> ivanov.
# Отрезаем префикс курса и затем префикс группы — по тому же правилу.
student_of_repo() {
  local rest="${1#"${REPO_PREFIX}"}"
  case "${rest}" in
    [a-z][0-9]-*|[a-z][0-9][0-9]-*|[0-9]*-*) printf '%s' "${rest#*-}" ;;
    *) printf '%s' "${rest}" ;;
  esac
}

# Все открытые PR курса одним списком, отсортированные по группе, фамилии и
# дате последнего коммита (старые сверху).
#
# ЗАЧЕМ ОТДЕЛЬНО ОТ status. Команда status печатает секции "=== репозиторий
# ===" и отвечает на вопрос "что происходит у этого студента". Здесь нужен
# ровно обратный разрез: один плоский список работ, ждущих проверки,
# упорядоченный так, чтобы сверху оказалось то, что ждёт дольше всех.
# Сквозная сортировка по дате внутри секций невозможна в принципе.
#
# ПОЧЕМУ ДАТА ПОСЛЕДНЕГО КОММИТА, А НЕ updatedAt. updatedAt меняется от
# любого действия в PR, включая комментарий бота и назначение ревьюера.
# Сортировка по нему поднимала бы наверх свежеотревьюированные PR. Дата
# коммита отвечает на нужный вопрос: как давно студент прислал работу.
#
# Берётся committedDate последнего коммита, а не authoredDate: при rebase
# и cherry-pick authoredDate сохраняет исходное время, и давно лежащая
# ветка выглядела бы новой (и наоборот).
cmd_prs() {
  local student="${1:-}"
  require_gh_auth
  load_review_markers

  local repos
  if [ -n "${student}" ]; then
    repos="$(repo_for_student "${student}")"
  else
    repos="$(list_student_repos)"
  fi

  if [ -z "${repos}" ]; then
    echo "Репозиториев студентов не найдено (префикс $(group_prefix))."
    return 0
  fi

  # Строки собираем в TSV: группа, фамилия, дата коммита — ключи сортировки,
  # остальное — для печати. Дата в ISO 8601 (UTC), поэтому лексикографическая
  # сортировка совпадает с хронологической.
  local rows="" repo failed="" errors=""

  # Индикатор прогресса. Опрос идёт по одному репозиторию, а на курсе их
  # под сотню — без индикатора минута работы выглядит как зависание.
  # Печатается в stderr, чтобы не попасть в перенаправленную таблицу
  # (./manage.sh prs > list.txt), и только в интерактивном терминале.
  local total_repos done_repos=0 show_progress=0
  total_repos="$(printf '%s\n' "${repos}" | grep -c '^' || true)"
  if [ -t 2 ] && [ "${total_repos}" -gt 1 ]; then
    show_progress=1
  fi

  while IFS= read -r repo; do
    [ -z "${repo}" ] && continue

    if [ "${show_progress}" -eq 1 ]; then
      done_repos=$((done_repos + 1))
      printf '\rОпрос репозиториев: %s/%s' "${done_repos}" "${total_repos}" >&2
    fi

    # ПОЧЕМУ GraphQL, А НЕ `gh pr list --json commits`. Поле commits у gh
    # тянет до 100 коммитов на каждый PR вместе с объектами авторов, и
    # запрос упирается в лимит GraphQL на сложность (500 000 узлов):
    #   "This query requests up to 505,050 possible nodes".
    # Нужен же ровно один — последний. Уменьшать число PR вместо этого
    # нельзя: это молча отрезало бы работы студентов.
    #
    # В discover.sh тот же `gh pr list` работает именно потому, что commits
    # он не запрашивает.
    #
    # СТОИМОСТЬ ЗАПРОСА (измерено, сервер сообщает её при превышении):
    #   узлов = PR * (COMMENTS + 1) + 100
    # При 50 PR и comments(last:30) это ~1650 узлов — от лимита в 500 000
    # запас 300-кратный. Поэтому обход идёт ПО ОДНОМУ репозиторию, а не
    # пакетом: пакет из 86 репозиториев с comments(first:100) стоил бы
    # ~443 000 узлов, то есть работал бы на грани и ломался по мере роста
    # курса — ровно тот же класс ошибки, что и исходный баг.
    #
    # comments(last:30), а не first: считаются комментарии бота, а они
    # свежие. Если комментариев больше 30, totalCount это покажет, и
    # счётчик будет помечен как неполный, — но молча не соврёт.
    local prs_json err_file="${TMPDIR:-/tmp}/prs-err.$$"
    if ! prs_json="$(gh api graphql \
        -f owner="${ORG}" -f name="${repo}" -f query='
        query($owner:String!, $name:String!) {
          repository(owner:$owner, name:$name) {
            pullRequests(states:OPEN, first:50) {
              nodes {
                number url createdAt isDraft headRefName
                commits(last:1) { nodes { commit { committedDate } } }
                comments(last:30) { totalCount nodes { body } }
              }
            }
          }
        }' --jq '.data.repository.pullRequests.nodes' 2>"${err_file}")"; then
      failed="${failed}  - ${repo}"$'\n'
      # Причину сохраняем: молчаливое "нет доступа" для всех репозиториев
      # скрыло бы ошибку в самом запросе (ровно так и случилось с лимитом
      # GraphQL). Одинаковые сообщения печатаем один раз.
      local msg
      msg="$(sed 's/^[[:space:]]*//' "${err_file}" | grep -v '^$' | head -1)"
      case "${errors}" in
        *"${msg}"*) ;;
        *) [ -n "${msg}" ] && errors="${errors}${msg}"$'\n' ;;
      esac
      rm -f "${err_file}"
      continue
    fi
    rm -f "${err_file}"

    # gh при нехватке прав печатает ошибку в stdout с нулевым кодом возврата
    # (на этом уже ломались лимиты ревьюера, см. discover.sh). Поэтому
    # проверяем, что пришёл именно массив, а не объект с message.
    if ! printf '%s' "${prs_json}" | jq -e 'type == "array"' >/dev/null 2>&1; then
      failed="${failed}  - ${repo}"$'\n'
      continue
    fi

    local group student_name
    group="$(group_of_repo "${repo}")"
    student_name="$(student_of_repo "${repo}")"

    # Подсчёт комментариев бота делает jq, а не shell: тело комментария
    # многострочное, и в TSV его не разобрать. Отказы (MARKER_SKIPPED) и
    # сбои (MARKER_FAILED) считаются отдельно от фактических ревью — так же,
    # как их разделяет discover.sh при учёте лимитов. Иначе "0 ревью" у PR,
    # упёршегося в лимит, читалось бы как "бот до него не дошёл".
    local tsv
    tsv="$(printf '%s' "${prs_json}" | jq -r \
      --arg group "${group:--}" \
      --arg student "${student_name}" \
      --arg repo "${repo}" \
      --arg m "${MARKER_REVIEW}" \
      --arg s "${MARKER_SKIPPED}" \
      --arg f "${MARKER_FAILED}" '
      .[]
      | ([ .comments.nodes[]? | select(.body | contains($m)) ]) as $bot
      # Последний коммит ветки. У PR без коммитов (такое бывает сразу после
      # создания) список пуст — подставляем дату создания PR, иначе строка
      # уехала бы в начало списка как самая старая.
      | ((.commits.nodes[0].commit.committedDate) // .createdAt) as $last
      | [ $group,
          $student,
          $last,
          .createdAt,
          $repo,
          (.number | tostring),
          .url,
          .headRefName,
          (if .isDraft then "draft" else "" end),
          ([ $bot[] | select((.body | contains($s)) or (.body | contains($f))) ]
            | length | tostring),
          ([ $bot[]
             | select(.body | contains($s) | not)
             | select(.body | contains($f) | not)
           ] | length | tostring),
          # Возраст последнего коммита в днях. Считается здесь, а не в awk:
          # в awk на macOS нет mktime (это BWK awk, а не GNU), и разбор даты
          # пришлось бы писать руками с учётом високосных лет.
          (((now - ($last | fromdateiso8601)) / 86400) | floor | tostring),
          # Признак того, что прочитаны не все комментарии (их больше, чем
          # запрошено). Тогда счётчик ревью — нижняя оценка, и это должно
          # быть видно в таблице, а не проглочено.
          (if (.comments.totalCount > (.comments.nodes | length))
           then "~" else "" end)
        ] | @tsv')"
    [ -n "${tsv}" ] && rows="${rows}${tsv}"$'\n'
  done <<< "${repos}"

  # Стираем строку прогресса, иначе она останется висеть над таблицей.
  # Ширины 60 символов достаточно: строка короткая и фиксированного вида.
  [ "${show_progress}" -eq 1 ] && printf '\r%60s\r' "" >&2

  rows="$(printf '%s' "${rows}" | sed '/^$/d')"

  # Отчёт о нечитаемых репозиториях. Печатается в обоих случаях — и когда
  # таблица пуста, и когда она есть, поэтому вынесен в функцию.
  #
  # Причину показываем обязательно. Если ошибка одна и та же во всех
  # репозиториях, дело почти наверняка не в правах, а в самом запросе:
  # именно так выглядел баг с лимитом GraphQL, когда «нет доступа»
  # печаталось для всех 86 репозиториев курса.
  report_prs_failures() {
    [ -z "${failed}" ] && return 0
    local n
    n="$(printf '%s' "${failed}" | grep -c '^' || true)"
    echo
    echo "Не удалось прочитать репозиториев: ${n}"
    if [ -n "${errors}" ]; then
      echo "Причина:"
      printf '%s' "${errors}" | sed 's/^/  /'
      # Одинаковая ошибка на всех репозиториях — признак ошибки запроса,
      # а не прав доступа.
      if [ "${n}" -gt 1 ] && [ "$(printf '%s' "${errors}" | grep -c '^' || true)" -eq 1 ]; then
        echo "  (одна и та же ошибка во всех репозиториях — вероятно, дело не в правах)"
      fi
    fi
    printf '%s' "${failed}"
  }

  if [ -z "${rows}" ]; then
    echo "Открытых PR нет."
    report_prs_failures
    return 0
  fi

  # Сортировка: группа, фамилия, дата последнего коммита по возрастанию —
  # более старые сверху. LC_ALL=C делает порядок детерминированным и
  # независимым от локали машины преподавателя.
  #
  # Ключи заданы по номерам полей (-k1,1 -k2,2 -k3,3), а не как -k1 -k2:
  # в последнем случае sort сравнивает «от поля до конца строки», и порядок
  # начал бы зависеть от URL и заголовка.
  rows="$(printf '%s\n' "${rows}" | LC_ALL=C sort -t $'\t' -k1,1 -k2,2 -k3,3)"

  # Печать таблицы. Ширину колонок awk считает по факту, чтобы длинные
  # фамилии и имена веток не ломали выравнивание. Возраст последнего
  # коммита — то, ради чего таблицу читают: он сразу показывает, что зависло.
  #
  # LC_ALL=C обязателен: при нём length() считает байты, и вычитание
  # продолжающих байтов UTF-8 в dwidth даёт верное число символов. Без
  # него поведение length() зависит от локали машины, и ширина колонок
  # стала бы неповторяемой.
  printf '%s\n' "${rows}" | LC_ALL=C awk -F'\t' '
    # Ширина в символах, а не в байтах: кириллица в UTF-8 занимает два
    # байта, и на заголовках колонок length() съехал бы. Продолжающие
    # байты UTF-8 (10xxxxxx) не занимают позицию на экране.
    function dwidth(s,   t) { t = s; gsub(/[\200-\277]/, "", t); return length(t) }
    function pad(s, w,   n) { n = w - dwidth(s); return n > 0 ? s sprintf("%" n "s", "") : s }
    {
      n = NR
      # Репозиторий ($5) в колонку не выносим: группа и фамилия уже задают
      # его однозначно, а полное имя втрое шире номера. Ссылка под строкой
      # содержит и то, и другое.
      group[n]=$1; pr[n]="#" $6; url[n]=$7; branch[n]=$8
      # Пометка draft добавляется до расчёта ширины колонки, иначе
      # выравнивание разъехалось бы ровно на этих строках.
      student[n] = ($9 != "") ? $2 " [draft]" : $2
      created[n] = substr($4,1,10)
      commit[n]  = substr($3,1,10) " (" $12 " дн.)"
      # Колонка ИИ: число опубликованных ревью, а следом — отказы и сбои,
      # если они были. Без этой пометки "0" у PR, упёршегося в лимит,
      # читалось бы как "бот до него не дошёл".
      #
      # Префикс "~" ($13) значит, что комментариев в PR больше, чем было
      # прочитано, и счётчик — нижняя оценка. Лучше показать приблизительное
      # число явно, чем молча соврать точным.
      ai[n] = $13 $11
      if ($10 + 0 > 0) ai[n] = ai[n] " (+" $13 $10 " без ревью)"
    }
    END {
      if (n == 0) exit 0
      h[1]="ГРУППА"; h[2]="СТУДЕНТ"; h[3]="PR"; h[4]="ВЕТКА"
      h[5]="СОЗДАН"; h[6]="КОММИТ"; h[7]="ИИ"
      for (c=1; c<=6; c++) w[c] = dwidth(h[c])
      for (i=1; i<=n; i++) {
        if (dwidth(group[i])   > w[1]) w[1]=dwidth(group[i])
        if (dwidth(student[i]) > w[2]) w[2]=dwidth(student[i])
        if (dwidth(pr[i])      > w[3]) w[3]=dwidth(pr[i])
        if (dwidth(branch[i])  > w[4]) w[4]=dwidth(branch[i])
        if (dwidth(created[i]) > w[5]) w[5]=dwidth(created[i])
        if (dwidth(commit[i])  > w[6]) w[6]=dwidth(commit[i])
      }
      print pad(h[1],w[1]) "  " pad(h[2],w[2]) "  " pad(h[3],w[3]) "  " \
            pad(h[4],w[4]) "  " pad(h[5],w[5]) "  " pad(h[6],w[6]) "  " h[7]
      for (i=1; i<=n; i++) {
        print pad(group[i],w[1]) "  " pad(student[i],w[2]) "  " pad(pr[i],w[3]) "  " \
              pad(branch[i],w[4]) "  " pad(created[i],w[5]) "  " \
              pad(commit[i],w[6]) "  " ai[i]
        print "    " url[i]
      }
      print ""
      print "Всего открытых PR: " n
    }'

  report_prs_failures
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

# Печатает пути, которые нужно УДАЛИТЬ из целевого репозитория
# (остатки прежней схемы, см. комментарий в манифесте). Применяется и к
# шаблону (sync-template), и к репозиториям студентов (sync-workflow):
# копирование по манифесту само по себе не убирает файлы, которых в
# манифесте больше нет.
parse_student_remove() {
  awk '/^[[:space:]]*!STUDENT_REMOVE[[:space:]]+/ { $1=""; sub(/^[[:space:]]+/,""); print }' \
    "${1:-${TEMPLATE_MANIFEST}}"
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

  local excludes removals
  excludes="$(parse_excludes "${manifest}")"
  if [ -n "${excludes}" ]; then
    echo
    echo "Не попадёт в ${target}:"
    echo "${excludes}" | sed 's/^/  /'
  fi
  removals="$(parse_student_remove "${manifest}")"
  if [ -n "${removals}" ]; then
    echo
    echo "Будет УДАЛЕНО из ${target} (остатки прежней схемы):"
    echo "${removals}" | sed 's/^/  /'
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

  # Пути, помеченные !STUDENT_REMOVE, вычищаем и здесь: иначе файлы прежней
  # схемы (workflow ревью, движок) остались бы в шаблоне навсегда и
  # разъезжались бы с репозиториями студентов, откуда их удаляет
  # sync-workflow.
  local rm_path
  while IFS= read -r rm_path; do
    [ -z "${rm_path}" ] && continue
    rm -rf "${work:?}/${rm_path}"
  done <<< "$(parse_student_remove "${manifest}")"

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
  # Глобальные флаги (--group/--yes) уже разобраны выше и не должны
  # доезжать до диспетчера: иначе `--group g1 list` попытается выполнить
  # команду «--group». Вырезаем их из списка аргументов целиком.
  local args=() skip_next=0 a
  for a in "$@"; do
    if [ "${skip_next}" -eq 1 ]; then skip_next=0; continue; fi
    case "${a}" in
      --group)   skip_next=1; continue ;;
      --group=*) continue ;;
      --yes)     continue ;;
    esac
    args+=("${a}")
  done
  set -- "${args[@]+"${args[@]}"}"

  local command="${1:-}"
  [ $# -gt 0 ] && shift || true

  case "${command}" in
    doctor)            cmd_doctor "$@" ;;
    protect)           cmd_protect "$@" ;;
    stats)             cmd_stats "$@" ;;
    audit)             cmd_audit "$@" ;;
    list)             cmd_list "$@" ;;
    create)            cmd_create "$@" ;;
    enroll)             cmd_enroll "$@" ;;
    invite)            cmd_invite "$@" ;;
    set-secret)         cmd_set_secret "$@" ;;
    status)            cmd_status "$@" ;;
    prs)                cmd_prs "$@" ;;
    review)             cmd_review "$@" ;;
    assign-reviewers)   cmd_assign_reviewers "$@" ;;
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
