#->name;
#->name.foo();
#->name.name.foo();

#.name;
#.name.foo();
#.name->name.foo();

#return 1;

# scalar: byte (1), int (4), float (4), string
# array, vector, map, type

proc foo(a:int(32)) int:bits(32)
---
   decl a = 0;
   a = (a + 1) * 2;
---

foo(1);
