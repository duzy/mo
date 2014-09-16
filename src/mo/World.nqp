class MO::World is HLL::World {
    my %builtins;

    has @!scopes; # Hash with QAST::Block

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
        unless +@name { nqp::die("cannot look up empty name"); }

        # If it's a single-part name, look through the lexical scopes.
        if +@name == 1 {
            my $name := @name[0];
            my $i := +@!scopes;
            while 0 < $i {
                $i := $i - 1;
                my %sym := @!scopes[$i]<block>.symbol($name);
                if +%sym {
                    return %sym;
                }
            }

            if nqp::existskey(%builtins, $name) {
                return %builtins{$name};
            }
        }

        nqp::say("variable: "~@name[0]);

        # If it's a multi-part name, see if the containing package
        # is a lexical somewhere. Otherwise we fall back to looking
        # in GLOBALish.
        my $result;
        if +@name >= 2 {
            my $first := @name[0];
            my int $i := +@!scopes;
            while $i > 0 {
                $i := $i - 1;
                my %sym := @!scopes[$i]<block>.symbol($first);
                if +%sym {
                    $result := %sym;
                    @name := nqp::clone(@name);
                    @name.shift();
                    $i := 0;
                }
            }
        }

        # If it has any other parts of the name, we try to chase down the parts.
        if +@name {
            unless nqp::existskey($result, 'value') {
                nqp::die("no compile-time value for symbol " ~ join('::', @name));
            }

            # Try to chase down the parts of the name.
            my $value := $result<value>;

            for @name {
                if nqp::existskey($value.WHO, ~$_) {
                    $value := ($value.WHO){$_};
                } else {
                    nqp::die("no compile-time value for symbol " ~ join('::', @name));
                }
            }

            $result := nqp::hash();
            $result<value> := $value;
        }

        $result;
    }

    method symbol_ast($/, %sym, $name, int $die) {
        if nqp::existskey(%sym, 'ast') {
            %sym<ast>;
        } elsif nqp::existskey(%sym, 'value') {
            QAST::WVal.new( :node($/), :value(%sym<value>) );
        } else {
            my $sigil := nqp::substr($name, 0, 1);
            if %sym<scope> eq 'lexical' && ($sigil eq '$' || $sigil eq '&') {
                QAST::Var.new( :node($/), :name($name), :scope<lexical> );
            } else {
                $die ?? nqp::die("No compile-time value for $name") !! NQPMu
            }
        }
    }

    # Creates a meta-object for a package, adds it to the root objects and
    # stores an event for the action. Returns the created object.
    method pkg_create_mo($/, $how, :$name, :$repr) {
        # Create the meta-object and add to root objects.
        my %args;
        if nqp::defined($name) { %args<name> := $name; }
        if nqp::defined($repr) { %args<repr> := $repr; }

        my $mo := $how.new_type(|%args);
        self.add_object($mo);

        # Result is just the object.
        return $mo;
    }

    # Composes the package, and stores an event for this action.
    method pkg_compose($obj) {
        $obj.HOW.compose($obj);
    }

    method add_builtin_objects() {
        self.add_object($_.value<value>) for %builtins;
    }

    method add_builtin_code($name, $code) {
        my $routine := nqp::create(MO::Routine);
        nqp::bindattr($routine, MO::Routine, '$!code', $code);
        nqp::setcodename($code, $name);
        nqp::setcodeobj($code, $routine);

        my %sym := nqp::hash();
        %sym<value> := $routine;
        %builtins{$name} := %sym;
    }
}

# I/O opcodes (vm/parrot/QAST/Operations.nqp)
MO::World.add_builtin_code('print', -> $s { nqp::print($s) });
MO::World.add_builtin_code('say', -> $s { nqp::say($s) });

# MO::World.add_builtin_code('die',            &nqp::die);
# MO::World.add_builtin_code('say',            &nqp::say);
# MO::World.add_builtin_code('exit',           &nqp::exit);
# MO::World.add_builtin_code('print',          &nqp::print);
# MO::World.add_builtin_code('sleep',          &nqp::sleep);
# MO::World.add_builtin_code('open',           &nqp::open);
# MO::World.add_builtin_code('pipe',           &nqp::openpipe);
# MO::World.add_builtin_code('system',         &nqp::system);
# MO::World.add_builtin_code('shell',          &nqp::shell);
# MO::World.add_builtin_code('execname',       &nqp::execname);
# MO::World.add_builtin_code('env',            &nqp::getenvhash);
# MO::World.add_builtin_code('null',           &nqp::null);
# MO::World.add_builtin_code('isnull',         &nqp::isnull);
