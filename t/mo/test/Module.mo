say("ok\t- test/Module.mo loaded");

def Test($arg) {
    if $arg eq 'test-arg'
        say("ok\t- Module::Test: "~$arg);
    else
        say("fail\t- Module::Test: "~$arg);
    end
}

$TestVar = 'test-export-var';
$test = 'test-var';
