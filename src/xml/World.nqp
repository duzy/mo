class XML::World is HLL::World {
    # This is actually as QAST::Block objects.
    has @!NODES;
    has $!ROOT;

    method BUILD(*%opts) {
        @!NODES := nqp::list();
    }

    method push_node($/) {
        my $stmts := QAST::Stmts.new( :node($/) );
        $!ROOT := $stmts unless $!ROOT;
        if +@!NODES {
            $stmts<parent> := @!NODES[+@!NODES - 1];
        }
        @!NODES[+@!NODES] := $stmts;
        $stmts<TAGS> := nqp::hash();
        $stmts<*> := QAST::Var.new( :scope('attribute'), :name('*') );
        $stmts<.*> := QAST::Var.new( :scope('attribute'), :name('.*') );
        $stmts;
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
