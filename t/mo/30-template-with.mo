say("1..3")

var $v;

template T0
--------
$(.name)
---
end

$v = str T0
if $v eq 'test-name-value'
    say("ok\t - $v");
else
    say("fail\t - $v");
end

$v = str T0 with ->child[0]
if $v eq 'test-child-1'
    say("ok\t - $v");
else
    say("fail\t - $v");
end

$v = str T0 with ->child[1]
if $v eq 'test-child-2'
    say("ok\t - $v");
else
    say("fail\t - $v");
end
