/*
 * Spin to C/C++ converter
 * Copyright 2011-2018 Total Spectrum Software Inc.
 * See the file COPYING for terms of use
 *
 * code for BASIC specific features
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "spinc.h"

extern AST *genPrintf(AST *);

static void
AddLabel(AST *ast)
{
    if (!ast->left || ast->left->kind != AST_IDENTIFIER) {
        ERROR(ast, "Label is not an identifier");
    } else {
        const char *name = ast->left->d.string;
        Symbol *sym = FindSymbol(&curfunc->localsyms, name);
        if (sym) {
            WARNING(ast, "Redefining %s as a label", name);
        }
        AddSymbol(&curfunc->localsyms, name, SYM_LOCALLABEL, 0);
    }
}

/*
 * returns a list of if x goto y; statments where x is a case condition and
 * y is the case label
 */
static AST *
CreateGotos(AST *tmpvar, AST *switchstmt, AST *stmt, AST **defaultlabel, AST *endswitch)
{
    AST *labelid;
    AST *label;
again:    
    if (!stmt) {
        return switchstmt;
    }
    AstReportAs(stmt);
    switch (stmt->kind) {
    case AST_CASE:
        ERROR(stmt, "Internal error, case not transformed");
        return switchstmt;
    case AST_CASEITEM:
    {
        AST *ifgoto;
        AST *ifcond;
        
        labelid = AstTempIdentifier("_case_");
        label = NewAST(AST_LABEL, labelid, NULL);
        AddLabel(label);
        ifcond = AstOperator(K_EQ, tmpvar, stmt->left);
        *stmt = *NewAST(AST_STMTLIST, label,
                        NewAST(AST_STMTLIST, stmt->right, NULL));
        ifgoto = NewAST(AST_GOTO, labelid, NULL);
        ifgoto = NewAST(AST_STMTLIST, ifgoto, NULL);
        ifgoto = NewAST(AST_THENELSE, ifgoto, NULL);
        ifgoto = NewAST(AST_IF, ifcond, ifgoto);
        switchstmt = AddToList(switchstmt, NewAST(AST_STMTLIST, ifgoto, NULL));
        goto again;
    }
    case AST_OTHER:
        if (defaultlabel) {
            if (*defaultlabel) {
                ERROR(stmt, "Switch already has a default label");
            }
            labelid = AstTempIdentifier("_case_");
            *defaultlabel = labelid;
            label = NewAST(AST_LABEL, labelid, NULL);
            AddLabel(label);
            *stmt = *NewAST(AST_STMTLIST, label,
                            NewAST(AST_STMTLIST, stmt->left, NULL));
        } else {
            ERROR(stmt, "Internal error, got default when not expecting it");
            return switchstmt;
        }
        goto again;
    case AST_QUIT:
        if (endswitch) {
            *stmt = *NewAST(AST_GOTO, endswitch, NULL);
        }
        return switchstmt;
    // for loops, "break" cannot have special meaning any more
    case AST_WHILE:
    case AST_DOWHILE:
    case AST_FOR:
    case AST_FORATLEASTONCE:
        endswitch = NULL;
        // fall through
    case AST_STMTLIST:
    case AST_IF:
    case AST_SEQUENCE:
    case AST_COMMENTEDNODE:
        switchstmt = CreateGotos(tmpvar, switchstmt, stmt->left, defaultlabel, endswitch);
        return CreateGotos(tmpvar, switchstmt, stmt->right, defaultlabel, endswitch);
    default:
        return switchstmt;
    }
    return switchstmt;
}

