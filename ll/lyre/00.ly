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

proc foo(a:int) int
----
    decl b = 0;
    b = (a + 1) * 2;
    a = b * b;
    return a;
----

say("foo"); #say(foo(1));

decl a = 1 + 2 + 3 + foo(4);

decl v; # variant

return foo(foo(a * 5) * 10);
