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
        typedef llvm::Value * result_type;

        compiler *comp;

        llvm::Value *compile(const ast::expr & v);
        llvm::Value *operator()(const ast::expr & v);
        llvm::Value *operator()(const ast::none & v);
        llvm::Value *operator()(const std::string & v);
        llvm::Value *operator()(int v);
        llvm::Value *operator()(unsigned int v);
        llvm::Value *operator()(float v);
        llvm::Value *operator()(double v);

    private:
        llvm::Value *op_attr(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_call(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_set(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_add(llvm::Value *operand1, llvm::Value *operand2);
    };

    llvm::Value *expr_compiler::compile(const ast::expr & expr)
    {
        auto operand1 = boost::apply_visitor(*this, expr.operand_);
        if (expr.operators_.empty()) {
            return operand1;
        }

        for (auto op : expr.operators_) {
            auto operand2 = boost::apply_visitor(*this, op.operand_);

            switch (op.operator_) {
            case ast::opcode::attr:     operand1 = op_attr(operand1, operand2); break;
            case ast::opcode::call:     operand1 = op_call(operand1, operand2); break;
            case ast::opcode::set:      operand1 = op_set(operand1, operand2); break;
            case ast::opcode::add:      operand1 = op_add(operand1, operand2); break;
            default:
                std::clog
                    << __FUNCTION__
                    << ": expr: op = " << int(op.operator_) << ", "
                    << "operand1 = " << operand1 << ", "
                    << "operand2 = " << operand2
                    << std::endl ;
            }
        }

        return operand1;
    }

    llvm::Value *expr_compiler::operator()(const ast::expr & expr)
    {
        return compile(expr);
    }

    llvm::Value *expr_compiler::operator()(const ast::none & v)
    {
        std::clog << __FUNCTION__ << ": none" << std::endl;
        return nullptr;
    }

    llvm::Value *expr_compiler::operator()(const std::string & v)
    {
        //std::clog << __FUNCTION__ << ": string = " << v << std::endl;
        return comp->builder->CreateGlobalString(v);
    }

    llvm::Value *expr_compiler::operator()(int v)
    {
        //std::clog << __FUNCTION__ << ": int = " << v << std::endl;
        return comp->builder->getInt32(v);
    }

    llvm::Value *expr_compiler::operator()(unsigned int v)
    {
        return comp->builder->getInt32(v);
    }

    llvm::Value *expr_compiler::operator()(float v)
    {
        std::clog << __FUNCTION__ << ": float = " << v << std::endl;
        return nullptr;
    }

    llvm::Value *expr_compiler::operator()(double v)
    {
        std::clog << __FUNCTION__ << ": double = " << v << std::endl;
        return nullptr;
    }

    llvm::Value *expr_compiler::op_attr(llvm::Value *operand1, llvm::Value *operand2)
    {
        return operand1;
    }

    llvm::Value *expr_compiler::op_call(llvm::Value *operand1, llvm::Value *operand2)
    {
        return operand1;
    }

    llvm::Value *expr_compiler::op_set(llvm::Value *operand1, llvm::Value *operand2)
    {
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;

        /*
        // Assignment requires the LHS to be an identifier.
        VariableExprAST *LHSE = dynamic_cast<VariableExprAST *>(LHS);
        if (!LHSE)
            return ErrorV("destination of '=' must be a variable");
        // Codegen the RHS.
        Value *Val = RHS->Codegen();
        if (Val == 0)
            return 0;

        // Look up the name.
        Value *Variable = NamedValues[LHSE->getName()];
        if (Variable == 0)
            return ErrorV("Unknown variable name");

        Builder.CreateStore(Val, Variable);
        return Val;
        */

        auto var = operand1;

        comp->builder->CreateStore(operand2, var);
        return operand1;
    }

    llvm::Value *expr_compiler::op_add(llvm::Value *operand1, llvm::Value *operand2)
    {
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;
        return operand1;
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

    bool compiler::operator()(const ast::expr & expr)
    {
        // TODO: accepts invocation only...
        expr_compiler excomp{ this };
        auto value = excomp.compile(expr);
        std::clog << "expr: " << value << std::endl;
        return value != nullptr;
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
             *  var = alloca typeof(sym.expr_)
             *  init = sym.expr_
             */
            auto type = Type::getDoubleTy(context);
            auto alloca = builder0->CreateAlloca(type, nullptr, sym.name_.c_str());
            if (sym.expr_) {
                expr_compiler excomp{ this };
                auto value = excomp.compile(boost::get<ast::expr>(sym.expr_));
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
