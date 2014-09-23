say('1..3');

def value($v) {
    say("ok\t1. value("~$v~")");
    $v
}

var $var1 = "ok\t2. test-var-1";
var $var2 = value("test-var-2");

say($var1);
say("ok\t3. "~$var2);
