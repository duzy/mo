say("foobar");

decl n = 1;
say("foobar: %d", n);

decl v variant;
v = 2;
n = v;
say("foobar: %d", n);

decl m = n + v;
say("foobar: %d", m);

decl o = 1 + v;
say("foobar: %d", o);
