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
        $stmts;
    }

    method pop_node() {
        @!NODES.pop();
    }
    
    method current_node() {
        @!NODES[+@!NODES - 1];
    }

    method root() {
        $!ROOT;
    }
}
