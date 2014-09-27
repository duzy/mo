say('1..3');

class A
{
    $static_var = 123;
    $.attribute = 123;

    method test1() {
        say('ok - A.test1 - ' ~ $static_var);
    }

    method test2($arg) {
        me.test1();
        say('ok - A.test2('~$arg~') - '~$.attribute);
    }
}

var $a = new(A);
$a.test1;
$a.test2('test-arg');
