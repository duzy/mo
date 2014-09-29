say("1..1")

template T0
--------
.for ->child
$(.name)
.end
---
end

var $v = str T0

say($v)
