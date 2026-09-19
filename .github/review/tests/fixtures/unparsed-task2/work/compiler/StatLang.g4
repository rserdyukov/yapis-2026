// Грамматика StatLang (ЛР2).
// Намеренные дефекты фикстуры: нет лексерного правила для комментариев `//`
// и нет ветки else в условном операторе — примеры ЛР1 не разбираются.
grammar StatLang;

program : funcDecl* statement* EOF ;

funcDecl : type ID '(' paramList? ')' block ;
paramList : type ID (',' type ID)* ;

block : '{' statement* '}' ;

statement
    : varDecl
    | assignment
    | ifStmt
    | whileStmt
    | returnStmt
    | exprStmt
    ;

varDecl    : type ID '=' expr ';' ;
assignment : ID '=' expr ';' ;
ifStmt     : 'if' '(' expr ')' block ;
whileStmt  : 'while' '(' expr ')' block ;
returnStmt : 'return' expr ';' ;
exprStmt   : expr ';' ;

type : 'int' | 'float' | 'string' ;

// Приоритеты: от низшего к высшему.
expr
    : expr ('&&' | '||') expr
    | expr ('==' | '!=' | '<' | '>' | '<=' | '>=') expr
    | expr ('+' | '-') expr
    | expr ('*' | '/' | '%') expr
    | '!' expr
    | '-' expr
    | ID '(' argList? ')'
    | ID
    | INT
    | FLOAT
    | STRING
    | '(' expr ')'
    ;

argList : expr (',' expr)* ;

INT    : [0-9]+ ;
FLOAT  : [0-9]+ '.' [0-9]+ ;
STRING : '"' (~["\r\n])* '"' ;
ID     : [a-zA-Z_][a-zA-Z0-9_]* ;
WS     : [ \t\r\n]+ -> skip ;
