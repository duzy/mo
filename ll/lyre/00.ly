#->name;
#->name.foo();
#->name.name.foo();

#.name;
#.name.foo();
#.name->name.foo();

#return 1;

# scalar: byte (1), int (4), float (4), string
# array, vector, map, type

#type int32 is int:bits(32)
#type uint is int:unsigned(true)

say(1);

proc foo(a:int) int
---
   decl b = 0;
   b = (a + 1) * 2;
   a = b * b;
   #return a;
---

foo(0);

decl v = foo(foo(1));
