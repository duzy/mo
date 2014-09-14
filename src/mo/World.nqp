class MO::World is HLL::World {
    has @!scopes; # QAST::Block

    method push_scope($/) {
        my $scope := nqp::hash();
        $scope<block> := QAST::Block.new( QAST::Stmts.new(), :node($/) );
        $scope<outer> := @!scopes[+@!scopes - 1] if +@!scopes;
        @!scopes[+@!scopes] := $scope;
        $scope;
    }

    method pop_scope() {
        @!scopes.pop();
    }

    method current_scope() {
        @!scopes[+@!scopes - 1];
    }

    method find_symbol(@name) {
        # Make sure it's not an empty name.
        unless +@name { nqp::die("Cannot look up empty name"); }

        # If it's a single-part name, look through the lexical scopes.
        if +@name == 1 {
            my $name := @name[0];
            my $i := +@!scopes;
            while 0 < $i {
                $i := $i - 1;
                my %sym := @!scopes[$i]<block>.symbol($name);
                if %sym {
                    return %sym;
                }
            }
        }

        NQPMu;
    }

    method symbol_ast(%sym, $name, int $die) {
        my $sigil := nqp::substr(~$name, 0, 1);
        if $sigil eq '$' || $sigil eq '&' {
            QAST::Var.new( :name($name), :scope<lexical> );
        } else {
            $die ?? nqp::die("No compile-time value for $name") !! NQPMu
        }
    }
}
