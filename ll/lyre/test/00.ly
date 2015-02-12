proc foo(a:variant) int
----
    return a;
----

decl a = foo(4);

say("foo: %d", a);
