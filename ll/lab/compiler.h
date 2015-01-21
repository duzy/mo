#ifndef __LAB_COMPILER_H____DUZY__
#define __LAB_COMPILER_H____DUZY__ 1
#include "ast.h"
#include "llvm/IR/LLVMContext.h"

namespace lab
{
    struct compiler
    {
        typedef bool result_type;

        static void Init();
        static void Shutdown();

        compiler();

        bool compile(const ast::stmts & stmts);

        template <class T> bool operator()(const T &) { return false; }

        bool operator()(const ast::expr & s);
        bool operator()(const ast::none &);
        bool operator()(const ast::decl & s);
        bool operator()(const ast::proc & s);
        bool operator()(const ast::type & s);
        bool operator()(const ast::see & s);
        bool operator()(const ast::with & s);
        bool operator()(const ast::speak & s);

    private:
        llvm::LLVMContext context;
    };
}

#endif//__LAB_COMPILER_H____DUZY__
