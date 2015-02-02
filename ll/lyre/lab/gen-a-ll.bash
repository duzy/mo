#!/bin/bash
rm -f a.bc
clang++ -emit-llvm -c a.cc
rm -f a.ll
llvm-dis a.bc
