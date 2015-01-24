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

a = 2;
