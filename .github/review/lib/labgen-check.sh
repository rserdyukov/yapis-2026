#!/usr/bin/env bash
# Мутанты labgen в выводе check.sh (ЛР4).
#
# ЗАЧЕМ. Зонды probe-check.sh не знают синтаксиса варианта и семантику не
# проверяют. labgen строит программы из корректных примеров студента с одним
# изменением (необъявленное имя, лишний аргумент, повтор функции, …) и знает,
# что должен ответить анализатор. Модель ревью запускать программы не может,
# поэтому без этих фактов она либо пропускала дефекты (germanenko#8:
# «замечаний не найдено» при двух error-примерах с кодом 0), либо выдавала
# догадки по коду за поведение.
#
# В вывод идёт только сводка (lib/labgen/report.py: write_summary): падение и
# таймаут — замечание по факту; «ошибка не найдена» и «ложная ошибка» —
# кандидат, который модель сверяет с README. Берутся только мутанты с
# однозначным ожиданием (--only-high): неявное приведение и каскад зависят
# от варианта.
#
# Использование: source labgen-check.sh; run_labgen_checks <work_dir> [budget_s]
# Требует python3; ANTLR_JAR и java — для точного лексера (без них запасной).
# Всегда возвращает 0: результат — данные для модели, а не код проверки.

LABGEN_BUDGET_DEFAULT=90
LABGEN_MAX_PER_OP=2
LABGEN_TIMEOUT=20

run_labgen_checks() {
  local work="${1:?work_dir}" budget="${2:-${LABGEN_BUDGET_DEFAULT}}"
  work="$(cd "${work}" && pwd)"
  local lib; lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if ! command -v python3 >/dev/null 2>&1; then
    echo "ОКРУЖЕНИЕ: python3 не найден — мутанты не строились."
    return 0
  fi
  [ -f "${work}/compile.sh" ] || { echo "compile.sh не найден — мутанты не строились."; return 0; }

  # .review/ исключён из раскладки и diff, как у зондов.
  local out_dir="${work}/.review/labgen" summary="${work}/.review/labgen-summary.txt" log rc
  rm -rf "${out_dir}" "${summary}"; mkdir -p "${work}/.review"
  log="$( cd "${work}" && timeout "$((budget + LABGEN_TIMEOUT + 15))" \
            python3 -B "${lib}/labgen" "${work}" --mode sem --only-high \
              --max-per-op "${LABGEN_MAX_PER_OP}" --timeout "${LABGEN_TIMEOUT}" --jobs 2 \
              --budget "${budget}" --out "${out_dir}" --summary "${summary}" 2>&1 )"
  rc=$?

  if [ -s "${summary}" ]; then
    cat "${summary}"
  elif [ "${rc}" -eq 124 ]; then
    echo "Мутанты не завершились за $((budget + LABGEN_TIMEOUT + 15))с — сводки нет. Это ограничение проверки, не замечание."
  else
    # Код 2 — нет грамматики, примеров или compile.sh: это видно и в других
    # разделах вывода, здесь только причина.
    echo "Мутанты не строились: $(printf '%s\n' "${log}" | grep . | tail -n 1 | cut -c1-200)"
  fi
  rm -rf "${out_dir}" "${summary}"
  rmdir "${work}/.review" 2>/dev/null || true
  return 0
}
