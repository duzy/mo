use test::Module;

say($Module::TestVar);

var $s = "ok\t- 3. $s is defined in 00.mo";
var $S = "ok\t- 4. $S is defined in 00.mo";

say($s);
say($S);

Module::Test('test-arg');

var $var = 'test-var-1';
say("ok\t- "~$var);

def _var() { 'test-var-2' }
def test($arg) {
    say($arg~' - '~$var);
    say($arg~' - '~_var());
}

test("ok\t- test(...)");
test("ok\t- test(...)");
