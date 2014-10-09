say('1..8')

def test1($arg)
    say("ok\t\t- test1")
    return $arg ~ ' ~ test1'
    say("xx\t\t- $arg eq 'test-arg'")
end

def test2($arg) {
    say("ok\t\t- test2")
    return $arg ~ ' ~ test2'
    say("xx\t\t- $arg eq 'test-arg'")
}

var $res1;
var $res2;
var $res3;
var $res4;
var $test;

$res1 = test1('test-arg')
$res2 = test2('test-arg')

$test = def ($arg) {
    say("ok\t\t- test3")
    return $arg ~ ' ~ test3'
    say("xx\t\t- $arg eq 'test-arg'")
}

$res3 = $test('test-arg')
$res4 = def ($arg) {
    say("ok\t\t- test4")
    return $arg ~ ' ~ test4'
    say("xx\t\t- $arg eq 'test-arg'")
}('test-arg')

if $res1 eq 'test-arg'~' ~ test1'
    say("ok\t\t- test1 returns 'test-arg ~ test1'");
else
    say("xx\t\t- test1 returns 'test-arg ~ test1'");
end
if $res2 eq 'test-arg'~' ~ test2'
    say("ok\t\t- test2 returns 'test-arg ~ test2'");
else
    say("xx\t\t- test2 returns 'test-arg ~ test2'");
end
if $res3 eq 'test-arg'~' ~ test3'
    say("ok\t\t- test3 returns 'test-arg ~ test3'");
else
    say("xx\t\t- test3 returns 'test-arg ~ test3'");
end
if $res4 eq 'test-arg'~' ~ test4'
    say("ok\t\t- test4 returns 'test-arg ~ test4'");
else
    say("xx\t\t- test4 returns 'test-arg ~ test4'");
end
