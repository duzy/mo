say('1..4')

var $var = 'test-var'

def test($arg) {
    if $arg eq 'test-arg'
        say("ok\t\t- $arg eq 'test-arg'")
    else
        say("xx\t\t- $arg eq 'test-arg'")
    end

    if $var eq 'test-var'
        say("ok\t\t- $var eq 'test-var'")
    else
        say("xx\t\t- $var eq 'test-var'")
    end
}

var $test = def ($arg) {
    if $arg eq 'test-arg'
        say("ok\t\t- $arg eq 'test-arg'")
    else
        say("xx\t\t- $arg eq 'test-arg'")
    end

    if $var eq 'test-var'
        say("ok\t\t- $var eq 'test-var'")
    else
        say("xx\t\t- $var eq 'test-var'")
    end
}

$test('test-arg')
test('test-arg')
