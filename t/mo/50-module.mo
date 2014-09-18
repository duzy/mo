use test::Module;

say($Module::TestVar);

$s = "ok\t- 3. $s is defined in 00.mo";
$S = "ok\t- 4. $S is defined in 00.mo";

say($s);
say($S);

Module::Test('test-arg');
