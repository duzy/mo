LYRE_USING_MCJIT := true

ifeq ($(LYRE_USING_MCJIT),true)
  #LLVMLIBS := core jit mcjit native irreader
  LLVMLIBS := core mcjit native
else
  LLVMLIBS := interpreter nativecodegen
endif

$(info LLVMLIBS: $(LLVMLIBS))

LLVM := $(or $(wildcard /open/llvm),$(wildcard ~/tools/ll/llvm))
LLVM_CONFIG := $(LLVM)/Debug+Asserts/bin/llvm-config
LLVM_DIS := $(LLVM)/Debug+Asserts/bin/llvm-dis
LLI := $(LLVM)/Debug+Asserts/bin/lli

CXXFLAGS := \
  -DLYRE_USING_MCJIT=$(LYRE_USING_MCJIT) \
  $(shell $(LLVM_CONFIG) --cxxflags)
LIBS := \
  $(shell $(LLVM_CONFIG) --ldflags --libs $(LLVMLIBS)) \
  -lpthread -ltinfo -ldl -lm -lz
LOADLIBS := 

lyre: main.o compiler.o parse.o
	$(LINK.cc) -o $@ $^ $(LOADLIBS) $(LIBS)

main.o: main.cpp parse.h ast.h compiler.h
compiler.o: compiler.cpp ast.h compiler.h
parse.o: parse.cpp parse.h grammar.h ast.h

parse.o:
	$(CXX) -DLYRE_USING_MCJIT=$(LYRE_USING_MCJIT) -std=c++11 -fPIC -c $< -o $@

%.o: %.cpp
	$(COMPILE.cc) $< -o $@

test: lyre ; @./lyre
lab: lab.ll ; @$(LLI) lab.ll
