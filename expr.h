#ifndef EXPR_H
#define EXPR_H

typedef struct exprval {
    AST *type;
    int32_t  val;
} ExprVal;

/* evaluate a constant expression */
int32_t EvalConstExpr(AST *expr);

/* similar but for PASM */
int32_t EvalPasmExpr(AST *expr);

/* determine whether an expression is constant */
/* note that strings, as pointers to memory, are not "constant"
   in that their value is not known until link time */
int IsConstExpr(AST *expr);
/* determine whether an expression is a float constant */
int IsFloatConst(AST *expr);
/* determine whether an expression is a string constant
   the value will not be known initially at compile time!
*/
bool IsStringConst(AST *expr);

/* evaluate to an integer if an expression is constant */
AST *FoldIfConst(AST *expr);

/* look up a methodref or constref */
Symbol *LookupMethodRef(AST *expr, Module **Ptr);

/* look up the class name of an object */
const char *ObjClassName(AST *objtype);

/* expression utility functions */
union float_or_int {
    int32_t i;
    float   f;
};

ExprVal intExpr(int32_t x);
ExprVal floatExpr(float f);
ExprVal fixedExpr(int32_t f);
int32_t  floatAsInt(float f);
float    intAsFloat(int32_t i);

AST *RemoveTypeModifiers(AST *typ);

int TypeSize(AST *typ);
int TypeAlign(AST *typ);

int IsArray(AST *expr);
int IsArrayType(AST *typ);
int IsArrayOrPointerSymbol(Symbol *);
int TypeAlignment(AST *typ);
int PointerTypeIncrement(AST *typ);
// get base of an array type
AST *GetArrayBase(AST *type);

int IsFunctionType(AST *typ);
int IsStringType(AST *typ);
int IsFloatType(AST *typ);
int IsIntType(AST *typ);
int IsVoidType(AST *typ);
int IsUnsignedType(AST *typ);
int IsGenericType(AST *typ);
int IsPointerType(AST *typ);
#define IsIntOrGenericType(t) (IsGenericType(t) || IsIntType(t))
int IsBoolCompatibleType(AST *typ);
int IsClassType(AST *typ);

int IsConstType(AST *typ);

// note that this function isn't symmetric; for pointer types,
// it allows A to have a stricter type than B (so for example
// it's OK to pass a "char *" to a "const char *" but not vice-versa)
int CompatibleTypes(AST *A, AST *B);

// get the name from an AST_IDENTIFIER or AST_SYMBOL
const char *GetIdentifierName(AST *ident);

Symbol *LookupSymbol(const char *name);
Symbol *LookupAstSymbol(AST *ast, const char *msg);
Symbol *LookupMemberSymbol(AST *topexpr, AST *objtype, const char *name, Module **Ptr);

// find expression type relative to current function
AST *ExprType(AST *ast);

// find expression type relative to some table
AST *ExprTypeRelative(SymbolTable *table, AST *ast);

// the type underlying an array or pointer
AST *BaseType(AST *ast);

AST *TransformRangeAssign(AST *dst, AST *src, int toplevel);
AST *TransformRangeUse(AST *src);
AST *TransformCaseExprList(AST *var, AST *list);

// optimize things like ((a+N)-N) -> a
AST *SimpleOptimizeExpr(AST *);

// return 1 if an expression can have side effects
int ExprHasSideEffects(AST *);

// number of results from a function
int FuncNumResults(AST *functype);

// number of parameters to a function (negative for varargs, in which
// case the absolute value is the minimum number of parameters)
int FuncNumParams(AST *functype);

#endif
