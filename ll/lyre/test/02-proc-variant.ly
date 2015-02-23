# Returns 'void'
proc foo1(a:int)
----
    say("foo1:void: %d", a);
----

# Returns an 'int'
proc foo2(a:int)
----
    say("foo2:<int>: %d", a);
    return a + 1;
----

# Declared as 'variant' explicitly and only returns a 'variant'
proc foo3(a:int) variant
----
    decl v variant
    v = a;
    return v;
----

foo1(1);

say("foo2: %d", foo2(1));

decl v = foo3(1);
decl n int = v;
say("foo3: %d", n);
