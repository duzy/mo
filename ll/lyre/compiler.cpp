#if LYRE_USING_MCJIT
#  include <llvm/ExecutionEngine/MCJIT.h>
#  include <llvm/ExecutionEngine/SectionMemoryManager.h>
#else
#  include <llvm/ExecutionEngine/Interpreter.h>
#endif
#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/ValueSymbolTable.h>
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
        llvm::Value *operator()(const ast::identifier & v);
        llvm::Value *operator()(const std::string & v);
        llvm::Value *operator()(int v);
        llvm::Value *operator()(unsigned int v);
        llvm::Value *operator()(float v);
        llvm::Value *operator()(double v);

    private:
        llvm::Value *op_attr(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_call(llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_list(llvm::Value *operand1, llvm::Value *operand2);
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
        auto operand1 = boost::apply_visitor(*this, expr.operand);
        if (expr.operators.empty()) {
            return operand1;
        }

        for (auto op : expr.operators) {
            auto operand2 = boost::apply_visitor(*this, op.operand);
            switch (op.opcode) {
            case ast::opcode::attr:     operand1 = op_attr(operand1, operand2); break;
            case ast::opcode::call:     operand1 = op_call(operand1, operand2); break;
            case ast::opcode::list:     operand1 = op_list(operand1, operand2); break;
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
                    << ": expr: op = " << int(op.opcode) << ", "
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

        if (!isa<Function>(operand1)) {
            std::cerr
                << "lyre: '" << operand1->getName().str() << "' is not a function"
                << std::endl ;
            return nullptr;
        }

        auto fun = cast<Function>(operand1);
        auto fty = fun->getFunctionType();

        std::vector<Value*> args = { operand2 };

        if (args.size() != fty->getNumParams()) {
            std::cerr
                << "lyre: '" << operand1->getName().str() << "' wrong number of arguments"
                << std::endl ;
            return nullptr;
        }

        for (auto n=0; n < fty->getNumParams(); ++n) {
            auto pty = fty->getParamType(n);
            auto aty = args[n]->getType();
            if (pty == aty) continue;
            if (aty->canLosslesslyBitCastTo(pty)) {
                if (aty->isPointerTy()) {
                    args[n] = comp->builder->CreatePointerCast(args[n], pty);
                } else if (aty->isIntegerTy()) {
                    args[n] = comp->builder->CreateIntCast(args[n], pty, true /* TODO: isSigned */);
                }
                continue;
            }
        }

        auto name = "res";
        if (fun->getReturnType()->isVoidTy()) {
            name = ""; // "Cannot assign a name to void values!"
        }
        return comp->builder->CreateCall(fun, args, name);
    }

    Value *expr_compiler::op_list(Value *operand1, Value *operand2)
    {
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;
        return nullptr;
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

    static void say(const char * s)
    {
        printf("%s\n", s);
    }

    static std::unordered_map<std::string, void*> LyreLazyFunctionMap = {
        std::pair<std::string, void*>("say", reinterpret_cast<void*>(&say))
    };

    static void* LyreLazyFunctionCreator(const std::string & name)
    {
        auto i = LyreLazyFunctionMap.find(name);
        if (i != LyreLazyFunctionMap.end()) return i->second;
        return nullptr;
    }

    compiler::compiler()
        : context()
        , typemap({
                //std::pair<std::string, Type*>("float16", Type::getHalfTy(context)),
                //std::pair<std::string, Type*>("float32", Type::getFloatTy(context)),
                //std::pair<std::string, Type*>("float64", Type::getDoubleTy(context)),
                std::pair<std::string, Type*>("float", Type::getDoubleTy(context)),
                std::pair<std::string, Type*>("int", IntegerType::get(context, 32)),
                std::pair<std::string, Type*>("bool", Type::getInt1Ty(context)),
                std::pair<std::string, Type*>("variant", PointerType::get(Type::getInt8PtrTy(context), 0)),
                std::pair<std::string, Type*>("node", StructType::get(context))
          })
        , error()
        , module(nullptr)
        , engine(nullptr)
        , builder(nullptr)
    {
        auto m = make_unique<Module>("a", context);

        // Keep the reference to the module
        module = m.get();

        // Now we create the JIT.
        auto jit = EngineBuilder(std::move(m))
            .setErrorStr(&error)
#if LYRE_USING_MCJIT
            .setMCJITMemoryManager(make_unique<SectionMemoryManager>())
#endif
            .create();

#if LYRE_USING_MCJIT
        jit->setProcessAllSections(true);
#endif

        jit->InstallLazyFunctionCreator(LyreLazyFunctionCreator);

        module->setDataLayout(jit->getDataLayout());

        if (1) {
            std::vector<Type *> params = { Type::getInt8PtrTy(context) }; // { ArrayType::get(Type::getInt8Ty(context)) }
            FunctionType *FT = FunctionType::get(Type::getVoidTy(context), params, false);
            Function *F = Function::Create(FT, Function::ExternalLinkage, "say", module);
            F->arg_begin()->setName("s");
        }

        engine.reset(jit);
    }

    GenericValue compiler::eval(const ast::stmts & stmts)
    {
        GenericValue gv;

        if (!compile(stmts)) {
            std::clog << "lyre: failed to compile statements"  << std::endl;
            return gv;
        }

        // Print out all of the generated code.
#if 1
        module->dump();
#else
        outs() << "\n" << *module << "\n";
        outs().flush();
#endif

        auto start = module->getFunction("lyre.start"); // lyre·start
        if (!start) {
            std::clog << "no module start point"  << std::endl;
            return gv;
        }

        if (!engine) {
            std::cerr << "Could not create ExecutionEngine: " << error << std::endl;
            return gv;
        }

        std::clog << "-------------------\n"
                  << "Run: " << start->getName().str()
                  << std::endl ;

        //engine->generateCodeForModule(module);

        // Ensure the module is fully processed and is usable. It has no effect for the interpeter.
        engine->finalizeObject();

        engine->runStaticConstructorsDestructors(/* isDtors = */false);

        // Call the `foo' function with no arguments:
        std::vector<GenericValue> noargs; // = { GenericValue(1) };
        gv = engine->runFunction(start, noargs);

        engine->runStaticConstructorsDestructors(/* isDtors = */true);

        return gv;
    }

    compiler::result_type compiler::compile(const ast::stmts & stmts)
    {
        // Create the ~start function entry and insert this entry into module M.
        // The '0' terminates the list of argument types.
        auto start = cast<Function>(
            module->getOrInsertFunction("lyre.start"
                , Type::getInt32Ty(context) //Type::getVoidTy(context)
                , static_cast<Type*>(nullptr)
            )
        );

        auto EntryBlock = BasicBlock::Create(context, "EntryBlock", start);
        builder = make_unique<IRBuilder<>>(EntryBlock);

        if (stmts.empty()) {
            builder->CreateRet(builder->getInt32(0));
            return start;
        }

        auto TopBlock = BasicBlock::Create(context, "TopBlock", start);
        builder->CreateBr(TopBlock);
        builder->SetInsertPoint(TopBlock);

        Value *last = nullptr;
        for (auto stmt : stmts) {
            if (!(last = boost::apply_visitor(*this, stmt))) {
                builder->CreateRet(builder->getInt32(0));
                return nullptr;
            }
        }

        // If the block is well formed, we don't need to add 'ret'.
        if (builder->GetInsertBlock()->getTerminator()) return start;

#if 0
        if (last == nullptr) {
            builder->CreateRet(builder->getInt32(0));
        } else if (last->getType()->isPointerTy()) {
            last = builder->CreateLoad(last, "res");
        }

        if (last->getType()->isIntegerTy()) {
            builder->CreateRet(builder->CreateLoad(last, "res"));
        } else {
            builder->CreateRet(builder->getInt32(0));
        }
#else
        builder->CreateRet(builder->getInt32(0));
#endif

        return start;
    }

    compiler::result_type compiler::compile_expr(const ast::expr & expr)
    {
        expr_compiler excomp{ this };
        auto value = excomp.compile(expr);
        return value;
    }

    compiler::result_type compiler::operator()(const ast::expr & expr)
    {
        // TODO: accepts invocation only...
        return compile_expr(expr);
    }

    compiler::result_type compiler::operator()(const ast::none &)
    {
        std::clog << "none: " << std::endl;
        return nullptr;
    }

    compiler::result_type compiler::operator()(const ast::decl & decl)
    {
        auto & EntryBlock = builder->GetInsertBlock()->getParent()->getEntryBlock();
        IRBuilder<> allocaBuilder(&EntryBlock, EntryBlock.begin());

        auto variant = typemap.find("variant")->second;
        compiler::result_type lastAlloca = nullptr;
        for (auto sym : decl) {
            /**
             *  var = alloca typeof(sym.expr)
             *  store var, sym.expr
             */

            auto type = variant;

            Value* value = nullptr;
            if (sym.expr) {
                if ((value = compile_expr(sym.expr))) {
                    type = value->getType();

                    /*
                    std::clog
                        << "decl: " << sym.id.string << ", "
                        << type->getTypeID() << ", "
                        << type->getScalarSizeInBits()
                        << std::endl;
                    */
                }
            }

            /**
             *  Get a PointerTy of new alloca.
             */
            auto alloca = allocaBuilder.CreateAlloca(type, nullptr, sym.id.string.c_str());
            if (value) {
                auto store = builder->CreateStore(value, alloca);
            }

            lastAlloca = alloca;

            /*
            std::clog
                //<< builder->GetInsertBlock()->getParent()->getValueSymbolTable().lookup(sym.name.c_str());
                << builder->GetInsertBlock()->getValueSymbolTable()->lookup(sym.name.c_str())
                << alloca << ", "
                << std::endl;
            */
        }
        return lastAlloca;
    }

    compiler::result_type compiler::operator()(const ast::proc & proc)
    {
        auto rty = Type::getVoidTy(context);
        if (proc.type) {
            auto id = boost::get<ast::identifier>(proc.type);
            auto t = typemap.find(id.string);
            if (t == typemap.end()) {
                std::cerr
                    << "proc: " << proc.name.string << ": unknown return type '" << id.string << "'"
                    << std::endl ;
                return nullptr;
            }
            rty = t->second;
        }

        std::vector<Type*> params;
        for (auto param : proc.params) {
            //std::clog << "param: " << param.type.string << std::endl;
            auto t = typemap.find(param.type.string);
            if (t == typemap.end()) {
                std::cerr
                    << "proc: " << proc.name.string << ": unknown parameter type '"
                    << param.type.string << "' referenced by '" << param.name.string << "'"
                    << std::endl ;
                return nullptr;
            }
            params.push_back(t->second);
        }

        auto fty = FunctionType::get(rty, params, false);

        // ExternalLinkage, InternalLinkage, PrivateLinkage
        auto fun = Function::Create(fty, Function::PrivateLinkage, proc.name.string, module);
        auto arg = fun->arg_begin();
        for (auto param : proc.params) {
            assert (arg != fun->arg_end());
            arg->setName(param.name.string);
            ++arg;
        }

        auto savedInsertBlock = builder->GetInsertBlock();

        if (nullptr == this->compile_body(fun, proc.block.stmts)) {
            // No function body, remove function.
            fun->eraseFromParent();
            return nullptr;
        }

        builder->SetInsertPoint(savedInsertBlock);
        return fun;
    }

    compiler::result_type compiler::compile_body(llvm::Function * fun, const ast::stmts & stmts)
    {
        auto rty = fun->getReturnType();

        auto EntryBlock = BasicBlock::Create(context, "EntryBlock", fun);
        builder->SetInsertPoint(EntryBlock);

        if (stmts.empty()) {
            return builder->CreateRetVoid();
        }

        auto StartBlock = BasicBlock::Create(context, "StartBlock", fun);
        builder->CreateBr(StartBlock);
        builder->SetInsertPoint(StartBlock);

        Value *last = nullptr;
        for (auto stmt : stmts) {
            if (!(last = boost::apply_visitor(*this, stmt))) {
                builder->CreateRetVoid();
                return nullptr;
            }
        }

        if (builder->GetInsertBlock()->getTerminator()) return last;

        if (rty->isVoidTy()) return builder->CreateRetVoid();
        if (last) {
            auto fty = fun->getFunctionType();
            auto lty = last->getType();
            if (lty->isPointerTy() && fty->isValidReturnType(lty->getPointerElementType()))
                return builder->CreateRet(builder->CreateLoad(last, "res"));
            if (fty->isValidReturnType(lty))
                return builder->CreateRet(last);
        }
        return builder->CreateRetVoid();
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

    compiler::result_type compiler::operator()(const ast::per & s)
    {
        return nullptr;
    }

    compiler::result_type compiler::operator()(const ast::ret & s)
    {
        auto value = compile_expr(s.expr);
        /*
        std::clog
            << "return: " << value << ", "
            << std::endl
            ;
        */
        if (!value) return nullptr;
        return builder->CreateRet(value);
    }
}
