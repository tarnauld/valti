%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <stdarg.h>
	#include <math.h>
	#include <string.h>

	extern int yyparse();
	extern int yyerror(char*);
	extern int yylex();
	extern FILE *yyin;

	/* Node */

	typedef enum NodeType {
		NTINST, // Handle instructions
	    NTNUM, NTVAR, // Value or variable?
		NTPLUS, NTMIN, NTMULT, NTDIV, NTPOW, NTMOD, NTAFF, // Operators
		NTISEQ, NTISDIFF, NTISLT, NTISGT, NTISGE, NTISLE, // Boolean operators
		NTAND, NTOR,
		NTECHO, NTIF, NTELIF, NTELSE, NTDO, NTWHILE, NTFOR, // Primary instructions
	} NodeType;

	typedef struct Node {
	    NodeType type;
		size_t children_count;

	    union {
	        double value;
	        char *name;
	        struct Node **children;
	    };
	} Node;

	Node *node_new(NodeType type);
	Node *node_children(Node*, size_t, Node*, ...);
	int exec(Node*);
	int boolean_value(Node*);
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
	int parse_interpreter(void);
	int parse_file(char*);

	List *variables = NULL;
	int DEBUG_MODE = 0;
%}

%union {
	struct Node *node;
}

%token <node> NUMBER VARIABLE
%token <node> PLUS MINUS MULTIPLY DIVIDE POWER MODULO AFFECT
%token <node> PLUS_EQ MINUS_EQ MULTIPLY_EQ DIVIDE_EQ POWER_EQ MODULO_EQ
%token <node> IS_EQUAL IS_DIFFERENT IS_LOWER IS_GREATER IS_LOWER_EQUAL IS_GREATER_EQUAL
%token <node> BOOL_AND BOOL_OR
%token <node> __ECHO__ __IF__ __ELIF__ __ELSE__ __DO__ __WHILE__ __FOR__

%token OP_PAR CL_PAR OP_BRA CL_BRA COLON COMMA
%token END

%type <node> InstList
%type <node> Inst
%type <node> Condition
%type <node> ConditionnalInst
%type <node> LoopInst
%type <node> BooleanExpression
%type <node> AffectationList
%type <node> Affectation
%type <node> Expression

%left PLUS MINUS
%left MULTIPLY DIVIDE MODULO
%left NEG

%left IS_EQUAL IS_DIFFERENT IS_LOWER IS_GREATER IS_LOWER_EQUAL IS_GREATER_EQUAL
%left BOOL_AND BOOL_OR

%right POWER

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
		if(DEBUG_MODE)
			tree_print($1, 0);

		int code = exec($1);

		if(DEBUG_MODE)
			list_print(variables);

		tree_free($1);
		return code;
	}
	;

InstList:
	Inst {
		$$ = node_children(node_new(NTINST), 1, $1);
	}
	| InstList Inst {
		$$ = node_children(node_new(NTINST), 2, $1, $2);
	}
	;

Inst:
	// Affectation
	AffectationList COLON {
		$$ = $1;
	}
	// Echo
	| __ECHO__ OP_PAR Expression CL_PAR COLON {
		$$ = node_children($1, 1, $3);
	}
	// Conditions
	| ConditionnalInst {
		$$ = $1;
	}
	// Loops
	| LoopInst {
		$$ = $1;
	}
	;

Condition:
	__IF__ OP_PAR BooleanExpression CL_PAR OP_BRA InstList CL_BRA {
		$$ = node_children($1, 2, $3, $6);
	}
	| Condition __ELIF__ OP_PAR BooleanExpression CL_PAR OP_BRA InstList CL_BRA {
		$$ = node_children($2, 3, $1, $4, $7);
	}
	;

ConditionnalInst:
	Condition {
		$$ = $1;
	}
	| Condition __ELSE__ OP_BRA InstList CL_BRA {
		$$ = node_children($2, 2, $1, $4);
	}
	/*/ TODO: One-inst conditions
	| __IF__ OP_PAR BooleanExpression CL_PAR Inst {
		$$ = node_children($1, 2, $3, $5);
	}
	| ConditionnalInst __ELSE__ Inst {
		$$ = node_children($2, 2, $1, $3);
	}//*/
	;

