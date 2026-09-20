// Фрагменты из antlr/grammars-v4, java/java/JavaParser.g4
// (commit 20efa537586610f5aebd584429ac1b5993a30381).
// Правила скопированы дословно; секции размечены маркерами pymdownx.snippets.
// Лицензия источника воспроизводится в секции notice: BSD-3-Clause требует
// сохранять уведомление при распространении исходного кода.

// --8<-- [start:notice]
 [The "BSD licence"]
 Copyright (c) 2013 Terence Parr, Sam Harwell
 Copyright (c) 2017 Ivan Kochurkin (upgrade to Java 8)
 Copyright (c) 2021 Michał Lorek (upgrade to Java 11)
 Copyright (c) 2022 Michał Lorek (upgrade to Java 17)
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
    derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// --8<-- [end:notice]

// JavaParser.g4:478
// --8<-- [start:localVariableDeclaration]
localVariableDeclaration
    : variableModifier* (VAR identifier '=' expression | typeType variableDeclarators)
    ;
// --8<-- [end:localVariableDeclaration]

// JavaParser.g4:468
// --8<-- [start:block]
block
    : '{' blockStatement* '}'
    ;
// --8<-- [end:block]

// JavaParser.g4:521 — первые альтернативы правила statement
// --8<-- [start:statement]
statement
    : blockLabel = block
    | ASSERT expression (':' expression)? ';'
    | IF '(' expression ')' statement (ELSE statement)?
    | FOR '(' forControl ')' statement
    | WHILE '(' expression ')' statement
    | DO statement WHILE '(' expression ')' ';'
    | TRY block (catchClause+ finallyBlock? | finallyBlock)
    | TRY resourceSpecification block catchClause* finallyBlock?
    | SWITCH '(' expression ')' '{' switchBlockStatementGroup* switchLabel* '}'
    // ... остальные альтернативы опущены
    ;
// --8<-- [end:statement]

// JavaParser.g4:722
// --8<-- [start:switchExpression]
switchExpression
    : SWITCH '(' expression ')' '{' switchLabeledRule* '}'
    ;
// --8<-- [end:switchExpression]

// JavaParser.g4:584
// --8<-- [start:forControl]
forControl
    : enhancedForControl
    | forInit? ';' expression? ';' forUpdate = expressionList?
    ;
// --8<-- [end:forControl]

// JavaParser.g4:168
// --8<-- [start:methodDeclaration]
methodDeclaration
    : typeTypeOrVoid identifier formalParameters ('[' ']')* (THROWS qualifiedNameList)? methodBody
    ;
// --8<-- [end:methodDeclaration]

// JavaParser.g4:305
// --8<-- [start:formalParameter]
formalParameter
    : variableModifier* typeType (annotation* '...')? variableDeclaratorId
    ;
// --8<-- [end:formalParameter]
