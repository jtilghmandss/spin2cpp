/*
 * Spin compiler parser
 * Copyright (c) 2011-2018 Total Spectrum Software Inc.
 * See the file COPYING for terms of use.
 */

/* %define api.prefix {spinyy} */

%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "spinc.h"
    
#define YYSTYPE AST*
    
/* Yacc functions */
    void spinyyerror(const char *);
    int spinyylex();

    extern int gl_errors;

    extern AST *last_ast;
    
AST *
SpinRetType(AST *funcdef)
{
    AST *resultvars = NULL;
    
    if (funcdef->kind != AST_FUNCDEF) return NULL;
    funcdef = funcdef->left;
    if (funcdef->kind != AST_FUNCDECL) return NULL;
    resultvars = funcdef->right;
    if (resultvars && resultvars->kind == AST_DECLARE_VAR) {
        return resultvars->left;
    }
    funcdef = funcdef ->left;
    if (funcdef->kind != AST_IDENTIFIER) return NULL;
    if (strrchr(funcdef->d.string, '$') != NULL)
        return ast_type_string;
    return NULL;
}

#define YYERROR_VERBOSE 1
%}

%pure-parser
 //%define parse.error verbose
 //%define parse.lac full

%token SP_IDENTIFIER "identifier"
%token SP_NUM        "number"
%token SP_STRING     "string"
%token SP_FLOATNUM   "float point number"
%token SP_SPR        "SPR"

/* various keywords */
%token SP_CON        "CON"
%token SP_VAR        "VAR"
%token SP_DAT        "DAT"
%token SP_PUB        "PUB"
%token SP_PRI        "PRI"
%token SP_OBJ        "OBJ"
%token SP_ASM        "ASM"
%token SP_ENDASM     "ENDASM"
%token SP_INLINECCODE "CCODE"
%token SP_BYTE       "BYTE"
%token SP_WORD       "WORD"
%token SP_LONG       "LONG"

%token SP_INSTR      "instruction"
%token SP_INSTRMODIFIER "instruction modifier"
%token SP_HWREG      "hardware register"
%token SP_ORG        "ORG"
%token SP_ORGH       "ORGH"
%token SP_ORGF       "ORGF"
%token SP_RES        "RES"
%token SP_FIT        "FIT"
%token SP_ALIGNL     "ALIGNL"
%token SP_ALIGNW     "ALIGNW"

%token SP_REPEAT     "REPEAT"
%token SP_FROM       "FROM"
%token SP_TO         "TO"
%token SP_STEP       "STEP"
%token SP_WHILE      "WHILE"
%token SP_UNTIL      "UNTIL"
%token SP_IF         "IF"
%token SP_IFNOT      "IFNOT"
%token SP_ELSE       "ELSE"
%token SP_ELSEIF     "ELSEIF"
%token SP_ELSEIFNOT  "ELSEIFNOT"
%token SP_THEN       "THEN"
%token SP_ENDIF      "ENDIF"

%token SP_LOOKDOWN   "LOOKDOWN"
%token SP_LOOKDOWNZ  "LOOKDOWNZ"
%token SP_LOOKUP     "LOOKUP"
%token SP_LOOKUPZ    "LOOKUPZ"
%token SP_COGINIT    "COGINIT"
%token SP_COGNEW     "COGNEW"

%token SP_CASE       "CASE"
%token SP_OTHER      "OTHER"

%token SP_QUIT       "QUIT"
%token SP_NEXT       "NEXT"

%token SP_ALLOCA     "__BUILTIN_ALLOCA"

/* other stuff */
%token SP_ABORT      "ABORT"
%token SP_RESULT     "RESULT"
%token SP_RETURN     "RETURN"
%token SP_INDENT     "indentation"
%token SP_OUTDENT    "lack of indentation"
%token SP_EOLN       "end of line"
%token SP_EOF        "end of file"
%token SP_DOTS       ".."
%token SP_HERE       "$"
%token SP_STRINGPTR  "STRING"
%token SP_FILE       "FILE"

%token SP_ANNOTATION

/* operators */
%token SP_ASSIGN     ":="
%token SP_XOR        "XOR"
%token SP_OR         "OR"
%token SP_AND        "AND"
%token SP_GE         "=>"
%token SP_LE         "=<"
%token SP_GEU        "+=>"
%token SP_LEU        "+=<"
%token SP_GTU        "+>"
%token SP_LTU        "+<"
%token SP_NE         "<>"
%token SP_EQ         "=="
%token SP_SGNCOMP    "<=>"
%token SP_LIMITMIN   "#>"
%token SP_LIMITMAX   "<#"
%token SP_REMAINDER  "//"
%token SP_UNSDIV     "~/"
%token SP_UNSMOD     "~//"
%token SP_HIGHMULT   "**"
%token SP_ROTR       "ROR (->)"
%token SP_ROTL       "ROL (<-)"
%token SP_SHL        "<<"
%token SP_SHR        ">>"
%token SP_SAR        "SAR (~>)"
%token SP_REV        "REV (><)"
%token SP_NEGATE     "-"
%token SP_BIT_NOT    "!"
%token SP_SQRT       "^^"
%token SP_ABS        "ABS (||)"
%token SP_DECODE     "|<"
%token SP_ENCODE     ">|"
%token SP_NOT        "NOT"
%token SP_DOUBLETILDE "~~"
%token SP_INCREMENT  "++"
%token SP_DECREMENT  "--"
%token SP_DOUBLEAT   "@@"
%token SP_TRIPLEAT   "@@@"
%token SP_FLOAT      "floating point number"
%token SP_TRUNC      "TRUNC"
%token SP_ROUND      "ROUND"
%token SP_CONSTANT   "constant"
%token SP_RANDOM     "??"

