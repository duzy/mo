class Routine {
    has $!do;

    method dispatch($capture) {
        nqp::say("Routine.dispatch");
    }
}

nqp::setinvokespec(Routine, Routine, '$!do', nqp::null());
   
nqp::say('ctx: '~nqp::ctx());
nqp::say('what: '~nqp::what(Routine));
nqp::say('reprname: '~nqp::reprname(nqp::what(Routine)));

sub test_code_1($arg) {
    nqp::say('test_code_1: '~$arg);
}

my $code := &test_code_1;
nqp::say('codecuid: '~nqp::getcodecuid($code));
nqp::say('codename: '~nqp::getcodename($code));

my $routine := nqp::create(Routine);
nqp::bindattr($routine, Routine, '$!do', $code);
nqp::setcodeobj($code, $routine); ## not neccesory for invocation, just binding $code and $routine
$routine('test-routine-arg');

nqp::say('istype: Routine: '~nqp::istype($routine, Routine));
nqp::say('istype: Routine: '~nqp::istype($code, Routine));

nqp::say(nqp::getcodename($code)~': isinvokable: '~nqp::isinvokable($code));
nqp::say(nqp::getcodename($routine)~': isinvokable: '~nqp::isinvokable($routine));

my $codeobj := nqp::getcodeobj($code);
nqp::say('istype: Routine: '~nqp::istype($codeobj, Routine));
nqp::say(nqp::getcodename($codeobj)~': isinvokable: '~nqp::isinvokable($codeobj));

if nqp::eqaddr($codeobj, $routine) {
    nqp::say('eqaddr: true');
} else {
    nqp::die("this shouldn't happen");
}

$codeobj.dispatch(1);
