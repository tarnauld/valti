./clean.sh

bison -d ../src/valti.y
mv valti.tab.h valti.h
mv valti.tab.c valti.y.c

flex ../src/valti.l
mv lex.yy.c valti.lex.c
gcc -c valti.lex.c -o valti.lex.o -Wall
gcc -c valti.y.c -o valti.y.o -Wall
gcc -o valti valti.lex.o valti.y.o -Wall

clear
./valti main.vt
