set(LLVM_LINK_COMPONENTS
  BitWriter
  Core
  ExecutionEngine
  MC
  Support
  nativecodegen
  )

add_llvm_project(Foo
  a.cpp
  )
