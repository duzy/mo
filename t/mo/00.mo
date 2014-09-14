$g = 'global';
$var = 'test-var';

say('$g = '~$g);

def test($a) {
    $v = 'local';

    say('$g: '~isnull($g));
    say('$v: '~isnull($v));

    unless isnull($g)
      say(~$g);
    end
    unless isnull($v)
      say(~$v);
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

test('test-arg')
