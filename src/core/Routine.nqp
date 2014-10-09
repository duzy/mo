class MO::Routine {
    has $!code;

    method !set_code($code) {
        $!code := $code;
    }

    method name() {
        nqp::getcodename($!code)
    }
}
nqp::setinvokespec(MO::Routine, MO::Routine, '$!code', nqp::null);
nqp::setboolspec(MO::Routine, 5, nqp::null());
