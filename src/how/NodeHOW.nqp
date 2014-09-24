knowhow MO::NodeHOW {
    my $type;

    # ''                tag (e.g. XML tag name, <name/>)
    # '?'               node class (what kind of node?)
    # '.*'              all attributes in represented order
    # '*'               all children (e.g. XML subtags and texts)
    # '.name'           an attribute ( <tag name="value"/>)
    # 'name'            a named child
    #

    method type() {
        unless nqp::defined($type) {
            my %methods;
            %methods<name> := -> $node { nqp::getattr($node, $type, ''); };
            %methods<type> := -> $node { nqp::getattr($node, $type, '?'); };
            %methods<text> := -> $node {
                nqp::join('', nqp::getattr($node, $type, '*'));
            };
            %methods<attributes> := -> $node {
                nqp::getattr($node, $type, '.*');
            };
            %methods<get> := -> $node, $name {
                nqp::getattr($node, $type, '.'~$name);
            };
            %methods<set> := -> $node, $name, $value {
                MO::NodeHOW.node_bindattr($node, $name, $value);
            };
            %methods<count> := -> $node, $name = nqp::null() {
                +nqp::getattr($node, $type, nqp::isnull($name) ?? '*' !! $name);
            };
            %methods<children> := -> $node, $name = nqp::null() {
                nqp::getattr($node, $type, nqp::isnull($name) ?? '*' !! $name);
            };

            my $repr := 'HashAttrStore'; # P6opaque
            my $metaclass := nqp::create(self);
            $type := nqp::setwho(nqp::newtype($metaclass, $repr), {});
            nqp::setmethcache($type, %methods);
            nqp::setmethcacheauth($type, 1);
        }
        $type;
    }

    method name() { 'Node' }

    # method type_check($o, $t) {
    #     #nqp::say('type_check: '~$t~', '~$type);
    #     #nqp::say('type_check: '~$o.WHAT);
    #     #nqp::say('type_check: '~$t.WHAT);
    #     0;
    # }

    method node_new(:$kind = 'data') {
        my $node := nqp::create($type);
        nqp::bindattr($node, $type, '?', $kind);
        $node;
    }

    method node_child($o, $node) {
        my $name := $node.name;
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
    method node_bindattr($o, $n, $v) {
        my $all := nqp::getattr($o, $type, '.*');
        if nqp::isnull($all) {
            nqp::bindattr($o, $type, '.*', ($all := nqp::list()));
        }
        nqp::bindattr($o, $type, '.' ~ $n, $v);
        $all.push(nqp::list($n, $v));
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
