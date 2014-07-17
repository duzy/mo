knowhow NodeClassHOW {
    my %BUILTINS;

    INIT {
        %BUILTINS<name>   := -> $o { nqp::getattr($o, $o, ''); };
        %BUILTINS<text>   := -> $o { nqp::join('', nqp::getattr($o, $o, '*')); };
        %BUILTINS<count>  := -> $o, $n = nqp::null() {
            +nqp::getattr($o, $o, nqp::defined($n) ?? $n !! '*');
        };
        %BUILTINS<+> := -> $o, $node {
            my $name := $node.name;
            my $named := nqp::getattr($o, $o, $name);
            my $all := nqp::getattr($o, $o, '*');
            if nqp::isnull($named) {
                $named := nqp::list();
                nqp::bindattr($o, $o, $name, $named);
            }
            if nqp::isnull($all) {
                $all := nqp::list();
                nqp::bindattr($o, $o, '*', $all);
            }
            nqp::push($named, $node);
            nqp::push($all, $node);
        };
        %BUILTINS<~> := -> $o, $text {
            my $all := nqp::getattr($o, $o, '*');
            if nqp::isnull($all) {
                $all := nqp::list();
                nqp::bindattr($o, $o, '*', $all);
            }
            nqp::push($all, $text);
        };
        %BUILTINS<.> := -> $o, $n, $v {
            my $all := nqp::getattr($o, $o, '.*');
            if nqp::isnull($all) {
                nqp::bindattr($o, $o, '.*', ($all := nqp::list()));
            }
            nqp::bindattr($o, $o, '.' ~ $n, $v);
            $all.push(nqp::list($n, $v));
        };
        %BUILTINS<..> := -> $o, $nv {
            my $all := nqp::getattr($o, $o, '.*');
            if nqp::isnull($all) {
                nqp::bindattr($o, $o, '.*', ($all := nqp::list()));
            }
            my $i := 0;
            my $elems := nqp::elems($nv);
            while $i < $elems {
                my $n := '.' ~ $nv[$i];
                my $v :=     ~ $nv[$i+1];
                nqp::bindattr($o, $o, $n, $v);
                $all.push(nqp::list($n, $v));
                $i := $i + 2;
            }
        };
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
