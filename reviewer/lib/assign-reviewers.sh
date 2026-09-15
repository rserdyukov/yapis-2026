#!/usr/bin/env bash
# Назначает преподавателя ревьюером в открытых PR студентов.
#
# ЗАЧЕМ. Работа сдаётся через Pull Request, финальное решение принимает
# преподаватель. Без review request такой PR не попадает ни в один рабочий
# список: преподаватель узнаёт о нём только из письма или обходя репозитории
# руками. Назначенный ревьюер ставит PR в личный раздел
# "Pull requests -> Review requests" — единую очередь работ на проверку по
# всем группам.
#
# ПОЧЕМУ НЕ CODEOWNERS. Файл .github/CODEOWNERS — штатный механизм, но на
# плане Free для ПРИВАТНЫХ репозиториев он не запрашивает ревьюера при
# открытии PR. Проверено экспериментально: CODEOWNERS с '* @kvetkod'
# принимается без ошибок (GET /codeowners/errors отдаёт []), но у созданного
# PR requested_reviewers остаётся пустым. Если организация перейдёт на план
# Team (GitHub Education), CODEOWNERS заработает и этот скрипт можно будет
# заменить на файл в шаблоне.
#
# ПОЧЕМУ НЕ WORKFLOW У СТУДЕНТА. По тем же причинам, что и ИИ-ревью:
# у студента есть write, он может подменить workflow в своей ветке. Кроме
# того, workflow в репозитории студента расходует минуты Actions организации.
#
# Скрипт ИДЕМПОТЕНТЕН: если нужный преподаватель уже запрошен или уже оставил
# ревью, PR не трогается. Это важно, потому что ревьюер запускается по
# расписанию каждые 10 минут.
#
# СОЗНАТЕЛЬНО НЕ переназначает ревью после того, как преподаватель его
# оставил: повторный review request — это задача преподавателя ("Re-request
# review"), а не автоматики. Иначе после каждого нового коммита студента
# бот заново дёргал бы преподавателя по уже проверенной работе.
#
# Требования: gh (installation token GitHub App с pull_requests:write), jq.
#
# Использование:
#   assign-reviewers.sh <org> <repo_prefix> [--only <repo>[:<pr>]] [--dry-run]
#
#   --only     обработать только указанный репозиторий (и PR).
#   --dry-run  только показать, что было бы сделано.
#
# Переменные окружения:
#   REVIEW_ROOT  каталог .github/review с config.env
#                (по умолчанию — ../../.github/review относительно скрипта).

set -euo pipefail

ORG="${1:?org is required}"
REPO_PREFIX="${2:?repo_prefix is required}"
shift 2

ONLY=""
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "${1}" in
    --only)    ONLY="${2:?--only requires <repo>[:<pr>]}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "Неизвестный аргумент: ${1}" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_ROOT="${REVIEW_ROOT:-$(cd "${SCRIPT_DIR}/../../.github/review" && pwd)}"

# shellcheck source=/dev/null
source "${REVIEW_ROOT}/config.env"

log() { echo "$*" >&2; }

# --- Преподаватель по группе ---------------------------------------------

# Логин преподавателя для группы. Печатает пустую строку, если не задан.
teacher_for_group() {
  local group="${1}" pair
  for pair in ${TEACHER_BY_GROUP:-}; do
    case "${pair}" in
      "${group}:"*) printf '%s' "${pair#*:}"; return 0 ;;
    esac
  done
  printf '%s' "${TEACHER_DEFAULT:-}"
}

# Группа из имени репозитория: yapis-2026-321701-ivanov -> 321701.
# Условие то же, что в discover.sh: первый сегмент считается группой только
# если похож на её идентификатор (g1, 2, 321701), иначе двойная фамилия
# petrov-sidorov дала бы группу "petrov".
group_of_repo() {
  local rest="${1#"${REPO_PREFIX}"}"
  case "${rest}" in
    [a-z][0-9]-*|[a-z][0-9][0-9]-*|[0-9]*-*) printf '%s' "${rest%%-*}" ;;
    *) printf '%s' "" ;;
  esac
}

# --- Список репозиториев --------------------------------------------------

ONLY_REPO="${ONLY%%:*}"
ONLY_PR=""
if [[ "${ONLY}" == *:* ]]; then
  ONLY_PR="${ONLY#*:}"
  case "${ONLY_PR}" in
    ''|*[!0-9]*) echo "Номер PR в --only должен быть числом: ${ONLY}" >&2; exit 2 ;;
  esac
fi

if [ -n "${ONLY_REPO}" ]; then
  REPOS="${ONLY_REPO}"
else
  REPOS="$(gh repo list "${ORG}" --limit 500 --json name --jq '.[].name' 2>/dev/null \
    | grep -E "^${REPO_PREFIX}" \
    | grep -v -- '-template$' || true)"
fi

if [ -z "${REPOS}" ]; then
  log "Репозиториев студентов в ${ORG} с префиксом ${REPO_PREFIX} не найдено."
  exit 0
