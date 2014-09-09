say('1..1');

$g = 'global';

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
}

test('arg');

say('ok');
