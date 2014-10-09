say('1..2');
var $res = shell('echo "ok - shell"', '.', null);
if $res == 0
    say('ok - shell: '~$res);
else
    say('xx - shell: '~$res);
end
