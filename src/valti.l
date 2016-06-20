%option noyywrap
%{
	#include <stdlib.h>
	#include <string.h>
	#include "valti.h"

	/* Node */

	typedef enum NodeType {
		NTINST, NTEMPTY, // Handle instructions
	    NTNUM, NTVAR, // Value or variable?
		NTPLUS, NTMIN, NTMULT, NTDIV, NTPOW, NTAFF, // Operators
		NTISEQ, NTISDIFF, NTISLT, NTISGT, NTISGE, NTISLE, // Boolean operators
		NTAND, NTOR,
		NTECHO, NTIF, NTELSE // Primary instructions
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

"echo" {
	yylval.node = node_new(NTECHO);
	return(__ECHO__);
}

"if" {
	yylval.node = node_new(NTIF);
	return(__IF__);
}

"else" {
	yylval.node = node_new(NTELSE);
	return(__ELSE__);
}

{reel} {
	yylval.node = node_new(NTNUM);
	yylval.node->value = atof(yytext);
	return(NUMBER);
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
	return(MINUS);
}

"*" {
	yylval.node = node_new(NTMULT);
	return(MULTIPLY);
}
"/" {
	yylval.node = node_new(NTDIV);
	return(DIVIDE);
}

"^" {
	yylval.node = node_new(NTPOW);
	return(POWER);
}

"(" return(OP_PAR);
")" return(CL_PAR);
"{" return(OP_BRA);
"}" return(CL_BRA);

"=" {
	yylval.node = node_new(NTAFF);
	return(AFFECT);
}

"==" {
	yylval.node = node_new(NTISEQ);
	return(IS_EQUAL);
}

"!=" {
	yylval.node = node_new(NTISDIFF);
	return(IS_DIFFERENT);
}

"<" {
	yylval.node = node_new(NTISLT);
	return(IS_LOWER);
}

">" {
	yylval.node = node_new(NTISGT);
	return(IS_GREATER);
}

"<=" {
	yylval.node = node_new(NTISLE);
	return(IS_LOWER_EQUAL);
}

">=" {
	yylval.node = node_new(NTISGE);
	return(IS_GREATER_EQUAL);
}

"&&" {
	yylval.node = node_new(NTAND);
	return(BOOL_AND);
}

"||" {
	yylval.node = node_new(NTOR);
	return(BOOL_OR);
}

";" return (COLON);

"\n" return(END);
