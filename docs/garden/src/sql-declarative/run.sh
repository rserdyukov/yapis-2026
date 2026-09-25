#!/usr/bin/env bash
# Запускает все примеры статьи «SQL: декларативность».
# Требуется: sqlite3 (проверено 3.51.0), python3, node (Object.groupBy — Node 21+).
set -u
cd "$(dirname "$0")"

run_sql() {  # $1 — файл с запросами, остальные — опции sqlite3
  local file=$1; shift
  echo "== $file"
  cat data.sql "$file" | sqlite3 -batch "$@" :memory:
  echo
}

sqlite3 --version
run_sql plan.sql
run_sql aggregate.sql -header -column
run_sql reach.sql -header -column
run_sql nulls_order.sql -separator ' | '

echo "== host.py"
python3 host.py
echo

echo "== streams.mjs"
node streams.mjs
echo

echo "== reach.pl (SWI-Prolog)"
if command -v swipl >/dev/null 2>&1; then
  swipl -g "forall(reach(X,Y), (write(X-Y), nl)), halt" reach.pl
else
  echo "  swipl не найден; команда: swipl -g \"forall(reach(X,Y), (write(X-Y), nl)), halt\" reach.pl"
fi