//
// transform a case statement
// we evaluate _tmpvar = expr
// then construct a series of statements like:
//  if (_tmpvar == case1expr) goto case1label
// for each case found within the stmt
//
static AST *
CreateSwitch(AST *expr, AST *stmt)
{
    AST *casetype;
    AST *tmpvar;
    AST *endswitch;
    AST *switchstmt = NULL;
    AST *defaultlabel = NULL;
    AST *gostmt;
    AST *endlabel;

    AstReportAs(stmt);
    casetype = ExprType(expr);
    tmpvar = AstTempLocalVariable("_tmp_", casetype);
    endswitch = AstTempIdentifier("_endswitch");
    
    switchstmt = NewAST(AST_STMTLIST, AstAssign(tmpvar, expr), NULL);
    // find all CASE labels within stmt; turn them into labels, and
    // create if(tmpvar == val) goto label;

    endlabel = NewAST(AST_LABEL, endswitch, NULL);
    AddLabel(endlabel);
    
    // switchstmt will have all the gotos
    switchstmt = CreateGotos(tmpvar, switchstmt, stmt, &defaultlabel, endswitch);
    // add a "goto default"
    if (!defaultlabel) {
        defaultlabel = endswitch;
    }
    gostmt = NewAST(AST_GOTO, defaultlabel, NULL);
    switchstmt = AddToList(switchstmt, NewAST(AST_STMTLIST, gostmt, NULL));
    switchstmt = AddToList(switchstmt, stmt);
    switchstmt = AddToList(switchstmt,
                           NewAST(AST_STMTLIST, endlabel, NULL));
    return switchstmt;
}

static void
doCTransform(AST **astptr)
{
    AST *ast = *astptr;
    Function *func;
    
    while (ast && ast->kind == AST_COMMENTEDNODE) {
        astptr = &ast->left;
        ast = *astptr;
    }
    if (!ast) return;
    AstReportAs(ast); // any newly created AST nodes should reflect debug info from this one
    switch (ast->kind) {
    case AST_ASSIGN:
        if (ast->left && ast->left->kind == AST_RANGEREF) {
            *astptr = ast = TransformRangeAssign(ast->left, ast->right, 1);
        }
        doCTransform(&ast->left);
        doCTransform(&ast->right);
        break;
    case AST_COUNTREPEAT:
        // convert repeat count into a for loop
        doCTransform(&ast->left);
        doCTransform(&ast->right);
        *astptr = TransformCountRepeat(*astptr);
        break;
    case AST_RANGEREF:
        doCTransform(&ast->left);
        doCTransform(&ast->right);
        *astptr = ast = TransformRangeUse(ast);
        break;
    case AST_ALLOCA:
        doCTransform(&ast->right);
        curfunc->uses_alloca = 1;
        break;
    case AST_ADDROF:
    case AST_ABSADDROF:
        {
            doCTransform(&ast->left);
            doCTransform(&ast->right);
            if (IsLocalVariable(ast->left)) {
                curfunc->local_address_taken = 1;
            }
            // taking the address of a function may restrict how
            // we can call it (stack vs. register calling)
            Symbol *sym;
            Function *f = NULL;
            sym = FindCalledFuncSymbol(ast, NULL, 0);
            if (sym && sym->type == SYM_FUNCTION) {
                f = (Function *)sym->val;
            }
            if (f) {
                f->used_as_ptr = 1;
                f->callSites++;
            }
        }
        break;
    case AST_METHODREF:
        doCTransform(&ast->left);
        doCTransform(&ast->right);
        if (IsPointerType(ast->left)) {
            WARNING(ast, "Needs a pointer dereference");
        }
        break;
    case AST_TRYENV:
        doCTransform(&ast->left);
        doCTransform(&ast->right);
        // keep local variables on stack, so they will be preserved
        // if an exception throws us back here without cleanup
        curfunc->local_address_taken = 1;
        break;
    case AST_LABEL:
        AddLabel(ast);
        break;
    case AST_COGINIT:
        doCTransform(&ast->left);
        doCTransform(&ast->right);
        if (0 != (func = IsSpinCoginit(ast))) {
            func->cog_task = 1;
            func->force_static = 1;
        }
        break;
    case AST_FUNCCALL:
        // handle __builtin_printf(x, ...) specially
        doCTransform(&ast->left);
        doCTransform(&ast->right);
        if (ast->left && ast->left->kind == AST_PRINT) {
            *ast = *genPrintf(ast);
        }
        break;
    case AST_CASE:
        doCTransform(&ast->left);
        doCTransform(&ast->right);
        AstReportAs(ast->left);
        *ast = *CreateSwitch(ast->left, ast->right);
        break;
    default:
        doCTransform(&ast->left);
        doCTransform(&ast->right);
        break;
    }
}

void
CTransform(Function *func)
{
    InitGlobalFuncs();
    
    SimplifyAssignments(&func->body);
    doCTransform(&func->body);
    CheckTypes(func->body);
}
