%option noyywrap
%{
	#include <stdlib.h>
	#include <string.h>
	#include "valti.h"

	/* Node */

	typedef enum NodeType {
	    NTNUM, NTVAR, // Value or variable?
		NTPLUS, NTMIN, NTMULT, NTDIV, NTPOW, NTEQ // Operators
	} NodeType;

	typedef struct Node {
	    NodeType type;
	    union {
	        double value;
	        char *name;
	        struct Node **children;
	    };
	} Node;

	Node *node_new(NodeType type)
	{
	    Node *node = (Node*)malloc(sizeof(Node));
	    node->type = type;
		node->name = NULL;
	    node->children = NULL;

	    return node;
	}
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
	yylval.node = node_new(NTNUM);
	yylval.node->value = atof(yytext);
	return(NOMBRE);
}

{variable} {
	yylval.node = node_new(NTVAR);
	yylval.node->name = strdup(yytext);
	return(VARIABLE);
}

"+" {
	yylval.node = node_new(NTPLUS);
	return(PLUS);
}
"-" {
	yylval.node = node_new(NTMIN);
	return(MOINS);
}

"*" {
	yylval.node = node_new(NTMULT);
	return(FOIS);
}
"/" {
	yylval.node = node_new(NTDIV);
	return(DIVISE);
}

"^" {
	yylval.node = node_new(NTPOW);
	return(PUISSANCE);
}

"(" return(OP_PAR);
")" return(CL_PAR);

"=" {
	yylval.node = node_new(NTEQ);
	return(EQUAL);
}

";" return (COLON);

"\n" return(END);
