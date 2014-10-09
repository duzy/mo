say('1..1');

var $cmd = 'echo';
var $tip = 'ok - shell ran, escape';

lang shell :escape:stdout($out) as run
---------------------------------------
cmd=echo
tip='xx - shell ran, but no escape'
$cmd "$tip"
------------------------------------end

run()
if isnull($out) {
    say('xx - $out is null');
} else {
    say($out);
}
