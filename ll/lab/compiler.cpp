#include <llvm/ExecutionEngine/Interpreter.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/Support/ManagedStatic.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/Support/raw_ostream.h>
#include "compiler.h"

namespace lab
{
    using namespace llvm;

    static bool llvm_init_done = false;

    void compiler::Init()
    {
        if (llvm_init_done) return;
        llvm_init_done = true;
        llvm::InitializeNativeTarget();
    }

    void compiler::Shutdown()
    {
        llvm::llvm_shutdown();
    }

    compiler::compiler()
        : context()
        , module(nullptr)
    {
    }

    GenericValue compiler::eval(const ast::stmts & stmts)
    {
        GenericValue gv;

        if (!compile(stmts)) {
            //std::clog << "malformed statements"  << std::endl;
            //return gv;
        }

        auto m = module.get();
        if (!m) {
            std::clog << "no module created"  << std::endl;
            return gv;
        }

        auto start = m->getFunction("~start");
        if (!start) {
            std::clog << "no module start point"  << std::endl;
            return gv;
        }

        outs() << "\n" << *m << "\n";
        outs().flush();

        this->builder.reset();

        // Now we create the JIT.
        std::unique_ptr<ExecutionEngine> engine(EngineBuilder(std::move(module)).create());

        std::clog << "-------------------\n"
                  << "Run: ~start" << std::endl;

        // Call the `foo' function with no arguments:
        std::vector<GenericValue> noargs; // = { GenericValue(1) };
        gv = engine->runFunction(start, noargs);

        // Import result of execution:
        outs() << "Result: " << gv.IntVal << "\n";

        return gv;
    }

    bool compiler::compile(const ast::stmts & stmts)
    {
        module = make_unique<Module>("a", context);

        // Create the ~start function entry and insert this entry into module M.
        // The '0' terminates the list of argument types.
        auto start = cast<Function>(
            module->getOrInsertFunction(
                "~start"
                , Type::getInt32Ty(context)
                //, Type::getInt32Ty(context)
                , static_cast<Type*>(nullptr)
        ));

        auto block = BasicBlock::Create(context, "EntryBlock", start);
        auto b0 = ( builder = make_unique<IRBuilder<>>(block) ).get();

        for (auto stmt : stmts)
            if (!boost::apply_visitor(*this, stmt))
                return false;

        auto inst = b0->CreateRet(builder->getInt32(0));
        return inst != nullptr;
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
