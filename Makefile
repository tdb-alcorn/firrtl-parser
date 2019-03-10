
firrtl:	firrtl.tab.c lex.yy.c
		g++ firrtl.tab.c lex.yy.c -o firrtl

firrtl.tab.c: firrtl.y
		bison -d firrtl.y

lex.yy.c: firrtl.lex firrtl.tab.c
		lex firrtl.lex

clean:
	rm -f *~ lex.yy.c firrtl.tab.c firrtl.tab.h firrtl

