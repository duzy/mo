say('1..1')

$var = 'test'

$test = fun ($arg) {
    say('var: '~isnull($var));

    if $arg eq 'test-arg'
        say("ok\t\t- $arg eq 'test-arg'")
    else
        say("fail\t\t- $arg eq 'test-arg'")
    end
}

$test('test-arg')
