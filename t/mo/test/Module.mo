say('1..6');
say("ok\t- 1. test/Module.mo loaded");

def Test($arg) {
    say("ok\t- 5. Test is defined in test::Module");
    if $arg eq 'test-arg'
        say("ok\t- Module::Test: "~$arg);
    else
        say("fail\t- Module::Test: "~$arg);
    end
}

$TestVar = "ok\t- 2. $TestVar is defined in test::Module";
$test = "ok\t- 3. $test is defined in test::Module";
