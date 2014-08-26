knowhow MO::NodeClassHOW {
    my $type;

    # ''                tag (e.g. XML tag name, <name/>)
    # '.name'           an attribute ( <tag name="value"/>)
    # 'name'            a named child
    # '*'               all children (e.g. XML subtags and texts)
    # '.*'              all attributes in represented order
    # '?'               node class (what kind of node?)

    method type() {
        unless nqp::defined($type) {
            # my $repr := 'P6opaque';
            # my $metaclass := self.new(:name($name));
            # my $metainfo := nqp::hash();
            # nqp::setwho(nqp::composetype(nqp::newtype($metaclass, $repr), $metainfo), {});

            my $repr := 'HashAttrStore'; # P6opaque
            my $metaclass := nqp::create(self);
            $type := nqp::setwho(nqp::newtype($metaclass, $repr), {});
        }
        $type;
    }

    method name() { 'Node' }

    method type_check($o, $t) {
        #nqp::say('type_check: '~$t~', '~$type);
        #nqp::say('type_check: '~$o.WHAT);
        #nqp::say('type_check: '~$t.WHAT);
        0;
    }

    ##
    ## We're mapping any method to 'getattr' of HashAttrStore.
    method find_method($obj, $name) {
        my $attribute := nqp::getattr($obj, $type, '.'~$name);
        nqp::isnull($attribute) ?? nqp::null() !! -> $o { $attribute };
    }

    method node_new(:$kind = 'data') {
        my $node := nqp::create($type);
        nqp::bindattr($node, $type, '?', $kind);
        $node;
    }

    method node_name($o) { nqp::getattr($o, $type, ''); }
    method node_text($o) { nqp::join('', nqp::getattr($o, $type, '*')); }
    method node_count($o, $n = nqp::null()) { # counting sub nodes (including text)
        +nqp::getattr($o, $type, nqp::defined($n) ?? $n !! '*');
    }

    method node_child($o, $node) {
        my $name := self.node_name($node);
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

    method node_getchildren($o, $n) {
        nqp::getattr($o, $type, $n);
    }

    ## Add attribute
    method node_attr($o, $n, $v) {
        my $all := nqp::getattr($o, $type, '.*');
        if nqp::isnull($all) {
            nqp::bindattr($o, $type, '.*', ($all := nqp::list()));
        }
        nqp::bindattr($o, $type, '.' ~ $n, $v);
        $all.push(nqp::list($n, $v));
    }

    method node_getattr($o, $n) {
        $n := '.'~$n unless $n eq '';
        nqp::getattr($o, $type, $n);
    }

    ## Concat text string
    method node_concat($o, $text) {
        my $all := nqp::getattr($o, $type, '*');
        if nqp::isnull($all) {
            $all := nqp::list();
            nqp::bindattr($o, $type, '*', $all);
        }
        nqp::push($all, $text);
    }

    method node_keyed_i($node, $key) {
        nqp::null();
    }

    method node_keyed_s($node, $key) {
        nqp::getattr($node, $type, $key);
    }
}
