class MO::World is HLL::World {
    my %builtins;

    has @!scopes; # Hash with QAST::Block
    has $!fixups; # Fixup tasks in one QAST::Stmts
    has %!fixupPackages; # %!fixupPackages{nqp::where($package)} = name;

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

    # Find the name in the scopes defined so far.
    method symbol_in_scopes($name) {
        my %sym;
        my int $i := +@!scopes;
        while 0 < $i {
            $i := $i - 1;
            %sym := @!scopes[$i]<block>.symbol($name);
            $i := 0 if +%sym;
        }

        # %sym := %builtins{$first}
        #    if !+%sym && nqp::existskey(%builtins, $first);

        %sym;
    }

    method value_of(@name, $value) {
        for @name {
            if nqp::existskey($value.WHO, ~$_) {
                $value := ($value.WHO){$_};
            } else {
                $value := NQPMu;
                last;
            }
        }
        $value;
    }

    # method find_symbol(@name) {
    #     # Make sure it's not an empty name.
    #     unless +@name { nqp::die("cannot look up empty name"); }

    #     # If it's a single-part name, look through the lexical scopes.
    #     if +@name == 1 {
    #         my $first := @name[0];
    #         my %sym := self.symbol_in_scopes($first);
    #         return %sym if +%sym;

    #         if nqp::existskey(%builtins, $first) {
    #             return %builtins{$first};
    #         }
    #     }

    #     # If it's a multi-part name, see if the containing package
    #     # is a lexical somewhere. Otherwise we fall back to looking
    #     # in GLOBALish.
    #     my %result;
    #     if +@name >= 2 {
    #         my $first := @name[0];
    #         my %sym := self.symbol_in_scopes($first);
    #         if +%sym {
    #             %result := %sym;
    #             @name := nqp::clone(@name);
    #             @name.shift();
    #         }
    #     }

    #     # If it has any other parts of the name, we try to chase down the parts.
    #     if +@name {
    #         my $value := self.value_of(@name, nqp::existskey(%result, 'value') ?? %result<value> !! $*GLOBALish);
    #         if nqp::defined($value) {
    #             %result := nqp::hash();
    #             %result<value> := $value;
    #         }
    #     }

    #     %result;
    # }

