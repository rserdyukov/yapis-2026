#!/usr/bin/env bash
# Обходит репозитории студентов организации и решает, какие PR нужно
# проверить в этом запуске ревьюера.
#
# Для каждого открытого PR:
#   1. Пропускает служебные ветки (ci/*), draft-PR и PR без изменений.
#   2. Смотрит комментарии бота: если для текущего head SHA уже есть
#      комментарий (ревью или отказ) — PR уже обработан, пропускаем.
#   3. Применяет лимиты из config.env. Лимиты считаются по ФАКТИЧЕСКИ
#      опубликованным ревью (маркер MARKER_REVIEW без MARKER_SKIPPED), а не
#      по запускам workflow — отказы бюджет не расходуют.
#        - MAX_REVIEWS_PER_PR        на один PR за всё время;
#        - MAX_REVIEWS_PER_DAY       на репозиторий за последние 24 часа;
#        - MAX_REVIEWS_PER_DAY_TOTAL на все репозитории за последние 24 часа;
#        - MAX_DIFF_LINES            размер PR (additions + deletions) БЕЗ
#                                    сгенерированных файлов (см.
#                                    .github/review/lib/generated-files.sh).
#      При превышении PR-лимита — в PR ставится комментарий-отказ (один раз
#      на SHA). При исчерпании дневных лимитов комментарий НЕ ставится: PR
#      просто дождётся следующего запуска.
#      Слишком большой PR НЕ пропускается: он помечается oversize=true и
#      ревью проводится в сокращённом режиме — только по результатам
#      автоматических проверок (compile.sh, сборка грамматики), без анализа
#      кода. Раньше такой PR отвергался целиком, и студент оставался без
#      проверки работоспособности компилятора.
#   4. Отбирает не более MAX_REVIEWS_PER_RUN PR, самые старые по времени
#      обновления первыми (справедливость: кто раньше запушил, тот раньше
#      получит ревью).
#
# Результат — JSON-массив в stdout, по элементу на PR:
#   {"repo":"yapis-2026-ivanov","pr":4,"head_sha":"...","base_sha":"...",
#    "branch":"task3","student":"ivanov","oversize":false,"changed":812}
# Он используется как matrix в reviewer/workflow/review.yml.
#
# Требования: gh (аутентифицирован токеном с доступом ко всем репозиториям
# организации — installation token GitHub App), jq.
#
# Использование:
#   discover.sh <org> <repo_prefix> [--only <repo>[:<pr>]] [--dry-run]
#
#   --only     проверить только указанный репозиторий (и PR) — для ручного
#              запуска через workflow_dispatch / ./manage.sh review.
#              Лимиты при этом всё равно применяются, кроме
#              MAX_REVIEWS_PER_RUN.
#   --dry-run  не публиковать комментарии-отказы, только напечатать решение.
#   --force    проверить PR повторно, даже если для этого коммита уже есть
#              комментарий и даже если исчерпан лимит ревью на PR. Нужен
#              после починки инфраструктуры: при технической ошибке SHA
#              помечается обработанным, чтобы сбой не повторялся каждые
#              10 минут. Требует --only — иначе повтор всех PR разом сожжёт
#              дневной лимит курса.
#
# Переменные окружения:
#   REVIEW_ROOT  каталог .github/review с config.env и messages.env
#                (по умолчанию — ../../.github/review относительно скрипта).

set -euo pipefail

ORG="${1:?org is required}"
REPO_PREFIX="${2:?repo_prefix is required}"
shift 2

ONLY=""
DRY_RUN=0
FORCE=0
while [ $# -gt 0 ]; do
  # shellcheck disable=SC2034  # DRY_RUN читается в common.sh (post_skip)
  case "${1}" in
    --only)    ONLY="${2:?--only requires <repo>[:<pr>]}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force)   FORCE=1; shift ;;
    *) echo "Неизвестный аргумент: ${1}" >&2; exit 2 ;;
  esac