/* operator precedence */
%right SP_ASSIGN
%left '\\'
%right SP_THEN
%right SP_ELSE
%left SP_OR SP_XOR
%left SP_AND
%left SP_NOT
%left '<' '>' SP_GE SP_LE SP_NE SP_EQ SP_SGNCOMP SP_GEU SP_LEU SP_GTU SP_LTU
%left SP_LIMITMIN SP_LIMITMAX
%left '-' '+'
%left '*' '/' SP_REMAINDER SP_HIGHMULT SP_UNSDIV SP_UNSMOD
%left '|' '^'
%left '&'
%left SP_ROTL SP_ROTR SP_SHL SP_SHR SP_SAR SP_REV
%left SP_NEGATE SP_BIT_NOT SP_ABS SP_SQRT SP_DECODE SP_ENCODE SP_ALLOCA
%left '@' '~' '?' SP_RANDOM SP_DOUBLETILDE SP_INCREMENT SP_DECREMENT SP_DOUBLEAT SP_TRIPLEAT
%left SP_CONSTANT SP_FLOAT SP_TRUNC SP_ROUND

%%
input:
  rest
  | conblock rest
;

rest:
  topelement
  | topelement rest
  ;

emptyline:
  SP_EOLN
  ;

emptylines: 
  | emptylines emptyline
  ;

topelement:
  SP_CON conblock
  { $$ = current->conblock = AddToList(current->conblock, $2); }
  | SP_DAT datblock
  { $$ = current->datblock = AddToList(current->datblock, $2); }
  | SP_DAT annotation datblock
  {
      current->datannotations = AddToList(current->datannotations, $2);
      $$ = current->datblock = AddToList(current->datblock, $3); 
  }
  | SP_VAR varblock
  { $$ = current->pendingvarblock = AddToList(current->pendingvarblock, $2); }
  | SP_OBJ objblock
  {
    $$ = current->objblock = AddToList(current->objblock, $2);
  }
  | SP_PUB funcdef funcbody
    { DeclareFunction(current, SpinRetType($2), 1, $2, $3, NULL, $1); }
  | SP_PRI funcdef funcbody
    { DeclareFunction(current, SpinRetType($2), 0, $2, $3, NULL, $1); }
  | SP_PUB annotation funcdef funcbody
    { DeclareFunction(current, SpinRetType($3), 1, $3, $4, $2, $1); }
  | SP_PRI annotation funcdef funcbody
    { DeclareFunction(current, SpinRetType($3), 0, $3, $4, $2, $1); }
  | annotation emptylines
    { DeclareToplevelAnnotation($1); }
;

funcdef:
  identifier optparamlist SP_EOLN
  { AST *funcdecl = NewAST(AST_FUNCDECL, $1, NULL);
    AST *funcvars = NewAST(AST_FUNCVARS, $2, NULL);
    $$ = NewAST(AST_FUNCDEF, funcdecl, funcvars);
  }
|  identifier optparamlist localvars SP_EOLN
  { AST *funcdecl = NewAST(AST_FUNCDECL, $1, NULL);
    AST *funcvars = NewAST(AST_FUNCVARS, $2, $3);
    $$ = NewAST(AST_FUNCDEF, funcdecl, funcvars);
  }
|  identifier optparamlist resultname localvars SP_EOLN
  { AST *funcdecl = NewAST(AST_FUNCDECL, $1, $3);
    AST *funcvars = NewAST(AST_FUNCVARS, $2, $4);
    $$ = NewAST(AST_FUNCDEF, funcdecl, funcvars);
  }
|  identifier optparamlist resultname SP_EOLN
  { AST *funcdecl = NewAST(AST_FUNCDECL, $1, $3);
    AST *funcvars = NewAST(AST_FUNCVARS, $2, NULL);
    $$ = NewAST(AST_FUNCDEF, funcdecl, funcvars);
  }
;

optparamlist:
/* empty */
  { $$ = NULL; }
| paramidentlist
  { $$ = $1; }
| '(' paramidentlist ')'
  { $$ = $2; }
  ;

resultname: ':' paramidentlist
  {
      // handle the common case of just one identifier by
      // unwrapping the list
      AST *list = $2;
      if (list->kind == AST_LISTHOLDER && list->right == NULL) {
          list = list->left;
      }
      $$ = list;
  }
  ;

localvars:
 '|' identlist
  { $$ = $2; }
    ;

funcbody:
  /* empty */
  { $$ = NULL; }
| stmtlist
  { $$ = $1; }
  ;

stmtlist:
  stmt
    {
        $$ = $1;
    }
  | stmtlist stmt
  {
      $$ = AddToList($1, $2); 
  }
  ;

stmt:
  basicstmt
    {  $$ = NewCommentedStatement($1); }
  | compoundstmt
    { $$ = NewStatement($1); }
  | SP_EOLN
    { $$ = NULL; }
  | error SP_EOLN
    { $$ = NULL; }
  ;

