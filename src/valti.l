%option noyywrap
%{
	#include "valti.h"
	#include <stdlib.h>
%}

blank [ \t]+

chiffre [0-9]
entier {chiffre}+
exposant [eE][+-]?{entier}

reel {entier}("."{entier})?{exposant}?

variable [a-zA-Z]+

%%

{blank} { /* On ignore */ }

{reel} {
	yylval.val = atof(yytext);
	return(NOMBRE);
}

{variable} {
	yylval.var = (char*)_strdup(yytext);
	return(VARIABLE);
}

"+" return(PLUS);
"-" return(MOINS);

"*" return(FOIS);
"/" return(DIVISE);

"^" return(PUISSANCE);

"(" return(PARENTHESE_GAUCHE);
")" return(PARENTHESE_DROITE);

"=" return(EGAL);

"\n" return(FIN);
