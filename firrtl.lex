%{
#include <stdlib.h>
#include "firrtl.tab.h"  // generated via `bison -d`
%}

%option noyywrap

%%


\"[^"]*\"               {yylval.string_val = yytext; return string_literal;}
-?[0-9]+                {yylval.int_val = atoi(yytext); return int_literal;}
input                   {yylval.output = false; return dir;}
output                  {yylval.output = true; return dir;}
UInt|SInt|Fixed|Clock|Analog    {yylval.kind = yytext; return kind;}
add|sub|mul|div         {yylval.primop = yytext; return primop;}
[a-zA-Z_][a-zA-Z0-9_]*  {yylval.id = yytext; return id;}
[@:()<>\[\]{}.,]        {return yytext[0];}
[ \t\n]                 {; /* do nothing */}
%%