fi

ASSIGNED=0
SKIPPED=0
FAILED=0

while IFS= read -r repo; do
  [ -z "${repo}" ] && continue

  # Группа может не читаться из имени (репозиторий без префикса группы —
  # схема курса с одним преподавателем). Это не ошибка: тогда работает
  # TEACHER_DEFAULT, и только его отсутствие делает назначение невозможным.
  group="$(group_of_repo "${repo}")"
  if [ -n "${group}" ]; then
    teacher="$(teacher_for_group "${group}")"
  else
    teacher="${TEACHER_DEFAULT:-}"
  fi

  if [ -z "${teacher}" ]; then
    if [ -n "${group}" ]; then
      log "${repo}: для группы ${group} не задан преподаватель (TEACHER_BY_GROUP), пропускаю."
    else
      log "${repo}: группа не читается из имени и не задан TEACHER_DEFAULT, пропускаю."
    fi
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # reviewRequests — кого уже просили; latestReviews — кто уже высказался.
  # Автор нужен, чтобы не пытаться назначить преподавателя на его же PR
  # (например, ci/sync-review-tooling): GitHub такой запрос отклоняет.
  if ! prs_json="$(gh pr list --repo "${ORG}/${repo}" --state open --limit 50 \
      --json number,headRefName,isDraft,author,reviewRequests,latestReviews 2>/dev/null)"; then
    log "${repo}: не удалось получить список PR (нет доступа?), пропускаю."
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if ! printf '%s' "${prs_json}" | jq -e 'type == "array"' >/dev/null 2>&1; then
    log "${repo}: неожиданный ответ API, пропускаю."
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Сравнение логинов и поиск в списках делает jq, а не shell: логины
  # GitHub регистронезависимы, а @tsv экранирует перевод строки, из-за чего
  # склеенный в одно поле список ревьюеров в bash уже не разобрать.
  while IFS=$'\t' read -r number branch draft is_author already_requested already_reviewed; do
    [ -z "${number}" ] && continue

    if [ -n "${ONLY_PR}" ] && [ "${number}" != "${ONLY_PR}" ]; then
      continue
    fi

    # Служебные ветки — это PR преподавателя (sync-workflow) и ботов.
    # Ревью преподавателя они не требуют.
    case "${branch}" in
      ci/*|dependabot/*) continue ;;
    esac

    # Draft — работа ещё не сдана: не дёргаем преподавателя раньше времени.
    # Когда студент нажмёт "Ready for review", PR попадёт в следующий обход.
    if [ "${draft}" = "true" ]; then
      log "${repo}#${number}: draft, пропускаю."
      continue
    fi

    # Свой же PR назначить себе нельзя — GitHub вернёт 422.
    if [ "${is_author}" = "true" ]; then
      log "${repo}#${number}: автор — сам преподаватель, пропускаю."
      continue
    fi

    # Идемпотентность: ревью уже запрошено либо уже оставлено.
    if [ "${already_requested}" = "true" ]; then
      log "${repo}#${number}: ревью у ${teacher} уже запрошено."
      continue
    fi
    if [ "${already_reviewed}" = "true" ]; then
      log "${repo}#${number}: ${teacher} уже оставил ревью."
      continue
    fi

    if [ "${DRY_RUN}" -eq 1 ]; then
      log "[dry-run] ${repo}#${number}: назначить ревьюером ${teacher}."
      ASSIGNED=$((ASSIGNED + 1))
      continue
    fi

    if gh api "repos/${ORG}/${repo}/pulls/${number}/requested_reviewers" \
        --method POST -f "reviewers[]=${teacher}" --silent >/dev/null 2>&1; then
      log "${repo}#${number}: назначен ревьюером ${teacher}."
      ASSIGNED=$((ASSIGNED + 1))
    else
      # Типичная причина — у преподавателя нет доступа к репозиторию
      # (не добавлен коллаборатором) либо он автор PR.
      log "${repo}#${number}: НЕ УДАЛОСЬ назначить ${teacher} (нет доступа к репозиторию?)."
      FAILED=$((FAILED + 1))
    fi
  done < <(printf '%s' "${prs_json}" | jq -r --arg t "${teacher}" '
    ($t | ascii_downcase) as $tl
    | .[]
    | [ .number,
        .headRefName,
        (.isDraft | tostring),
        (((.author.login // "") | ascii_downcase) == $tl | tostring),
        ([ .reviewRequests[]?.login // empty | ascii_downcase ] | index($tl) != null | tostring),
        ([ .latestReviews[]?.author.login // empty | ascii_downcase ] | index($tl) != null | tostring)
      ] | @tsv')
done <<< "${REPOS}"

log "Назначено: ${ASSIGNED}, пропущено репозиториев: ${SKIPPED}, ошибок: ${FAILED}."

# Ошибка назначения не должна ронять ревьюера: ИИ-ревью важнее и уже
# отработало в соседней job. Проблема видна в логе и в summary.
exit 0
