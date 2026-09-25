\ Не поддерживается miniforth.py; запуск: gforth does.fs -e bye
\ --8<-- [start:main]
: CONST ( x "name" -- )  CREATE ,  DOES> ( -- x ) @ ;
42 CONST ANSWER
: COUNTER ( "name" -- )  CREATE 0 ,  DOES> ( -- n ) DUP @ 1+ DUP ROT ! ;
COUNTER TICKS
ANSWER .  TICKS . TICKS . TICKS . CR
\ --8<-- [end:main]
