say(@ARGS[0]~' '~@ARGS[1]);

template cmd
------------
ls -l examples/a.*
---------end
var $h = open(str cmd, 'rp');
$h.encoding('utf8');
say($h.readall());
$h.close();
