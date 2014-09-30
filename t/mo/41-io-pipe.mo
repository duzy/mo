say('1..1');
#var $h = pipe('echo "ok - pipe"');
var $h = open('echo "ok - pipe"', 'rp');
say($h.readline());
$h.close();
