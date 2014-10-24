class MO::RuleTarget {
    has $!code;
    has $!node;
    has @!prerequisites;

    method new($name) {
        my $o := nqp::create(MO::RuleTarget);
        $o.BUILD(:$name);
        $o
    }

    method BUILD(:$name) {
        $!node := MO::FilesystemNodeHOW.open(:path($name));
    }

    method name() { $!node.name }
    method path() { $!node.path }
    method exists() { $!node.exists }

    method node() { $!node }
    method prerequisites() { @!prerequisites }

    method bind($code, @prerequisites) {
        $!code := $code;
        @!prerequisites := @prerequisites;
    }

    method make($context?) {
        my int $updated := 0;
        my int $missing := 0;

        my @depends;
        if nqp::defined(@!prerequisites) {
            for @!prerequisites {
                my $pre := $_.node;
                @depends.push($pre);

                my int $made := $_.make($context);
                if $made < 0 {
                    $missing := $missing + $made;
                } elsif $pre.exists() {
                    $made := 1 if $made == 0 && $pre.newer_than($!node);
                    $updated := $updated + $made;
                } else {
                    $missing := $missing - 1;
                    nqp::say('target '~$pre.name~' was not made');
                }
            }
        }

        if $missing == 0 && nqp::isinvokable($!code) {
            if !$!node.exists() || 0 < $updated {
                my $status := $!code($context, $!node, @depends);
                if $!node.exists() {
                    $updated := $updated + 1;
                }
            }
        }

        $missing == 0 ?? $updated !! $missing
    }
}

knowhow MO::RuleHashHOW {
    my $type;

    sub target($o, $name) {
        my $target := nqp::getattr($o, $type, $name);
        unless nqp::defined($target) {
            $target := MO::RuleTarget.new($name);
            nqp::bindattr($o, $type, $name, $target);
        }
        $target
    }

    sub method_rule($o, $name) {
        target($o, $name);
    }

    sub method_link($o, $targets, $prerequisites, $build) {
        $targets := flatten_str_list($targets);
        $prerequisites := flatten_str_list($prerequisites);

        my @prerequisites;
        @prerequisites.push(target($o, $_)) for $prerequisites;

        for $targets {
            target($o, $_).bind($build, @prerequisites);
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
        %methods<rule> := &method_rule;
        %methods<link> := &method_link;
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
