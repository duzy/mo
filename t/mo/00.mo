say('1..2')

$var = 'test-var'

def test($arg) {
    say('var: '~$var);

    if $arg eq 'test-arg'
        say("ok\t\t- $arg eq 'test-arg'")
    else
        say("fail\t\t- $arg eq 'test-arg'")
    end
}

$test = fun ($arg) {
    say('var: '~$var);

    if $arg eq 'test-arg'
        say("ok\t\t- $arg eq 'test-arg'")
    else
        say("fail\t\t- $arg eq 'test-arg'")
    end
}

$test('test-arg')
test('test-arg')
