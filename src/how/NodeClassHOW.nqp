knowhow NodeClassHOW {
    my %BUILTINS;

    INIT {
        #%BUILTINS<get_string>   := -> $o { nqp::getattr($o, $o, ''); };
        %BUILTINS<name>   := -> $o { nqp::getattr($o, $o, ''); };
        %BUILTINS<text>   := -> $o { nqp::join('', nqp::getattr($o, $o, '*')); };
        %BUILTINS<count>  := -> $o, $n = nqp::null() {
            +nqp::getattr($o, $o, nqp::defined($n) ?? $n !! '*');
        };
        # %BUILTINS<dot>   := -> $o, $name {
        #     nqp::say('dot: '~$name);
        #     ~$name;
        # };
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
                # my $attr := QAST::Var.new( :scope('attribute'), :name($<name>),
                #     $parent<node>, $node_type );
                # $ast.push(QAST::Op.new( :op('ifnull'), $attr,
                #     QAST::Op.new( :op('bind'), $attr, QAST::Op.new( :op('list') ) ),
                # ));
                # $ast.push( QAST::Op.new( :op('callmethod'), :name('push'), $attr, $node ) );

                # my $all := $parent<*>;
                # $ast.push(QAST::Op.new( :op('ifnull'), $all,
                #     QAST::Op.new( :op('bind'), $all, QAST::Op.new( :op('list') ) ),
                # ));
                # $ast.push( QAST::Op.new( :op('callmethod'), :name('push'), $all, $node ) );
        };
        %BUILTINS<~> := -> $o, $text {
            my $all := nqp::getattr($o, $o, '*');
            if nqp::isnull($all) {
                $all := nqp::list();
                nqp::bindattr($o, $o, '*', $all);
            }
            nqp::push($all, $text);
            # my $all := $cur<*>;
            # $ast := QAST::Stmts.new( :node($/),
            #     QAST::Op.new( :op('ifnull'), $all,
            #         QAST::Op.new( :op('bind'), $all, QAST::Op.new( :op('list') ) ),
            #     ),
            #     QAST::Op.new( :op('callmethod'), :name('push'), $all,
            #         QAST::SVal.new( :value(~$/) ),
            #     ),
            # );
        };
        %BUILTINS<.> := -> $o, $n, $v {
            my $all := nqp::getattr($o, $o, '.*');
            if nqp::isnull($all) {
                nqp::bindattr($o, $o, '.*', ($all := nqp::list()));
            }
            nqp::bindattr($o, $o, '.' ~ $n, $v);
            $all.push(nqp::list($n, $v));
                # my $all := $ast<.*>;
                # $ast.push(QAST::Op.new( :op('ifnull'), $all,
                #     QAST::Op.new( :op('bind'), $all, QAST::Op.new( :op('list') ) ),
                # ));
                # for $<attribute> -> $a {
                #     my $val := $a<value>.made;
                #     my $attr := QAST::Var.new( :node($/), :scope('attribute'),
                #         :name('.' ~ $a<name>), $node, $node_type );
                #     $ast.push( QAST::Op.new(:op('bind'), $attr, $val ) ); # repr_bind_attr_obj
                #     $ast.push( QAST::Op.new( :op('callmethod'), :name('push'), $all,
                #         QAST::Op.new(:op('list'), QAST::SVal.new(:value($a<name>)), $attr) ) );
                # }
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
    }

    method name() {
        $!name;
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
        my $attribute := nqp::getattr($obj, $obj, '.'~$name);
        nqp::isnull($attribute) ?? %BUILTINS{$name} !! -> $o { $attribute };
    }
}
