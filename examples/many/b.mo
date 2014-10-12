use many::a 'b.mo';

var $B = 'many::b';

say("ok - $B b.mo");

init {
  say("ok - many::b init: isnull(\$B) = "~isnull($B));
  say("ok - many::b init: \$a::A = $a::A");
}

load {
  say("ok - b.load from " ~ @_[0])
}

def SetB($v) { $B = $v }
def SayB() { say("ok - b: $B") }
