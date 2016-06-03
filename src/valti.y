%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <math.h>
	#include <string.h>

	/* List */
	typedef struct list {
	    char *name;
	    double value;

	    struct list *next;
	} List;

	List *list_new(char*, double);
	void list_add(List**, char*, double);
	void list_free(List**);
	List *list_get(List*, char*);
	void list_print(List*);

	/* Global */
	List *var = NULL;
%}

%union
{
	double val;
	char* var;
}

%token <val> NOMBRE
%token <var> VARIABLE
%token PLUS  MOINS FOIS  DIVISE  PUISSANCE
%token PARENTHESE_GAUCHE PARENTHESE_DROITE
%token FIN
%token EGAL

%type <val> Expression

%left PLUS MOINS
%left FOIS DIVISE
%left NEG
%right PUISSANCE

%start Input
%%

Input:
    /* Vide */
  | Input Ligne
  ;

Ligne:
	FIN
  | Expression FIN {
	  printf("Result: %f\n", $1);
  }
  | VARIABLE EGAL Expression FIN {
	  list_add(&var, $1, $3);
	  printf("Affectation: %s = %f\n", $1, $3);
  }
  ;

Expression:
    NOMBRE { $$ = $1; }
  | VARIABLE {
	  List *v = list_get(var, $1);

	  if(v) {
		  $$ = v->value;
	  }
	  else {
		  printf("Unknown variable: %s\n", $1);
		  return;
	  }
  }
  | Expression PLUS Expression { $$ = $1 + $3; }
  | Expression MOINS Expression { $$ = $1 - $3; }
  | Expression FOIS Expression { $$ = $1 * $3; }
  | Expression DIVISE Expression { $$ = $1 / $3; }
  | MOINS Expression %prec NEG { $$ = -$2; }
  | Expression PUISSANCE Expression { $$ = pow($1, $3); }
  | PARENTHESE_GAUCHE Expression PARENTHESE_DROITE { $$ = $2; }
  ;

%%

/* Main */

int yyerror(char *s)
{
	printf("%s\n", s);
  	list_free(&var);
}

int main(int argc, char **argv)
{
  	yyparse();
	list_free(&var);
}

/* List */

List *list_new(char *name, double value)
{
    List *list = malloc(sizeof(List));

    if(list)
    {
        list->name = name;
        list->value = value;
        list->next = NULL;
    }

    return list;
}

void list_add(List **list, char *name, double value)
{
    if(list)
    {
        int i, size = strlen(name);
        char *str = malloc((size + 1) * sizeof(char));
        List *tmp = NULL;

        for(i = 0 ; i < size ; i++)
            str[i] = name[i];
        str[i] = '\0';

        tmp = list_new(str, value);

        if(*list)
            tmp->next = *list;
        *list = tmp;
    }
}

void list_free(List **list)
{
    if(list)
    {
        while(*list)
        {
            List *tmp = (*list)->next;

            free((*list)->name);
            free(*list);

            *list = tmp;
        }
    }
}

List *list_get(List *list, char *name)
{
    while(list)
    {
        if(strcmp(list->name, name) == 0)
            return list;
        list = list->next;
    }

    return NULL;
}

void list_print(List *list)
{
    while(list)
    {
        printf("%s = %lf\n", list->name, list->value);
        list = list->next;
    }
}
