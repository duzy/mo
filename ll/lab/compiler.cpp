#include <llvm/ExecutionEngine/GenericValue.h>
#include <llvm/ExecutionEngine/Interpreter.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/Support/ManagedStatic.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/Support/raw_ostream.h>
#include "compiler.h"

namespace lab
{
    static bool llvm_init_done = false;

    void compiler::Init()
    {
        if (!llvm_init_done) {
            llvm::InitializeNativeTarget();
            llvm_init_done = true;
        }
    }

    void compiler::Shutdown()
    {
        llvm::llvm_shutdown();
    }

    compiler::compiler()
        : context()
    {
    }

    bool compiler::compile(const ast::stmts & stmts)
    {
        

        for (auto stmt : stmts)
            if (!boost::apply_visitor(*this, stmt))
                return false;
        return true;
    }

    bool compiler::operator()(const ast::expr & s)
    {
        return false;
    }

    bool compiler::operator()(const ast::none &)
    {
        return false;
    }

    bool compiler::operator()(const ast::decl & s)
    {
        return false;
    }

    bool compiler::operator()(const ast::proc & s)
    {
        return false;
    }

    bool compiler::operator()(const ast::type & s)
    {
        return false;
    }

    bool compiler::operator()(const ast::see & s)
    {
        return false;
    }

    bool compiler::operator()(const ast::with & s)
    {
        return false;
    }

    bool compiler::operator()(const ast::speak & s)
    {
        return false;
    }
}
