var $s = 'param-1';
var $n = 123;
use test::ModuleInit :init($s, 'param-2', $n);
if isnull($ModuleInit::Test) {
    say('xx - 4. $ModuleInit::Test is null');
} elsif $ModuleInit::Test eq 'test' {
    say('ok - 4. $ModuleInit::Test = test');
}
