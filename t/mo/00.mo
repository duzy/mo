say('1..3');

class A
{
    method test1() {
        say('ok - A.test1');
    }

    method test2($arg) {
        say('ok - A.test2('~$arg~')');
    }
}