done

if [ "${FORCE}" -eq 1 ] && [ -z "${ONLY}" ]; then
  echo "--force требует --only: повторное ревью всех PR разом сожгло бы лимит." >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_ROOT="${REVIEW_ROOT:-$(cd "${SCRIPT_DIR}/../../.github/review" && pwd)}"

# shellcheck source=/dev/null
source "${REVIEW_ROOT}/config.env"
# shellcheck source=/dev/null
source "${REVIEW_ROOT}/messages.env"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=/dev/null
source "${REVIEW_ROOT}/lib/generated-files.sh"

log() { echo "$*" >&2; }

# Размер PR без сгенерированных файлов. GitHub отдаёт additions/deletions по
# всему PR одним числом, поэтому для точного счёта берём список файлов
# (`gh pr view --json files`). При сбое API возвращаем исходное число —
# лучше переоценить размер, чем пропустить проверку лимита.
# Печатает: <changed_without_generated> <generated_files_count>
pr_changed_lines() {
  local repo_full="$1" number="$2" fallback="$3"
  local files_json
  if ! files_json="$(gh pr view "${number}" --repo "${repo_full}" --json files --jq '.files[] | [(.additions|tostring), (.deletions|tostring), .path] | @tsv' 2>/dev/null)"; then
    echo "${fallback} 0"; return 0
  fi
  if [ -z "${files_json}" ]; then
    echo "${fallback} 0"; return 0
  fi
  local changed generated
  changed="$(printf '%s\n' "${files_json}" | filter_generated_numstat | sum_numstat_lines)"
  generated="$(printf '%s\n' "${files_json}" | list_generated_numstat | wc -l | tr -d ' ')"
  echo "${changed} ${generated}"
}

# --- Список репозиториев ---------------------------------------------------

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
  # gh не поддерживает --arg, поэтому префикс фильтруется после выборки.
  REPOS="$(gh repo list "${ORG}" --limit 500 --json name --jq '.[].name' 2>/dev/null \
    | grep -E "^${REPO_PREFIX}" \
    | grep -v -- '-template$' || true)"
fi

if [ -z "${REPOS}" ]; then
  log "Репозиториев студентов в ${ORG} с префиксом ${REPO_PREFIX} не найдено."
  echo "[]"
  exit 0
fi

SINCE="$(since_24h)"

# --- Обход PR ------------------------------------------------------------

# Кандидаты собираются в TSV: updatedAt<TAB>json — чтобы потом отсортировать
# по времени и отрезать MAX_REVIEWS_PER_RUN.
CANDIDATES=""
GLOBAL_TODAY=0
# Дневной счётчик по репозиториям: repo<TAB>count.
DAILY_BY_REPO=""

