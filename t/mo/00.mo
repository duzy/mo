say('1..1');

var $cmd = 'echo';
var $tip = 'ok - shell ran, escape';

lang shell :escape:stdout($out) as run
---------------------------------------
cmd=echo
tip='fail - shell ran, but no escape'
$cmd "$tip"
------------------------------------end

run()
say('output: '~(isnull($out) ? '<null>' : $out))
