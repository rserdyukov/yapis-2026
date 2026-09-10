#!/usr/bin/env bash
# Формирует текст комментария об отказе от ИИ-ревью и печатает его в stdout.
#
# Вынесено из workflow, потому что используется в двух местах (отказ по
# лимитам и отказ по размеру diff) и требует аккуратной сборки GitHub alert:
# синтаксис `> [!WARNING]` работает только если символ '>' стоит в начале
# КАЖДОЙ строки блока, включая пустые.
#
# Использование: skip-comment.sh "<причина отказа>"
#
# Тексты и тип alert настраиваются в .github/review/messages.env.

set -euo pipefail

REASON="${1:?Укажите причину отказа}"
REVIEW_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."

# shellcheck source=/dev/null
source "${REVIEW_ROOT}/messages.env"

# Маркеры идут перед alert: это HTML-комментарии, они не отображаются,
# но по ним lib/rate-limit.sh отличает отказы от выполненных ревью.
echo "${MARKER_REVIEW}"
echo "${MARKER_SKIPPED}"
echo

echo "> [!${MSG_SKIPPED_ALERT_TYPE:-WARNING}]"
echo "> **${MSG_SKIPPED_HEADER}**"
echo ">"

# Причина может быть длинной; каждую её строку префиксуем '>', иначе alert
# оборвётся на первой строке без префикса.
while IFS= read -r line; do
  if [ -z "${line}" ]; then echo ">"; else echo "> ${line}"; fi
done <<< "${REASON}"
