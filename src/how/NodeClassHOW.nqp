knowhow NodeClassHOW {
    my %BUILTINS;

    INIT {
        %BUILTINS<name>   := -> $o { nqp::getattr($o, $o, ''); };
        %BUILTINS<count>  := -> $o, $n { +nqp::getattr($o, $o, $n); };
    }

    has $!name;
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
        @!children := nqp::list();
    }

    method name() {
        $!name;
    }

    method find_method($obj, $name) {
        #-> $o, $a = nqp::null() { nqp::how($o).name; };

        my $code := %BUILTINS{$name};
        nqp::die($!name ~ '.' ~ $name ~ ' is not supported') unless $code;
        $code;
    }

    # method add_child($obj, $node) {
    #     nqp::push(@!children, $node);
    # }
}
