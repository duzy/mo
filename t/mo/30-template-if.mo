say("1..1")

template T0
-----------
.if defined(->child[0])
child-0 $(->child[0].name) in $(..)
.else
child-0 missed in $(..)
.end
---
end

var $v = str T0
if $v eq "child-0 test-child-1 in test\n"
    say("ok - template if");
else
    say("fail - $v");
end
