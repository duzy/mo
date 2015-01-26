#proc foo(a) --- ---

#foo(1); # invocation

#->name;
#->name.foo();
#->name.name.foo();

#.name;
#.name.foo();
#.name->name.foo();

#return 1;

decl a = 0 + 1 + 2 + 3;
decl b = 0;

a = 2;
b = 1 + 2;

decl c = a + b + 1;

c = a - b;

c = a * b;

c = a / b;

c = a;

c = b;

# byte (1), int (4), float (4)

proc foo(int a) int:bits(32)
---
   decl a = 0;
   a = (a + 1) * 2;
---

#foo(1); # invocation

decl v int:signed
decl u int:unsigned
decl f float:bits(64)
decl r array:int
decl n array:int(:signed)
