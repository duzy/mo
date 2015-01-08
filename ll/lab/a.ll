@.str = "this is a global string"

; External declaration of the puts function
declare i32 @puts(i8* nocapture) nounwind

define i32 @main() {
       
       ret 0
}
