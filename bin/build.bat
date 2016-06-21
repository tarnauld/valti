@echo off

call .\clean.bat

bison -d --report=state ..\src\valti.y
rename valti.tab.h valti.h
rename valti.tab.c valti.y.c

flex ..\src\valti.l
rename lex.yy.c valti.lex.c
gcc -c valti.lex.c -o valti.lex.o -Wall
gcc -c valti.y.c -o valti.y.o -Wall
gcc -o valti valti.lex.o valti.y.o -Wall

pause

cls
call valti.exe -d main.vt

pause
