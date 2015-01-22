#ifndef __LAB_COMPILER_H____DUZY__
#define __LAB_COMPILER_H____DUZY__ 1
#include <llvm/ExecutionEngine/GenericValue.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/IRBuilder.h>
#include "ast.h"

namespace lab
{
    struct compiler
    {
        typedef bool result_type;

        static void Init();
        static void Shutdown();

        compiler();

        bool compile(const ast::stmts & stmts);

        llvm::GenericValue eval(const ast::stmts & stmts);

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
        std::unique_ptr<llvm::Module> module;
        std::unique_ptr<llvm::IRBuilder<>> builder; // the current block builder
    };
}

#endif//__LAB_COMPILER_H____DUZY__
