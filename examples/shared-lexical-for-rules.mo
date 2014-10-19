def test($target) {
    var $v = "test:$target";
    var $n = 0;

    say($v);

    $target:
    {
        # say("build: $target, $v, $n, "~addr($v)~', '~$_.name());
        say("build: $target, $v, $n, "~$_.name());
        $n = $n + 1;
    }

    if $target eq 'test' {
        ## ISSUE: an recursive call of 'test' shares the same lexical stack?
        ## Because the build code references to the same $target and $v!
        var $t1 = test('test/more1');
        var $t2 = test('test/more2');
        $t1.make();
        $t2.make();
    }

    <"$target">
}

test('test/some').make();
test('test/less').make();
test('test').make();

say('---------------------');

def test2($v) {
    var $s = "test:$v";
    def () { $s }
}
var $f1 = test2(1);
var $f2 = test2(2);
var $f3 = test2(3);
say($f1());
say($f2());
say($f3());

say('---------------------');

def test3($v) {
    var $s = "test:$v";

    var $ret = def () {
        # say("def: $v, $s, "~addr($s));
        say("def: $v, $s");
        $s
    }

    if 1 <= $v && $v <= 3 {
        var $f = test3($s);
        $f(); #say($f());
    }

    $ret
}
$f1 = test3(1);
$f2 = test3(2);
$f3 = test3(3);
$f1(); #say($f1());
$f2(); #say($f2());
$f3(); #say($f3());
