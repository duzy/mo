knowhow MO::RuleHashHOW {
    my $type;

    sub method_get($node, $name) {
        nqp::getattr($node, $type, $name)
    }

    sub method_set($node, $name, $value) {
        nqp::bindattr($node, $type, $name, $value)
    }

    method methods() {
        my %methods;
        %methods<get>        := &method_get;
        %methods<set>        := &method_set;
        %methods;
    }

    method type() {
        unless nqp::defined($type) {
            my %methods := self.methods();
            my $repr := 'HashAttrStore'; # P6opaque
            my $metaclass := nqp::create(self);
            $type := nqp::setwho(nqp::newtype($metaclass, $repr), {});
            nqp::setmethcache($type, %methods);
            nqp::setmethcacheauth($type, 1);
        }
        $type;
    }

    method name($o) { 'RuleHash' }
}