    ## Convert a symbol into a AST node.
    ## NOTE: Name of '$Module:Var' must be converted into ['Module', '$Var'].
    method symbol_ast($/, @name, int $panic = 1) {
        my $name := @name[0];
        my %sym := self.symbol_in_scopes($name);
        my $value;

        # If it's a single-part name, we look for it in the scopes defined so
        # far and the builtin symbol table.
        if +@name == 1 {
            if nqp::existskey(%sym, 'ast') {
                return %sym<ast>;
            }

            if nqp::existskey(%sym, 'value') {
                return QAST::WVal.new( :node($/), :value(%sym<value>) );
            }

            if +%sym {
                return QAST::Var.new( :node($/), :name($name), :scope(%sym<scope>) );
            } elsif nqp::existskey(%builtins, $name) {
                %sym := %builtins{$name};
                return %sym<ast> if nqp::existskey(%sym, 'ast');
                return QAST::WVal.new( :node($/), :value(%sym<value>) )
                    if nqp::existskey(%sym, 'value');
            } else {
                # Finally try to lookup the GLOBAL
                $value := self.value_of(@name, $*GLOBALish);
            }
        }

        # Multi-part name
        elsif +@name >= 2 {
            if !+%sym && nqp::existskey(%builtins, $name) {
                %sym := %builtins{$name};
            }

            my $root := nqp::existskey(%sym, 'value') ?? %sym<value> !! $*GLOBALish;

            @name := nqp::clone(@name);
            $name := @name.pop(); # reset the final name
            $value := self.value_of(@name, $root);
        }

        if nqp::defined($value) {
            my $who := QAST::Op.new( :op<who>, QAST::WVal.new( $value ) );
            return QAST::Var.new( :node($/), :scope<associative>,
                $who, QAST::SVal.new( :value($name) ) );
        }

        $/.CURSOR.panic('undefined symbol '~nqp::join('::', @name)) if $panic;

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

    method is_export_name($name) {
        my $s := nqp::substr($name, 0, 1);
        # $s := nqp::substr($name, 1, 1) if $s eq '$' || $s eq '&';
        $s eq nqp::uc($s);
    }

    # Loads a module immediately, and also makes sure we load it
    # during the deserialization.
    method load_module($/, $module_name, $GLOBALish) {
        my $module := nqp::gethllsym('mo', 'ModuleLoader').load_module(
            $module_name, $GLOBALish);

        # say("load_module: $module_name, "~$GLOBALish.WHO<Module>.WHO<$TestVar>);
        # say("$module_name: "~$_.key) for $GLOBALish.WHO;
        # say("$module_name: Module: "~$_.key) for $GLOBALish.WHO<Module>.WHO;

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

    # Adds a fixup to install a specified QAST::Block in a package under the
    # specified name.
    method install_package_routine($package, $name, $block_ast) {
        my $code_type := MO::Routine;

        # Install stub that will dynamically compile the code if
        # we ever try to run it during compilation. (similar approach as Perl6)
        my $precomp;
        my $compiler_thunk := {
            # Fix up GLOBAL.
            # nqp::bindhllsym('mo', 'GLOBAL', $*GLOBALish);

            my $wrapper := QAST::Block.new(QAST::Stmts.new(), $block_ast);
            $wrapper.annotate('DYNAMIC_COMPILE_WRAPPER', 1);

            # Compile the block.
            my $compunit := QAST::CompUnit.new(
                :hll('mo'),
                :sc(self.sc()),
                :compilation_mode(0),
                $wrapper
            );
            my $compiler := nqp::getcomp('mo');
            my $compiled := $compiler.compile( $compunit,
                :from<ast>, :compunit_ok(1), :lineposcache($*LINEPOSCACHE) );
            my $mainline := $compiler.backend.compunit_mainline($compiled);
            $mainline();

            # Fix up Code object associations (including nested blocks).
            my @coderefs := $compiler.backend.compunit_coderefs($compiled);
            my int $num_subs := nqp::elems(@coderefs);
            my int $i := 0;
            while $i < $num_subs {
                my $coderef := @coderefs[$i];
                my $subid := nqp::getcodecuid($coderef);
                if $subid eq $block_ast.cuid {
                    $precomp := $coderef;
                }
                $i := $i + 1;
    say(''~$name~', '~$subid);
            }

            # Flag block as dynamically compiled.
            $block_ast.annotate('DYNAMICALLY_COMPILED', 1);
        };

        # This is a coderef to be installed to the code object.
        my $stub := nqp::freshcoderef(sub (*@args, *%named) {
            $compiler_thunk() unless $precomp;
            $precomp(|@args, |%named);
        });
        my $routine := nqp::create($code_type);
        nqp::bindattr($routine, $code_type, '$!code', $stub);
        nqp::setcodeobj($stub, $routine);
        nqp::setcodename($stub, $block_ast.name);

        nqp::markcodestatic($stub);
        nqp::markcodestub($stub);

        # Install compile time code object.
        ($package.WHO){$name} := $routine;
        self.add_object( $routine );

        my $pkg_var_name := self.add_fixup_package($package);
        self.add_fixup(QAST::Op.new( :op<bindkey>,
            QAST::Var.new( :scope<local>, :name($pkg_var_name~'_who') ),
            QAST::SVal.new( :value(~$name) ),
            QAST::BVal.new( :value($block_ast) )
        ));
    }

    method install_fixups() {
        self.add_fixup_task(:deserialize_ast($!fixups), :fixup_ast($!fixups));
        $!fixups := nqp::null();
        # %!fixupPackages := nqp::hash();
    }

    method add_fixup_package($package, :$name = QAST::Node.unique('temp_pkg')) {
        my $pkg_var_name := %!fixupPackages{nqp::where($package)};
        unless $pkg_var_name {
            %!fixupPackages{nqp::where($package)} := $pkg_var_name := $name;
            self.add_fixup(QAST::Op.new( :op<bind>,
                QAST::Var.new( :scope<local>, :decl<var>, :name($pkg_var_name) ),
                QAST::WVal.new( :value($package) ),
            ));
            self.add_fixup(QAST::Op.new( :op<bind>,
                QAST::Var.new( :scope<local>, :decl<var>, :name($pkg_var_name~'_who') ),
                QAST::Op.new( :op<who>, QAST::Var.new( :scope<local>, :name($pkg_var_name) ) ),
            ));
        }
        $pkg_var_name;
    }

    method add_fixup($fixup) {
        $!fixups := QAST::Stmts.new() unless nqp::defined($!fixups);
        $!fixups.push($fixup);
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
MO::World.add_builtin_code('die', -> $s { nqp::die($s) });
MO::World.add_builtin_code('open', -> $s, $m { nqp::open($s, $m) });

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
