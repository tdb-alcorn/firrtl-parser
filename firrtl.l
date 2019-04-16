/* Firrtl lexer */

/* Indentation parsing derived with modification from https://github.com/lucasb-eyer/flex-bison-indentation */

%{
#include <stdlib.h>
#include <stack>
#include "firrtl.tab.h"  // generated via `bison -d`

/* globals to track current indentation */
int g_current_line_indent = 0;  /* indentation of current line */
std::stack<size_t> g_indent_levels;
int g_is_fake_outdent_symbol = 0;

static const unsigned int TAB_WIDTH = 2;

#define YY_USER_INIT { \
    g_indent_levels.push(0); \
    BEGIN(initial); \
}

int yycolumn = 1;

void set_yycolumn(int val) {
    yycolumn = val;
    yylloc.first_column = yycolumn;
    yylloc.last_column = yycolumn + yyleng - 1;
}

#define YY_USER_ACTION { \
    yylloc.first_line = yylloc.last_line = yylineno; \
    set_yycolumn(yycolumn); \
    yycolumn += yyleng; \
}


%}

/* sub-parser for indentation-sensitive scoping */

%x initial
%x indent
%s normal


%option warn
%option noyywrap
%option nodefault
%option yylineno

%%
    int indent_caller = normal;

 /* This helps to keep track of the column number.
  * Note that it won't work if you have a rule which includes a newline and is
  * longer than one character because in that case that rule will be favored
  * and this one here won't get called.
  * TL;DR: If you have a rule which includes \n and more, you need to reset
  *        yycolumn inside that rule!
  */
<*>\n { set_yycolumn(0); yylineno--; REJECT; }

 /* Everything runs in the <normal> mode and enters the <indent> mode
    when a newline symbol is encountered.
    There is no newline symbol before the first line, so we need to go
    into the <indent> mode by hand there.
 */
<initial>.  { set_yycolumn(yycolumn-1); indent_caller = normal; yyless(0); BEGIN(indent); }
<initial>\n { indent_caller = normal; yyless(0); BEGIN(indent); }

 /* The following are the rules that keep track of indentation. */
<indent>" "     { g_current_line_indent++; }
<indent>\t      { g_current_line_indent = (g_current_line_indent + TAB_WIDTH) & ~(TAB_WIDTH-1); }
<indent>\n      { g_current_line_indent = 0; /* ignoring blank line */ }
<indent><<EOF>> {
                    // When encountering the end of file, we want to emit an
                    // outdent for all indents currently left.
                    if (g_indent_levels.top() != 0) {
                        g_indent_levels.pop();

                        // See the same code below (<indent>.) for a rationale.
                        if (g_current_line_indent != g_indent_levels.top()) {
                            unput('\n');
                            for(size_t i = 0 ; i < g_indent_levels.top() ; ++i) {
                                unput(' ');
                            }
                        } else {
                            BEGIN(indent_caller);
                        }

                        return ')';
                    } else {
                        yyterminate();
                    }
                }
<indent>.       {
                    if (!g_is_fake_outdent_symbol) {
                        unput(*yytext);
                    }
                    set_yycolumn(yycolumn-1);
                    g_is_fake_outdent_symbol = 0;

                    // Indentation level has increased. It can only ever
                    // increase by one level at a time. Remember how many
                    // spaces this level has and emit an indentation token.
                    if(g_current_line_indent > g_indent_levels.top()) {
                        g_indent_levels.push(g_current_line_indent);
                        BEGIN(indent_caller);
                        return '(';
                    } else if(g_current_line_indent < g_indent_levels.top()) {
                        // Outdenting is the most difficult, as we might need to
                        // outdent multiple times at once, but flex doesn't allow
                        // emitting multiple tokens at once! So we fake this by
                        // 'unput'ting fake lines which will give us the next
                        // outdent.
                        g_indent_levels.pop();

                        if(g_current_line_indent != g_indent_levels.top()) {
                            // Unput the rest of the current line, including the newline.
                            // We want to keep it untouched.
                            for(size_t i = 0 ; i < g_current_line_indent ; ++i) {
                                unput(' ');
                            }
                            unput('\n');
                            // Now, insert a fake character indented just so
                            // that we get a correct outdent the next time.
                            unput('.');
                            // Though we need to remember that it's a fake one
                            // so we can ignore the symbol.
                            g_is_fake_outdent_symbol = 1;
                            for(size_t i = 0 ; i < g_indent_levels.top() ; ++i) {
                                unput(' ');
                            }
                            unput('\n');
                        } else {
                            BEGIN(indent_caller);
                        }

                        return ')';
                    } else {
                        // No change in indentation, not much to do here...
                        BEGIN(indent_caller);
                    }
                }

<normal>\n { g_current_line_indent = 0; indent_caller = YY_START; BEGIN(indent); }
<normal><<EOF>> { g_current_line_indent = 0; indent_caller = YY_START; BEGIN(indent); }

<normal>circuit                 {return CIRCUIT;}
<normal>module                  {return MODULE;}
<normal>extmodule               {return EXTMODULE;}
<normal>wire                    {return WIRE;}
<normal>reg                     {return REG;}
<normal>mux                     {return MUX;}
<normal>node                    {return NODE;}
<normal>inst                    {return INST;}
<normal>of                      {return OF;}

<normal>when                    {return WHEN;}
<normal>else                    {return ELSE;}

<normal>input                   {yylval.output = false; return DIR;}
<normal>output                  {yylval.output = true; return DIR;}
<normal>flip                    {return FLIP;}

<normal>UInt|SInt|Fixed|Clock|Analog    {yylval.kind = strdup(yytext); return KIND;}
<normal>add|sub|mul|div|asFixedPoint|tail|gt|lt    {yylval.primop = yytext; return PRIMOP;}
<normal><=                      {return ASSIGN;}

<normal>\"[^"]*\"               {yylval.string_val = yytext; return STRING;}
<normal>-?[0-9]+                {yylval.int_val = atoi(yytext); return INT;}

<normal>[ \t]                   { /* do nothing */ }

<normal>[a-zA-Z_][a-zA-Z0-9_]*  {yylval.id = yytext; return ID;}
<normal>[:()<>\[\]{}.,=]        {return yytext[0];}
<normal>\<\<                    {return LEFTLEFT;}
<normal>\>\>                    {return RIGHTRIGHT;}
<normal>@\[.*\]                 {yylval.info = yytext; return INFO;}

(.|\n)                          {fprintf(stderr, "Unexpected token at line %d column %d: '%s'\n", yylineno, yycolumn, yytext); exit(1);}

%%