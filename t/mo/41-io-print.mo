say('1..1');
var $h = open('test.log', 'w');
$h.print('test');
$h.close;

$h = open('test.log', 'r');
if $h.readline eq 'test'
    say('ok - test');
else
    say('fail - test');
end
$h.close;

