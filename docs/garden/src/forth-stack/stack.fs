\ --8<-- [start:main]
1 2 SWAP .S CR  DROP DROP        \ SWAP ( a b -- b a )
1 2 OVER .S CR  DROP DROP DROP   \ OVER ( a b -- a b a )
1 2 3 ROT .S CR DROP DROP DROP   \ ROT  ( a b c -- b c a )
5 DUP * . CR                     \ DUP  ( a -- a a ), затем *
\ --8<-- [end:main]
