say('1..1');

var $cmd = 'echo';
var $tip = 'xx - no escape';

lang shell as run
--------------------------
cmd=echo
tip="ok - shell ran, no escape"
$cmd "$tip"
-----------------------end

run()
