decl v variant;
decl n int;

n = 1;
v = 1;
v = n;

proc fun(a:int) int
----
    return a + 2;
----

say("fun: %d", fun(2));