LoopInst:
	// While(...) {...}
	__WHILE__ OP_PAR BooleanExpression CL_PAR OP_BRA InstList CL_BRA {
		$$ = node_children($1, 2, $3, $6);
	}
	// Do {...} While(...);
	| __DO__ OP_BRA InstList CL_BRA __WHILE__ OP_PAR BooleanExpression CL_PAR COLON {
		$$ = node_children($1, 2, $7, $3);
		free($5); // Free unused NTWHILE Node*
	}
	| __FOR__ OP_PAR AffectationList COLON BooleanExpression COLON AffectationList CL_PAR OP_BRA InstList CL_BRA {
		$$ = node_children($1, 4, $3, $5, $7, $10);
	}
	;

BooleanExpression:
	Expression IS_EQUAL Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| Expression IS_DIFFERENT Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| Expression IS_LOWER Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| Expression IS_GREATER Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| Expression IS_LOWER_EQUAL Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| Expression IS_GREATER_EQUAL Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| BooleanExpression BOOL_AND BooleanExpression {
		$$ = node_children($2, 2, $1, $3);
	}
	| BooleanExpression BOOL_OR BooleanExpression {
		$$ = node_children($2, 2, $1, $3);
	}
	| OP_PAR BooleanExpression CL_PAR {
		$$ = $2;
	}
	;

AffectationList:
	Affectation {
		$$ = $1;
	}
	| AffectationList COMMA Affectation {
		$$ = node_children(node_new(NTINST), 2, $1, $3);
	}
	;

Affectation:
	VARIABLE AFFECT Expression {
		// Add the affectation in the tree
		$$ = node_children($2, 2, $1, $3);
	}
	| VARIABLE PLUS_EQ Expression {
		$$ = node_children(node_new(NTAFF), 2, $1, node_children(node_new(NTPLUS), 2, $1, $3));
	}
	| VARIABLE MINUS_EQ Expression {
		$$ = node_children(node_new(NTAFF), 2, $1, node_children(node_new(NTMIN), 2, $1, $3));
	}
	| VARIABLE MULTIPLY_EQ Expression {
		$$ = node_children(node_new(NTAFF), 2, $1, node_children(node_new(NTMULT), 2, $1, $3));
	}
	| VARIABLE DIVIDE_EQ Expression {
		$$ = node_children(node_new(NTAFF), 2, $1, node_children(node_new(NTDIV), 2, $1, $3));
	}
	| VARIABLE POWER_EQ Expression {
		$$ = node_children(node_new(NTAFF), 2, $1, node_children(node_new(NTPOW), 2, $1, $3));
	}
	| VARIABLE MODULO_EQ Expression {
		$$ = node_children(node_new(NTAFF), 2, $1, node_children(node_new(NTMOD), 2, $1, $3));
	}
	;

Expression:
    NUMBER {
		$$ = $1;
	}
  	| VARIABLE {
		$$ = $1;
	}
	| Expression PLUS Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| Expression MINUS Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| Expression MULTIPLY Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| Expression DIVIDE Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| MINUS Expression %prec NEG {
		$2->value = -($2->value);
		$$ = $2;
	}
	| Expression POWER Expression {
		$$ = node_children($2, 2, $1, $3);
	}
	| Expression MODULO Expression {
		$$ = node_children($2, 2, $1, $3);
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
	return 1;
}

int main(int argc, char **argv)
{
	int code;

	if(argc >= 2)
	{
		if(!strcmp(argv[1], "-d"))
		{
			DEBUG_MODE = 1;

			if(argc == 3)
				code = parse_file(argv[2]);
			else
				code = parse_interpreter();
		}
		else
			code = parse_file(argv[1]);
	}
	else
		code = parse_interpreter();

	// Cleanup
	list_free(&variables);
	return code;
}

int parse_interpreter(void)
{
	printf("<Valti Interpreter> (send Ctrl+Z signal to execute)\n");
	return yyparse();
}

int parse_file(char *filepath)
{
	int code;
	FILE *src = NULL;

	src = fopen(filepath, "r");
	if(!src)
	{
		printf("Unable to open the file.\n");
		exit(-1);
	}

	yyin = src;
	code = yyparse();
	fclose(src);

	return code;
}

/* Node */

Node *node_children(Node *father, size_t count, Node *child, ...)
{
	va_list list;
	int i;
	Node *node;

    father->children = (Node**)malloc(sizeof(Node*) * count);
	father->children_count = count;

	va_start(list, child);
	for(i = 0, node = child ; i < count ; i++, node = va_arg(list, Node*))
		father->children[i] = node;
	va_end(list);

    return father;
}

