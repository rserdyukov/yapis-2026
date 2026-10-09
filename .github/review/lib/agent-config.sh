#!/usr/bin/env bash
# Конфигурация opencode для агента ревью — одна на ревьюер, review-local.sh
# и стенд eval-prompts.sh, чтобы локальная проверка и отладка промптов
# шли в тех же условиях, что ревью в PR.
#
# Использование: source agent-config.sh; agent_config_json <model>
# Печатает JSON для OPENCODE_CONFIG_CONTENT. Читает из окружения
# (обычно из config.env):
#   MODEL_DECLARE         1 — объявить модель в блоке provider. Лимиты ниже
#                         заданы для MODEL из config.env, поэтому при
#                         подмене модели вызывающая сторона сбрасывает его;
#   MODEL_CONTEXT_TOKENS  лимит контекста для объявления;
#   MODEL_OUTPUT_TOKENS   лимит ответа для объявления.
#
# ЗАЧЕМ ОБЪЯВЛЕНИЕ. opencode знает модели из каталога models.dev, который
# кэшируется и обновляется с задержкой. Модель, которой в кэше ещё нет,
# даёт «Model unavailable» — так было с claude-haiku-5.5 через два дня
# после выхода. Объявление в provider снимает зависимость от каталога.
# Цену не объявляем: её считает OpenRouter, а неверная цифра в конфиге
# только путала бы статистику opencode.
#
# Разрешения: всё, кроме чтения и поиска, запрещено ЯВНО и по именам —
# "*" перекрывается ключами из конфигурации проекта, отдельные ключи нет.
# small_model = model: иначе opencode для служебных вызовов (заголовок
# сессии) сам выбирает gemini-flash из каталога — лишний запрос мимо MODEL.

agent_config_json() {
  local model="${1:?model}"
  # JSON собираем без jq (его может не быть у студента), поэтому имя
  # модели и числа проверяем: в них не должно быть кавычек и т.п.
  case "${model}" in
    *[!A-Za-z0-9._:/@~+-]*) echo "agent_config_json: недопустимое имя модели: ${model}" >&2; return 1 ;;
  esac
  local ctx="${MODEL_CONTEXT_TOKENS:-200000}" out="${MODEL_OUTPUT_TOKENS:-32000}"
  case "${ctx}${out}" in *[!0-9]*) ctx=200000; out=32000 ;; esac
  local provider="${model%%/*}" model_id="${model#*/}" provider_block=""
  if [ "${MODEL_DECLARE:-0}" = "1" ] && [ "${provider}" != "${model}" ]; then
    provider_block="$(printf '"provider":{"%s":{"models":{"%s":{"name":"%s","tool_call":true,"limit":{"context":%s,"output":%s}}}}},' \
      "${provider}" "${model_id}" "${model_id}" "${ctx}" "${out}")"
  fi
  # shellcheck disable=SC2016  # "$schema" — ключ JSON, а не переменная
  printf '{"$schema":"https://opencode.ai/config.json",%s"model":"%s","small_model":"%s","share":"disabled","autoupdate":false,"snapshot":false,"plugin":[],"instructions":[],"permission":{"*":"deny","read":"allow","glob":"allow","grep":"allow","list":"allow","bash":"deny","edit":"deny","write":"deny","patch":"deny","task":"deny","skill":"deny","lsp":"deny","question":"deny","webfetch":"deny","websearch":"deny","todowrite":"deny","external_directory":"deny","doom_loop":"deny"}}\n' \
    "${provider_block}" "${model}" "${model}"
}

# Флаги opencode run, общие для всех запусков агента. Модель передаётся
# и в конфиге, и через -m: opencode 2.x без -m и --standalone берёт модель
# фонового сервиса пользователя, а не из OPENCODE_CONFIG_CONTENT. --pure
# (без внешних плагинов) есть только в 1.x, --standalone — только в 2.x.
#   agent_run_flags <model> -> печатает флаги по одному в строке
agent_run_flags() {
  local model="${1:?model}" help
  help="$(opencode run --help 2>&1 || true)"
  echo "--auto"
  case "${help}" in *--standalone*) echo "--standalone" ;; esac
  case "${help}" in *--pure*) echo "--pure" ;; esac
  echo "-m"
  echo "${model}"
  echo "--format"
  echo "default"
}
