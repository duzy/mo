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

#define D(MSG)                                                          \
    std::clog << __FILE__ << ":" << __LINE__ << ": " << MSG << std::endl ;
    
#define DUMP_TY(MSG, TY)                                                \
    std::clog << __FILE__ << ":" << __LINE__ << ": " << MSG ;           \
    if (TY) { (TY)->dump(); } else { std::clog << "null" << std::endl; }

// TODO: http://llvm.org/docs/GarbageCollection.html

namespace lyre
{
    using namespace llvm;

    typedef llvm::Value *(*CC)(compiler *comp, llvm::Type *target, llvm::Value *value);

    struct CallingCast
    {
        /*
        static llvm::Value *Void_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Void_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Half_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Float_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Double_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_FP80_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *FP128_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *PPC_FP128_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Label_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Metadata_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *X86_MMX_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Integer_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Function_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Struct_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Array_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Pointer_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Void(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Half(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Float(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Double(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Label(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Integer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Function(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Struct(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Array(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value);
        static llvm::Value *Vector_Vector(compiler *comp, llvm::Type *target, llvm::Value *value);
        */

        static llvm::Value *identical(compiler */*comp*/, llvm::Type *target, llvm::Value *value)
        {
            assert(value->getType() == target && "value type and target type is not identical");
            return value;
        }

        static llvm::Value *impossible(compiler */*comp*/, llvm::Type *target, llvm::Value *value)
        {
            assert(value->getType() == target && "value type and target type is not convertible");
            return value;
        }

        static llvm::Value *Void_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isVoidTy() && "value type is not Void");
            return value;
        }

        static llvm::Value *Void_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Void_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Void_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Void_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Void_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Void_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Void_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Void_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Void_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Void_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Void_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Void_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Void_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Void_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *Void_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVoidTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Half_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Half_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Half_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Half_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Half_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Half_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Half_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Half_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Half_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Half_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Half_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Half_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Half_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Half_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Half_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *Half_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isHalfTy() && "target type is not Half");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Float_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Float_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Float_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Float_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Float_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Float_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Float_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Float_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Float_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Float_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Float_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Float_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Float_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Float_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Float_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *Float_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFloatTy() && "target type is not Float");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Double_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isVoidTy() && "value type is not Void");
            return value;
        }

        static llvm::Value *Double_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Double_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Double_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Double_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Double_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Double_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Double_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Double_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Double_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Double_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Double_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Double_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Double_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Double_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *Double_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isDoubleTy() && "target type is not Double");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *X86_FP80_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isVoidTy() && "value type is not Void");
            return value;
        }

        static llvm::Value *X86_FP80_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *X86_FP80_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *X86_FP80_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *X86_FP80_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *X86_FP80_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *X86_FP80_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *X86_FP80_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *X86_FP80_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *X86_FP80_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *X86_FP80_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *X86_FP80_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *X86_FP80_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *X86_FP80_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *X86_FP80_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *X86_FP80_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_FP80Ty() && "target type is not X86_FP80");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *FP128_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isVoidTy() && "value type is not Void");
            return value;
        }

        static llvm::Value *FP128_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *FP128_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *FP128_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *FP128_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *FP128_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *FP128_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *FP128_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *FP128_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *FP128_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *FP128_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *FP128_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *FP128_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *FP128_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *FP128_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *FP128_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFP128Ty() && "target type is not FP128");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *PPC_FP128_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isVoidTy() && "value type is not Void");
            return value;
        }

        static llvm::Value *PPC_FP128_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *PPC_FP128_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *PPC_FP128_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *PPC_FP128_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *PPC_FP128_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *PPC_FP128_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC PPC_FP128");
            return value;
        }

        static llvm::Value *PPC_FP128_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *PPC_FP128_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *PPC_FP128_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *PPC_FP128_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *PPC_FP128_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *PPC_FP128_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *PPC_FP128_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *PPC_FP128_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *PPC_FP128_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPPC_FP128Ty() && "target type is not PPC_FP128");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Label_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isVoidTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Label_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Label_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Label_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Label_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Label_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Label_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Label_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Label_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Label_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Label_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Label_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Label_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Label_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Label_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *Label_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isLabelTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Metadata_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Metadata_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Metadata_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Metadata_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Metadata_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Metadata_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Metadata_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Metadata_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Metadata_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Metadata_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Metadata_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Metadata_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Metadata_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Metadata_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Metadata_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *Metadata_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isMetadataTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *X86_MMX_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *X86_MMX_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *X86_MMX_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *X86_MMX_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *X86_MMX_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *X86_MMX_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *X86_MMX_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *X86_MMX_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *X86_MMX_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *X86_MMX_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *X86_MMX_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *X86_MMX_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *X86_MMX_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *X86_MMX_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *X86_MMX_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *X86_MMX_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isX86_MMXTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Integer_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Integer_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Integer_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Integer_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Integer_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Integer_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Integer_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Integer_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Integer_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Integer_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Integer_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Integer_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Integer_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Integer_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Integer_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            //DUMP_TY("target-type: ", target);
            //DUMP_TY("value-type: ", value->getType());

            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");

            auto pointeeTy = value->getType()->getSequentialElementType();

            if (pointeeTy == target) {
                return comp->builder->CreateLoad(value);
            }

            //DUMP_TY("pointee-type: ", pointeeTy);

            if (pointeeTy == comp->variant) {
                auto ptr = comp->builder->CreatePointerCast(
                    comp->get_variant_storage(value), PointerType::getUnqual(target));
                //DUMP_TY("storage: ", ptr->getType());
                return comp->builder->CreateLoad(ptr);
            }

            return value;
        }

        static llvm::Value *Integer_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isIntegerTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Function_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Function_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Function_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Function_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Function_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Function_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Function_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Function_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Function_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Function_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Function_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Function_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Function_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Function_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Function_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *Function_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isFunctionTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Struct_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Struct_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Struct_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Struct_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Struct_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Struct_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Struct_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Struct_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Struct_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Struct_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Struct_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);

            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");

            DUMP_TY("target-type: ", target);
            DUMP_TY("value-type: ", value->getType());

            if (target == comp->variant) {
                D("variant");
            }

            return value;
        }

        static llvm::Value *Struct_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Struct_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Struct_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Struct_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *Struct_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isStructTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Array_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Array_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Array_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Array_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Array_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Array_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Array_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Array_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Array_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Array_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Array_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Array_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Array_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Array_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Array_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);

            auto valueTy = value->getType();

            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");

            

            return value;
        }

        static llvm::Value *Array_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isArrayTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Pointer_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isPointerTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Pointer_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Pointer_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Pointer_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Pointer_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Pointer_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Pointer_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Pointer_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Pointer_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Pointer_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Pointer_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Pointer_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Pointer_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Pointer_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);

            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Array");

            

            return value;
        }

        static llvm::Value *Pointer_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);

            DUMP_TY("target-type: ", target);

            auto valueTy = value->getType();
            DUMP_TY("value-type: ", valueTy);

            assert(valueTy->isPointerTy() && "value type is not Pointer");
            assert(target->isPointerTy() && "target type is not Void");

            auto pointeeTy = valueTy->getSequentialElementType();
            DUMP_TY("pointee-type: ", pointeeTy);

            if (pointeeTy == comp->variant) {
                D("TODO: variant casting");
            }

