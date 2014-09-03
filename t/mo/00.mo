## * one compile unit defines a module, the file name is the module name
##

say('1..2')

$global = 'test-global';

sub test($arg) {
say($global)
    if $arg eq 'test-arg'
        say("ok\t\t- $arg eq 'test-arg'")
    else
        say("fail\t\t- $arg eq 'test-arg'")
    end

    if $global eq 'test-global'
        say("ok\t\t- $global eq 'test-global'")
    else
        say("fail\t\t- $global eq 'test-global'")
    end
}

test('test-arg')

class Bar {
    method foo($arg) {
        
    }
}
