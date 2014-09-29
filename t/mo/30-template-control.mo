say("1..1")

template T0
--------
.for ->child
$(.name)
.end
---
end

$v = str T0

if $v eq 'template T0 test test test'
    say("ok\t - $v");
else
    say("fail\t - $v");
end
