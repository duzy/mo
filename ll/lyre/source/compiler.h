#ifndef __LYRE_COMPILER_H____DUZY__
#define __LYRE_COMPILER_H____DUZY__ 1
#include <llvm/ExecutionEngine/GenericValue.h>
#include <llvm/ExecutionEngine/ExecutionEngine.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/IRBuilder.h>
#include <unordered_map>
#include "ast.h"

namespace lyre
{
    struct compiler
    {
        typedef llvm::Value* result_type;

        static void Init();
        static void Shutdown();

        compiler();

        llvm::GenericValue eval(const ast::stmts & stmts);

        result_type compile(const ast::stmts & stmts);

        result_type operator()(const ast::expr & s);
        result_type operator()(const ast::none &);
        result_type operator()(const ast::decl & s);
        result_type operator()(const ast::proc & s);
        result_type operator()(const ast::type & s);
        result_type operator()(const ast::see & s);
        result_type operator()(const ast::with & s);
        result_type operator()(const ast::speak & s);
        result_type operator()(const ast::per & s);
        result_type operator()(const ast::ret & s);

    private:
        result_type compile_expr(const ast::expr &);
        result_type compile_expr(const boost::optional<ast::expr> & e) { return compile_expr(boost::get<ast::expr>(e)); }
        result_type compile_body(llvm::Function * fun, const ast::stmts &);

        result_type create_alloca(llvm::Type *Ty, llvm::Value *ArraySize = nullptr, const std::string &Name = "");

        result_type calling_conv(llvm::Type*, llvm::Value*);

    private:
        friend struct expr_compiler;
        llvm::LLVMContext context;
        llvm::Type* variant;
        llvm::Type* nodetype;
        std::unordered_map<std::string, llvm::Type*> typemap;
        std::string error;
        llvm::Module * module;
        std::unique_ptr<llvm::ExecutionEngine> engine;
        std::unique_ptr<llvm::IRBuilder<>> builder; // the current block builder
    };
}

#endif//__LYRE_COMPILER_H____DUZY__