basicstmt:
   SP_RETURN SP_EOLN
    { $$ = AstReturn(NULL, $1); }
  |  SP_RETURN '(' exprlist ')' SP_EOLN
    {
        $$ = AstReturn($3, $1);
    }
  |  SP_RETURN exprlist SP_EOLN
    { $$ = AstReturn($2, $1); }
  | SP_ABORT SP_EOLN
    { $$ = AstAbort(NULL, $1); }
  |  SP_ABORT expr SP_EOLN
    { $$ = AstAbort($2, $1); }
  | multiassign
  | expr SP_EOLN
    { $$ = $1; }
  | SP_QUIT SP_EOLN
    { $$ = NewCommentedAST(AST_QUIT, NULL, NULL, $1); }
  | SP_NEXT SP_EOLN
    { $$ = NewCommentedAST(AST_CONTINUE, NULL, NULL, $1); }
;

multiassign:
  lhsseq SP_ASSIGN '(' exprlist ')'
    { $$ = AstAssignList($1, $4, $2); }
  | lhsseq SP_ASSIGN exprlist
    { $$ = AstAssignList($1, $3, $2); }

compoundstmt:
   ifstmt
    { $$ = $1; }
  | repeatstmt
    { $$ = $1; }
  | stmtblock
    { $$ = $1; }
   | casestmt
    { $$ = $1; }
;

stmtblock:
  SP_INDENT stmtlist SP_OUTDENT
  { $$ = $2; }
  | SP_INDENT SP_OUTDENT
  { $$ = NULL; }
;

ifstmt:
  SP_IF expr SP_EOLN elseblock
    { $$ = NewCommentedAST(AST_IF, $2, $4, $1); }
  | SP_IFNOT expr SP_EOLN elseblock
    { $$ = NewCommentedAST(AST_IF, AstOperator(K_BOOL_NOT, NULL, $2), $4, $1); }
;

elseblock:
  stmtblock
    { $$ = NewAST(AST_THENELSE, $1, NULL); }
  | stmtblock SP_ELSE SP_EOLN stmtblock
  { $$ = NewCommentedAST(AST_THENELSE, $1, $4, $2); }
  | stmtblock SP_ELSEIF expr SP_EOLN elseblock
    { $$ = NewAST(AST_THENELSE, $1, NewAST(AST_STMTLIST, NewCommentedAST(AST_IF, $3, $5, $2), NULL)); }
  | stmtblock SP_ELSEIFNOT expr SP_EOLN elseblock
    { $$ = NewAST(AST_THENELSE, $1, NewAST(AST_STMTLIST, NewCommentedAST(AST_IF, AstOperator(K_BOOL_NOT, NULL, $3), $5, $2), NULL)); }
  ;

casestmt:
  SP_CASE expr SP_EOLN SP_INDENT casematchlist SP_OUTDENT
    { $$ = NewCommentedAST(AST_CASE, $2, $5, $1); }
;

casematchlist:
  casematchitem
    { $$ = NewAST(AST_LISTHOLDER, $1, NULL); }
  | casematchlist casematchitem
    { $$ = AddToList($1, NewAST(AST_LISTHOLDER, $2, NULL)); }
  ;

casematchitem:
  casematch SP_EOLN stmtblock
    {
        AST *slist = NewAST(AST_STMTLIST, $3, NULL);
        $$ = NewAST(AST_CASEITEM, $1, slist);
    }
  ;

casematch:
  matchexprlist ':'
  {
      $$ = $1;
      EstablishIndent(current->Lptr, -1);
      resetLineState(current->Lptr);
  }

matchexprlist:
  matchexpritem
  | matchexprlist ',' matchexpritem
    { $$ = AddToList($1, $3); }
  ;

matchexpritem:
  SP_OTHER
    { $$ = NewAST(AST_OTHER, NULL, NULL); }
  | expr SP_DOTS expr
    { $$ = NewAST(AST_EXPRLIST, NewAST(AST_RANGE, $1, $3), NULL); }
  | expr
    { $$ = NewAST(AST_EXPRLIST, $1, NULL); }
  ;


rangeexpritem:
  expr
    { $$ = NewAST(AST_EXPRLIST, $1, NULL); }
  | expr SP_DOTS expr
    { $$ = NewAST(AST_EXPRLIST, NewAST(AST_RANGE, $1, $3), NULL); }
  ;

rangeexprlist:
  rangeexpritem
  | rangeexprlist ',' rangeexpritem
    { $$ = AddToList($1, $3); }
  ;

repeatstmt:
    SP_REPEAT SP_EOLN stmtblock
    {   AST *body = $3; body = CheckYield(body);
        AST *one = AstInteger(1);
        one->lineidx = $1->lineidx;
        $$ = NewCommentedAST(AST_WHILE, one, body, $1);
        $$->lineidx = $1->lineidx;
    }
  | SP_REPEAT SP_EOLN stmtblock SP_WHILE expr SP_EOLN
    { $$ = NewCommentedAST(AST_DOWHILE, $5, CheckYield($3), $1); }
  | SP_REPEAT SP_EOLN stmtblock SP_UNTIL expr SP_EOLN
    { $$ = NewCommentedAST(AST_DOWHILE, AstOperator(K_BOOL_NOT, NULL, $5), CheckYield($3), $1); }
  | SP_REPEAT SP_WHILE expr SP_EOLN stmtblock
    {   AST *body = $5; body = CheckYield(body); 
        $$ = NewCommentedAST(AST_WHILE, $3, body, $1);
        $$->lineidx = $1->lineidx;
    }
  | SP_REPEAT SP_UNTIL expr SP_EOLN stmtblock
    {   AST *body = $5;
        AST *expr = AstOperator(K_BOOL_NOT, NULL, $3);
        expr->lineidx = $3->lineidx;
        body = CheckYield(body); 
        $$ = NewCommentedAST(AST_WHILE, expr, body, $1);
        $$->lineidx = $1->lineidx;
    }
  | SP_REPEAT identifier SP_FROM expr SP_TO expr SP_STEP expr SP_EOLN stmtblock
    {
      AST *from, *to, *step; 
      step = NewAST(AST_STEP, $8, $10);
      to = NewAST(AST_TO, $6, step);
      from = NewAST(AST_FROM, $4, to);
      $$ = NewCommentedAST(AST_COUNTREPEAT, $2, from, $1);
    }
  | SP_REPEAT identifier SP_FROM expr SP_TO expr SP_EOLN stmtblock
    {
      AST *from, *to, *step; 
      step = NewAST(AST_STEP, AstInteger(1), $8);
      to = NewAST(AST_TO, $6, step);
      from = NewAST(AST_FROM, $4, to);
      $$ = NewCommentedAST(AST_COUNTREPEAT, $2, from, $1);
    }
  | SP_REPEAT expr SP_EOLN stmtblock
    {
      AST *from, *to, *step;
      AST *body = $4;
      body = CheckYield(body);
      step = NewAST(AST_STEP, AstInteger(1), body);
      to = NewAST(AST_TO, $2, step);
      from = NewAST(AST_FROM, NULL, to);
      $$ = NewCommentedAST(AST_COUNTREPEAT, NULL, from, $1);
    }
  | SP_ASM datblock SP_ENDASM
    {  $$ = NewCommentedAST(AST_INLINEASM, $2, NULL, $1); }
  | SP_INLINECCODE
    {  $$ = $1; }
