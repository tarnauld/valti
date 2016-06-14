%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <math.h>
	#include <string.h>

	extern int yyparse();
	extern FILE *yyin;

	/* Node */
	typedef enum NodeType {
	    NTNUM, NTVAR, // Value or variable?
		NTPLUS, NTMIN, NTMULT, NTDIV, NTPOW, NTEQ, // Operators
		NTINST, NTEMPTY // Handle instructions
	} NodeType;

	typedef struct Node {
	    NodeType type;
	    union {
	        double value;
	        char *name;
	        struct Node **children;
	    };
	} Node;

	Node *node_new(NodeType type);
	Node *node_children(Node*, Node*, Node*);
	void exec(Node*);
	double calculate_expression(Node*);
	void tree_print(Node*, int);
	void tree_free(Node*);

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
	List *variables = NULL;
%}

%union {
	struct Node *node;
}

%token <node> NOMBRE VARIABLE
%token <node> PLUS MOINS FOIS DIVISE PUISSANCE EQUAL
%token OP_PAR CL_PAR COLON
%token END

%type <node> InstList
%type <node> Inst
%type <node> Expression

%left PLUS MOINS
%left FOIS DIVISE
%left NEG
%right PUISSANCE

%start Input
%%

Input:
    /* Empty */
	| Input Line
	;

Line:
	END
	| InstList END {
		// Process the tree
		tree_print($1, 0);
		exec($1);
		tree_free($1);
	}
	;

InstList:
	Inst {
		Node *inst = node_new(NTINST);
		Node *empty = node_new(NTEMPTY);

		$$ = node_children(inst, $1, empty);
	}
	| InstList Inst {
		Node *inst = node_new(NTINST);
		$$ = node_children(inst, $1, $2);
	}
	;

Inst:
	// Expression
	Expression COLON {
		$$ = $1;
	}
	// Affectation
	| VARIABLE EQUAL Expression COLON {
    	// Add the affectation in the tree
    	$$ = node_children($2, $1, $3);
    }
	;

Expression:
    NOMBRE {
		$$ = $1;
	}
  	| VARIABLE {
		$$ = $1;
	}
	| Expression PLUS Expression {
		$$ = node_children($2, $1, $3);
	}
	| Expression MOINS Expression {
		$$ = node_children($2, $1, $3);
	}
	| Expression FOIS Expression {
		$$ = node_children($2, $1, $3);
	}
	| Expression DIVISE Expression {
		$$ = node_children($2, $1, $3);
	}
	| MOINS Expression %prec NEG {
		$2->value = -($2->value);
		$$ = $2;
	}
	| Expression PUISSANCE Expression {
		$$ = node_children($2, $1, $3);
	}
	| OP_PAR Expression CL_PAR {
		$$ = $2;
	}
	;

%%

/* Main */
int yyerror(char *s)
{
	printf("%s\n", s);
	list_free(&variables);
}

int main(int argc, char **argv)
{
	FILE *src = NULL;

	if((argc == 3) && (strcmp(argv[1], "-f") == 0))
	{
		src = fopen(argv[2], "r");
		if(!src)
		{
			printf("Impossible d'ouvrir le fichier à executer.\n");
			exit(-1);
		}

		yyin = src;
	}

	yyparse();

	// Cleanup
	if(src)
		fclose(src);
	list_free(&variables);

	exit(0);
}

/* Node */

Node *node_children(Node *father, Node *child1, Node *child2)
{
    father->children = (Node**)malloc(sizeof(Node*) * 2);
    father->children[0] = child1;
    father->children[1] = child2;

    return father;
}

void exec(Node *node)
{
	double val;

	switch(node->type)
	{
		case NTINST:
			exec(node->children[0]);
			exec(node->children[1]);
			break;

		case NTEMPTY:
			break;

		case NTEQ:
			// We ignore the left (NTVAR) part of the tree when processing an = (NTEQ) node.
			val = calculate_expression(node->children[1]);

			// Store a new variable in memory
			list_add(&variables, node->children[0]->name, val);
			printf("Affectation: %s = %f\n", node->children[0]->name, val);
			break;

		// Arithmetic expression
		default:
			val = calculate_expression(node);
			printf("%lf\n\n", val);
	}
}

double calculate_expression(Node *node)
{
	// Temp variables
	List *var = NULL;

    switch(node->type)
    {
        case NTNUM:
            return node->value;
            break;

		case NTVAR:
			var = list_get(variables, node->name);

			if(var)
				return var->value;
			printf("Unknown variable: %s\n", node->name);
			break;

        case NTPLUS:
            return calculate_expression(node->children[0]) + calculate_expression(node->children[1]);
            break;

        case NTMIN:
            return calculate_expression(node->children[0]) - calculate_expression(node->children[1]);
            break;

        case NTMULT:
            return calculate_expression(node->children[0]) * calculate_expression(node->children[1]);
            break;

        case NTDIV:
            return calculate_expression(node->children[0]) / calculate_expression(node->children[1]);
            break;

        case NTPOW:
            return calculate_expression(node->children[0]) + calculate_expression(node->children[1]);
            break;
    }
}

void tree_print(Node *node, int stage)
{
    int i;

    for(i = 0 ; i < stage ; i++)
        printf(" ");

    switch(node->type)
    {
		case NTINST: printf("Inst {"); break;
		case NTEMPTY: printf("}"); break;

        case NTNUM: printf("%.2lf", node->value); break;
        case NTVAR: printf("%s", node->name); break;
        case NTPLUS: printf("+"); break;
		case NTMIN: printf("-"); break;
        case NTMULT: printf("*"); break;
        case NTDIV: printf("/"); break;
        case NTPOW: printf("^"); break;
        case NTEQ: printf("="); break;
    }
    printf("\n");

    if(node->children && node->type != NTVAR)
    {
        tree_print(node->children[0], stage + 1);
        tree_print(node->children[1], stage + 1);
    }
}

void tree_free(Node *node)
{
	if(node->children && node->type != NTVAR)
	{
		tree_free(node->children[0]);
		tree_free(node->children[1]);
	}

	// The node->name is already free in list_free
	free(node);
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
