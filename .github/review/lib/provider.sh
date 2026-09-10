#!/usr/bin/env bash
# Определяет провайдера модели и имя переменной окружения с ключом.
#
# ЗАЧЕМ. opencode поддерживает 200+ провайдеров (см. https://models.dev),
# и жёсткий список из трёх штук в коде означал бы, что студент не может
# подключить свою модель. Здесь имя ключа выводится по общему правилу
# <PROVIDER>_API_KEY, а исключения перечислены явной таблицей.
#
# Использование (через source):
#     source lib/provider.sh
#     provider_for "openrouter/nvidia/model:free"   -> печатает "openrouter"
#     key_var_for  "openrouter"                     -> печатает "OPENROUTER_API_KEY"
#     key_url_for  "openrouter"                     -> печатает URL для получения ключа
#     local_only   "ollama"                         -> код 0, если ключ не нужен

# Провайдеры, у которых имя переменной не выводится из имени провайдера.
# Формат: <провайдер>=<ИМЯ_ПЕРЕМЕННОЙ>
_PROVIDER_KEY_EXCEPTIONS="
google=GEMINI_API_KEY
google-vertex=GOOGLE_APPLICATION_CREDENTIALS
amazon-bedrock=AWS_ACCESS_KEY_ID
azure=AZURE_API_KEY
github-copilot=GITHUB_TOKEN
opencode=OPENCODE_API_KEY
"

# Провайдеры, работающие локально: ключ не требуется.
_PROVIDER_LOCAL="ollama lmstudio llama.cpp atomic-chat"

# Где получить ключ. Только для популярных — для остальных даём общую ссылку.
_PROVIDER_KEY_URLS="
openrouter=https://openrouter.ai/keys
groq=https://console.groq.com/keys
google=https://aistudio.google.com/apikey
anthropic=https://console.anthropic.com/settings/keys
openai=https://platform.openai.com/api-keys
deepseek=https://platform.deepseek.com/api_keys
mistral=https://console.mistral.ai/api-keys
cerebras=https://cloud.cerebras.ai
together=https://api.together.ai/settings/api-keys
xai=https://console.x.ai
"

# Первый сегмент модели до '/' — это провайдер.
# Пример: openrouter/nvidia/nemotron:free -> openrouter
provider_for() {
  printf '%s' "${1%%/*}"
}

# true, если провайдер работает локально и ключ не нужен.
local_only() {
  case " ${_PROVIDER_LOCAL} " in
    *" ${1} "*) return 0 ;;
    *)          return 1 ;;
  esac
}

# Имя переменной окружения с ключом. Пустая строка — ключ не требуется.
key_var_for() {
  local provider="${1}"
  local_only "${provider}" && { printf ''; return 0; }

  local line
  while IFS= read -r line; do
    [ -z "${line}" ] && continue
    case "${line}" in
      "${provider}="*) printf '%s' "${line#*=}"; return 0 ;;
    esac
  done <<< "${_PROVIDER_KEY_EXCEPTIONS}"

  # Общее правило: openrouter -> OPENROUTER_API_KEY, deepseek -> DEEPSEEK_API_KEY.
  # Дефисы и точки в именах провайдеров заменяем на подчёркивание.
  printf '%s_API_KEY' \
    "$(printf '%s' "${provider}" | tr '[:lower:].-' '[:upper:]__')"
}

key_url_for() {
  local provider="${1}" line
  while IFS= read -r line; do
    [ -z "${line}" ] && continue
    case "${line}" in
      "${provider}="*) printf '%s' "${line#*=}"; return 0 ;;
    esac
  done <<< "${_PROVIDER_KEY_URLS}"
  printf 'https://opencode.ai/docs/providers/#%s' "${provider}"
}