;

lookupexpr:
  SP_LOOKUPZ '(' expr ':' rangeexprlist ')'
    { $$ = AstLookup(AST_LOOKUP, 0, $3, $5); }
  | SP_LOOKUP '(' expr ':' rangeexprlist ')'
    { $$ = AstLookup(AST_LOOKUP, 1, $3, $5); }
;
lookdownexpr:
  SP_LOOKDOWNZ '(' expr ':' rangeexprlist ')'
    { $$ = AstLookup(AST_LOOKDOWN, 0, $3, $5); }
  | SP_LOOKDOWN '(' expr ':' rangeexprlist ')'
    { $$ = AstLookup(AST_LOOKDOWN, 1, $3, $5); }
;

conblock:
  conline
  { $$ = $1; }
  | conblock conline
  { $$ = AddToList($1, $2); }
  ;

conline:
  enumlist SP_EOLN
    { $$ = $1; }
  | SP_EOLN
    { $$ = NULL; }
  | error SP_EOLN
    { $$ = NULL; }
  ;

enumlist:
  enumitem
    { $$ = CommentedListHolder($1); }
  | enumlist ',' enumitem
    { $$ = AddToList($1, CommentedListHolder($3)); }
  ;

enumitem:
  identifier '=' expr
  { $$ = NewAST(AST_ASSIGN, $1, $3); }
  | identifier
  { $$ = $1; }
  | identifier '[' expr ']'
    {
        $$ = NewAST(AST_ENUMSKIP, $1, $3);
    }
  | '#' expr
  { $$ = NewAST(AST_ENUMSET, $2, NULL); }
  ;

datblock:
  datline
    {
        AST *dat = $1;
        $$ = dat; //NewAST(AST_LISTHOLDER, dat, NULL);
    }
  | datblock datline
    { $$ = AddToList($1, $2); }
  ;

datline:
  basedatline
  | identifier basedatline
    {   AST *linebreak;
        AST *comment = GetComments();
        AST *ast;
        ast = $1;
        if (comment && (comment->d.string || comment->kind == AST_SRCCOMMENT)) {
            linebreak = NewCommentedAST(AST_LINEBREAK, NULL, NULL, comment);
        } else {
            linebreak = NewAST(AST_LINEBREAK, NULL, NULL);
        }
        ast = AddToList(ast, $2);
        ast = AddToList(linebreak, ast);
        $$ = ast;
    }
  ;

basedatline:
  SP_EOLN
    { $$ = NULL; }
  | error SP_EOLN
    { $$ = NULL; }
  | SP_BYTE SP_EOLN
    { $$ = NewCommentedAST(AST_BYTELIST, NULL, NULL, $1); }
  | SP_BYTE exprlist SP_EOLN
    { $$ = NewCommentedAST(AST_BYTELIST, $2, NULL, $1); }
  | SP_WORD SP_EOLN
    { $$ = NewCommentedAST(AST_WORDLIST, NULL, NULL, $1); }
  | SP_WORD exprlist SP_EOLN
    { $$ = NewCommentedAST(AST_WORDLIST, $2, NULL, $1); }
  | SP_LONG SP_EOLN
    { $$ = NewCommentedAST(AST_LONGLIST, NULL, NULL, $1); }
  | SP_LONG exprlist SP_EOLN
    { $$ = NewCommentedAST(AST_LONGLIST, $2, NULL, $1); }
  | instruction SP_EOLN
    { $$ = NewCommentedInstr($1); }
  | instruction operandlist SP_EOLN
    { $$ = NewCommentedInstr(AddToList($1, $2)); }
  | instruction modifierlist SP_EOLN
    { $$ = NewCommentedInstr(AddToList($1, $2)); }
  | instruction operandlist modifierlist SP_EOLN
    { $$ = NewCommentedInstr(AddToList($1, AddToList($2, $3))); }
  | SP_ALIGNL SP_EOLN
    { $$ = NewCommentedAST(AST_ALIGN, AstInteger(4), NULL, $1); }
  | SP_ALIGNW SP_EOLN
    { $$ = NewCommentedAST(AST_ALIGN, AstInteger(2), NULL, $1); }
  | SP_ORG SP_EOLN
    { $$ = NewCommentedAST(AST_ORG, NULL, NULL, $1); }
  | SP_ORG expr SP_EOLN
    { $$ = NewCommentedAST(AST_ORG, $2, NULL, $1); }
  | SP_ORGH SP_EOLN
    { $$ = NewCommentedAST(AST_ORGH, NULL, NULL, $1); }
  | SP_ORGH expr SP_EOLN
    { $$ = NewCommentedAST(AST_ORGH, $2, NULL, $1); }
  | SP_ORGF expr SP_EOLN
    { $$ = NewCommentedAST(AST_ORGF, $2, NULL, $1); }
  | SP_RES expr SP_EOLN
    { $$ = NewCommentedAST(AST_RES, $2, NULL, $1); }
  | SP_FIT expr SP_EOLN
    { $$ = NewCommentedAST(AST_FIT, $2, NULL, $1); }
  | SP_FIT SP_EOLN
    { $$ = NewCommentedAST(AST_FIT, AstInteger(0x1f0), NULL, $1); }
  | SP_FILE string SP_EOLN
    { $$ = NewCommentedAST(AST_FILE, GetFullFileName($2), NULL, $1); }
  ;

