say('1..1');

var $v = map { "map.$_" } "foo", "bar", "foobar"
if isnull($v) {
   say('xx - 1. $v is null');
} elsif join(',', $v) eq 'map.foo,map.bar,map.foobar' {
   say('ok - 1. $v eq '~join(',', $v));
} else {
   say('xx - 1. $v eq '~join(',', $v));
}
