say("1..1")

var $v = 'test'

template T0
--------
template T0 $v $($v) ${$v}
---
end

$v = str T0

if $v eq 'template T0 test test test'
    say("ok\t - $v");
else
    say("xx\t - $v");
end
