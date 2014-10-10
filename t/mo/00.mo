var $s = 'param-1';
var $n = 123;
use test::ModuleInit :init($s, 'param-2', $n);
if isnull($ModuleInit::Test) {
    say('xx - 5. $ModuleInit::Test is null');
} elsif $ModuleInit::Test eq 'test' {
    say('ok - 5. $ModuleInit::Test = test');
}
