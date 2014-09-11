say('1..9')

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

    def test_nested($arg) {
        if $arg eq 'test-arg-nested'
            say("ok\t\t- $arg eq 'test-arg-nested'")
        else
            say("fail\t\t- $arg eq 'test-arg-nested'")
        end

        if $var eq 'test-var'
            say("ok\t\t- $var eq 'test-var'")
        else
            say("fail\t\t- $var eq 'test-var'")
        end

        def test_nested_nested($arg) {
            if $arg eq 'test-arg-nested-nested'
                say("ok\t\t- $arg eq 'test-arg-nested-nested'")
            else
                say("fail\t\t- $arg eq 'test-arg-nested-nested'")
            end

            if $var eq 'test-var'
                say("ok\t\t- $var eq 'test-var'")
            else
                say("fail\t\t- $var eq 'test-var'")
            end
        }

        test_nested_nested('test-arg-nested-nested')
    }

    test_nested('test-arg-nested')
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

    if $var eq 'test-var'
        say("ok\t\t- $var eq 'test-var'")
    else
        say("fail\t\t- $var eq 'test-var'")
    end
}

$test('test-arg')
test('test-arg')
