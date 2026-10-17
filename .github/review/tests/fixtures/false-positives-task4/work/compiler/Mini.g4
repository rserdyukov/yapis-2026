// Грамматика языка Mini. Анализатор compiler/mini.py разбирает её вручную,
// построчно; файл — описание синтаксиса для отчёта.
grammar Mini;

// Порядок: глобальные переменные, затем функции, затем операторы.
program: NL* varDecl* funcDecl* statement* EOF;

varDecl: TYPE ID '=' expr NL*;
funcDecl: 'func' TYPE ID '(' (param (',' param)*)? ')' NL* body 'end' NL*;
param: ('val' | 'res') TYPE ID;
body: (varDecl | statement)*;

statement
    : ID '=' expr NL*
    | 'if' expr NL* body 'end' NL*
    | 'return' expr NL*
    | call NL*
    ;

expr
    : expr ('*' | '/') expr
    | expr ('+' | '-') expr
    | expr ('<' | '>') expr
    | call
    | INT
    | FLOAT
    | BOOL
    | ID
    ;
call: ID '(' (expr (',' expr)*)? ')';

TYPE: 'int' | 'float' | 'bool' | 'void';
BOOL: 'true' | 'false';
ID: [A-Za-z_] [A-Za-z0-9_]*;
FLOAT: [0-9]+ '.' [0-9]+;
INT: [0-9]+;
COMMENT: '#' ~[\r\n]* -> skip;
NL: '\r'? '\n';
WS: [ \t]+ -> skip;
