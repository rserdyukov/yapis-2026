grammar Lang;
prog: stat+ ;
stat: decl ';' | expr ';' ;
decl: TYPE ID '=' expr ;
expr: expr op=('*'|'/') expr
    | expr op=('+'|'-') expr
    | ID | INT ;
TYPE: 'int' | 'float' ;
ID: [a-zA-Z_][a-zA-Z_0-9]* ;
INT: [0-9]+ ;
WS: [ \t\r\n]+ -> skip ;
