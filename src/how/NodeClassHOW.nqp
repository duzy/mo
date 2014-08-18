knowhow NodeClassHOW {
    my $type;

    method type() {
        unless $type {
            # my $repr := 'P6opaque';
            # my $metaclass := self.new(:name($name));
            # my $metainfo := nqp::hash();
            # nqp::setwho(nqp::composetype(nqp::newtype($metaclass, $repr), $metainfo), {});

            my $repr := 'HashAttrStore'; # P6opaque
            my $metaclass := self.new(:name('Node'));
            $type := nqp::setwho(nqp::newtype($metaclass, $repr), {});
        }
        $type;
    }

    method new(:$name) {
        my $obj := nqp::create(self);
        $obj.BUILD(:name($name));
        $obj;
    }

    method BUILD(:$name) {
    }

    method name($o) { nqp::getattr($o, $type, ''); };
    method text($o) { nqp::join('', nqp::getattr($o, $type, '*')); };
    method count($o, $n = nqp::null()) {
        +nqp::getattr($o, $type, nqp::defined($n) ?? $n !! '*');
    };

    method child($o, $node) {
        my $name := self.name($node);
        my $named := nqp::getattr($o, $type, $name);
        my $all := nqp::getattr($o, $type, '*');
        if nqp::isnull($named) {
                $named := nqp::list();
                nqp::bindattr($o, $type, $name, $named);
        }
        if nqp::isnull($all) {
                $all := nqp::list();
                nqp::bindattr($o, $type, '*', $all);
        }
        nqp::push($named, $node);
        nqp::push($all, $node);
    }

    ## Add attribute
    method attr($o, $n, $v) {
        my $all := nqp::getattr($o, $type, '.*');
        if nqp::isnull($all) {
                nqp::bindattr($o, $type, '.*', ($all := nqp::list()));
        }
        nqp::bindattr($o, $type, '.' ~ $n, $v);
        $all.push(nqp::list($n, $v));
    }

    ## Add attributes (deprecated)
    method _attributes($o, $nv) {
        my $all := nqp::getattr($o, $type, '.*');
        if nqp::isnull($all) {
            nqp::bindattr($o, $type, '.*', ($all := nqp::list()));
        }
        my $i := 0;
        my $elems := nqp::elems($nv);
        while $i < $elems {
            my $n := '.' ~ $nv[$i];
            my $v :=     ~ $nv[$i+1];
            nqp::bindattr($o, $type, $n, $v);
            $all.push(nqp::list($n, $v));
            $i := $i + 2;
        }
    }

    ## Concat text string
    method concat($o, $text) {
            my $all := nqp::getattr($o, $type, '*');
            if nqp::isnull($all) {
                $all := nqp::list();
                nqp::bindattr($o, $type, '*', $all);
            }
            nqp::push($all, $text);
    }

    # method type_check($obj, $o) {
    #     #nqp::say('type_check: '~$obj.WHAT);
    #     #nqp::say('type_check: '~$o.WHAT);
    #     0;
    # }

    ##
    ## We're mapping any method to 'getattr' of HashAttrStore, if no specified method was
    ## found, a BUILTIN mapping will take effect.
    method find_method($obj, $name) {
        my $attribute := nqp::getattr($obj, $type, '.'~$name);
        #nqp::isnull($attribute) ?? %static_methods{$name} !! -> $o { $attribute };
        nqp::isnull($attribute) ?? nqp::null() !! -> $o { $attribute };
    }
}
