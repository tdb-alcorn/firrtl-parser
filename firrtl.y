%{
#include <stdlib.h>
#include <stdio.h>

extern int yylex();
void yyerror(char* msg);
%}

%union {
    char* id;
    char* string_val;
    int int_val;
    bool output;
    char* kind;
    char* primop;

    // string ast_node;  // TODO
}


%token <id> id  /* [a-zA-Z_][a-zA-Z0-9_]* */
%token <string_val> string_literal /* "foobar" */
%token <int_val> int_literal  /* [0-9]+ */
%token <output> dir  /* input|output */
%token <kind> kind  /* UInt|SInt|Fixed|Clock|Analog */
%token <primop> primop  /* add|sub|mul|div|... */
// %type <ast_node> modules m_info info module ports port type basic aggregate bundle fields field vector stmts stmt exprs expr int_literals

%%

/* the prefix `m_` means `maybe` */

circuit: "circuit" id ':' m_info '(' modules ')'   { printf("%s\n", $2); }
       ;

modules: %empty
       | modules module
       ;

m_info: %empty
      | info
      ;

info: '@' '[' string_literal ']'
    ;

module: "module" id ':' m_info '(' ports stmt ')'
      | "extmodule" id ':' m_info '(' ports ')'
      ;

ports: %empty
     | ports port
     ;

port: dir id ':' type m_info
    ;

type: basic
    | aggregate
    ;

basic: kind
     | kind '<' int_literal '>'
     |  '<' int_literal '>' "<<" int_literal ">>"
     ;

aggregate   : bundle
            | vector
            ;

bundle  : '{' fields '}'
        ;

fields  : %empty
        | fields field
        ;

field   : id ':' type
        | "flip" id ':' type
        ;

vector  : type '[' int_literal ']'
        ;

stmts   : %empty
        | stmts stmt
        ;

stmt    : "wire" id ':' type m_info
        | "reg" id ':' type expr
        | expr "<=" expr m_info
        | '(' stmts ')'
        ;

expr    : id
        | expr '.' id
        | expr '[' int_literal ']'
        | expr '[' expr ']'
        | "mux" '(' expr ',' expr ',' expr ',' ')'
        | primop '(' exprs ',' int_literals ')'
        ;

exprs   : %empty
        | exprs expr
        ;

int_literals    : %empty
                | int_literals int_literal
                ;


%%

void yyerror(char* msg) {
    extern int yylineno;
    extern char *yytext;
    fprintf(stderr, "%s at symbol \"%s\" on line %d\n", msg, yytext, yylineno);
    exit(1);
}

int main() {
    yyparse();
    return 0;
}
