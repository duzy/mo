use test::Module;

say($Module::TestVar);

var $s = "ok\t- 3. \$s is defined in 00.mo";
var $S = "ok\t- 4. \$S is defined in 00.mo";

say($s);
say($S);

Module::Test('test-arg');

var $var = 'test-var-1';
def _var() { 'test-var-2' }
def test($arg) {
    say($arg~' - '~$var);
    say($arg~' - '~_var());
}

test("ok\t- test(...)");
test("ok\t- test(...)");

$var = Module::TestTemplate;
if isnull($var)
    say("fail\t- Module::TestTemplate is null");
end

$var = str Module::TestTemplate;
say($var);
if $var eq 'ok	- 6. $test is defined in test::Module -- "test template"'
    say("ok\t- Module::TestTemplate");
else
    say("fail\t- Module::TestTemplate: $var");
end

$var = new(Module::TestClass);
say($var.test());
