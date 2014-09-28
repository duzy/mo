say("1..1")

var $v;

template T0
--------
$(.name)
---
end

$v = with ->child[0] yield T0
if $v eq 'test-child-1'
    say("ok\t - $v");
else
    say("fail\t - $v");
end
