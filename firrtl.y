/* Firrtl parser */

%{
#include <stdlib.h>
#include <stdio.h>

extern int yylex();
void yyerror(const char* msg);
extern char* yytext;
%}

%define parse.error verbose

%union {
    char* id;
    char* string_val;
    int int_val;
    bool output;
    char* kind;
    char* primop;
    char* circuit;
    char* info;

    // string ast_node;  // TODO
}


%token <id> ID  /* [a-zA-Z_][a-zA-Z0-9_]* */
%token <string_val> STRING  /* "foobar" */
%token <int_val> INT  /* [0-9]+ */
%token <output> DIR  /* input|output */
%token <kind> KIND  /* UInt|SInt|Fixed|Clock|Analog */
%token <primop> PRIMOP  /* add|sub|mul|div|... */
%token <info> INFO /* @[foo.scala 1:23] */

%token CIRCUIT  /* circuit */
%token MODULE
%token EXTMODULE
%token WIRE
%token REG
%token MUX
%token FLIP
%token NODE
%token INST
%token OF
// %type <ast_node> modules m_info info module ports port type basic aggregate bundle fields field vector stmts stmt exprs expr ints

%token WHEN
%token ELSE

%token ASSIGN
%token LEFTLEFT
%token RIGHTRIGHT

%type <circuit> circuit

%locations

%%

/* the prefix `m_` means `maybe` */

circuit: CIRCUIT ID ':' m_info '(' modules ')' {printf("parsed circuit %s\n", $2);}
       ;

modules: %empty
       | modules module
       ;

m_info: %empty
      | INFO
      ;

module: MODULE ID ':' m_info '(' ports stmts ')'
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
     | KIND '<' INT '>' LEFTLEFT INT RIGHTRIGHT
     ;

aggregate: bundle
         | vector
         ;

bundle: '{' fields '}'
      ;

fields: %empty
      | fields ',' field
      | field
      ;

field: ID ':' type
     | FLIP ID ':' type
     ;

vector: type '[' INT ']'
      ;

stmts: %empty
     | stmts stmt
     ;

stmt: WIRE ID ':' type m_info
    | REG ID ':' type ',' expr
    | NODE ID '=' expr m_info
    | INST ID OF ID m_info
    | expr ASSIGN expr m_info
    | when
    | '(' stmts ')'
    ;

when: WHEN expr ':' m_info stmt
    | WHEN expr ':' m_info stmt ELSE ':' stmt
    ;

expr: basic '(' INT ')'
    | basic '(' STRING ')'
    | ID
    | expr '.' ID
    | expr '[' INT ']'
    | expr '[' expr ']'
    | MUX '(' expr ',' expr ',' expr ')'
    | PRIMOP '(' primop_args ')'
    ;

primop_args: expr
    | INT
    | primop_args ',' expr
    | primop_args ',' INT
    ;


%%

void yyerror(const char* msg) {
    // extern int yylineno;
    // extern int yycolumn;
    extern char *yytext;
    fprintf(stderr, "%s at symbol \"%s\" on line %d column %d:%d\n",
        msg, yytext, yylloc.first_line, yylloc.first_column, yylloc.last_column);
    extern int yylineno;
    exit(1);
}

int main(int argc, char **argv) {
    if ((argc > 1) && (freopen(argv[1], "r", stdin) == NULL))
    {
        fprintf(stderr, "%s: File %s cannot be opened.\n", argv[0], argv[1]);
        exit(1);
    }

#if YYDEBUG
    printf("%d\n", YYDEBUG);
    yydebug = 1;
#endif

    yyparse();
    return 0;
}
