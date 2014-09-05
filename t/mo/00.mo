say('1..3')

$test = fun ($arg) {
    if $arg eq 'test-arg'
        say("ok\t\t- $arg eq 'test-arg'")
    else
        say("fail\t\t- $arg eq 'test-arg'")
    end
}

$test('test-arg')