objblock:
  objline
  { $$ = $1; }
  | objblock objline
  { $$ = AddToList($1, $2); }
;

objline:
    SP_EOLN
    { $$ = NULL; }
  | error  SP_EOLN
    { $$ = NULL; }
  | identdecl ':' string
    {
        AST *typ = NewObject($1, $3);
        DeclareOneMemberVar(current, $1, typ);
        $$ = typ;
    }
  | identdecl '=' string
    {
        AST *typ = NewAbstractObject($1, $3);
        AST *ident = $1;
        const char *name = GetIdentifierName(ident);
        AddSymbol(&current->objsyms, name, SYM_TYPEDEF, typ);
        $$ = typ;
    }
;

varblock:
    varline
    { $$ = CommentedListHolder($1); }
  | varblock varline
    { $$ = AddToList($1, CommentedListHolder($2)); }
  ;

varline:
  SP_BYTE identlist SP_EOLN
    { $$ = NewAST(AST_BYTELIST, $2, NULL); }
  | SP_WORD identlist SP_EOLN
    { $$ = NewAST(AST_WORDLIST, $2, NULL); }
  | SP_LONG identlist SP_EOLN
    { $$ = NewAST(AST_LONGLIST, $2, NULL); }
  | SP_EOLN
    { $$ = NULL; }
  | error SP_EOLN
    { $$ = NULL; }
  ;

identlist:
  identdecl
  { $$ = NewAST(AST_LISTHOLDER, $1, NULL); }
  | annotation identdecl
  { $$ = AddToList(NewAST(AST_LISTHOLDER, $1, NULL),
                   NewAST(AST_LISTHOLDER, $2, NULL)); }
  | identlist ',' identdecl
  { $$ = AddToList($1, NewAST(AST_LISTHOLDER, $3, NULL)); }
  ;

identdecl:
  identifier
  { $$ = $1; }
  | identifier '[' expr ']'
  { $$ = NewAST(AST_ARRAYDECL, $1, $3); }
  ;

paramidentdecl:
  identifier
  { $$ = $1; }
  | identifier '[' expr ']'
  { $$ = NewAST(AST_ARRAYDECL, $1, $3); }
  | identifier '=' expr
  { $$ = AstAssign($1, $3); }
  | identifier '=' SP_LONG
  { $$ = NewAST(AST_DECLARE_VAR, ast_type_long, $1); }
  | identifier '=' SP_FLOAT
  { $$ = NewAST(AST_DECLARE_VAR, ast_type_float, $1); }
  | identifier '=' '@' SP_LONG
  { $$ = NewAST(AST_DECLARE_VAR, ast_type_ptr_long, $1); }
  | identifier '=' '@' SP_WORD
  { $$ = NewAST(AST_DECLARE_VAR, ast_type_ptr_word, $1); }
  | identifier '=' '@' SP_BYTE
  { $$ = NewAST(AST_DECLARE_VAR, ast_type_ptr_byte, $1); }
  ;

paramidentlist:
  paramidentdecl
  { $$ = NewAST(AST_LISTHOLDER, $1, NULL); }
  | annotation paramidentdecl
  { $$ = AddToList(NewAST(AST_LISTHOLDER, $1, NULL),
                   NewAST(AST_LISTHOLDER, $2, NULL)); }
  | paramidentlist ',' paramidentdecl
  { $$ = AddToList($1, NewAST(AST_LISTHOLDER, $3, NULL)); }
  ;

