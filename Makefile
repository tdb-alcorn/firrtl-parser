
firrtl:	firrtl.tab.c lex.yy.c
	g++ ast.cc firrtl.tab.c lex.yy.c -o firrtl

firrtl.tab.c: firrtl.y
	bison -d firrtl.y

lex.yy.c: firrtl.l firrtl.tab.c
	lex firrtl.l

clean:
	rm -f *~ lex.yy.c firrtl.tab.c firrtl.tab.h firrtl

debug: firrtl.tab.c.debug lex.yy.c
	g++ firrtl.tab.c lex.yy.c -o firrtl

firrtl.tab.c.debug: firrtl.y
	bison -d --debug --verbose firrtl.y
