say("1..2")

template T1
-----------
.if defined(->child[0])
child-0 $(->child[0].name) in $(..)
.else
child-0 missed in $(..)
.end
---
end

var $v1 = str T1
if $v1 eq "child-0 test-child-1 in test\n"
    say("ok - template if");
else
    say("fail - $v1");
end

template T2
-----------
.if defined(->child[1])
child-0 $(->child[1].name) in $(..)
.else
child-0 missed in $(..)
.end
---
end

var $v2 = str T2
if $v2 eq "child-0 test-child-2 in test\n"
    say("ok - template if");
else
    say("fail - $v2");
end
