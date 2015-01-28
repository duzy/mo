#include <llvm/ExecutionEngine/Interpreter.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/ValueSymbolTable.h>
#include <llvm/Support/ManagedStatic.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/Support/raw_ostream.h>
#include "compiler.h"

extern "C" void sayd(int s)
{
    printf("%d\n", s);
}

extern "C" void say(int s)
{
    printf("%d\n", s);
}

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
        llvm::Value *operator()(const ast::identifier & v);
        llvm::Value *operator()(const std::string & v);
        llvm::Value *operator()(int v);
        llvm::Value *operator()(unsigned int v);
        llvm::Value *operator()(float v);
        llvm::Value *operator()(double v);

    private:
        llvm::Value *op_attr(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_call(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_set(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_mul(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_div(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_add(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_sub(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_and(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_or (llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_xor(llvm::Value *operand1, llvm::Value *operand2);

        llvm::Value *binary(llvm::Instruction::BinaryOps, llvm::Value *operand1, llvm::Value *operand2);
    };

    Value *expr_compiler::compile(const ast::expr & expr)
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
            case ast::opcode::mul:      operand1 = op_mul(operand1, operand2); break;
            case ast::opcode::div:      operand1 = op_div(operand1, operand2); break;
            case ast::opcode::add:      operand1 = op_add(operand1, operand2); break;
            case ast::opcode::sub:      operand1 = op_sub(operand1, operand2); break;
            case ast::opcode::a:        operand1 = op_and(operand1, operand2); break;
            case ast::opcode::o:        operand1 = op_or (operand1, operand2); break;
            case ast::opcode::xo:       operand1 = op_xor(operand1, operand2); break;
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

    Value *expr_compiler::operator()(const ast::expr & expr)
    {
        return compile(expr);
    }

    Value *expr_compiler::operator()(const ast::none & v)
    {
        std::clog << __FUNCTION__ << ": none" << std::endl;
        return nullptr;
    }

    Value *expr_compiler::operator()(const ast::identifier & id)
    {
        auto sym = comp->builder->GetInsertBlock()->getValueSymbolTable()->lookup(id.string);
        if (sym) return sym;
        
        auto gv = comp->module->getGlobalVariable(id.string);
        if (gv) return gv;

        auto fun = comp->module->getFunction(id.string);
        if (fun) return fun;
        
        return nullptr;
    }

    Value *expr_compiler::operator()(const std::string & v)
    {
        //std::clog << __FUNCTION__ << ": string = " << v << std::endl;
        return comp->builder->CreateGlobalString(v);
    }

    Value *expr_compiler::operator()(int v)
    {
        //std::clog << __FUNCTION__ << ": int = " << v << std::endl;
        return comp->builder->getInt32(v);
    }

    Value *expr_compiler::operator()(unsigned int v)
    {
        return comp->builder->getInt32(v);
    }

    Value *expr_compiler::operator()(float v)
    {
        std::clog << __FUNCTION__ << ": float = " << v << std::endl;
        return nullptr;
    }

    Value *expr_compiler::operator()(double v)
    {
        //!< see <llvm/ADT/APFloat.h>
        return ConstantFP::get(comp->context, APFloat(v));
    }

    Value *expr_compiler::op_attr(Value *operand1, Value *operand2)
    {
        return operand1;
    }

    Value *expr_compiler::op_call(Value *operand1, Value *operand2)
    {
        /*
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;
        */

        auto name = "res";
        if (isa<Function>(operand1) && cast<Function>(operand1)->getReturnType()->isVoidTy()) {
            name = ""; // "Cannot assign a name to void values!"
        }

        std::vector<Value*> args = { operand2 };

        return comp->builder->CreateCall(operand1, args, name);
    }

    Value *expr_compiler::op_set(Value *operand1, Value *operand2)
    {
        /*
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;
        */

        auto var = operand1;
        auto val = operand2;

        if (val->getType()->isPointerTy()) {
            val = comp->builder->CreateLoad(val, "value");
        }

        if (var->getType()->isPointerTy()) {
            comp->builder->CreateStore(val, var);
        }

        return operand1;
    }

    Value *expr_compiler::op_mul(Value *operand1, Value *operand2)
    {
        /*
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;
        */
        return binary(Instruction::Mul,  operand1, operand2);
    }

    Value *expr_compiler::op_div(Value *operand1, Value *operand2)
    {
        /*
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;
        */
        return binary(Instruction::UDiv,  operand1, operand2);
    }

    Value *expr_compiler::op_add(Value *operand1, Value *operand2)
    {
        /*
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;
        */
        return binary(Instruction::Add,  operand1, operand2); // comp->builder->CreateAdd(operand1, operand2, "tmp");
    }

    Value *expr_compiler::op_sub(Value *operand1, Value *operand2)
    {
        /*
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;
        */
        return binary(Instruction::Sub,  operand1, operand2);
    }

    llvm::Value *expr_compiler::op_and(llvm::Value *operand1, llvm::Value *operand2)
    {
        return binary(Instruction::And,  operand1, operand2);
    }

    llvm::Value *expr_compiler::op_or (llvm::Value *operand1, llvm::Value *operand2)
    {
        return binary(Instruction::Or,  operand1, operand2);
    }

    llvm::Value *expr_compiler::op_xor(llvm::Value *operand1, llvm::Value *operand2)
    {
        return binary(Instruction::Xor,  operand1, operand2);
    }

    Value *expr_compiler::binary(Instruction::BinaryOps op, Value *operand1, Value *operand2)
    {
#if 0
        if (isa<ConstantFP>(operand1) || isa<ConstantFP>(operand2)) {
            return comp->builder->CreateFAdd(operand1, operand2, "tmp");
        } else {
        }
#endif

        if (operand1->getType()->isPointerTy()) {
            operand1 = comp->builder->CreateLoad(operand1, "operand");
        }
        if (operand2->getType()->isPointerTy()) {
            operand2 = comp->builder->CreateLoad(operand2, "operand");
        }
        return comp->builder->CreateBinOp(op,  operand1, operand2, "binres");
    }

    static bool llvm_init_done = false;

    void compiler::Init()
    {
        if (llvm_init_done) return;
        llvm_init_done = true;

        InitializeNativeTarget();
        InitializeNativeTargetAsmPrinter();
        InitializeNativeTargetAsmParser();
    }

    void compiler::Shutdown()
    {
        llvm_shutdown();
    }

    compiler::compiler()
        : context()
        , typemap({
                //std::pair<std::string, Type*>("float16", Type::getHalfTy(context)),
                //std::pair<std::string, Type*>("float32", Type::getFloatTy(context)),
                //std::pair<std::string, Type*>("float64", Type::getDoubleTy(context)),
                std::pair<std::string, Type*>("float", Type::getDoubleTy(context)),
                std::pair<std::string, Type*>("int", IntegerType::get(context, 32))
          })
        , module(nullptr)
        , builder0(nullptr)
        , builder(nullptr)
    {
    }

    GenericValue compiler::eval(const ast::stmts & stmts)
    {
        GenericValue gv;

        if (!compile(stmts)) {
            std::clog << "malformed statements"  << std::endl;
            return gv;
        }

        auto m = module.get();
        if (!m) {
            std::clog << "no module created"  << std::endl;
            return gv;
        }

        auto start = m->getFunction("lyre·~start"); // lyre·start
        if (!start) {
            std::clog << "no module start point"  << std::endl;
            return gv;
        }

        outs() << "\n" << *m << "\n";
        outs().flush();

        this->builder.reset();

        // Now we create the JIT.
        std::string error;
        std::unique_ptr<ExecutionEngine> engine(
            EngineBuilder(std::move(module))
            .setErrorStr(&error)
            .setMCJITMemoryManager(make_unique<SectionMemoryManager>())
            .create()
        );

        if (!engine) {
            std::cerr << "Could not create ExecutionEngine: " << error << std::endl;
            return gv;
        }

        std::clog << "-------------------\n"
                  << "Run: ~start" << std::endl;

        // Call the `foo' function with no arguments:
        std::vector<GenericValue> noargs; // = { GenericValue(1) };
        gv = engine->runFunction(start, noargs);

        // Import result of execution:
        outs() << "Result: " << gv.IntVal << "\n";

        return gv;
    }

    compiler::result_type compiler::compile(const ast::stmts & stmts)
    {
        module = make_unique<Module>("a", context);

        {
            //std::vector<Type *> params = { Type::getDoubleTy(context) };
            std::vector<Type *> params = { Type::getInt32Ty(context) };
            FunctionType *FT = FunctionType::get(Type::getVoidTy(context), params, false);
            Function *F = Function::Create(FT, Function::ExternalLinkage, "say", module.get());
            F->arg_begin()->setName("s");
        }

        // Create the ~start function entry and insert this entry into module M.
        // The '0' terminates the list of argument types.
        auto start = cast<Function>(
            module->getOrInsertFunction(
                "lyre·~start"
                , Type::getInt32Ty(context)
                //, Type::getInt32Ty(context)
                , static_cast<Type*>(nullptr)
        ));

        auto EntryBlock = BasicBlock::Create(context, "EntryBlock", start);
        auto b0 = (builder0 = make_unique<IRBuilder<>>(EntryBlock)).get();
        if (stmts.empty()) {
            builder0->CreateRet(builder->getInt32(0));
            return start;
        }

        Value *last = nullptr;
        auto RootBlock = BasicBlock::Create(context, "RootBlock", start);
        builder = make_unique<IRBuilder<>>(RootBlock);
        for (auto stmt : stmts) {
            if (!(last = boost::apply_visitor(*this, stmt))) {
                b0->CreateRet(builder->getInt32(0));
                return nullptr;
            }
        }

        b0->CreateBr(RootBlock);

        if (last == nullptr) {
            builder->CreateRet(builder->getInt32(0));
        } else if (last->getType()->isPointerTy()) {
            last = builder->CreateLoad(last, "res");
        }

        if (last->getType()->isIntegerTy()) {
            builder->CreateRet(builder->CreateLoad(last, "res"));
        } else {
            builder->CreateRetVoid();
        }

        return start;
    }

    compiler::result_type compiler::operator()(const ast::expr & expr)
    {
        // TODO: accepts invocation only...
        expr_compiler excomp{ this };
        auto value = excomp.compile(expr);
        // std::clog << "expr: " << value << std::endl;
        return value;
    }

    compiler::result_type compiler::operator()(const ast::none &)
    {
        std::clog << "none: " << std::endl;
        return nullptr;
    }

    compiler::result_type compiler::operator()(const ast::decl & decl)
    {
        /*
        IRBuilder<> TmpB(&TheFunction->getEntryBlock(), TheFunction->getEntryBlock().begin());
        return TmpB.CreateAlloca(Type::getDoubleTy(getGlobalContext()), 0, VarName.c_str());
        */
        compiler::result_type lastStore = nullptr;
        for (auto sym : decl) {
            /**
             *  var = alloca typeof(sym.expr_)
             *  init = sym.expr_
             */
            auto type = Type::getVoidTy(context); // Type::getInt32Ty(context); // Type::getDoubleTy(context);

            Value* value = nullptr;
            if (sym.expr_) {
                expr_compiler excomp{ this };
                if ((value = excomp.compile(boost::get<ast::expr>(sym.expr_)))) {
                    type = value->getType();

                    /*
                    std::clog
                        << "decl: " << sym.id_.string << ", "
                        << type->getTypeID() << ", "
                        << type->getScalarSizeInBits()
                        << std::endl;
                    */
                }
            }

            /**
             *  Get a PointerTy of new alloca.
             */
            auto alloca = builder0->CreateAlloca(type, nullptr, sym.id_.string.c_str());
            if (value) {
                auto store = builder->CreateStore(value, alloca);
                lastStore = store;
            }

            /*
            std::clog
                //<< builder0->GetInsertBlock()->getParent()->getValueSymbolTable().lookup(sym.name_.c_str());
                << builder0->GetInsertBlock()->getValueSymbolTable()->lookup(sym.name_.c_str())
                << alloca << ", "
                << std::endl;
            */
        }
        return lastStore;
    }

    compiler::result_type compiler::operator()(const ast::proc & proc)
    {
        auto rty = Type::getVoidTy(context);
        if (proc.type_) {
            auto id = boost::get<ast::identifier>(proc.type_);
            auto t = typemap.find(id.string);
            if (t == typemap.end()) {
                std::cerr
                    << "proc: " << proc.name_.string << ": unknown return type '" << id.string << "'"
                    << std::endl ;
                return nullptr;
            }
            rty = t->second;
        }

        std::vector<Type*> params;
        for (auto param : proc.params_) {
            //std::clog << "param: " << param.type_.string << std::endl;
            auto t = typemap.find(param.type_.string);
            if (t == typemap.end()) {
                std::cerr
                    << "proc: " << proc.name_.string << ": unknown parameter type '"
                    << param.type_.string << "' referenced by '" << param.name_.string << "'"
                    << std::endl ;
                return nullptr;
            }
            params.push_back(t->second);
        }

        auto fty = FunctionType::get(rty, params, false);

        // ExternalLinkage, InternalLinkage, PrivateLinkage
        auto fun = Function::Create(fty, Function::PrivateLinkage, proc.name_.string, module.get());
        auto arg = fun->arg_begin();
        for (auto param : proc.params_) {
            assert (arg != fun->arg_end());
            arg->setName(param.name_.string);
            ++arg;
        }

        auto savedBuilder0 = std::move(builder0);
        auto savedBuilder = std::move(builder);

        if (nullptr == this->compile_body(fun, proc.block_.stmts_)) return nullptr;

        builder0 = std::move(savedBuilder0);
        builder = std::move(savedBuilder);
        return fun;
    }

    compiler::result_type compiler::compile_body(llvm::Function * fun, const ast::stmts & stmts)
    {
        auto rty = fun->getReturnType();

        auto EntryBlock = BasicBlock::Create(context, "EntryBlock", fun);
        auto b0 = (builder0 = make_unique<IRBuilder<>>(EntryBlock)).get();
        if (stmts.empty()) {
            /*
            if (rty->isVoidTy()) return b0->CreateRetVoid();
            return b0->CreateRet(builder->getInt32(0));
            */
            return b0->CreateRetVoid();
        }

        Value *last = nullptr;
        auto StartBlock = BasicBlock::Create(context, "StartBlock", fun);
        builder = make_unique<IRBuilder<>>(StartBlock);
        for (auto stmt : stmts) {
            if (!(last = boost::apply_visitor(*this, stmt))) {
                //b0->CreateRet(builder->getInt32(0));
                b0->CreateRetVoid();
                return nullptr;
            }
        }

        b0->CreateBr(StartBlock);

        if (rty->isVoidTy()) return b0->CreateRetVoid();
        if (last) {
            auto fty = fun->getFunctionType();
            auto lty = last->getType();
            if (lty->isPointerTy() && fty->isValidReturnType(lty->getPointerElementType()))
                return builder->CreateRet(builder->CreateLoad(last, "res"));
            if (fty->isValidReturnType(lty))
                return builder->CreateRet(last);
        }

        return b0->CreateRetVoid();
    }

    compiler::result_type compiler::operator()(const ast::type & s)
    {
        std::clog << "type: " << std::endl;
        return nullptr;
    }

    compiler::result_type compiler::operator()(const ast::see & s)
    {
        std::clog << "see: " << std::endl;
        return nullptr;
    }

    compiler::result_type compiler::operator()(const ast::with & s)
    {
        std::clog << "with: " << std::endl;
        return nullptr;
    }

    compiler::result_type compiler::operator()(const ast::speak & s)
    {
        std::clog << "speak: " << std::endl;
        return nullptr;
    }
}
