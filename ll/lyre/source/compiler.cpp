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

// TODO: http://llvm.org/docs/GarbageCollection.html

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
        llvm::Value *operator()(ast::cv v);
        llvm::Value *operator()(int v);
        llvm::Value *operator()(unsigned int v);
        llvm::Value *operator()(float v);
        llvm::Value *operator()(double v);

    private:
        llvm::Value *op_attr(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_call(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_set(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_mul(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_div(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_add(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_sub(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_and(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_or (const ast::op & op, llvm::Value *operand1, llvm::Value *operand2);
        llvm::Value *op_xor(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2);

        llvm::Value *binary(llvm::Instruction::BinaryOps, llvm::Value *operand1, llvm::Value *operand2);
    };

    Value *expr_compiler::compile(const ast::expr & expr)
    {
        auto operand1 = boost::apply_visitor(*this, expr.operand);
        if (expr.operators.empty()) {
            return operand1;
        }

        if (expr.operators.front().opcode == ast::opcode::comma) {
            std::vector<Metadata*> a{ ValueAsMetadata::get(operand1) };
            for (auto & op : expr.operators) {
                assert(op.opcode == ast::opcode::comma && "mixed comma with other operators");
                auto value = boost::apply_visitor(*this, op.operand);
                a.push_back( ValueAsMetadata::get(value) );
            }
            return MetadataAsValue::get(comp->context, MDNode::get(comp->context, a));
        }

        for (auto & op : expr.operators) {
            auto operand2 = boost::apply_visitor(*this, op.operand);
            switch (op.opcode) {
            case ast::opcode::attr:     operand1 = op_attr(op, operand1, operand2); break;
            case ast::opcode::call:     operand1 = op_call(op, operand1, operand2); break;
            case ast::opcode::set:      operand1 = op_set(op, operand1, operand2); break;
            case ast::opcode::mul:      operand1 = op_mul(op, operand1, operand2); break;
            case ast::opcode::div:      operand1 = op_div(op, operand1, operand2); break;
            case ast::opcode::add:      operand1 = op_add(op, operand1, operand2); break;
            case ast::opcode::sub:      operand1 = op_sub(op, operand1, operand2); break;
            case ast::opcode::a:        operand1 = op_and(op, operand1, operand2); break;
            case ast::opcode::o:        operand1 = op_or (op, operand1, operand2); break;
            case ast::opcode::xo:       operand1 = op_xor(op, operand1, operand2); break;
            default:
                std::clog
                    << __FUNCTION__
                    << ": expr: op = " << int(op.opcode) << ", "
                    //<< "operand1 = " << operand1 << ", "
                    //<< "operand2 = " << operand2
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
        //std::clog << __FILE__ << ":" << __LINE__ << ": " << id.string << std::endl;

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
        return comp->builder->CreateGlobalString(v, ".str");
    }

    Value *expr_compiler::operator()(ast::cv cv)
    {
        //std::clog << __FUNCTION__ << ": int = " << v << std::endl;
        switch (cv) {
        case ast::cv::null:
            break;
        case ast::cv::true_:
            return comp->builder->getInt1(1);
        case ast::cv::false_:
            return comp->builder->getInt1(0);
        }
        return nullptr;
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

    Value *expr_compiler::op_attr(const ast::op & op, Value *operand1, Value *operand2)
    {
        return operand1;
    }

    Value *expr_compiler::op_call(const ast::op & op, Value *operand1, Value *operand2)
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

        std::vector<Value*> args;

        if (operand2->getType()->isMetadataTy()) {
            auto mav = cast<MetadataAsValue>(operand2);
            auto mdnode = cast<MDNode>(mav->getMetadata());
            auto n = 0;
            for (auto & mdop : mdnode->operands()) {
                auto md = cast<ValueAsMetadata>(mdop.get());
                args.push_back(comp->calling_cast(fty->getParamType(n++), md->getValue()));
            }
        } else {
            args.push_back(comp->calling_cast(fty->getParamType(0), operand2));
        }

        if (!fty->isVarArg() && args.size() != fty->getNumParams()) {
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

#if 0
    Value *expr_compiler::op_list(const ast::op & op, Value *operand1, Value *operand2, llvm::Value *index)
    {
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;

        auto elem = comp->builder->CreateGEP(operand1, index);
        auto ptr1 = comp->builder->CreateStructGEP(elem, 0);
        auto ptr2 = comp->builder->CreateStructGEP(elem, 1);
        auto val = operand2;
        if (operand2->getType()->isPtrOrPtrVectorTy())
            comp->builder->CreatePointerCast(operand2,
                cast<PointerType>(ptr2->getType())->getElementType());
        comp->builder->CreateStore(val, ptr2);
        return operand1;
    }
#endif

    Value *expr_compiler::op_set(const ast::op & op, Value *operand1, Value *operand2)
    {
        /*
        std::clog
            << __FUNCTION__ << ": "
            << "operand1 = " << operand1 << ", "
            << "operand2 = " << operand2
            << std::endl;
        */

        auto var = operand1;
        auto varTy = var->getType();

        if (varTy->isPointerTy()) {
            auto varElementTy = varTy->getSequentialElementType();
            auto val = comp->calling_cast(varElementTy, operand2);

            std::clog << __FILE__ << ": " << __LINE__ << ":" << std::endl;
            std::clog << "\t"; varTy->dump();
            std::clog << "\t"; varElementTy->dump();
            std::clog << "\t"; operand2->getType()->dump();
            std::clog << "\t"; val->getType()->dump();

            if (varElementTy == comp->variant) {
                /**
                 *  Get pointer to the variant storage.
                 *
                 *  %type.lyre.variant = type { [8 x i8], i8* }
                 */
                auto zero = comp->builder->getInt32(0);
                std::vector<llvm::Value*> idx = { zero, zero, zero };
                auto ptr = comp->builder->CreateGEP(var, idx);

                /**
                 *  Convert the storage pointer for the value type.
                 */
                auto destTy = PointerType::getUnqual(val->getType());
                var = comp->builder->CreatePointerCast(ptr, destTy);
            }

            comp->builder->CreateStore(val, var); // store 'val' to the 'var'
        } else {
            std::cerr
                << "lyre: can't set value to a non-pointer value"
                << std::endl ;
            return nullptr;
        }

        return operand1;
    }

    Value *expr_compiler::op_mul(const ast::op & op, Value *operand1, Value *operand2)
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

    Value *expr_compiler::op_div(const ast::op & op, Value *operand1, Value *operand2)
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

    Value *expr_compiler::op_add(const ast::op & op, Value *operand1, Value *operand2)
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

    Value *expr_compiler::op_sub(const ast::op & op, Value *operand1, Value *operand2)
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

    llvm::Value *expr_compiler::op_and(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2)
    {
        return binary(Instruction::And,  operand1, operand2);
    }

    llvm::Value *expr_compiler::op_or(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2)
    {
        return binary(Instruction::Or,  operand1, operand2);
    }

    llvm::Value *expr_compiler::op_xor(const ast::op & op, llvm::Value *operand1, llvm::Value *operand2)
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

    static void say(const char * s, ...)
    {
        va_list ap;
        va_start(ap, s);
        vprintf(s, ap);
        va_end(ap);
        printf("\n");
    }

    static std::unordered_map<std::string, void*> LyreLazyFunctionMap = {
        std::pair<std::string, void*>("say", reinterpret_cast<void*>(&say))
    };

    // FIXME: http://llvm.org/PR5184 (thread safe issue)
    static void* LyreLazyFunctionCreator(const std::string & name)
    {
        auto i = LyreLazyFunctionMap.find(name);
        if (i != LyreLazyFunctionMap.end()) return i->second;
        return nullptr;
    }

    compiler::compiler()
        : context()
        , variant(
            StructType::create(
                "type.lyre.variant",
                //PointerType::getUnqual(Type::getInt8Ty(context)),
                ArrayType::get(Type::getInt8Ty(context), 8),
                PointerType::getUnqual(Type::getInt8Ty(context)),
                nullptr
            )
        )
        , nodetype(
            StructType::create(context, "type.lyre.node")
        )
        , typemap({
                //std::pair<std::string, Type*>("float16", Type::getHalfTy(context)),
                //std::pair<std::string, Type*>("float32", Type::getFloatTy(context)),
                //std::pair<std::string, Type*>("float64", Type::getDoubleTy(context)),
                std::pair<std::string, Type*>("float",  Type::getDoubleTy(context)),
                std::pair<std::string, Type*>("int",    IntegerType::get(context, 32)),
                std::pair<std::string, Type*>("bool",   Type::getInt1Ty(context)),
                std::pair<std::string, Type*>("variant", variant),
          })
        , error()
        , module(nullptr)
        , engine(nullptr)
        , builder(nullptr)
    {
        reinterpret_cast<StructType*>(nodetype)->setBody(
            Type::getInt8PtrTy(context),        // node (tag) name
            Type::getInt32Ty(context),          // number of children
            PointerType::getUnqual(nodetype),   // children
            PointerType::getUnqual(nodetype),   // parent
            nullptr
        );

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
            std::vector<Type *> params = { Type::getInt8PtrTy(context) };
            FunctionType *FT = FunctionType::get(Type::getVoidTy(context), params, true);
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

        std::clog
            << "-------------------\n"
            << "Run: " << start->getName().str() << "\n"
            << "----\n"
            << std::endl
            ;

        //engine->generateCodeForModule(module);

        // Ensure the module is fully processed and is usable. It has no effect for the interpeter.
        engine->finalizeObject();

        engine->runStaticConstructorsDestructors(/* isDtors = */false);

        // Call the `foo' function with no arguments:
#if 0
        std::vector<GenericValue> noargs;
        gv = engine->runFunction(start, noargs);
#else
        std::vector<std::string> argv = { "a" };
        const char * const * envp = nullptr;
        auto status = engine->runFunctionAsMain(start, argv, envp);
#endif

        engine->runStaticConstructorsDestructors(/* isDtors = */true);

        return gv;
    }

    compiler::result_type compiler::variant_cast(llvm::Type * destTy, llvm::Value * value)
    {
        if (value->getType()->isPointerTy()) {
            return variant_cast(destTy, builder->CreateLoad(value));
        }
        if (value->getType() != variant) {
            return nullptr;
        }

        std::clog << __FILE__ << ": " << __LINE__ << ": TODO: variant cast" << std::endl;
        
        return value;
    }

    compiler::result_type compiler::calling_cast(llvm::Type * destTy, llvm::Value * value)
    {
        auto valueTy = value->getType();
        //std::clog<<"target-type: "; if (destTy) destTy->dump(); else std::clog<<"null"<<std::endl; 
        //std::clog<<"value-type: "; valueTy->dump();
        if (valueTy == destTy) return value;
        if (valueTy == variant) return variant_cast(destTy, value);
        if (valueTy->isPointerTy()) {
            auto valueElementTy = valueTy->getSequentialElementType();
            if (valueElementTy == variant) {
                return variant_cast(destTy, value);
            }

            /**
             *  If the destination type is 'variant', we're doing a special conversion.
             */
            if (destTy == variant) {
                // TODO: type checking
                return builder->CreateLoad(value);
            }

            /**
             *  If the value is a pointer to the destTy or no destination type is given.
             */
            if (valueElementTy == destTy || destTy == nullptr) {
                /**
                 *  %0 = load i32* %a_integer
                 */
                return builder->CreateLoad(value);
            }

            /**
             *  If the value is a pointer to an array.
             */
            if (valueElementTy->isArrayTy()) {
                auto arrayElementTy = valueElementTy->getSequentialElementType();
                //std::clog<<"element-element: "; arrayElementTy->dump();
                if (arrayElementTy == destTy) {
                    /**
                     *  %0 = i8* getelementptr inbounds ([11 x i8]* @str1, i32 0, i32 0)
                     */
                    auto zero = builder->getInt32(0);
                    std::vector<llvm::Value*> idx = { zero, zero };
                    return builder->CreateGEP(value, idx);
                }
#if 0
                if (destTy->isPointerTy()) {
                    if (destTy->getSequentialElementType() == arrayElementTy) {
                        /**
                         *  %0 = i8* getelementptr inbounds (???)
                         */
                        return builder->CreateGEP(value, builder->getInt32(0));
                    }
                }
#endif
            }
            //std::clog<<"unknown-element: "; valueElementTy->dump();
        }
        //std::clog<<"----"<<std::endl;
        return value;
    }

    compiler::result_type compiler::compile(const ast::stmts & stmts)
    {
        // Create the ~start function entry and insert this entry into module M.
        // The '0' terminates the list of argument types.
        auto start = cast<Function>(
            module->getOrInsertFunction("lyre.start"
                , Type::getInt32Ty(context)
                , Type::getInt32Ty(context)
                , PointerType::getUnqual(Type::getInt8PtrTy(context))
                , static_cast<Type*>(nullptr)
            )
        );

        //start->getFunctionType()->getParamType(0)->setName("argc");
        //start->getFunctionType()->getParamType(1)->setName("argv");
        start->arg_begin()->setName("argc");
        (++start->arg_begin())->setName("argv");

        auto entry = BasicBlock::Create(context, "entry", start);
        builder = make_unique<IRBuilder<>>(entry);

        if (stmts.empty()) {
            builder->CreateRet(builder->getInt32(0));
            return start;
        }

        auto block = BasicBlock::Create(context, "top", start);
        builder->CreateBr(block);
        builder->SetInsertPoint(block);

        Value *last = nullptr;
        for (auto & stmt : stmts) {
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

    compiler::result_type compiler::create_alloca(llvm::Type *Ty, llvm::Value *ArraySize, const std::string &Name)
    {
        auto & entry = builder->GetInsertBlock()->getParent()->getEntryBlock();
        IRBuilder<> allocaBuilder(&entry, entry.begin());
        return allocaBuilder.CreateAlloca(Ty, ArraySize, Name.c_str());
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
        auto & entry = builder->GetInsertBlock()->getParent()->getEntryBlock();
        IRBuilder<> allocaBuilder(&entry, entry.begin());

        compiler::result_type lastAlloca = nullptr;
        for (auto & sym : decl) {
            /**
             *  The default type is 'variant'.
             */
            auto type = variant;

            //std::clog << __FILE__ << ":" << __LINE__ << ": " << sym.id.string << std::endl;

            if (sym.type) {
                auto i = typemap.find(boost::get<ast::identifier>(sym.type).string);
                if (i != typemap.end()) type = i->second;
            }

            Value* value = nullptr;
            if (sym.expr) {
                if ((value = compile_expr(sym.expr))) {
                    /**
                     *  Use the value type if no explicit type specified.
                     */
                    if (!sym.type) type = value->getType();

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
        for (auto & param : proc.params) {
            if (!param.type) {
                params.push_back(variant);
                continue;
            }

            auto & id = boost::get<ast::identifier>(param.type);
            auto t = typemap.find(id.string);
            if (t == typemap.end()) {
                std::cerr
                    << "proc: " << proc.name.string << ": unknown parameter type '"
                    << id.string << "' referenced by '" << param.name.string << "'"
                    << std::endl ;
                return nullptr;
            }
            params.push_back(t->second);
        }

        auto fty = FunctionType::get(rty, params, false);

        // ExternalLinkage, InternalLinkage, PrivateLinkage
        auto fun = Function::Create(fty, Function::PrivateLinkage, proc.name.string, module);
        auto arg = fun->arg_begin();
        for (auto & param : proc.params) {
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

        auto entry = BasicBlock::Create(context, "entry", fun);
        builder->SetInsertPoint(entry);

        if (stmts.empty()) {
            return builder->CreateRetVoid();
        }

        auto block = BasicBlock::Create(context, "block", fun);
        builder->CreateBr(block);
        builder->SetInsertPoint(block);

        Value *last = nullptr;
        for (auto & stmt : stmts) {
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
