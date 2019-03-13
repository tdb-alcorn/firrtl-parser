/* Firrtl parser */

%{
#include <stdlib.h>
#include <stdio.h>

extern int yylex();
void yyerror(char* msg);
extern char* yytext;
%}

%union {
    char* id;
    char* string_val;
    int int_val;
    bool output;
    char* kind;
    char* primop;
    char* circuit;

    // string ast_node;  // TODO
}


%token <id> ID  /* [a-zA-Z_][a-zA-Z0-9_]* */
%token <string_val> STRING  /* "foobar" */
%token <int_val> INT  /* [0-9]+ */
%token <output> DIR  /* input|output */
%token <kind> KIND  /* UInt|SInt|Fixed|Clock|Analog */
%token <primop> PRIMOP  /* add|sub|mul|div|... */

%token CIRCUIT  /* circuit */
%token MODULE
%token EXTMODULE
// %type <ast_node> modules m_info info module ports port type basic aggregate bundle fields field vector stmts stmt exprs expr ints

%type <circuit> circuit

%locations

%%

/* the prefix `m_` means `maybe` */

circuit: CIRCUIT ID ':' m_info '(' modules ')' {printf("%s\n", $$);}
       ;

modules: %empty
       | modules module
       ;

m_info: %empty
      | info
      ;

info: '@' '[' STRING ']'
    ;

module: MODULE ID ':' m_info '(' ports stmt ')'
      | EXTMODULE ID ':' m_info '(' ports ')'
      ;

ports: %empty
     | ports port
     ;

port: DIR ID ':' type m_info
    ;

type: basic
    | aggregate
    ;

basic: KIND
     | KIND '<' INT '>'
     |  '<' INT '>' "<<" INT ">>"
     ;

aggregate: bundle
         | vector
         ;

bundle: '{' fields '}'
      ;

fields: %empty
      | fields field
      ;

field: ID ':' type
     | "flip" ID ':' type
     ;

vector: type '[' INT ']'
      ;

stmts: %empty
     | stmts stmt
     ;

stmt: "wire" ID ':' type m_info
    | "reg" ID ':' type expr
    | expr "<=" expr m_info
    | '(' stmts ')'
    ;

expr: ID
    | expr '.' ID
    | expr '[' INT ']'
    | expr '[' expr ']'
    | "mux" '(' expr ',' expr ',' expr ',' ')'
    | PRIMOP '(' exprs ',' ints ')'
    ;

exprs: %empty
     | exprs expr
     ;

ints: %empty
    | ints INT
    ;


%%

void yyerror(char* msg) {
    // extern int yylineno;
    // extern int yycolumn;
    extern char *yytext;
    fprintf(stderr, "%s at symbol \"%s\" on line %d column %d:%d\n", msg, yytext, yylloc.first_line, yylloc.first_column, yylloc.last_column);
    exit(1);
}

int main(int argc, char **argv) {
    if ((argc > 1) && (freopen(argv[1], "r", stdin) == NULL))
    {
        fprintf(stderr, "%s: File %s cannot be opened.\n", argv[0], argv[1]);
        exit(1);
    }

#ifdef YYDEBUG
    yydebug = 1;
#endif

    yyparse();
    return 0;
}
