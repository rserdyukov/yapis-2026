grammar Mini;

program : (function | statement)* EOF ;

function  : type ID '(' (param (',' param)*)? ')' block ;
param     : type ID ;
type      : 'int' | 'float' | 'bool' | 'string' | 'void' ;
block     : '{' statement* '}' ;

statement
    : type ID '=' expr ';'
    | ID '=' expr ';'
    | 'if' '(' expr ')' block ('else' block)?
    | 'while' '(' expr ')' block
    | 'return' expr? ';'
    | 'print' '(' expr ')' ';'
    | call ';'
    ;

expr
    : '-' expr
    | expr ('*' | '/') expr
    | expr ('+' | '-') expr
    | expr ('<' | '>' | '<=' | '>=' | '==' | '!=') expr
    | primary
    ;

primary : INT | FLOAT | STRING | 'true' | 'false' | call | ID | '(' expr ')' ;
call    : ID '(' (expr (',' expr)*)? ')' ;

ID      : [A-Za-z_] [A-Za-z0-9_]* ;
FLOAT   : [0-9]+ '.' [0-9]+ ;
INT     : [0-9]+ ;
STRING  : '"' ~["\r\n]* '"' ;
COMMENT : '//' ~[\r\n]* -> skip ;
WS      : [ \t\r\n]+ -> skip ;