while IFS= read -r repo; do
  [ -z "${repo}" ] && continue
  # Идентификатор студента для промпта: отрезаем общий префикс курса, а
  # затем — префикс группы (yapis-2026-g1-ivanov -> ivanov). Группа
  # техническая деталь раскладки репозиториев, модели она ничего не даёт.
  #
  # Отрезаем ТОЛЬКО если первый сегмент похож на идентификатор группы
  # (g1, 2, 321701): иначе двойная фамилия petrov-sidorov превратилась бы
  # в sidorov.
  student="${repo#"${REPO_PREFIX}"}"
  case "${student}" in
    [a-z][0-9]-*|[a-z][0-9][0-9]-*|[0-9]*-*) student="${student#*-}" ;;
  esac

  if ! prs_json="$(gh pr list --repo "${ORG}/${repo}" --state open --limit 50 \
      --json number,headRefName,headRefOid,baseRefName,isDraft,additions,deletions,updatedAt,comments 2>/dev/null)"; then
    log "${repo}: не удалось получить список PR (нет доступа?), пропускаю."
    continue
  fi

  if ! printf '%s' "${prs_json}" | jq -e 'type == "array"' >/dev/null 2>&1; then
    log "${repo}: неожиданный ответ API, пропускаю."
    continue
  fi

  # Дневной счётчик репозитория: опубликованные ревью во ВСЕХ его открытых
  # PR за 24 часа. (Закрытые PR игнорируем осознанно — их ревью не мешают
  # студенту продолжать работу, а запросов к API становится вдвое меньше.)
  repo_today="$(printf '%s' "${prs_json}" | jq \
    --arg m "${MARKER_REVIEW}" --arg s "${MARKER_SKIPPED}" --arg since "${SINCE}" '
    [ .[].comments[]
      | select(.body | contains($m))
      | select(.body | contains($s) | not)
      | select(.createdAt >= $since)
    ] | length')"
  GLOBAL_TODAY=$((GLOBAL_TODAY + repo_today))
  DAILY_BY_REPO="${DAILY_BY_REPO}${repo}"$'\t'"${repo_today}"$'\n'

  while IFS=$'\t' read -r number branch head_sha base_ref draft additions deletions updated_at; do
    [ -z "${number}" ] && continue

    if [ -n "${ONLY_PR}" ] && [ "${number}" != "${ONLY_PR}" ]; then
      continue
    fi

    case "${branch}" in
      ci/*|dependabot/*) log "${repo}#${number}: служебная ветка ${branch}, пропускаю."; continue ;;
    esac
    if [ "${draft}" = "true" ]; then
      log "${repo}#${number}: draft, пропускаю."; continue
    fi

    # Уже есть комментарий бота для этого коммита? Маркер ставится и при
    # технической ошибке — иначе сбой повторялся бы каждые 10 минут. Чтобы
    # перепроверить такой PR после починки, нужен явный --force.
    sha_marker="${MARKER_SHA_PREFIX}${head_sha}"
    seen="$(printf '%s' "${prs_json}" | jq -r --argjson n "${number}" --arg mk "${sha_marker}" '
      [ .[] | select(.number == $n) | .comments[] | select(.body | contains($mk)) ] | length')"
    if [ "${seen}" -gt 0 ] && [ "${FORCE}" -eq 0 ]; then
      log "${repo}#${number}: коммит ${head_sha:0:7} уже обработан."; continue
    fi

    # Сколько ревью уже опубликовано в этом PR.
    published="$(printf '%s' "${prs_json}" | jq -r --argjson n "${number}" \
      --arg m "${MARKER_REVIEW}" --arg s "${MARKER_SKIPPED}" '
      [ .[] | select(.number == $n) | .comments[]
        | select(.body | contains($m))
        | select(.body | contains($s) | not)
      ] | length')"

    if [ "${published}" -ge "${MAX_REVIEWS_PER_PR}" ] && [ "${FORCE}" -eq 0 ]; then
      log "${repo}#${number}: лимит ревью на PR (${published}/${MAX_REVIEWS_PER_PR})."
      post_skip "${ORG}/${repo}" "${number}" "${head_sha}" "$(render_msg "${MSG_LIMIT_PER_PR}")"
      continue
    fi

    changed_raw=$((additions + deletions))
    if [ "${changed_raw}" -eq 0 ]; then
      log "${repo}#${number}: нет изменений, пропускаю."; continue
    fi

    # Точный размер — без сгенерированных файлов. Запрашиваем список файлов
    # только когда суммарный размер вообще приближается к лимиту: для
    # маленьких PR лишний вызов API не нужен.
    changed="${changed_raw}"; generated_count=0
    if [ "${changed_raw}" -gt "${MAX_DIFF_LINES}" ]; then
      read -r changed generated_count <<< "$(pr_changed_lines "${ORG}/${repo}" "${number}" "${changed_raw}")"
      if [ "${changed}" -ne "${changed_raw}" ]; then
        log "${repo}#${number}: ${changed_raw} строк, из них без сгенерированных файлов — ${changed} (${generated_count} файлов исключено)."
      fi
    fi

    oversize=false
    if [ "${changed}" -gt "${MAX_DIFF_LINES}" ]; then
      # Не отказ, а сокращённый режим: проверки запускаются, анализ кода —
      # нет. Сообщение об этом добавит сам ревьюер в шапку комментария.
      log "${repo}#${number}: большой PR (${changed} > ${MAX_DIFF_LINES}) — ревью в сокращённом режиме."
      oversize=true
    fi

    if [ "${repo_today}" -ge "${MAX_REVIEWS_PER_DAY}" ]; then
      log "${repo}#${number}: дневной лимит репозитория (${repo_today}/${MAX_REVIEWS_PER_DAY}), отложено."
      continue
    fi

    # base SHA нужен ревьюеру для diff; берём актуальный коммит base-ветки.
    base_sha="$(gh api "repos/${ORG}/${repo}/git/ref/heads/${base_ref}" --jq '.object.sha' 2>/dev/null || true)"
    if [ -z "${base_sha}" ]; then
      log "${repo}#${number}: не удалось получить SHA ветки ${base_ref}, пропускаю."; continue
    fi

    item="$(jq -cn \
      --arg repo "${repo}" --argjson pr "${number}" --arg head "${head_sha}" \
      --arg base "${base_sha}" --arg branch "${branch}" --arg student "${student}" \
      --argjson oversize "${oversize}" --argjson changed "${changed}" \
      '{repo:$repo, pr:$pr, head_sha:$head, base_sha:$base, branch:$branch, student:$student, oversize:$oversize, changed:$changed}')"
    CANDIDATES="${CANDIDATES}${updated_at}"$'\t'"${repo}"$'\t'"${item}"$'\n'
  done < <(printf '%s' "${prs_json}" | jq -r '.[] |
    [.number, .headRefName, .headRefOid, .baseRefName, (.isDraft|tostring),
     (.additions // 0), (.deletions // 0), .updatedAt] | @tsv')
done <<< "${REPOS}"

# --- Глобальный лимит и отбор ---------------------------------------------

if [ -z "${CANDIDATES}" ]; then
  log "Новых PR для ревью нет."
  echo "[]"
  exit 0
fi

REMAINING_GLOBAL=$((MAX_REVIEWS_PER_DAY_TOTAL - GLOBAL_TODAY))
if [ "${REMAINING_GLOBAL}" -le 0 ]; then
  log "Общий дневной лимит исчерпан (${GLOBAL_TODAY}/${MAX_REVIEWS_PER_DAY_TOTAL}); все PR отложены."
  echo "[]"
  exit 0
fi

LIMIT="${MAX_REVIEWS_PER_RUN}"
if [ -n "${ONLY}" ]; then
  LIMIT=1000
fi
if [ "${REMAINING_GLOBAL}" -lt "${LIMIT}" ]; then
  LIMIT="${REMAINING_GLOBAL}"
fi

# Не более одного PR на репозиторий за запуск и не больше, чем осталось до
# дневного лимита репозитория: иначе студент с тремя открытыми PR получит
# три ревью за раз и съест общий лимит.
SELECTED="$(printf '%s' "${CANDIDATES}" | sort | awk -F'\t' -v limit="${LIMIT}" '
  NF >= 3 && !seen[$2]++ && n < limit { print $3; n++ }')"

if [ -z "${SELECTED}" ]; then
  echo "[]"
  exit 0
fi

log "Отобрано для ревью (лимит ${LIMIT}, за сутки уже ${GLOBAL_TODAY}/${MAX_REVIEWS_PER_DAY_TOTAL}):"
printf '%s\n' "${SELECTED}" | jq -r '"  \(.repo)#\(.pr) (\(.branch), \(.head_sha[0:7]), \(.changed) строк\(if .oversize then ", сокращённый режим" else "" end))"' >&2

printf '%s\n' "${SELECTED}" | jq -cs '.'
