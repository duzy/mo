say('1..13');
say("ok\t- 1. test/Module.mo loaded");

def Test($arg) {
    say("ok\t- 5. Test is defined in test::Module");
    if $arg eq 'test-arg'
        say("ok\t- Module::Test: "~$arg);
    else
        say("fail\t- Module::Test: "~$arg);
    end
}

class TestClass {
    method test() { "ok\t- 7. TestClass is defined in test::Module" }
}

var $TestVar = "ok\t- 2. \$TestVar is defined in test::Module";
var $test = "ok\t- 6. \$test is defined in test::Module";

template TestTemplate
--------
$test -- "test template"
