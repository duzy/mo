say('1..5');

class A
{
    var $okay = 'ok - A.$okay';
    var $.okay = "ok - A.okay";

    method test1() {
        say('ok - A.test1');
    }

    method test2($arg) {
        me.test1();
        say('ok - A.test2('~$arg~')');
        say($.okay);
        say($okay);
    }
}

var $a = new(A);
$a.test1();
$a.test2('test-arg');
