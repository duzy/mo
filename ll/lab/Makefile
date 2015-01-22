LLVM := $(or $(wildcard /open/llvm),$(wildcard ~/tools/ll/llvm))
LLVM_CONFIG := $(LLVM)/Debug+Asserts/bin/llvm-config
CXXFLAGS := $(shell $(LLVM_CONFIG) --cxxflags) -frtti -fexceptions
LOADLIBS := 
LIBS := $(shell $(LLVM_CONFIG) --ldflags) \
  $(shell $(LLVM_CONFIG) --libs mcjit interpreter nativecodegen) \
  -lpthread -ltinfo -ldl -lm -lz

main: main.o compiler.o
	$(LINK.cc) -o $@ $^ $(LOADLIBS) $(LIBS)

%.o: %.cpp
	$(COMPILE.cc) $< -o $@

main.o: main.cpp parse.h ast.h compiler.h
compiler.o: compiler.cpp ast.h compiler.h
parse.o: parse.cpp parse.h grammar.h ast.h

test: main ; @./main
