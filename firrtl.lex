%{
#include <stdlib.h>
#include "firrtl.tab.h"  // generated via `bison -d`
%}

%option noyywrap

%%


circuit                 {return CIRCUIT;}
module                  {return MODULE;}
extmodule               {return EXTMODULE;}

input                   {yylval.output = false; return DIR;}
output                  {yylval.output = true; return DIR;}

UInt|SInt|Fixed|Clock|Analog    {yylval.kind = yytext; return KIND;}
add|sub|mul|div         {yylval.primop = yytext; return PRIMOP;}

\"[^"]*\"               {yylval.string_val = yytext; return STRING;}
-?[0-9]+                {yylval.int_val = atoi(yytext); return INT;}

[a-zA-Z_][a-zA-Z0-9_]*  {yylval.id = yytext; return ID;}
[@:()<>\[\]{}.,]        {return yytext[0];}
[ \t\n]                 {; /* do nothing */}
%%