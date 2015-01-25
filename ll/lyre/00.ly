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
