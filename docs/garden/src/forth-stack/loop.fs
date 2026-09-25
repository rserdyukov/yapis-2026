\ Не поддерживается miniforth.py; запуск: gforth loop.fs -e bye
\ --8<-- [start:main]
: STARS ( n -- )  0 ?DO 42 EMIT LOOP ;          \ 42 — код символа *
: FACT-LOOP ( n -- n! )  1 SWAP 1+ 1 ?DO I * LOOP ;
: COUNTDOWN ( n -- )  BEGIN DUP . 1- DUP 0= UNTIL DROP ;
5 STARS CR  5 FACT-LOOP . CR  3 COUNTDOWN CR
\ --8<-- [end:main]
