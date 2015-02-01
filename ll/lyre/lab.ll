declare void @printf(i8*, ...)

@foo = constant [7 x i8] c"foobar\00", align 1

define i32 @main() {
  %v = alloca { i8* }
  ; call void @printf([7 x i8] *@foo)
  ret i32 0
}
