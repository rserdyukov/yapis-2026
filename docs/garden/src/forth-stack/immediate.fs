\ --8<-- [start:compile-time]
: HELLO  72 . ; IMMEDIATE      \ немедленное слово
: GREET  HELLO 1 . ;           \ 72 печатается при компиляции GREET
CR GREET CR                    \ при выполнении печатается только 1
: SECONDS/DAY  [ 24 60 * 60 * ] LITERAL ;   \ посчитано при компиляции
SECONDS/DAY . CR
\ --8<-- [end:compile-time]
\ --8<-- [start:unless]
: UNLESS ( C: -- orig )  POSTPONE 0= POSTPONE IF ; IMMEDIATE
: CHECK ( n -- )  0 < UNLESS 100 . THEN ;
5 CHECK  -5 CHECK  7 CHECK CR
\ --8<-- [end:unless]
