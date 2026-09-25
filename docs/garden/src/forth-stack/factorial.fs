\ --8<-- [start:main]
: FACT ( n -- n! )
  DUP 2 < IF DROP 1 ELSE DUP 1- RECURSE * THEN ;
0 FACT .  1 FACT .  5 FACT .  10 FACT . CR
\ --8<-- [end:main]