int exec(Node *node)
{
	int i;
	double val;

	switch(node->type)
	{
		case NTINST:
			for(i = 0 ; i < node->children_count ; i++)
				exec(node->children[i]);
			break;

		case NTAFF:
			// We ignore the left (NTVAR) part of the tree when processing an = (NTAFF) node.
			val = calculate_expression(node->children[1]);
			// Store a new variable in memory
			list_add(&variables, node->children[0]->name, val);

			if(DEBUG_MODE)
				printf("Affectation: %s = %f\n", node->children[0]->name, val);
			break;

		case NTECHO:
			printf("%lf\n", calculate_expression(node->children[0]));
			break;

		case NTIF:
			return boolean_value(node->children[0]) ? exec(node->children[1]) : 1;
			break;

		case NTELIF:
			if(exec(node->children[0]) == 1) { // If the IF statement is not executed
				// If the ELIF statement is true, execute it
				return boolean_value(node->children[1]) ? exec(node->children[2]) : 1;
			}
			break;

		case NTELSE:
			// If the IF or last ELIF statement is not executed, then we execute the ELSE statement
			if(exec(node->children[0]) == 1) {
				return exec(node->children[1]);
			}
			break;

		case NTDO:
			do {
				exec(node->children[1]);
			} while(boolean_value(node->children[0]));
			break;

		case NTWHILE:
			while(boolean_value(node->children[0])) {
				exec(node->children[1]);
			}
			break;

		case NTFOR:
			for(exec(node->children[0]) ; boolean_value(node->children[1]) ; exec(node->children[2])) {
				exec(node->children[3]);
			}
			break;

		default:
			printf("Syntax error (#%d).\n", node->type);
			return -1;
	}

	return 0;
}

int boolean_value(Node *node)
{
	switch(node->type)
	{
		case NTISEQ: return calculate_expression(node->children[0]) == calculate_expression(node->children[1]);
		case NTISDIFF: return calculate_expression(node->children[0]) != calculate_expression(node->children[1]);
		case NTISLT: return calculate_expression(node->children[0]) < calculate_expression(node->children[1]);
		case NTISGT: return calculate_expression(node->children[0]) > calculate_expression(node->children[1]);
		case NTISLE: return calculate_expression(node->children[0]) <= calculate_expression(node->children[1]);
		case NTISGE: return calculate_expression(node->children[0]) >= calculate_expression(node->children[1]);
		case NTAND: return boolean_value(node->children[0]) && boolean_value(node->children[1]);
		case NTOR: return boolean_value(node->children[0]) || boolean_value(node->children[1]);

		default: return 0; // False by default
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
            return pow(calculate_expression(node->children[0]), calculate_expression(node->children[1]));
            break;

		case NTMOD:
			return fmod(calculate_expression(node->children[0]), calculate_expression(node->children[1]));
			break;

		default:
			return -1.;
			break;
    }
	return -1.;
}

void tree_print(Node *node, int stage)
{
    int i;

    for(i = 0 ; i < stage ; i++)
        printf(" ");

    switch(node->type)
    {
		case NTINST: 	printf("{"); break;

        case NTNUM: 	printf("%.2lf", node->value); break;
        case NTVAR: 	printf("%s", node->name); break;

        case NTPLUS: 	printf("+"); break;
		case NTMIN: 	printf("-"); break;
        case NTMULT:	printf("*"); break;
        case NTDIV: 	printf("/"); break;
        case NTPOW: 	printf("^"); break;
		case NTMOD:		printf("%%"); break;
        case NTAFF: 	printf("="); break;

		case NTECHO: 	printf("echo"); break;

		case NTIF: 		printf("if"); break;
		case NTELIF:	printf("elif"); break;
		case NTELSE:	printf("else"); break;

		case NTDO:		printf("do"); break;
		case NTWHILE:	printf("while"); break;
		case NTFOR:		printf("for"); break;

		case NTISEQ:	printf("=="); break;
		case NTISDIFF:	printf("!="); break;
		case NTISLT:	printf("<"); break;
		case NTISGT:	printf(">"); break;
		case NTISLE:	printf("<="); break;
		case NTISGE: 	printf(">="); break;

		case NTAND:		printf("&&"); break;
		case NTOR:		printf("||"); break;
    }
    printf("\n");

    if(node->children && node->type != NTVAR && node->type != NTNUM && node->children_count > 0)
    {
		for(i = 0 ; i < node->children_count ; i++)
        	tree_print(node->children[i], stage + 1);
    }
}

void tree_free(Node *node)
{
	if(node->children && node->type != NTVAR && node->type != NTNUM && node->children_count > 0)
	{
		int i;

		for(i = 0 ; i < node->children_count ; i++)
			tree_free(node->children[i]);
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
