@echo off

call .\clean.bat

bison -d ..\src\valti.y
rename valti.tab.h valti.h
rename valti.tab.c valti.y.c

flex ..\src\valti.l
rename lex.yy.c valti.lex.c
gcc -c valti.lex.c -o valti.lex.o
gcc -c valti.y.c -o valti.y.o
gcc -o valti valti.lex.o valti.y.o
