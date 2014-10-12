var $A = 'many::a';

say("ok - $A a.mo");

init {
  say("ok - many::a init: isnull(\$A) = "~isnull($A));
}

load {
  say("ok - a.load from " ~ @_[0])
}

def SetA($v) { $A = $v }
def SayA() { say("ok - a: $A") }
