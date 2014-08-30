say('1..1');
#$h = pipe('echo "ok - pipe"');
$h = open('echo "ok - pipe"', 'rp');
say($h.readline);
$h.close;
