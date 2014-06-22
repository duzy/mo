class XML::World is HLL::World {
    # This is actually as QAST::Block objects.
    has @!DATA_SCOPES;
    has $!ROOT;

    method BUILD(*%opts) {
        @!DATA_SCOPES := nqp::list();
    }

    method push_datascope($/) {
        my $scope := QAST::Block.new(:node($/), :name($/<name>), QAST::Stmts.new());

        if 0 {
        $scope.push(QAST::Op.new(:op('for'),
            QAST::Var.new(:scope('local'), :name('@'), :decl('param'), :slurpy(1)),
            QAST::Block.new(:blocktype('immediate'),
                QAST::Var.new(:name('c'), :scope('local'), :decl('param')),
                QAST::Op.new(:op('call'), QAST::Var.new(:name('c'), :scope('local'))),
            )));
        } else {
        $scope.push(QAST::Op.new(:op('call'),
            QAST::Var.new(:scope('local'), :name('@'), :decl('param'))));
        }

        $!ROOT := $scope unless $!ROOT;
        if +@!DATA_SCOPES {
            $scope<outer> := @!DATA_SCOPES[+@!DATA_SCOPES - 1];

            my %sym := $scope<outer>.symbol($/<name>, :scope('lexical')); # :type('list')
            if %sym<value> {
               %sym<value>.push($scope);
            } else {
               %sym<value> := nqp::list();
               %sym<value>.push($scope);
               #$scope<outer>[0].push(QAST::Op.new(:op('bind'), $var, QAST::WVal.new(%sym)));
               $scope<outer>[0].push(QAST::Op.new(:op('bind'),
                   QAST::Var.new( :name($/<name>), :scope('lexical'), :decl('var') ),
                   QAST::Op.new(:op('list'))));
            }

            $scope<outer>[0].push(QAST::Op.new(:op('callmethod'), :name('push'),
               QAST::Var.new(:name($/<name>), :scope('lexical')), $scope));

            #self.add_object($scope);
            #self.add_root_code_ref($/<name>, $scope);

            #nqp::say($/<name>~': '~%sym<value>);
        }
        @!DATA_SCOPES[+@!DATA_SCOPES] := $scope;
        $scope;
    }

    method pop_datascope() {
        @!DATA_SCOPES.pop();
    }
    
    method current_datascope() {
        @!DATA_SCOPES[+@!DATA_SCOPES - 1];
    }

    method root() {
        $!ROOT;
    }
}
