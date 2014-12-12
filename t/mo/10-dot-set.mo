say("1..4");

var $v = lang bash
-------------------
echo "ok - bash echo test"
----------------end;

if $v == 0
    say("ok - bash: $v")
else
    say("xx - bash: $v")
end

if .name eq 'test-name-value'
    say('ok - .name = ' ~ .name);
else
    say('xx - .name = ' ~ .name);
end

.set('name', 'name-value-modified');

if .name eq 'name-value-modified'
    say('ok - .name = ' ~ .name);
else
    say('xx - .name = ' ~ .name);
end