expr:
  integer
  | float
  | string
  | SP_STRINGPTR '(' exprlist ')'
    { $$ = NewAST(AST_STRINGPTR, $3, NULL); }  
  | lhs
  | '@' lhs
    { $$ = NewAST(AST_ADDROF, $2, NULL); }
  | SP_DOUBLEAT expr
    { $$ = NewAST(AST_DATADDROF, $2, NULL); }
  | SP_TRIPLEAT lhs
    { $$ = NewAST(AST_ABSADDROF, $2, NULL); }
  | lhs SP_ASSIGN expr
    { $$ = AstAssign($1, $3); }
  | identifier '#' identifier
    { $$ = NewAST(AST_CONSTREF, $1, $3); }
  | lhs '\\' expr
    { $$ = NewAST(AST_POSTSET, $1, $3); }
  | expr '+' expr
    { $$ = AstOperator('+', $1, $3); }
  | expr '-' expr
    { $$ = AstOperator('-', $1, $3); }
  | expr '*' expr
    { $$ = AstOperator('*', $1, $3); }
  | expr '/' expr
    { $$ = AstOperator('/', $1, $3); }
  | expr '&' expr
    { $$ = AstOperator('&', $1, $3); }
  | expr '|' expr
    { $$ = AstOperator('|', $1, $3); }
  | expr '^' expr
    { $$ = AstOperator('^', $1, $3); }
  | expr '>' expr
    { $$ = AstOperator('>', $1, $3); }
  | expr '<' expr
    { $$ = AstOperator('<', $1, $3); }
  | expr SP_GE expr
    { $$ = AstOperator(K_GE, $1, $3); }
  | expr SP_LE expr
    { $$ = AstOperator(K_LE, $1, $3); }
  | expr SP_GEU expr
    { $$ = AstOperator(K_GEU, $1, $3); }
  | expr SP_LEU expr
    { $$ = AstOperator(K_LEU, $1, $3); }
  | expr SP_GTU expr
    { $$ = AstOperator(K_GTU, $1, $3); }
  | expr SP_LTU expr
    { $$ = AstOperator(K_LTU, $1, $3); }
  | expr SP_NE expr
    { $$ = AstOperator(K_NE, $1, $3); }
  | expr SP_EQ expr
    { $$ = AstOperator(K_EQ, $1, $3); }
  | expr SP_SGNCOMP expr
    { $$ = AstOperator(K_SGNCOMP, $1, $3); }
  | expr '<' SP_GE expr
    // lexer quirk, <=> gets parsed as <  => in Spin1
    { $$ = AstOperator(K_SGNCOMP, $1, $4); }
  | expr SP_REMAINDER expr
    { $$ = AstOperator(K_MODULUS, $1, $3); }
  | expr SP_UNSDIV expr
    { $$ = AstOperator(K_UNS_DIV, $1, $3); }
  | expr SP_UNSMOD expr
    { $$ = AstOperator(K_UNS_MOD, $1, $3); }
  | expr SP_HIGHMULT expr
    { $$ = AstOperator(K_HIGHMULT, $1, $3); }
  | expr SP_LIMITMIN expr
    { $$ = AstOperator(K_LIMITMIN, $1, $3); }
  | expr SP_LIMITMAX expr
    { $$ = AstOperator(K_LIMITMAX, $1, $3); }
  | expr SP_REV expr
    { $$ = AstOperator(K_REV, $1, $3); }
  | expr SP_ROTL expr
    { $$ = AstOperator(K_ROTL, $1, $3); }
  | expr SP_ROTR expr
    { $$ = AstOperator(K_ROTR, $1, $3); }
  | expr SP_SHL expr
    { $$ = AstOperator(K_SHL, $1, $3); }
  | expr SP_SHR expr
    { $$ = AstOperator(K_SHR, $1, $3); }
  | expr SP_SAR expr
    { $$ = AstOperator(K_SAR, $1, $3); }
  | expr SP_OR expr
    { $$ = AstOperator(K_BOOL_OR, $1, $3); }
  | expr SP_AND expr
    { $$ = AstOperator(K_BOOL_AND, $1, $3); }
  | expr SP_XOR expr
    { $$ = AstOperator(K_BOOL_XOR, $1, $3); }
  | expr '+' '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign('+', $1, $4); }
  | expr '-' '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign('-', $1, $4); }
  | expr '/' '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign('/', $1, $4); }
  | expr '*' '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign('*', $1, $4); }
  | expr '&' '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign('&', $1, $4); }
  | expr '|' '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign('|', $1, $4); }
  | expr '^' '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign('^', $1, $4); }
  | expr SP_REMAINDER '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_MODULUS, $1, $4); }
  | expr SP_HIGHMULT '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_HIGHMULT, $1, $4); }
  | expr SP_LIMITMIN '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_LIMITMIN, $1, $4); }
  | expr SP_LIMITMAX '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_LIMITMAX, $1, $4); }
  | expr SP_REV '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_REV, $1, $4); }
  | expr SP_ROTL '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_ROTL, $1, $4); }
  | expr SP_ROTR '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_ROTR, $1, $4); }
  | expr SP_SHL '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_SHL, $1, $4); }
  | expr SP_SHR '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_SHR, $1, $4); }
  | expr SP_SAR '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_SAR, $1, $4); }
  | expr SP_AND '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_BOOL_AND, $1, $4); }
  | expr SP_OR '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_BOOL_OR, $1, $4); }
  | expr SP_XOR '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_BOOL_XOR, $1, $4); }
  | expr '<' '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign('<', $1, $4); }
  | expr '>' '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign('>', $1, $4); }
  | expr SP_LE '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_LE, $1, $4); }
  | expr SP_GE '=' expr %prec SP_ASSIGN
    { $$ = AstOpAssign(K_GE, $1, $4); }
  | '(' expr ')' '?' expr ':' expr %prec SP_ELSE
    { $$ = NewAST(AST_CONDRESULT, $2, NewAST(AST_THENELSE, $5, $7)); }
  | '(' expr ')'
    { $$ = $2; }
  | '\\' expr
    { $$ = AstCatch($2); }
  | funccall
    { $$ = $1; }
  | '-' expr %prec SP_NEGATE
    {
        AST *op = $2;
        /* special case -x where x is a float constant */
        if (op->kind == AST_FLOAT) {
            op->d.ival ^= 0x80000000U;
            $$ = op;
        } else {
            $$ = AstOperator(K_NEGATE, NULL, $2);
        }
    }
  | '+' expr %prec SP_NEGATE
    {
        AST *op = $2;
        $$ = op;
    }
  | '!' expr %prec SP_BIT_NOT
    { $$ = AstOperator(K_BIT_NOT, NULL, $2); }
  | '~' expr
    { AST *shf;
      shf = AstOperator(K_SHL, $2, AstInteger(24));
      $$ = AstOperator(K_SAR, shf, AstInteger(24)); 
    }
  | SP_DOUBLETILDE expr
    { AST *shf;
      shf = AstOperator(K_SHL, $2, AstInteger(16));
      $$ = AstOperator(K_SAR, shf, AstInteger(16)); 
    }
  | SP_NOT expr
    { $$ = AstOperator(K_BOOL_NOT, NULL, $2); }
  | SP_ABS expr
    { $$ = AstOperator(K_ABS, NULL, $2); }
  | SP_SQRT expr
    { $$ = AstOperator(K_SQRT, NULL, $2); }
  | SP_DECODE expr
    { $$ = AstOperator(K_DECODE, NULL, $2); }
  | SP_ENCODE expr
    { $$ = AstOperator(K_ENCODE, NULL, $2); }
  | SP_HERE
    { $$ = NewAST(AST_HERE, NULL, NULL); }
  | lhs SP_INCREMENT
    { $$ = AstOperator(K_INCREMENT, $1, NULL); }
  | lhs SP_DECREMENT
    { $$ = AstOperator(K_DECREMENT, $1, NULL); }
  | SP_INCREMENT lhs
    { $$ = AstOperator(K_INCREMENT, NULL, $2); }
  | SP_DECREMENT lhs
    { $$ = AstOperator(K_DECREMENT, NULL, $2); }
  | lhs '?'
    { $$ = AstOperator('?', $1, NULL); }
  | lhs SP_RANDOM
    { $$ = AstOperator('?', $1, NULL); }
  | '?' lhs
    { $$ = AstOperator('?', NULL, $2); }
  | SP_RANDOM lhs
    { $$ = AstOperator('?', NULL, $2); }
  | lhs '~'
    { $$ = NewAST(AST_POSTSET, $1, AstInteger(0)); }
  | lhs SP_DOUBLETILDE
    { $$ = NewAST(AST_POSTSET, $1, AstInteger(-1)); }
  | SP_CONSTANT '(' expr ')'
    { $$ = NewAST(AST_CONSTANT, $3, NULL); }
  | SP_ALLOCA '(' expr ')'
    { $$ = NewAST(AST_ALLOCA, NULL, $3); }
  | SP_FLOAT '(' expr ')'
    { $$ = NewAST(AST_TOFLOAT, $3, NULL); }
  | SP_ROUND '(' expr ')'
    { $$ = NewAST(AST_ROUND, $3, NULL); }
  | SP_TRUNC '(' expr ')'
    { $$ = NewAST(AST_TRUNC, $3, NULL); }
  | lookupexpr
    { $$ = $1; }
  | lookdownexpr
    { $$ = $1; }
  | SP_IF expr SP_THEN expr SP_ELSE expr
    { $$ = NewAST(AST_CONDRESULT, $2, NewAST(AST_THENELSE, $4, $6)); }
  ;

