LLVM := $(or $(wildcard /open/llvm),$(wildcard ~/tools/ll/llvm))
LLVM_CONFIG := $(LLVM)/Debug+Asserts/bin/llvm-config
CXXFLAGS := -std=c++11 -I$(LLVM)/include
LOADLIBS := $(shell $(LLVM_CONFIG) --ldflags)
LIBS := \
  $(shell $(LLVM_CONFIG) --libs mcjit interpreter nativecodegen) \
  -lpthread -ltinfo -ldl -lm -lz

# -lLLVMX86CodeGen -lLLVMX86Desc -lLLVMX86Info -lLLVMX86AsmPrinter -lLLVMX86Utils -lLLVMSelectionDAG -lLLVMAsmPrinter -lLLVMMCParser -lLLVMInterpreter -lLLVMMCJIT -lLLVMJIT -lLLVMCodeGen -lLLVMObjCARCOpts -lLLVMScalarOpts -lLLVMInstCombine -lLLVMTransformUtils -lLLVMipa -lLLVMAnalysis -lLLVMRuntimeDyld -lLLVMExecutionEngine -lLLVMTarget -lLLVMMC -lLLVMObject -lLLVMCore -lLLVMSupport
#  -lpthread -lffi -ltinfo -ldl -lm

main: main.o compiler.o
	$(LINK.cc) -o $@ $^ $(LOADLIBS) $(LIBS)

%.o: %.cpp
	$(COMPILE.cc) $< -o $@

main.o: main.cpp parser.h ast.h compiler.h
compiler.o: compiler.cpp ast.h compiler.h

test: main ; @./main