#if 0
            /**
             *  CreatePointerCast can also convert a '[n x i8]*' into 'i8*', so we don't need
             *  to do this specially.
             */
            if (pointeeTy->isArrayTy()) {
                auto arrayElementTy = pointeeTy->getSequentialElementType();
                if  (arrayElementTy == target->getSequentialElementType()) {
                    /**
                     *  %0 = i8* getelementptr inbounds ([11 x i8]* @str1, i32 0, i32 0)
                     */
                    auto zero = comp->builder->getInt32(0);
                    auto idxs = std::vector<llvm::Value*>{ zero, zero };
                    return comp->builder->CreateGEP(value, idxs);
                }
            }
#endif

            /**
             *  Note that 'CreatePointerCast' can also convert '[n x i8]*' into 'i8*'.
             */
            auto result = comp->builder->CreatePointerCast(value, target);
            DUMP_TY("result-type: ", result->getType());

            return result;
        }

        static llvm::Value *Pointer_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isPointerTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static llvm::Value *Vector_Void(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Vector_Half(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isHalfTy() && "value type is not Half");
            return value;
        }

        static llvm::Value *Vector_Float(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isFloatTy() && "value type is not Float");
            return value;
        }

        static llvm::Value *Vector_Double(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isDoubleTy() && "value type is not Double");
            return value;
        }

        static llvm::Value *Vector_X86_FP80(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isX86_FP80Ty() && "value type is not X86_FP80");
            return value;
        }

        static llvm::Value *Vector_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isFP128Ty() && "value type is not FP128");
            return value;
        }

        static llvm::Value *Vector_PPC_FP128(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isPPC_FP128Ty() && "value type is not PPC_FP128");
            return value;
        }

        static llvm::Value *Vector_Label(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isLabelTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Vector_Metadata(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isMetadataTy() && "value type is not Label");
            return value;
        }

        static llvm::Value *Vector_X86_MMX(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isX86_MMXTy() && "value type is not X86_MMX");
            return value;
        }

        static llvm::Value *Vector_Integer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isIntegerTy() && "value type is not Integer");
            return value;
        }

        static llvm::Value *Vector_Function(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isFunctionTy() && "value type is not Function");
            return value;
        }

        static llvm::Value *Vector_Struct(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isStructTy() && "value type is not Struct");
            return value;
        }

        static llvm::Value *Vector_Array(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isArrayTy() && "value type is not Array");
            return value;
        }

        static llvm::Value *Vector_Pointer(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isPointerTy() && "value type is not Pointer");
            return value;
        }

        static llvm::Value *Vector_Vector(compiler *comp, llvm::Type *target, llvm::Value *value)
        {
            D(__FUNCTION__);
            assert(target->isVectorTy() && "target type is not Void");
            assert(value->getType()->isVectorTy() && "value type is not Vector");
            return value;
        }

        static CC getCallingCaster(llvm::Type::TypeID target, llvm::Type::TypeID dest)
        {
            static CC CastMap[16][16] = { { nullptr } };
            if (CastMap[0][0] == nullptr) {
                std::memset(CastMap, 0, sizeof(CC) * 16 * 16);
                CastMap[llvm::Type::VoidTyID][llvm::Type::VoidTyID]             = &Void_Void;
                CastMap[llvm::Type::VoidTyID][llvm::Type::HalfTyID]             = &Void_Half;
                CastMap[llvm::Type::VoidTyID][llvm::Type::FloatTyID]            = &Void_Float;
                CastMap[llvm::Type::VoidTyID][llvm::Type::DoubleTyID]           = &Void_Double;
                CastMap[llvm::Type::VoidTyID][llvm::Type::X86_FP80TyID]         = &Void_X86_FP80;
                CastMap[llvm::Type::VoidTyID][llvm::Type::FP128TyID]            = &Void_FP128;
                CastMap[llvm::Type::VoidTyID][llvm::Type::PPC_FP128TyID]        = &Void_PPC_FP128;
                CastMap[llvm::Type::VoidTyID][llvm::Type::LabelTyID]            = &Void_Label;
                CastMap[llvm::Type::VoidTyID][llvm::Type::MetadataTyID]         = &Void_Metadata;
                CastMap[llvm::Type::VoidTyID][llvm::Type::X86_MMXTyID]          = &Void_X86_MMX;
                CastMap[llvm::Type::VoidTyID][llvm::Type::IntegerTyID]          = &Void_Integer;
                CastMap[llvm::Type::VoidTyID][llvm::Type::FunctionTyID]         = &Void_Function;
                CastMap[llvm::Type::VoidTyID][llvm::Type::StructTyID]           = &Void_Struct;
                CastMap[llvm::Type::VoidTyID][llvm::Type::ArrayTyID]            = &Void_Array;
                CastMap[llvm::Type::VoidTyID][llvm::Type::PointerTyID]          = &Void_Pointer;
                CastMap[llvm::Type::VoidTyID][llvm::Type::VectorTyID]           = &Void_Vector;

                CastMap[llvm::Type::HalfTyID][llvm::Type::VoidTyID]             = &Half_Void;
                CastMap[llvm::Type::HalfTyID][llvm::Type::HalfTyID]             = &Half_Half;
                CastMap[llvm::Type::HalfTyID][llvm::Type::FloatTyID]            = &Half_Float;
                CastMap[llvm::Type::HalfTyID][llvm::Type::DoubleTyID]           = &Half_Double;
                CastMap[llvm::Type::HalfTyID][llvm::Type::X86_FP80TyID]         = &Half_X86_FP80;
                CastMap[llvm::Type::HalfTyID][llvm::Type::FP128TyID]            = &Half_FP128;
                CastMap[llvm::Type::HalfTyID][llvm::Type::PPC_FP128TyID]        = &Half_PPC_FP128;
                CastMap[llvm::Type::HalfTyID][llvm::Type::LabelTyID]            = &Half_Label;
                CastMap[llvm::Type::HalfTyID][llvm::Type::MetadataTyID]         = &Half_Metadata;
                CastMap[llvm::Type::HalfTyID][llvm::Type::X86_MMXTyID]          = &Half_X86_MMX;
                CastMap[llvm::Type::HalfTyID][llvm::Type::IntegerTyID]          = &Half_Integer;
                CastMap[llvm::Type::HalfTyID][llvm::Type::FunctionTyID]         = &Half_Function;
                CastMap[llvm::Type::HalfTyID][llvm::Type::StructTyID]           = &Half_Struct;
                CastMap[llvm::Type::HalfTyID][llvm::Type::ArrayTyID]            = &Half_Array;
                CastMap[llvm::Type::HalfTyID][llvm::Type::PointerTyID]          = &Half_Pointer;
                CastMap[llvm::Type::HalfTyID][llvm::Type::VectorTyID]           = &Half_Vector;

                CastMap[llvm::Type::FloatTyID][llvm::Type::VoidTyID]            = &Float_Void;
                CastMap[llvm::Type::FloatTyID][llvm::Type::HalfTyID]            = &Float_Half;
                CastMap[llvm::Type::FloatTyID][llvm::Type::FloatTyID]           = &Float_Float;
                CastMap[llvm::Type::FloatTyID][llvm::Type::DoubleTyID]          = &Float_Double;
                CastMap[llvm::Type::FloatTyID][llvm::Type::X86_FP80TyID]        = &Float_X86_FP80;
                CastMap[llvm::Type::FloatTyID][llvm::Type::FP128TyID]           = &Float_FP128;
                CastMap[llvm::Type::FloatTyID][llvm::Type::PPC_FP128TyID]       = &Float_PPC_FP128;
                CastMap[llvm::Type::FloatTyID][llvm::Type::LabelTyID]           = &Float_Label;
                CastMap[llvm::Type::FloatTyID][llvm::Type::MetadataTyID]        = &Float_Metadata;
                CastMap[llvm::Type::FloatTyID][llvm::Type::X86_MMXTyID]         = &Float_X86_MMX;
                CastMap[llvm::Type::FloatTyID][llvm::Type::IntegerTyID]         = &Float_Integer;
                CastMap[llvm::Type::FloatTyID][llvm::Type::FunctionTyID]        = &Float_Function;
                CastMap[llvm::Type::FloatTyID][llvm::Type::StructTyID]          = &Float_Struct;
                CastMap[llvm::Type::FloatTyID][llvm::Type::ArrayTyID]           = &Float_Array;
                CastMap[llvm::Type::FloatTyID][llvm::Type::PointerTyID]         = &Float_Pointer;
                CastMap[llvm::Type::FloatTyID][llvm::Type::VectorTyID]          = &Float_Vector;

                CastMap[llvm::Type::DoubleTyID][llvm::Type::VoidTyID]           = &Double_Void;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::HalfTyID]           = &Double_Half;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::FloatTyID]          = &Double_Float;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::DoubleTyID]         = &identical;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::X86_FP80TyID]       = &Double_X86_FP80;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::FP128TyID]          = &Double_FP128;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::PPC_FP128TyID]      = &Double_PPC_FP128;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::LabelTyID]          = &Double_Label;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::MetadataTyID]       = &Double_Metadata;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::X86_MMXTyID]        = &Double_X86_MMX;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::IntegerTyID]        = &Double_Integer;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::FunctionTyID]       = &Double_Function;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::StructTyID]         = &Double_Struct;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::ArrayTyID]          = &Double_Array;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::PointerTyID]        = &Double_Pointer;
                CastMap[llvm::Type::DoubleTyID][llvm::Type::VectorTyID]         = &Double_Vector;

                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::VoidTyID]         = &X86_FP80_Void;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::HalfTyID]         = &X86_FP80_Half;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::FloatTyID]        = &X86_FP80_Float;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::DoubleTyID]       = &X86_FP80_Double;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::X86_FP80TyID]     = &X86_FP80_X86_FP80;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::FP128TyID]        = &X86_FP80_FP128;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::PPC_FP128TyID]    = &X86_FP80_PPC_FP128;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::LabelTyID]        = &X86_FP80_Label;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::MetadataTyID]     = &X86_FP80_Metadata;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::X86_MMXTyID]      = &X86_FP80_X86_MMX;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::IntegerTyID]      = &X86_FP80_Integer;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::FunctionTyID]     = &X86_FP80_Function;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::StructTyID]       = &X86_FP80_Struct;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::ArrayTyID]        = &X86_FP80_Array;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::PointerTyID]      = &X86_FP80_Pointer;
                CastMap[llvm::Type::X86_FP80TyID][llvm::Type::VectorTyID]       = &X86_FP80_Vector;

                CastMap[llvm::Type::FP128TyID][llvm::Type::VoidTyID]            = &FP128_Void;
                CastMap[llvm::Type::FP128TyID][llvm::Type::HalfTyID]            = &FP128_Half;
                CastMap[llvm::Type::FP128TyID][llvm::Type::FloatTyID]           = &FP128_Float;
                CastMap[llvm::Type::FP128TyID][llvm::Type::DoubleTyID]          = &FP128_Double;
                CastMap[llvm::Type::FP128TyID][llvm::Type::X86_FP80TyID]        = &FP128_X86_FP80;
                CastMap[llvm::Type::FP128TyID][llvm::Type::FP128TyID]           = &identical;
                CastMap[llvm::Type::FP128TyID][llvm::Type::PPC_FP128TyID]       = &FP128_PPC_FP128;
                CastMap[llvm::Type::FP128TyID][llvm::Type::LabelTyID]           = &FP128_Label;
                CastMap[llvm::Type::FP128TyID][llvm::Type::MetadataTyID]        = &FP128_Metadata;
                CastMap[llvm::Type::FP128TyID][llvm::Type::X86_MMXTyID]         = &FP128_X86_MMX;
                CastMap[llvm::Type::FP128TyID][llvm::Type::IntegerTyID]         = &FP128_Integer;
                CastMap[llvm::Type::FP128TyID][llvm::Type::FunctionTyID]        = &FP128_Function;
                CastMap[llvm::Type::FP128TyID][llvm::Type::StructTyID]          = &FP128_Struct;
                CastMap[llvm::Type::FP128TyID][llvm::Type::ArrayTyID]           = &FP128_Array;
                CastMap[llvm::Type::FP128TyID][llvm::Type::PointerTyID]         = &FP128_Pointer;
                CastMap[llvm::Type::FP128TyID][llvm::Type::VectorTyID]          = &FP128_Vector;

                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::VoidTyID]        = &PPC_FP128_Void;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::HalfTyID]        = &PPC_FP128_Half;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::FloatTyID]       = &PPC_FP128_Float;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::DoubleTyID]      = &PPC_FP128_Double;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::X86_FP80TyID]    = &PPC_FP128_X86_FP80;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::FP128TyID]       = &PPC_FP128_FP128;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::PPC_FP128TyID]   = &PPC_FP128_PPC_FP128;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::LabelTyID]       = &PPC_FP128_Label;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::MetadataTyID]    = &PPC_FP128_Metadata;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::X86_MMXTyID]     = &PPC_FP128_X86_MMX;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::IntegerTyID]     = &PPC_FP128_Integer;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::FunctionTyID]    = &PPC_FP128_Function;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::StructTyID]      = &PPC_FP128_Struct;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::ArrayTyID]       = &PPC_FP128_Array;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::PointerTyID]     = &PPC_FP128_Pointer;
                CastMap[llvm::Type::PPC_FP128TyID][llvm::Type::VectorTyID]      = &PPC_FP128_Vector;
            
                CastMap[llvm::Type::LabelTyID][llvm::Type::VoidTyID]            = &Label_Void;
                CastMap[llvm::Type::LabelTyID][llvm::Type::HalfTyID]            = &Label_Half;
                CastMap[llvm::Type::LabelTyID][llvm::Type::FloatTyID]           = &Label_Float;
                CastMap[llvm::Type::LabelTyID][llvm::Type::DoubleTyID]          = &Label_Double;
                CastMap[llvm::Type::LabelTyID][llvm::Type::X86_FP80TyID]        = &Label_X86_FP80;
                CastMap[llvm::Type::LabelTyID][llvm::Type::FP128TyID]           = &Label_FP128;
                CastMap[llvm::Type::LabelTyID][llvm::Type::PPC_FP128TyID]       = &Label_PPC_FP128;
                CastMap[llvm::Type::LabelTyID][llvm::Type::LabelTyID]           = &Label_Label;
                CastMap[llvm::Type::LabelTyID][llvm::Type::MetadataTyID]        = &Label_Metadata;
                CastMap[llvm::Type::LabelTyID][llvm::Type::X86_MMXTyID]         = &Label_X86_MMX;
                CastMap[llvm::Type::LabelTyID][llvm::Type::IntegerTyID]         = &Label_Integer;
                CastMap[llvm::Type::LabelTyID][llvm::Type::FunctionTyID]        = &Label_Function;
                CastMap[llvm::Type::LabelTyID][llvm::Type::StructTyID]          = &Label_Struct;
                CastMap[llvm::Type::LabelTyID][llvm::Type::ArrayTyID]           = &Label_Array;
                CastMap[llvm::Type::LabelTyID][llvm::Type::PointerTyID]         = &Label_Pointer;
                CastMap[llvm::Type::LabelTyID][llvm::Type::VectorTyID]          = &Label_Vector;

                CastMap[llvm::Type::MetadataTyID][llvm::Type::VoidTyID]         = &Metadata_Void;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::HalfTyID]         = &Metadata_Half;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::FloatTyID]        = &Metadata_Float;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::DoubleTyID]       = &Metadata_Double;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::X86_FP80TyID]     = &Metadata_X86_FP80;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::FP128TyID]        = &Metadata_FP128;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::PPC_FP128TyID]    = &Metadata_PPC_FP128;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::LabelTyID]        = &Metadata_Label;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::MetadataTyID]     = &Metadata_Metadata;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::X86_MMXTyID]      = &Metadata_X86_MMX;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::IntegerTyID]      = &Metadata_Integer;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::FunctionTyID]     = &Metadata_Function;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::StructTyID]       = &Metadata_Struct;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::ArrayTyID]        = &Metadata_Array;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::PointerTyID]      = &Metadata_Pointer;
                CastMap[llvm::Type::MetadataTyID][llvm::Type::VectorTyID]       = &Metadata_Vector;

                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::VoidTyID]          = &X86_MMX_Void;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::HalfTyID]          = &X86_MMX_Half;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::FloatTyID]         = &X86_MMX_Float;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::DoubleTyID]        = &X86_MMX_Double;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::X86_FP80TyID]      = &X86_MMX_X86_FP80;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::FP128TyID]         = &X86_MMX_FP128;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::PPC_FP128TyID]     = &X86_MMX_PPC_FP128;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::LabelTyID]         = &X86_MMX_Label;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::MetadataTyID]      = &X86_MMX_Metadata;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::X86_MMXTyID]       = &X86_MMX_X86_MMX;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::IntegerTyID]       = &X86_MMX_Integer;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::FunctionTyID]      = &X86_MMX_Function;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::StructTyID]        = &X86_MMX_Struct;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::ArrayTyID]         = &X86_MMX_Array;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::PointerTyID]       = &X86_MMX_Pointer;
                CastMap[llvm::Type::X86_MMXTyID][llvm::Type::VectorTyID]        = &X86_MMX_Vector;

                CastMap[llvm::Type::IntegerTyID][llvm::Type::VoidTyID]          = &Integer_Void;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::HalfTyID]          = &Integer_Half;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::FloatTyID]         = &Integer_Float;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::DoubleTyID]        = &Integer_Double;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::X86_FP80TyID]      = &Integer_X86_FP80;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::FP128TyID]         = &Integer_FP128;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::PPC_FP128TyID]     = &Integer_PPC_FP128;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::LabelTyID]         = &Integer_Label;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::MetadataTyID]      = &Integer_Metadata;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::X86_MMXTyID]       = &Integer_X86_MMX;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::IntegerTyID]       = &identical;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::FunctionTyID]      = &Integer_Function;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::StructTyID]        = &Integer_Struct;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::ArrayTyID]         = &Integer_Array;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::PointerTyID]       = &Integer_Pointer;
                CastMap[llvm::Type::IntegerTyID][llvm::Type::VectorTyID]        = &Integer_Vector;

                CastMap[llvm::Type::FunctionTyID][llvm::Type::VoidTyID]         = &Function_Void;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::HalfTyID]         = &Function_Half;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::FloatTyID]        = &Function_Float;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::DoubleTyID]       = &Function_Double;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::X86_FP80TyID]     = &Function_X86_FP80;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::FP128TyID]        = &Function_FP128;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::PPC_FP128TyID]    = &Function_PPC_FP128;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::LabelTyID]        = &Function_Label;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::MetadataTyID]     = &Function_Metadata;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::X86_MMXTyID]      = &Function_X86_MMX;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::IntegerTyID]      = &Function_Integer;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::FunctionTyID]     = &identical;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::StructTyID]       = &Function_Struct;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::ArrayTyID]        = &Function_Array;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::PointerTyID]      = &Function_Pointer;
                CastMap[llvm::Type::FunctionTyID][llvm::Type::VectorTyID]       = &Function_Vector;

                CastMap[llvm::Type::StructTyID][llvm::Type::VoidTyID]           = &Struct_Void;
                CastMap[llvm::Type::StructTyID][llvm::Type::HalfTyID]           = &Struct_Half;
                CastMap[llvm::Type::StructTyID][llvm::Type::FloatTyID]          = &Struct_Float;
                CastMap[llvm::Type::StructTyID][llvm::Type::DoubleTyID]         = &Struct_Double;
                CastMap[llvm::Type::StructTyID][llvm::Type::X86_FP80TyID]       = &Struct_X86_FP80;
                CastMap[llvm::Type::StructTyID][llvm::Type::FP128TyID]          = &Struct_FP128;
                CastMap[llvm::Type::StructTyID][llvm::Type::PPC_FP128TyID]      = &Struct_PPC_FP128;
                CastMap[llvm::Type::StructTyID][llvm::Type::LabelTyID]          = &Struct_Label;
                CastMap[llvm::Type::StructTyID][llvm::Type::MetadataTyID]       = &Struct_Metadata;
                CastMap[llvm::Type::StructTyID][llvm::Type::X86_MMXTyID]        = &Struct_X86_MMX;
                CastMap[llvm::Type::StructTyID][llvm::Type::IntegerTyID]        = &Struct_Integer;
                CastMap[llvm::Type::StructTyID][llvm::Type::FunctionTyID]       = &Struct_Function;
                CastMap[llvm::Type::StructTyID][llvm::Type::StructTyID]         = &identical;
                CastMap[llvm::Type::StructTyID][llvm::Type::ArrayTyID]          = &Struct_Array;
                CastMap[llvm::Type::StructTyID][llvm::Type::PointerTyID]        = &Struct_Pointer;
                CastMap[llvm::Type::StructTyID][llvm::Type::VectorTyID]         = &Struct_Vector;

                CastMap[llvm::Type::ArrayTyID][llvm::Type::VoidTyID]            = &Array_Void;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::HalfTyID]            = &Array_Half;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::FloatTyID]           = &Array_Float;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::DoubleTyID]          = &Array_Double;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::X86_FP80TyID]        = &Array_X86_FP80;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::FP128TyID]           = &Array_FP128;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::PPC_FP128TyID]       = &Array_PPC_FP128;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::LabelTyID]           = &Array_Label;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::MetadataTyID]        = &Array_Metadata;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::X86_MMXTyID]         = &Array_X86_MMX;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::IntegerTyID]         = &Array_Integer;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::FunctionTyID]        = &Array_Function;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::StructTyID]          = &Array_Struct;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::ArrayTyID]           = &Array_Array;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::PointerTyID]         = &Array_Pointer;
                CastMap[llvm::Type::ArrayTyID][llvm::Type::VectorTyID]          = &Array_Vector;

                CastMap[llvm::Type::PointerTyID][llvm::Type::VoidTyID]          = &Pointer_Void;
                CastMap[llvm::Type::PointerTyID][llvm::Type::HalfTyID]          = &Pointer_Half;
                CastMap[llvm::Type::PointerTyID][llvm::Type::FloatTyID]         = &Pointer_Float;
                CastMap[llvm::Type::PointerTyID][llvm::Type::DoubleTyID]        = &Pointer_Double;
                CastMap[llvm::Type::PointerTyID][llvm::Type::X86_FP80TyID]      = &Pointer_X86_FP80;
                CastMap[llvm::Type::PointerTyID][llvm::Type::FP128TyID]         = &Pointer_FP128;
                CastMap[llvm::Type::PointerTyID][llvm::Type::PPC_FP128TyID]     = &Pointer_PPC_FP128;
                CastMap[llvm::Type::PointerTyID][llvm::Type::LabelTyID]         = &Pointer_Label;
                CastMap[llvm::Type::PointerTyID][llvm::Type::MetadataTyID]      = &Pointer_Metadata;
                CastMap[llvm::Type::PointerTyID][llvm::Type::X86_MMXTyID]       = &Pointer_X86_MMX;
                CastMap[llvm::Type::PointerTyID][llvm::Type::IntegerTyID]       = &Pointer_Integer;
                CastMap[llvm::Type::PointerTyID][llvm::Type::FunctionTyID]      = &Pointer_Function;
                CastMap[llvm::Type::PointerTyID][llvm::Type::StructTyID]        = &Pointer_Struct;
                CastMap[llvm::Type::PointerTyID][llvm::Type::ArrayTyID]         = &Pointer_Array;
                CastMap[llvm::Type::PointerTyID][llvm::Type::PointerTyID]       = &Pointer_Pointer;
                CastMap[llvm::Type::PointerTyID][llvm::Type::VectorTyID]        = &Pointer_Vector;

                CastMap[llvm::Type::VectorTyID][llvm::Type::VoidTyID]           = &Vector_Void;
                CastMap[llvm::Type::VectorTyID][llvm::Type::HalfTyID]           = &Vector_Half;
                CastMap[llvm::Type::VectorTyID][llvm::Type::FloatTyID]          = &Vector_Float;
                CastMap[llvm::Type::VectorTyID][llvm::Type::DoubleTyID]         = &Vector_Double;
                CastMap[llvm::Type::VectorTyID][llvm::Type::X86_FP80TyID]       = &Vector_X86_FP80;
                CastMap[llvm::Type::VectorTyID][llvm::Type::FP128TyID]          = &Vector_FP128;
                CastMap[llvm::Type::VectorTyID][llvm::Type::PPC_FP128TyID]      = &Vector_PPC_FP128;
                CastMap[llvm::Type::VectorTyID][llvm::Type::LabelTyID]          = &Vector_Label;
                CastMap[llvm::Type::VectorTyID][llvm::Type::MetadataTyID]       = &Vector_Metadata;
                CastMap[llvm::Type::VectorTyID][llvm::Type::X86_MMXTyID]        = &Vector_X86_MMX;
                CastMap[llvm::Type::VectorTyID][llvm::Type::IntegerTyID]        = &Vector_Integer;
                CastMap[llvm::Type::VectorTyID][llvm::Type::FunctionTyID]       = &Vector_Function;
                CastMap[llvm::Type::VectorTyID][llvm::Type::StructTyID]         = &Vector_Struct;
                CastMap[llvm::Type::VectorTyID][llvm::Type::ArrayTyID]          = &Vector_Array;
                CastMap[llvm::Type::VectorTyID][llvm::Type::PointerTyID]        = &Vector_Pointer;
                CastMap[llvm::Type::VectorTyID][llvm::Type::VectorTyID]         = &Vector_Vector;
            }
            return CastMap[target][dest];
        }
    };

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
                D( __FUNCTION__
                   << ": expr: op = " << int(op.opcode) << ", "
                   //<< "operand1 = " << operand1 << ", "
                   //<< "operand2 = " << operand2
                   );
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
        D(__FUNCTION__ << ": none");
        return nullptr;
    }

    Value *expr_compiler::operator()(const ast::identifier & id)
    {
        auto & name = id.string;

        //D("identifier: "<<name);

        auto sym = comp->builder->GetInsertBlock()->getValueSymbolTable()->lookup(name);
        if (sym) return sym;
        
        auto gv = comp->module->getGlobalVariable(name);
        if (gv) return gv;

        auto fun = comp->module->getFunction(name);
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
        if (!isa<Function>(operand1)) {
            llvm::errs()
                << "lyre: '" << operand1->getName().str() << "' is not a function"
                << "\n" ;
            return nullptr;
        }

        auto fun = cast<Function>(operand1);
        auto fty = fun->getFunctionType();

        D("calling "<<fun->getName().str()<<", "<<fty->getNumParams());

        std::vector<Value*> args;

        if (operand2->getType()->isMetadataTy()) {
            auto metaArgs = cast<MDNode>(cast<MetadataAsValue>(operand2)->getMetadata());
            auto n = 0;
            for (auto & metaArg : metaArgs->operands()) {
                auto paramType = fty->getParamType(n++);                        DUMP_TY("param-type: ", paramType);
                auto argMetadata = cast<ValueAsMetadata>(metaArg.get());        DUMP_TY("arg-type: ", argMetadata->getValue()->getType());
                auto arg = comp->calling_cast(paramType, argMetadata->getValue());
                args.push_back(arg);
            }
        } else {
            DUMP_TY("param-type: ", fty->getParamType(0));
            DUMP_TY("arg-type: ", operand2->getType());
            args.push_back(comp->calling_cast(fty->getParamType(0), operand2));
        }

        if (!fty->isVarArg() && args.size() != fty->getNumParams()) {
            llvm::errs()
                << "lyre: '" << operand1->getName().str() << "' wrong number of arguments"
                << "\n" ;
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
        auto var = operand1;
        if (isa<Argument>(var)) {
            auto arg = cast<Argument>(var);
            auto varName = arg->getName().str() + ".addr";
            if ((var = arg->getParent()->getValueSymbolTable().lookup(varName)) == nullptr) {
                llvm::errs()
                    << "lyre: argument#" << arg->getArgNo() << " " << arg->getName().str()
                    << " don't have an address"
                    << "\n" ;
                return nullptr;
            }
        }

        auto varTy = var->getType();
        //DUMP_TY("variable-type: ", varTy);

        if (varTy->isPointerTy()) {
            auto varElementTy = varTy->getSequentialElementType();
            auto val = operand2;

            if (varElementTy == comp->variant) {
                val = comp->calling_cast(nullptr, val);

                auto ptr = comp->get_variant_storage(var);

                /**
                 *  Convert the storage pointer for the value type.
                 */
                var = comp->builder->CreatePointerCast(ptr, PointerType::getUnqual(val->getType()));
            } else {
                val = comp->calling_cast(varElementTy, val);
            }

            comp->builder->CreateStore(val, var); // store 'val' to the 'var'
        } else {
            llvm::errs()
                << "lyre: can't set value to a non-pointer value"
                << "\n" ;
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
        /*
        DUMP_TY("binary-operand1: ", operand1->getType());
        DUMP_TY("binary-operand2: ", operand2->getType());
        */

        auto ty1 = operand1->getType();
        auto ty2 = operand2->getType();
        if (ty1 == ty2) {
            if ((ty1 == comp->variant) ||
                (ty1->isPointerTy() && ty1->getSequentialElementType() == comp->variant)) {
                llvm::errs()
                    << "lyre: can't perform binary operation on two variants"
                    << "\n" ;
                return nullptr;
            } else if (ty1->isPointerTy()) {
                operand1 = comp->builder->CreateLoad(operand1);
                operand2 = comp->builder->CreateLoad(operand2);
            }
        } else {
#if 1
            if (ty1->isPointerTy()) {
                if (ty1->getSequentialElementType() == comp->variant) {
                    auto ty = ty2->isPointerTy() ? ty2->getSequentialElementType() : ty2;
                    operand1 = comp->calling_cast(ty, operand1);
                } else {
                    operand1 = comp->builder->CreateLoad(operand1);
                }
            }
            if (ty2->isPointerTy()) {
                if (ty2->getSequentialElementType() == comp->variant) {
                    auto ty = ty1->isPointerTy() ? ty1->getSequentialElementType() : ty1;
                    operand2 = comp->calling_cast(ty, operand2);
                } else {
                    operand2 = comp->builder->CreateLoad(operand2);
                }
            }
#else
            if (ty1->isPointerTy()) operand1 = comp->builder->CreateLoad(operand1);
            if (ty2->isPointerTy()) operand2 = comp->builder->CreateLoad(operand2);

            ty1 = operand1->getType();
            ty2 = operand2->getType();
            if (ty1 == comp->variant) operand1 = comp->calling_cast(ty2, operand1);
            if (ty2 == comp->variant) operand2 = comp->calling_cast(ty1, operand2);
#endif
            // TODO: more conversion here...
        }

        DUMP_TY("binary-operand1: ", operand1->getType());
        DUMP_TY("binary-operand2: ", operand2->getType());

        assert (operand1->getType() == operand2->getType() && "binary operator must have operands of the same type");

        auto binres = comp->builder->CreateBinOp(op, operand1, operand2, "binres");

        //std::clog << "\t"; binres->getType()->dump();

        return binres;
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
            llvm::errs() << "Could not create ExecutionEngine: " << error << "\n";
            return gv;
        }

        std::clog
            << "--------------------------------------\n"
            << "Running: " << start->getName().str() << "\n"
            << "--------------------------------------\n"
            << std::flush
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

    llvm::Value* compiler::get_variant_storage(llvm::Value *value)
    {
        auto valueTy = value->getType();
        assert((valueTy == variant || valueTy->getSequentialElementType() == variant) && "value is not a variant");

        /**
         *  Get pointer to the variant storage.
         *
         *  %type.lyre.variant = type { [8 x i8], i8* }
         */
        auto zero = builder->getInt32(0);
        auto idxs = std::vector<llvm::Value*>{ zero, zero };
        if (valueTy->isPointerTy()) idxs.push_back(zero);
        return builder->CreateGEP(value, idxs);
    }

    llvm::Value* compiler::variant_cast(llvm::Type * destTy, llvm::Value * value)
    {
        assert ((value->getType() == variant || value->getType()->getSequentialElementType() == variant) &&
                "variant casting on non-variant");

        /**
         *  Get pointer to the variant storage.
         *
         *  %type.lyre.variant = type { [8 x i8], i8* }
         */
        auto zero = builder->getInt32(0);
        std::vector<llvm::Value*> idx = { zero, zero };

        /**
         *  If value is of type "%type.lyre.variant*".
         */
        if (value->getType()->isPointerTy())
            idx.push_back(zero);

        auto ptr = builder->CreateGEP(value, idx);

        /*
        DUMP_TY("target-type: ", destTy);
        DUMP_TY("value-type: ", value->getType());
        DUMP_TY("storage-type: ", ptr->getType());
        */

        if (destTy->isPointerTy()) {
            auto destPtrTy = PointerType::getUnqual(destTy);
            return builder->CreatePointerCast(ptr, destTy);
        }

        /**
         *  Convert the storage pointer for the value type.
         */
        auto destPtrTy = PointerType::getUnqual(destTy);
        ptr = builder->CreatePointerCast(ptr, destPtrTy);
        return builder->CreateLoad(ptr);
    }

    llvm::Value* compiler::calling_cast(llvm::Type * destTy, llvm::Value * value)
    {
        if (isa<Argument>(value)) {
            auto arg = cast<Argument>(value);
            auto varName = arg->getName().str() + ".addr";
            if ((value = arg->getParent()->getValueSymbolTable().lookup(varName)) == nullptr) {
                llvm::errs()
                    << "lyre: argument#" << arg->getArgNo() << " " << arg->getName().str()
                    << " don't have an address"
                    << "\n" ;
                return nullptr;
            }
        }

        auto valueTy = value->getType();

        if (destTy == nullptr) {
            if (valueTy->isPointerTy()) {
                return builder->CreateLoad(value);
            }
            return value;
        }

        auto cc = CallingCast::getCallingCaster(destTy->getTypeID(), valueTy->getTypeID());

        //DUMP_TY("target-type: ", destTy);
        //DUMP_TY("value-type: ", valueTy);

        assert(cc && "no calling caster");

        return cc(this, destTy, value);
        //-------------------------------end

        /*
        DUMP_TY("target-type: ", destTy);
        DUMP_TY("value-type: ", valueTy);
        */

        if (valueTy == destTy) return value;

        /**
         *  If the destination type is variant, we need to create a temporary alloca to
         *  store the value.
         */
        if (destTy == variant) {
            auto alloca = builder->CreateAlloca(variant, builder->getInt32(0));

            /**
             *  Get pointer to the variant storage.
             */
            auto zero = builder->getInt32(0);
            std::vector<llvm::Value*> idx = { zero, zero, zero };
            auto ptr = builder->CreateGEP(alloca, idx);

            /**
             *  Convert the storage pointer for the value type.
             */
            auto destTy = PointerType::getUnqual(value->getType());
            ptr = builder->CreatePointerCast(ptr, destTy);

            builder->CreateStore(value, ptr);

            //DUMP_TY("dest: ", destTy);
            
            return builder->CreateLoad(alloca);
        }

        if (valueTy == variant) {
            return variant_cast(destTy, value);
        }

        if (valueTy->isPointerTy()) {
            auto valueElementTy = valueTy->getSequentialElementType();
            if (valueElementTy == variant) return variant_cast(destTy, value);

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
        }

        return value;
    }

    llvm::Type* compiler::find_type(const std::string & name)
    {
        // Also see:
        //      std::vector<StructType *> getIdentifiedStructTypes() const;
        auto structTy = module->getTypeByName("type.lyre." + name);
        if (structTy != nullptr) {
            // DUMP_TY("type: ", structTy);
            return structTy;
        }

        // Searching custom Lyre types:
        structTy = module->getTypeByName("type." + name);
        if (structTy != nullptr) {
            // DUMP_TY("type: ", structTy);
            return structTy;
        }

        // Searching builtin alias:
        auto t = typemap.find(name);
        if (t == typemap.end()) return nullptr;
        return t->second;
    }

    llvm::Value* compiler::compile(const ast::stmts & stmts)
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

        start->setGC("lygc");

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

    llvm::Value* compiler::create_alloca(llvm::Type *Ty, llvm::Value *ArraySize, const std::string &Name)
    {
        auto & entry = builder->GetInsertBlock()->getParent()->getEntryBlock();
        IRBuilder<> allocaBuilder(&entry, entry.begin());
        return allocaBuilder.CreateAlloca(Ty, ArraySize, Name.c_str());
    }

    llvm::Value* compiler::compile_expr(const ast::expr & expr)
    {
        expr_compiler excomp{ this };
        auto value = excomp.compile(expr);
        return value;
    }

    llvm::Value* compiler::operator()(const ast::expr & expr)
    {
        // TODO: accepts invocation only...
        return compile_expr(expr);
    }

    llvm::Value* compiler::operator()(const ast::none &)
    {
        std::clog << "none: " << std::endl;
        return nullptr;
    }

    llvm::Value* compiler::operator()(const ast::decl & decl)
    {
        auto & entry = builder->GetInsertBlock()->getParent()->getEntryBlock();
        IRBuilder<> allocaBuilder(&entry, entry.begin());

        llvm::Value* lastAlloca = nullptr;
        for (auto & sym : decl) {
            /**
             *  The default type is 'variant'.
             */
            auto type = variant;

            //std::clog << __FILE__ << ":" << __LINE__ << ": " << sym.id.string << std::endl;

            if (sym.type) {
                auto typeName = boost::get<ast::identifier>(sym.type).string;
                if ((type = find_type(typeName)) == nullptr) {
                    llvm::errs()
                        << "lyre: decl " << sym.id.string << " as unknown type '" << typeName << "'"
                        << "\n" ;
                    return nullptr;
                }
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

    llvm::Value* compiler::operator()(const ast::proc & proc)
    {
        auto rty = Type::getVoidTy(context);
        if (proc.type) {
            auto id = boost::get<ast::identifier>(proc.type);
            if ((rty = find_type(id.string)) == nullptr) {
                llvm::errs()
                    << "lyre: " << proc.name.string << ": unknown return type '" << id.string << "'"
                    << "\n" ;
                return nullptr;
            }
        }

        std::vector<Type*> params;
        for (auto & param : proc.params) {
            auto type = variant;
            if (param.type) {
                auto & id = boost::get<ast::identifier>(param.type);
                if ((type = find_type(id.string)) == nullptr) {
                    llvm::errs()
                        << "lyre: " << proc.name.string << "used an unknown parameter type '"
                        << id.string << "' referenced by '" << param.name.string << "'"
                        << "\n" ;
                    return nullptr;
                }
            }
            if (type->isStructTy()) {
                params.push_back(PointerType::getUnqual(type));
            } else {
                params.push_back(type);
            }
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

        fun->setGC("lygc");

        auto savedInsertBlock = builder->GetInsertBlock();

        if (nullptr == this->compile_body(fun, proc.block.stmts)) {
            // No function body, remove function.
            fun->eraseFromParent();
            return nullptr;
        }

        builder->SetInsertPoint(savedInsertBlock);
        return fun;
    }

    llvm::Value* compiler::compile_body(llvm::Function * fun, const ast::stmts & stmts)
    {
        auto rty = fun->getReturnType();

        auto entry = BasicBlock::Create(context, "entry", fun);
        builder->SetInsertPoint(entry);

        /**
         *  Create allocas on the frame for arguments. 
         */
        for (auto arg = fun->arg_begin(); arg != fun->arg_end(); ++arg) {
            auto name = arg->getName().str() + ".addr";
            auto argAddr = builder->CreateAlloca(arg->getType(), builder->getInt32(0), name.c_str());
            builder->CreateStore(arg, argAddr);
        }

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

    llvm::Value* compiler::operator()(const ast::type & s)
    {
        std::clog << "type: " << std::endl;
        return nullptr;
    }

    llvm::Value* compiler::operator()(const ast::see & s)
    {
        std::clog << "see: " << std::endl;
        return nullptr;
    }

    llvm::Value* compiler::operator()(const ast::with & s)
    {
        std::clog << "with: " << std::endl;
        return nullptr;
    }

    llvm::Value* compiler::operator()(const ast::speak & s)
    {
        std::clog << "speak: " << std::endl;
        return nullptr;
    }

    llvm::Value* compiler::operator()(const ast::per & s)
    {
        return nullptr;
    }

    llvm::Value* compiler::operator()(const ast::ret & ret)
    {
        auto fun = builder->GetInsertBlock()->getParent();
        auto rty = fun->getReturnType();
        if (rty->isVoidTy()) {
            if (ret.expr) {
                llvm::errs()
                    << "lyre: procedure '" << fun->getName().str() << "' returns 'void' only"
                    << "\n" ;
                return nullptr;
            }
            return builder->CreateRetVoid();
        }

        auto value = compile_expr(ret.expr);
        if (!value) {
            llvm::errs()
                << "lyre: proc " << fun->getName().str() << " must return a value"
                << "\n" ;
            return nullptr;
        }

        value = calling_cast(rty, value);

        // TODO: check value and return type somehow

        return builder->CreateRet(value);
    }
}
