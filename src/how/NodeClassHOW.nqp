knowhow NodeClassHOW {
    has $!name;
    #has @!attributes;
    has @!children;

    method new_type(:$name) {
        # my $repr := 'P6opaque';
        # my $metaclass := self.new(:name($name));
        # my $metainfo := nqp::hash();
        # nqp::setwho(nqp::composetype(nqp::newtype($metaclass, $repr), $metainfo), {});

        my $repr := 'HashAttrStore'; # P6opaque
        my $metaclass := self.new(:name($name));
        nqp::setwho(nqp::newtype($metaclass, $repr), {});
    }

    method new(:$name) {
        my $obj := nqp::create(self);
        $obj.BUILD(:name($name));
        $obj;
    }

    method BUILD(:$name) {
        $!name := $name;
        #@!attributes := nqp::list();
        @!children := nqp::list();
    }

    method name() {
        $!name;
    }

    method find_method($obj, $name) {
        #nqp::die($!name ~ '.' ~ $name ~ ' is not supported')
        #    unless $name eq 'name';

        #nqp::say('TODO: ' ~ $!name ~ '.' ~ $name);
        #-> $o, $a = nqp::null() { nqp::how($o).name; };

        my $code := -> $o, $a = nqp::null() { $!name ~ '.' ~ $name; };
        if $name eq 'name' {
            $code := -> $o { nqp::getattr($o, $o, ''); }
        } elsif $name eq 'count' {
            $code := -> $o, $n { +nqp::getattr($o, $o, $n); }
        } else {
            nqp::die($!name ~ '.' ~ $name ~ ' is not supported');
        }
        $code;
    }

    # method add_child($obj, $node) {
    #     nqp::push(@!children, $node);
    # }

    # method attributes($obj, :$local = 0) {
    #     @!attributes;
    # }
}
