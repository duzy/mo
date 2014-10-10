say('1..7')

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

def modify($v) {
    $var = $v;
}

if $var eq 'test-var'
    say("ok\t\t- $var eq 'test-var'")
else
    say("xx\t\t- $var eq 'test-var'")
end

modify('abc');
if $var eq 'abc'
    say("ok\t\t- $var eq 'abc'")
else
    say("xx\t\t- $var eq 'abc'")
end

modify('123456');
if $var eq '123456'
    say("ok\t\t- $var eq '123456'")
else
    say("xx\t\t- $var eq '123456'")
end
