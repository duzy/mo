knowhow MO::NodeHOW {
    my $type;

    # '$..'             tag (e.g. XML tag name, <name/>)
    # '$.^'             node parent
    # '$.?'             node class (what kind of node?)
    # '$.*'             all attributes in represented order
    # '$.name'          an attribute ( <tag name="value"/>)
    # '*'               all children (e.g. XML subtags and texts)
    # 'name'            a named child
    #

    sub method_name($node) { nqp::getattr($node, $type, '$..') }
    sub method_type($node) { nqp::getattr($node, $type, '$.?') }
    sub method_attributes($node) { nqp::getattr($node, $type, '$.*') }
    sub method_get($node, $name) { nqp::getattr($node, $type, '$.'~$name) }
    sub method_set($node, $name, $value) { MO::NodeHOW.node_bindattr($node, $name, $value) }
    sub method_count($node, $name = nqp::null()) { +$node.children($name) }
    sub method_parent($node) { nqp::getattr($node, $type, '$.^') }
    sub method_children($node, $name = nqp::null()) {
        nqp::getattr($node, $type, nqp::isnull($name) ?? '*' !! $name)
    }
    sub method_text($node) {
        my $all := nqp::getattr($node, $type, '*');
        my $cache := nqp::list();
        if nqp::defined($all) {
            for $all {
                $cache.push($_) if nqp::isstr($_);
            }
        }
        nqp::join('', $cache)
    }

    sub method_remove($node, $target) {
        my @children := nqp::getattr($node, $type, '*');
        my int $i := 0;
        for @children -> $child {
            if nqp::where($child) == nqp::where($target) {
               # return nqp::splice(@children, [], $i, 1);
               my $a := nqp::splice(@children, [], $i, 1);
               return $a;
            }
            $i := $i + 1;
        }
        0
    }

    sub method_insert($node, $src, $sibling) {
        MO::NodeHOW.node_child($node, $src, $sibling)
    }

    method methods() {
        my %methods;
        %methods<name>       := &method_name;
        %methods<type>       := &method_type;
        %methods<text>       := &method_text;
        %methods<attributes> := &method_attributes;
        %methods<get>        := &method_get;
        %methods<set>        := &method_set;
        %methods<count>      := &method_count;
        %methods<parent>     := &method_parent;
        %methods<children>   := &method_children;
        %methods<insert>     := &method_insert;
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

    method name($o = nqp::null()) { 'Node' }

    # method type_check($o, $t) {
    #     #nqp::say('type_check: '~$t~', '~$type);
    #     #nqp::say('type_check: '~$o.WHAT);
    #     #nqp::say('type_check: '~$t.WHAT);
    #     0;
    # }

    method node_new(:$kind = 'data') {
        my $node := nqp::create($type);
        nqp::bindattr($node, $type, '$.?', $kind);
        $node;
    }

    method node_child($o, $node, $sibling = nqp::null()) {
        my $name := $node.name;
        my @named := nqp::getattr($o, $type, $name);
        my @allch := nqp::getattr($o, $type, '*');
        if nqp::isnull(@named) {
            @named := nqp::list();
            nqp::bindattr($o, $type, $name, @named);
        }
        if nqp::isnull(@allch) {
            @allch := nqp::list();
            nqp::bindattr($o, $type, '*', @allch);
        }
        if nqp::defined($sibling) {
            my int $i := 0;
            for @allch -> $child {
                if nqp::where($child) == nqp::where($sibling) {
                    nqp::splice(@allch, [$node], $i, 0);
                    last;
                }
                $i := $i + 1;
            }
            $i := 0;
            my int $inserted := 0;
            for @named -> $child {
                if nqp::where($child) == nqp::where($sibling) {
                    nqp::splice(@named, [$node], $i, 0);
                    $inserted := 1;
                    last;
                }
                $i := $i + 1;
            }
            nqp::push(@named, $node) unless $inserted;
        } else {
            nqp::push(@allch, $node);
            nqp::push(@named, $node);
        }
        nqp::bindattr($node, $type, '$.^', $o);
    }

    ## Add attribute
    method node_bindattr($o, $n, $v) {
        my $all := nqp::getattr($o, $type, '$.*');
        if nqp::isnull($all) {
            nqp::bindattr($o, $type, '$.*', ($all := nqp::list()));
        }
        nqp::bindattr($o, $type, '$.'~$n, $v);
        nqp::push($all, nqp::list($n, $v));
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

    # method node_keyed_i($node, $key) {
    #     nqp::null();
    # }

    # method node_keyed_s($node, $key) {
    #     nqp::getattr($node, $type, $key);
    # }
}
