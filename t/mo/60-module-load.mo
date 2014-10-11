var $s = 'param-1';
var $n = 123;
use test::ModuleLoad 'param-0', 1 :s($s), :n($n)

if isnull(ModuleLoad::Check) {
    say('xx - 6. ModuleLoad::Check is null');
} else {
    ModuleLoad::Check();
}

if isnull($ModuleLoad::Test) {
    say('xx - 7. $ModuleLoad::Test is null');
} elsif $ModuleLoad::Test eq 'test' {
    say('ok - 7. $ModuleLoad::Test = test');
} else {
    say('xx - 7. $ModuleLoad::Test = '~$ModuleLoad::Test);
}
