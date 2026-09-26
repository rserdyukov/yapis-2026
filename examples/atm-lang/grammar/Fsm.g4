// Грамматика языка FSM — языка описания конечных автоматов.
//
// Тот же язык описан второй раз для Lark: fsmc/frontend_lark/fsm.lark.
// Обе грамматики обязаны принимать одни и те же программы и строить
// одинаковое AST — это проверяет tests/test_frontends.py.
//
// Сгенерировать парсер (результат закоммичен, Java в CI и в браузере не нужна):
//   antlr4 -Dlanguage=Python3 -visitor -no-listener \
//          -o fsmc/frontend_antlr/generated -Xexact-output-dir grammar/Fsm.g4
// или просто: python3 tools/gen_antlr.py
//
// Переводы строк незначимы. Чтобы грамматика оставалась однозначной без них,
// переход в себя записывается только с действием: `A -- e -> / act`
// (после `->` идёт либо имя состояния, либо `/`).

grammar Fsm;

program
    : 'machine' name=ID decl* EOF
    ;

decl
    : constDecl
    | contextDecl
    | eventsDecl
    | statesDecl
    | initialDecl
    | terminalDecl
    | actionDecl
    | transition
    ;

// ---------------------------------------------------------------- объявления

constDecl    : 'const' name=ID ':' ty=ID '=' expr ;

contextDecl  : 'context' '{' (field (','? field)*)? '}' ;
field        : name=ID ':' ty=ID ('=' expr)? ;

eventsDecl   : 'events' '{' (eventSig (','? eventSig)*)? '}' ;
eventSig     : name=ID ('(' params? ')')? ;

params       : param (',' param)* ;
param        : name=ID ':' ty=ID ;

statesDecl   : 'states' idList ;
initialDecl  : 'initial' idList ;
terminalDecl : 'terminal' idList ;
idList       : ID (',' ID)* ;

actionDecl   : 'action' name=ID ('(' params? ')')? block ;

// ---------------------------------------------------------------- переходы

//   PinWait -- pin(c) [c == PIN]      -> Menu     / greet
//   PinWait -- pin(_) else            -> / count_attempt
//   Idle    -- pin | cancel               ignore
transition
    : source=ID DASHES triggers guard? ARROW target=ID calls?  # moveTransition
    | source=ID DASHES triggers guard? ARROW calls             # selfTransition
    | source=ID DASHES triggers 'ignore'                       # ignoreTransition
    ;

triggers     : trigger ('|' trigger)* ;
trigger      : event=ID ('(' (pattern (',' pattern)*)? ')')? ;
pattern      : name=ID (':' ty=ID)? ;

guard
    : 'else'? '[' expr ']'
    | 'else'
    ;

calls        : '/' call (',' call)* ;
call         : name=ID ('(' (expr (',' expr)*)? ')')? ;

// ---------------------------------------------------------------- операторы

block        : '{' stmt* '}' ;

stmt         : assignStmt | sayStmt | ifStmt ;
assignStmt   : target=ID '=' expr ;
sayStmt      : 'say' expr (',' expr)* ;
ifStmt       : 'if' expr block ('else' (block | ifStmt))? ;

// ---------------------------------------------------------------- выражения
// Приоритет — сверху вниз по убыванию. `not` ниже сравнений:
// `not a == b` означает `not (a == b)`.

expr
    : '(' expr ')'                                       # parenExpr
    | op='-' expr                                        # negExpr
    | expr op=('*' | '/' | '%') expr                     # binExpr
    | expr op=('+' | '-') expr                           # binExpr
    | expr op=('==' | '!=' | '<' | '<=' | '>' | '>=') expr  # binExpr
    | op='not' expr                                      # notExpr
    | expr op='and' expr                                 # binExpr
    | expr op='or' expr                                  # binExpr
    | INT                                                # intExpr
    | STRING                                             # strExpr
    | value=('true' | 'false')                           # boolExpr
    | ID                                                 # refExpr
    ;

// ---------------------------------------------------------------- лексика

// «Стрелки» любой длины, как в эскизе: `----- pin ------->`.
// ARROW длиннее DASHES на `>`, поэтому `--->` всегда стрелка.
ARROW   : '-'+ '>' ;
DASHES  : '--' '-'* ;

ID      : [\p{L}_] [\p{L}\p{Nd}_]* ;
INT     : [0-9]+ ;
STRING  : '"' (~["\\\r\n] | '\\' ["\\n])* '"' ;

COMMENT : '//' ~[\r\n]* -> skip ;
WS      : [ \t\r\n]+ -> skip ;
