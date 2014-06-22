class MO::World is HLL::World {
    # This is actually as QAST::Block objects.
    has @!DATA_SCOPES;

    method BUILD(*%opts) {
        @!DATA_SCOPES := nqp::list();
        nqp::say('MO::World.BUILD: '~%opts);
    }

    method push_datascope($/) {
        my $scope := QAST::Block.new( QAST::Stmts.new(), :node($/) );
        if +@!DATA_SCOPES {
            $scope<outer> := @!DATA_SCOPES[+@!DATA_SCOPES - 1];
        }
        @!DATA_SCOPES[+@!DATA_SCOPES] := $scope;
        $scope;
    }

    method pop_datascope($/) {
        @!DATA_SCOPES.pop();
    }
    
    method current_datascope() {
        @!DATA_SCOPES[+@!DATA_SCOPES - 1];
    }
}