lhs: identifier
  | identifier '[' expr ']'
    { $$ = NewAST(AST_ARRAYREF, $1, $3); }
  | hwreg
  | hwreg '[' range ']'
    { $$ = NewAST(AST_RANGEREF, $1, $3);
    }
  | memref '[' expr ']'
    { $$ = NewAST(AST_ARRAYREF, $1, $3); }
  | '(' expr ')' '[' expr ']'
    { $$ = NewAST(AST_ARRAYREF, $2, $5); }
  | memref
    { $$ = NewAST(AST_ARRAYREF, $1, AstInteger(0)); }
  | SP_SPR '[' expr ']'
    { $$ = AstSprRef($3); }
  ;

lhsseq:
  '(' lhs ',' lhsseqcont ')'
    { $$ = NewAST(AST_EXPRLIST, $2, $4); }
  | lhs ',' lhsseqcont
    { $$ = NewAST(AST_EXPRLIST, $1, $3); }
  ;

lhsseqcont:
  lhs
    { $$ = NewAST(AST_EXPRLIST, $1, NULL); }
  | lhsseqcont ',' lhs
    { $$ = AddToList($1, NewAST(AST_EXPRLIST, $3, NULL)); }
;

memref:
  SP_BYTE '[' expr ']'
    { $$ = NewAST(AST_MEMREF, ast_type_byte, $3); }
  | SP_WORD '[' expr ']'
    { $$ = NewAST(AST_MEMREF, ast_type_word, $3); }
  | SP_LONG '[' expr ']'
    { $$ = NewAST(AST_MEMREF, ast_type_long, $3); }
  | identifier '.' SP_BYTE
    { $$ = NewAST(AST_MEMREF, ast_type_byte, NewAST(AST_ADDROF, $1, NULL)); }
  | identifier '.' SP_WORD
    { $$ = NewAST(AST_MEMREF, ast_type_word, NewAST(AST_ADDROF, $1, NULL)); }
  | identifier '.' SP_LONG
    { $$ = NewAST(AST_MEMREF, ast_type_long, NewAST(AST_ADDROF, $1, NULL)); }
;

