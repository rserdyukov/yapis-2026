#!/usr/bin/env bash
# Примеры статьи «Erlang: модель ошибок «let it crash»».
# Erlang-примеры требуют Erlang/OTP 26+ (erlc, erl); при их отсутствии
# скрипт печатает команды. Остальные примеры требуют python3 и rustc.
set -u
cd "$(dirname "$0")"

erl_cmds=(
  "erlc messages.erl && erl -noshell -eval 'messages:main(), halt().'"
  "erlc crash.erl && erl -noshell -eval 'crash:main(), halt().'"
  "erlc supervisor_loop.erl && erl -noshell -eval 'supervisor_loop:main(), halt().'"
  "erlc calc_server.erl calc_sup.erl otp_demo.erl && erl -noshell -eval 'otp_demo:main(), halt().'"
)

if command -v erlc >/dev/null 2>&1 && command -v erl >/dev/null 2>&1; then
  for c in "${erl_cmds[@]}"; do
    echo "== $c"
    bash -c "$c"
    echo
  done
  rm -f ./*.beam
else
  echo "== Erlang/OTP не найден; команды для запуска:"
  printf '  %s\n' "${erl_cmds[@]}"
  echo
fi

echo "== python3 supervise.py   (stderr: трассировки упавших рабочих)"
python3 supervise.py
echo
echo "== python3 defensive.py"
python3 defensive.py
echo

echo "== rustc restart_thread.rs   (stderr: сообщения о панике)"
tmp=$(mktemp -d)
rustc -O -o "$tmp/restart_thread" restart_thread.rs && "$tmp/restart_thread"
rm -rf "$tmp"
