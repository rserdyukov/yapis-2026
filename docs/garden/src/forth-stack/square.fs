\ --8<-- [start:main]
: SQUARE ( n -- n*n )  DUP * ;
: CUBE   ( n -- n^3 )  DUP SQUARE * ;
: HYP2   ( a b -- a^2+b^2 )  SQUARE SWAP SQUARE + ;
7 SQUARE .  3 CUBE .  3 4 HYP2 . CR
\ --8<-- [end:main]
