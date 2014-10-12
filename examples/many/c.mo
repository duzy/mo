use many::a 'c.mo';
use many::b 'c.mo';

var $C = 'many::c';

say("ok - $C c.mo");

init {
  say("ok - many::c init: isnull(\$C) = "~isnull($C));
  say("ok - many::c init: \$a::A = $a::A");
  say("ok - many::c init: \$b::B = $b::B");
}

load {
  say("ok - c.load from " ~ @_[0])
}

def SetC($v) { $C = $v }
def SayC() { say("ok - c: $C") }
