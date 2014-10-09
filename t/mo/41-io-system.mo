say("1..2")

var $res = system('echo "ok - system"');
if $res == 0
    say("ok - result = $res")
else
    say("xx - result = $res")
end
