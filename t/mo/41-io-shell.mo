say('1..2');
$res = shell('echo "ok - shell"', '.', null);
if $res == 0
    say('ok - shell: '~$res);
else
    say('fail - shell: '~$res);
end
