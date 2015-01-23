#include <llvm/ExecutionEngine/Interpreter.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/Support/ManagedStatic.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/Support/raw_ostream.h>
#include "compiler.h"

namespace lyre
{
    using namespace llvm;

    struct expr_compiler
    {
        compiler *comp;

        llvm::Value *compile(const ast::expr & v);
        llvm::Value *operator()(const ast::expr & v);
        llvm::Value *operator()(const ast::none & v);
        llvm::Value *operator()(const std::string & v);
        llvm::Value *operator()(int v);
        llvm::Value *operator()(unsigned int v);
        llvm::Value *operator()(float v);
        llvm::Value *operator()(double v);
    };

    llvm::Value *expr_compiler::compile(const ast::expr & v)
    {
        return nullptr;
    }

    llvm::Value *expr_compiler::operator()(const ast::expr & v)
    {
        return nullptr;
    }

    llvm::Value *expr_compiler::operator()(const ast::none & v)
    {
        return nullptr;
    }

    llvm::Value *expr_compiler::operator()(const std::string & v)
    {
        return comp->builder->CreateGlobalString(v);
    }

    llvm::Value *expr_compiler::operator()(int v)
    {
        return nullptr;
    }

    llvm::Value *expr_compiler::operator()(unsigned int v)
    {
        return nullptr;
    }

    llvm::Value *expr_compiler::operator()(float v)
    {
        return nullptr;
    }

    llvm::Value *expr_compiler::operator()(double v)
    {
        return nullptr;
    }

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
        , builder(nullptr)
        , builder0(nullptr)
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
        auto b0 = (builder0 = make_unique<IRBuilder<>>(block)).get();
        if (stmts.empty()) {
            return nullptr != builder0->CreateRet(builder->getInt32(0));
        }

        block = BasicBlock::Create(context, "RootBlock", start);
        builder = make_unique<IRBuilder<>>(block);
        for (auto stmt : stmts)
            if (!boost::apply_visitor(*this, stmt))
                return false;

        return nullptr != b0->CreateRet(builder->getInt32(0));
    }

    bool compiler::operator()(const ast::expr & s)
    {
        // TODO: accepts invocation only...
        std::clog << "expr: " << std::endl;
        return false;
    }

    bool compiler::operator()(const ast::none &)
    {
        std::clog << "none: " << std::endl;
        return false;
    }

    bool compiler::operator()(const ast::decl & decl)
    {
        /*
        IRBuilder<> TmpB(&TheFunction->getEntryBlock(),
                         TheFunction->getEntryBlock().begin());
        return TmpB.CreateAlloca(Type::getDoubleTy(getGlobalContext()), 0,
                                 VarName.c_str());
        */
        for (auto sym : decl) {
            /**
             *  var = alloca typeof(sym._expr)
             *  init = sym._expr
             */
            auto type = Type::getDoubleTy(context);
            auto alloca = builder0->CreateAlloca(type, nullptr, sym._name.c_str());
            if (sym._expr) {
                expr_compiler comp{ this };
                auto value = comp.compile(boost::get<ast::expr>(sym._expr));
            }
        }
        return false;
    }

    bool compiler::operator()(const ast::proc & s)
    {
        std::clog << "proc: " << std::endl;
        return false;
    }

    bool compiler::operator()(const ast::type & s)
    {
        std::clog << "type: " << std::endl;
        return false;
    }

    bool compiler::operator()(const ast::see & s)
    {
        std::clog << "see: " << std::endl;
        return false;
    }

    bool compiler::operator()(const ast::with & s)
    {
        std::clog << "with: " << std::endl;
        return false;
    }

    bool compiler::operator()(const ast::speak & s)
    {
        std::clog << "speak: " << std::endl;
        return false;
    }
}
