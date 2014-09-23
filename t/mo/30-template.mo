say("1..2")

template T0
--------
ok - template T0
---
end

say(yield T0)

var $v = yield T0
say($v)
