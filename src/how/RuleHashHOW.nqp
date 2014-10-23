knowhow MO::RuleHashHOW {
    my $type;

    sub method_get($o, $name) {
        my $node := nqp::getattr($o, $type, $name);
        unless nqp::defined($node) {
            $node := MO::FilesystemNodeHOW.open(:path($name));
            nqp::bindattr($o, $type, $name, $node);
        }
        $node
    }

    sub method_link($o, $targets, $prerequisites, $build) {
        $targets := flatten_str_list($targets);
        $prerequisites := flatten_str_list($prerequisites);

        my @prerequisites;
        @prerequisites.push(method_get($o, $_)) for $prerequisites;

        for $targets {
            my $t := method_get($o, $_);
            $t.install_build_code($build);
            MO::FilesystemNodeHOW.add_depends($t, @prerequisites);
        }
    }

    sub flatten_str_list($l) {
        my @a;
        for $l {
            if nqp::isstr($_) {
                @a.push($_)
            } elsif nqp::islist($_) {
                @a.push($_) for flatten_str_list($_);
            } else {
                nqp::die('not a string');
            }
        }
        @a
    }

    method methods() {
        my %methods;
        %methods<get>        := &method_get;
        %methods<link>       := &method_link;
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

    method new_hash($s) {
        my $o := nqp::create(self.type);
        $o
    }

    method name($o) { 'RuleHash' }
}
