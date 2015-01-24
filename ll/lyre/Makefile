LLVM := $(or $(wildcard /open/llvm),$(wildcard ~/tools/ll/llvm))
LLVM_CONFIG := $(LLVM)/Debug+Asserts/bin/llvm-config
CXXFLAGS := $(shell $(LLVM_CONFIG) --cxxflags)
LOADLIBS := 
LIBS := $(shell $(LLVM_CONFIG) --ldflags) \
  $(shell $(LLVM_CONFIG) --libs mcjit interpreter nativecodegen) \
  -lpthread -ltinfo -ldl -lm -lz

lyre: main.o compiler.o parse.o
	$(LINK.cc) -o $@ $^ $(LOADLIBS) $(LIBS)

main.o: main.cpp parse.h ast.h compiler.h
compiler.o: compiler.cpp ast.h compiler.h
parse.o: parse.cpp parse.h grammar.h ast.h

parse.o:
	$(CXX) -std=c++11 -fPIC -c $< -o $@

%.o: %.cpp
	$(COMPILE.cc) $< -o $@

test: lyre ; @./lyre
