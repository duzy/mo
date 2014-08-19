class XML::World is HLL::World {
    # This is actually as QAST::Block objects.
    has @!NODES;
    has $!ROOT;

    method BUILD(*%opts) {
        @!NODES := nqp::list();
    }

    method push_node($/) {
        my $nodestub := nqp::hash();
        $!ROOT := $nodestub unless $!ROOT;
        if +@!NODES {
            $nodestub<parent> := @!NODES[+@!NODES - 1];
        }
        @!NODES[+@!NODES] := $nodestub;
        $nodestub<ast> := QAST::Stmts.new( :node($/) );
        $nodestub<*> := QAST::Var.new( :scope('attribute'), :name('*') );
        $nodestub<.*> := QAST::Var.new( :scope('attribute'), :name('.*') );
        $nodestub<TAGS> := nqp::hash();
        $nodestub;
    }

    method pop_node() {
        @!NODES.pop();
    }
    
    method current() {
        my $n := +@!NODES;
        (0 < $n) ?? @!NODES[$n - 1] !! nqp::null();
    }

    method root() {
        $!ROOT;
    }
}
