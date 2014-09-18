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
            my $first := @name[0];
            my int $i := +@!scopes;
            while 0 < $i {
                $i := $i - 1;
                my %sym := @!scopes[$i]<block>.symbol($first);
                if +%sym {
                    return %sym;
                }
            }

            if nqp::existskey(%builtins, $first) {
                return %builtins{$first};
            }
        }

        # If it's a multi-part name, see if the containing package
        # is a lexical somewhere. Otherwise we fall back to looking
        # in GLOBALish.
        my %result;
        if +@name >= 2 {
            my $first := @name[0];
            my int $i := +@!scopes;
            while $i > 0 {
                $i := $i - 1;
                my %sym := @!scopes[$i]<block>.symbol($first);
                if +%sym {
                    %result := %sym;
                    @name := nqp::clone(@name);
                    @name.shift();
                    $i := 0;
                }
            }
        }

        # If it has any other parts of the name, we try to chase down the parts.
        if +@name {
            my $value := nqp::existskey(%result, 'value') ?? %result<value> !! $*GLOBALish;
            for @name {
                if nqp::existskey($value.WHO, ~$_) {
                    $value := ($value.WHO){$_};
                } else {
                    # nqp::die("no compile-time value for symbol " ~ nqp::join('::', @name));
                    $value := NQPMu;
                    last;
                }
            }

            if nqp::defined($value) {
                %result := nqp::hash();
                %result<value> := $value;
            }
        }

        %result;
    }

    ## Convert a symbol hash returned by find_symbol into a AST node.
    method symbol_ast($/, %sym, $name, int $die) {
        if nqp::existskey(%sym, 'ast') {
            return %sym<ast>;
        }

        if nqp::existskey(%sym, 'value') {
            return QAST::WVal.new( :value(%sym<value>) );

            ## TODO: optimize WVal somehow:
            %sym<usecount> := +%sym<usecount> + 1;
            if +%sym<usecount> == 1 {
                my $scope := @!scopes[0];
                my $block := $scope<block>;
                return QAST::Op.new( :op<bind>, :node($/),
                    QAST::Var.new( :name($name), :scope<lexical>, :decl<var> ),
                    QAST::WVal.new( :value(%sym<value>) ),
                );
            }
            return QAST::Var.new( :name($name), :scope<lexical> );
        }

        my $sigil := nqp::substr($name, 0, 1);
        if %sym<scope> eq 'lexical' && ($sigil eq '$' || $sigil eq '&') {
            return QAST::Var.new( :node($/), :name($name), :scope<lexical> );
        }

        if $die {
            if %sym {
                nqp::die("no compile-time value for $name");
            } else {
                nqp::die("undefined symbol $name");
            }
        }

        NQPMu;
    }

    # Takes a name and compiles it to a lookup for the symbol.
    method symbol_lookup(@name, $/) {
        if +@name == 0 { $/.CURSOR.panic("cannot compile empty name"); }
        if +@name == 1 {
            if @name[0] eq 'GLOBAL' {
                # return QAST::Op.new( :op<getcurhllsym>, QAST::SVal.new(:value<GLOBAL>) );
                return QAST::Var.new( :scope<lexical>, :name<GLOBAL> );
            }
        }
    }

    method isexportname($name) {
        my $s := nqp::substr($name, 0, 1);
        # $s := nqp::substr($name, 1, 1) if $s eq '$' || $s eq '&';
        $s eq nqp::uc($s);
    }

    # Loads a module immediately, and also makes sure we load it
    # during the deserialization.
    method load_module($/, $module_name, $GLOBALish) {
        my $module := nqp::gethllsym('mo', 'ModuleLoader').load_module(
            $module_name, $GLOBALish);

        say("load_module: $module_name, "~$GLOBALish.WHO<Module>.WHO<$TestVar>);

        # Make sure we do the loading during deserialization.
        if self.is_precompilation_mode() {
            self.add_load_dependency_task(:deserialize_ast(QAST::Stmts.new(
                # Uses the NQP module loader to load Perl6::ModuleLoader, which
                # is a normal NQP module.
                QAST::Op.new( :op<loadbytecode>,
                    QAST::VM.new(
                        :parrot(QAST::SVal.new( :value('ModuleLoader.pbc') )),
                        :jvm(QAST::SVal.new( :value('ModuleLoader.class') )),
                        :moar(QAST::SVal.new( :value('ModuleLoader.moarvm') ))
                    )),
                QAST::Op.new( :op<callmethod>, :name<load_module>,
                   QAST::Op.new( :op<gethllsym>,
                       QAST::SVal.new( :value<nqp> ),
                       QAST::SVal.new( :value<ModuleLoader> ),
                   ),
                   QAST::SVal.new( :value<mo::ModuleLoader> ),
                ),

                # Uses mo::ModuleLoader to load the MO module.
                QAST::Op.new( :op<callmethod>, :name<load_module>,
                   QAST::Op.new( :op<getcurhllsym>, QAST::SVal.new( :value<ModuleLoader> ) ),
                   QAST::SVal.new( :value($module_name) ),
                ),
            )));
        }

        $/.CURSOR.panic("missing module $module_name")
            unless nqp::defined($module);

        nqp::ctxlexpad($module);
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
        $mo;
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
