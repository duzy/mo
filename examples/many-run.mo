use many 'run.mo';

say('ok - many-run');

say("ok - $many::A");
say("ok - $many::B");
say("ok - $many::C");

many::SayA();
many::SayB();
many::SayC();

$many::A = 'A';
$many::B = 'B';
$many::C = 'C';

many::SayA();
many::SayB();
many::SayC();

many::SetA('aa');
many::SetB('bb');
many::SetC('cc');

many::SayA();
many::SayB();
many::SayC();
say("ok - $many::A ~");
say("ok - $many::B ~");
say("ok - $many::C ~");
