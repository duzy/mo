say("1..1")

template T0
--------
.for ->child
$(.name)
.end
---
end

var $v = str T0
if $v eq "test-child-1\ntest-child-2\n"
    say("ok - template for");
else
    say("xx - $v");
end