funccall:
  identifier '(' exprlist ')'
    { $$ = NewAST(AST_FUNCCALL, $1, $3); }
  | SP_COGINIT '(' exprlist ')'
    { $$ = NewAST(AST_COGINIT, $3, NULL); }
  | SP_COGNEW '(' exprlist ')'
    {
        AST *elist;
        AST *immval = AstInteger(0x1e); // works to cognew both P1 and P2
        elist = NewAST(AST_EXPRLIST, immval, NULL);
        elist = AddToList(elist, $3);
        $$ = NewAST(AST_COGINIT, elist, NULL);
    }
  | identifier '.' identifier '(' exprlist ')'
    { 
        $$ = NewAST(AST_FUNCCALL, NewAST(AST_METHODREF, $1, $3), $5);
    }
  | identifier '.' identifier
    { 
        $$ = NewAST(AST_FUNCCALL, NewAST(AST_METHODREF, $1, $3), NULL);
    }
  | identifier '[' expr ']' '.' identifier '(' exprlist ')'
    { 
        AST *arr = NewAST(AST_ARRAYREF, $1, $3);
        $$ = NewAST(AST_FUNCCALL, NewAST(AST_METHODREF, arr, $6), $8);
    }
  | identifier '[' expr ']' '.' identifier
    { 
        AST *arr = NewAST(AST_ARRAYREF, $1, $3);
        $$ = NewAST(AST_FUNCCALL, NewAST(AST_METHODREF, arr, $6), NULL);
    }
;


expritem:
  expr
   { $$ = NewAST(AST_EXPRLIST, $1, NULL); }
  | integer '[' expr ']'
   {
       $$ = NewAST(AST_EXPRLIST, NewAST(AST_ARRAYDECL, $1, $3), NULL);
   }
  | float '[' expr ']'
   {
       $$ = NewAST(AST_EXPRLIST, NewAST(AST_ARRAYDECL, $1, $3), NULL);
   }
  | '-' integer '[' expr ']'
   {
       AST *op = $2;
       op->d.ival = -op->d.ival;
       $$ = NewAST(AST_EXPRLIST, NewAST(AST_ARRAYDECL, op, $4), NULL);
   }
  | '-' float '[' expr ']'
   {
       AST *op = $2;
       op->d.ival ^= 0x80000000U;
       $$ = NewAST(AST_EXPRLIST, NewAST(AST_ARRAYDECL, op, $4), NULL);
   }
  | string '[' expr ']'
   {
       $$ = NewAST(AST_EXPRLIST, NewAST(AST_ARRAYDECL, $1, $3), NULL);
   }
  ;

exprlist:
  expritem
 | exprlist ',' expritem
   { $$ = AddToList($1, $3); }
 ;

operand:
  expr
   { $$ = NewAST(AST_EXPRLIST, $1, NULL); }
 | '#' expr
   { $$ = NewAST(AST_EXPRLIST, NewAST(AST_IMMHOLDER, $2, NULL), NULL); }
 | '#' '#' expr
   { $$ = NewAST(AST_EXPRLIST, NewAST(AST_BIGIMMHOLDER, $3, NULL), NULL); }
 | expr '[' expr ']'
   { $$ = NewAST(AST_EXPRLIST, NewAST(AST_ARRAYREF, $1, $3), NULL); }
;

operandlist:
   operand
   { $$ = $1; }
 | operandlist ',' operand
   { $$ = AddToList($1, $3); }
 ;

range:
  expr
    { $$ = NewAST(AST_RANGE, $1, NULL); }
  | expr SP_DOTS expr
    { $$ = NewAST(AST_RANGE, $1, $3); }
  ;

integer:
  SP_NUM
;

float:
  SP_FLOATNUM
;

string:
  SP_STRING
;

identifier:
  SP_IDENTIFIER
  { $$ = $1; }
  | SP_RESULT
  { $$ = NewAST(AST_RESULT, NULL, NULL); }
;

annotation:
  SP_ANNOTATION
  { $$ = $1; }
;


hwreg:
  SP_HWREG
  { $$ = $1; }
;

instruction:
  SP_INSTR
  { $$ = $1; }
  | instrmodifier instruction
  { $$ = AddToList($2, $1); }
;
 
instrmodifier:
  SP_INSTRMODIFIER
  { $$ = $1; }
;

modifierlist:
  instrmodifier
    { $$ = $1; }
  | modifierlist instrmodifier
    { $$ = AddToList($1, $2); }
  | modifierlist ',' instrmodifier
    { $$ = AddToList($1, $3); }
  ;

%%

void
spinyyerror(const char *msg)
{
    extern int saved_spinyychar;
    int yychar = saved_spinyychar;
    
    ERRORHEADER(current->Lptr->fileName, current->Lptr->lineCounter, "error");

    // massage bison's error messages to make them easier to understand
    while (*msg) {
        // say which identifier was unexpected
        if (!strncmp(msg, "unexpected identifier", strlen("unexpected identifier")) && last_ast && last_ast->kind == AST_IDENTIFIER) {
            fprintf(stderr, "unexpected identifier `%s'", last_ast->d.string);
            msg += strlen("unexpected identifier");
        }
        // if we get a stray character in source, sometimes bison tries to treat it as a token for
        // error purposes, resulting in $undefined as the token
        else if (!strncmp(msg, "$undefined", strlen("$undefined")) && yychar >= ' ' && yychar < 127) {
            fprintf(stderr, "%c", yychar);
            msg += strlen("$undefined");
        }
        else {
            fprintf(stderr, "%c", *msg);
            msg++;
        }
    }
    fprintf(stderr, "\n");     
    gl_errors++;
}
