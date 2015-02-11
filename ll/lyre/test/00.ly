proc fun(a:int) int
----
    decl v = a + 1;
    a = 1;
    return a;
----

say("fun: %d", fun(2));
