say("1..2")

var $res = system('echo "ok - system"');
if $res == 0
    say("ok - result = $res")
else
    say("fail - result = $res")
end
