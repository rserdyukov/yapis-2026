// Фрагменты из antlr/grammars-v4, python/python3_14/PythonParser.g4
// (commit 20efa537586610f5aebd584429ac1b5993a30381) и PythonLexer.g4.
// Правила скопированы дословно; секции размечены маркерами pymdownx.snippets.
// Лицензия источника воспроизводится в секции notice, как требует MIT.

// --8<-- [start:notice]
Python grammar
The MIT License (MIT)
Copyright (c) 2021 Robert Einhorn

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Project      : an ANTLR4 parser grammar for Python 3 programming language based on the official PEG grammar
               https://github.com/RobEin/ANTLR4-parser-for-Python-3.14
Developed by : Robert Einhorn
// --8<-- [end:notice]

// PythonLexer.g4:35 — токены отступов объявлены как виртуальные:
// их порождает не лексер ANTLR, а базовый класс PythonLexerBase на целевом языке.
// --8<-- [start:tokens]
tokens {
    ENCODING // https://docs.python.org/3.14/reference/lexical_analysis.html#encoding-declarations
  , INDENT, DEDENT // https://docs.python.org/3.14/reference/lexical_analysis.html#indentation
  , TYPE_COMMENT // not supported, only for compatibility with the parser grammar
}
// --8<-- [end:tokens]

// PythonParser.g4:185
// --8<-- [start:block]
block
    : NEWLINE INDENT statements DEDENT
    | simple_stmts;
// --8<-- [end:block]

// PythonParser.g4:98
// --8<-- [start:assignment]
assignment
    : name ':' expression ('=' annotated_rhs )?
    | ('(' single_target ')'
         | single_subscript_attribute_target) ':' expression ('=' annotated_rhs )?
    | (star_targets '=' )+ annotated_rhs TYPE_COMMENT?
    | single_target augassign annotated_rhs;
// --8<-- [end:assignment]

// PythonParser.g4:278
// --8<-- [start:if_stmt]
if_stmt
    : 'if' named_expression ':' block (elif_stmt | else_block?)
    ;
// --8<-- [end:if_stmt]

// PythonParser.g4:340
// --8<-- [start:match_stmt]
match_stmt
    : 'match' subject_expr ':' NEWLINE INDENT case_block+ DEDENT;
// --8<-- [end:match_stmt]

// PythonParser.g4:290
// --8<-- [start:while_stmt]
while_stmt
    : 'while' named_expression ':' block else_block?;
// --8<-- [end:while_stmt]

// PythonParser.g4:296
// --8<-- [start:for_stmt]
for_stmt
    : 'async'? 'for' star_targets 'in' star_expressions ':' TYPE_COMMENT? block else_block?
    ;
// --8<-- [end:for_stmt]

// PythonParser.g4:208
// --8<-- [start:function_def_raw]
function_def_raw
    : 'def' name type_params? '(' params? ')' ('->' expression )? ':' func_type_comment? block
    | 'async' 'def' name type_params? '(' params? ')' ('->' expression )? ':' func_type_comment? block;
// --8<-- [end:function_def_raw]
