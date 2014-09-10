say('1..4')

$var = 'test-var'

def test($arg) {
    if $arg eq 'test-arg'
        say("ok\t\t- $arg eq 'test-arg'")
    else
        say("fail\t\t- $arg eq 'test-arg'")
    end

    if $var eq 'test-var'
        say("ok\t\t- $var eq 'test-var'")
    else
        say("fail\t\t- $var eq 'test-var'")
    end
}

$test = fun ($arg) {
    if $arg eq 'test-arg'
        say("ok\t\t- $arg eq 'test-arg'")
    else
        say("fail\t\t- $arg eq 'test-arg'")
    end

    if $var eq 'test-var'
        say("ok\t\t- $var eq 'test-var'")
    else
        say("fail\t\t- $var eq 'test-var'")
    end
}

$test('test-arg')
test('test-arg')
