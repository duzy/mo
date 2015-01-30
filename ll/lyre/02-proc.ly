proc foo(a:int) int
----
    decl b = 0;
    b = (a + 1) * 2;
    a = b * b;
    return a;
----

decl a = 1 + 2 + 3 + foo(4);

return foo(foo(a * 5) * 10);
