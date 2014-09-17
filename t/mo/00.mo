say('1..4');

use test::Module;

$s = "ok\t- lexical $s";
say($s);

$S = "ok\t- export $S";
say($S);

if $Module::TestVar eq 'test-export-var'
    say("ok\t- $Module::TestVar");
else
    say("fail\t- $Module::TestVar");
end

# Module::Test('test-arg');
