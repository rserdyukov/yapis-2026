// Фрагменты из antlr/grammars-v4, rust/RustParser.g4
// (commit 20efa537586610f5aebd584429ac1b5993a30381).
// Правила скопированы дословно; секции размечены маркерами pymdownx.snippets.
// Лицензия источника воспроизводится в секции notice, как требует MIT.

// --8<-- [start:notice]
Copyright (c) 2010 The Rust Project Developers
Copyright (c) 2020-2022 Student Main

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice (including the next paragraph) shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// --8<-- [end:notice]

// RustParser.g4:430
// --8<-- [start:letStatement]
letStatement
    : outerAttribute* KW_LET patternNoTopAlt (COLON type_)? (EQ expression)? SEMI
    ;
// --8<-- [end:letStatement]

// RustParser.g4:537
// --8<-- [start:blockExpression]
blockExpression
    : LCURLYBRACE innerAttribute* statements? RCURLYBRACE
    ;
// --8<-- [end:blockExpression]

// RustParser.g4:677
// --8<-- [start:ifExpression]
ifExpression
    : KW_IF expression blockExpression (KW_ELSE (blockExpression | ifExpression | ifLetExpression))?
    ;
// --8<-- [end:ifExpression]

// RustParser.g4:688
// --8<-- [start:matchExpression]
matchExpression
    : KW_MATCH expression LCURLYBRACE innerAttribute* matchArms? RCURLYBRACE
    ;
// --8<-- [end:matchExpression]

// RustParser.g4:647
// --8<-- [start:loopExpression]
loopExpression
    : loopLabel? (
        infiniteLoopExpression
        | predicateLoopExpression
        | predicatePatternLoopExpression
        | iteratorLoopExpression
    )
    ;
// --8<-- [end:loopExpression]

// RustParser.g4:195
// --8<-- [start:function_]
function_
    : functionQualifiers KW_FN identifier genericParams? LPAREN functionParameters? RPAREN functionReturnType? whereClause? (
        blockExpression
        | SEMI
    )
    ;
// --8<-- [end:function_]

// RustParser.g4:232
// --8<-- [start:functionParamPattern]
functionParamPattern
    : pattern COLON (type_ | DOTDOTDOT)
    ;
// --8<-- [end:functionParamPattern]
