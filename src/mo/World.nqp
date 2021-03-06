class MO::World is HLL::World {
    my %builtins;
    my %interpreters;

    has @!models;
    has @!scopes; # QAST::Block stack
    has $!fixups; # Fixup tasks in one QAST::Stmts
    has %!fixupPackages; # %!fixupPackages{nqp::where($package)} = name;

    # A fixup list of dynamically compiled code objects.
    #has %!dynamic_codeobjs_to_fix_up;
    #has %!dynamic_codeobj_types;

    method create_data_models() {
        my @files := $*DATAFILES;
        if +@files == 0 {
            my $file := nqp::getlexdyn('$?FILES');
            unless nqp::isnull($file) {
                my int $dot := nqp::rindex($file, '.');
                my str $base := nqp::substr($file, 0, $dot);
                unless $base eq '' {
                    @files.push("$base.xml") if nqp::stat("$base.xml", 0);
                    @files.push("$base.json") if nqp::stat("$base.json", 0);
                }
            }
        }

        my $default_compiler := nqp::getcomp('mo'); #HLL::Compiler.new(); # ;
        my @models;
        for @files {
            my $source := MO::ModuleLoader.load_source($_);
            if / .*\.xml$  / {
                my $lang := %*LANG<XML>;
                my $actions := %*LANG<XML-actions>;
                nqp::die("languge 'xml' not registered for $_") if nqp::isnull($lang);
                my $compiler := nqp::getcomp('xml') // $default_compiler;
                my $code := $compiler.compile($lang.parse($source, :$actions).made, :from<ast>);
                @models.push($code());
            } else {
                nqp::die("unsupported data file $_");
            }
        }

        unless +@models {
            my $type := MO::NodeHOW.type; # ensure the Node type is initialized
            my $node := MO::NodeHOW.node_new();
            @models.push($node);
        }

        @!models := @models;

        #MO::Model.init(@models[0]);
        #self.add_object(MO::Model.get());
        moop.set_root(@models[0]);
    }

    method push_scope($/) {
        my $scope := QAST::Block.new( QAST::Stmts.new(), :node($/) );
        $scope.annotate('outer', @!scopes[+@!scopes - 1]) if +@!scopes;
        @!scopes[+@!scopes] := $scope;
        $scope
    }

    method pop_scope() {
        my $scope := @!scopes.pop();
        $scope
    }

    method current_scope() {
        @!scopes[+@!scopes - 1];
    }

    method get_package($scope?) {
        $scope := self.current_scope unless nqp::defined($scope);
        while $scope {
            my $package := $scope.ann('package');
            return $package if nqp::defined($package);
            $scope := $scope.ann('outer');
        }
        NQPMu
    }

    method get_package_scope($scope?) {
        $scope := self.current_scope unless nqp::defined($scope);
        while $scope {
            my $package := $scope.ann('package');
            return $scope if nqp::defined($package);
            $scope := $scope.ann('outer');
        }
        NQPMu
    }

    # Find the name in the scopes defined so far.
    method symbol_in_scopes($name) {
        my %sym;
        my int $i := +@!scopes;
        while 0 < $i {
            $i := $i - 1;
            %sym := @!scopes[$i].symbol($name);
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

    ## Convert a symbol into an AST node. Names of '$Module:Var' form must be
    ## converted into ['Module', '$Var'] to be converted.
    method symbol_ast($/, @name, int $panic = 1) {
        my $first := @name[0];
        my %sym := self.symbol_in_scopes($first);

        # If it's a single-part name, we look for it in the scopes defined so
        # far and the builtin symbol table.
        if +@name == 1 {
            if $first eq 'GLOBAL' {
                # return QAST::WVal.new( :value($*GLOBALish) );
                return QAST::Op.new( :op<getcurhllsym>, QAST::SVal.new(:value<GLOBAL>) );
            } elsif $first eq 'EXPORT' {
                # return QAST::WVal.new( :value($*EXPORT) );
                return QAST::Op.new( :op<getcurhllsym>, QAST::SVal.new(:value<EXPORT>) );
            } elsif $first eq 'null' {
                return QAST::Op.new( :op<null> );
            }

            return %sym<ast> if nqp::existskey(%sym, 'ast');
            return QAST::WVal.new( :node($/), :value(%sym<value>) )
                if nqp::existskey(%sym, 'value');

            if +%sym {
                if %sym<scope> eq 'package' {
                    my $package := %sym<package>;
                    unless nqp::defined($package) {
                        $/.CURSOR.panic('no associated package by '~nqp::join('::', @name))  if $panic;
                        return NQPMu;
                    }
                    return QAST::Var.new( :scope<associative>,
                        QAST::Op.new( :op<who>, QAST::WVal.new( :value($package) ) ),
                        QAST::SVal.new( :value($first) ) );
                }
                return QAST::Var.new( :node($/), :name($first), :scope(%sym<scope>) );
            } elsif nqp::existskey(%builtins, $first) {
                %sym := %builtins{$first};
                return %sym<ast> if nqp::existskey(%sym, 'ast');
                return QAST::WVal.new( :node($/), :value(%sym<value>) )
                    if nqp::existskey(%sym, 'value');
            } elsif is_sigil(nqp::substr($first, 0, 1)) && nqp::substr($first, 1, 1) eq '.' { # } elsif is_sigil($first[0]) && $first[1] eq '.' {
                my $class := self.get_package;
                my $how := $class.HOW;
                unless nqp::can($how, 'find_attribute') && nqp::can($how, 'add_attribute') {
                    $/.CURSOR.panic($how.name($class)~' has no attributes') if $panic;
                    return NQPMu;
                }

                my $attr := $how.find_attribute($class, $first);
                unless nqp::defined($attr) {
                    $/.CURSOR.panic($how.name($class)~' has no attribute '~$first) if $panic;
                    return NQPMu;
                }
                return QAST::Var.new( :node($/), :name($first), :scope<attribute>,
                    QAST::Var.new( :name<me>, :scope<lexical> ),
                    QAST::WVal.new( :value($class) ) );
            } elsif self.is_export_name($first) {
                return QAST::Var.new( :node($/), :scope<associative>,
                    QAST::Op.new( :op<who>, QAST::WVal.new( :value($*EXPORT) ) ),
                    QAST::SVal.new( :value($first) ) );
            } else {
                # Finally try to lookup the GLOBAL
                my $value := self.value_of(@name, $*GLOBALish);
                return QAST::WVal.new( $value ) if nqp::defined($value);
            }
        }

        # Multi-part name
        elsif +@name >= 2 {
            if 0 < +%sym && nqp::existskey(%builtins, $first) {
                %sym := %builtins{$first};
            }

            my $root := nqp::existskey(%sym, 'value') ?? %sym<value> !! $*GLOBALish;

            @name := nqp::clone(@name);
            my $final_name := @name.pop();
            my $value := self.value_of(@name, $root);
            unless nqp::defined($value) {
                $/.CURSOR.panic('undefined package '~nqp::join('::', @name)~" for $final_name") if $panic;
                return NQPMu;
            }

            if nqp::existskey($value.WHO, $final_name) {
                try { # try solving PTP alias first (introduced by ModuleLoader)
                    my $v := ($value.WHO){$final_name};
                    $value := $v.pkg if nqp::istype($v, MO::PTP);
                }
                my $who := QAST::Op.new( :op<who>, QAST::WVal.new( $value ) );
                return QAST::Var.new( :node($/), :scope<associative>,
                    $who, QAST::SVal.new( :value($final_name) ) );
            }

            @name.push($final_name) if $panic; # restore the @name for correct panic.
        }

        if $panic {
            if is_sigil(nqp::substr(@name[+@name-1], 0, 1)) { # if is_sigil(@name[+@name-1][0]) {
                $/.CURSOR.panic('undefined variable '~nqp::join('::', @name));
            } else {
                $/.CURSOR.panic('undefined symbol '~nqp::join('::', @name));
            }
        }

        NQPMu;
    }

    sub is_sigil($c) { 0 <= nqp::index('$@%&', $c) }

    method is_export_name($name) {
        my int $pos := 0;
        if is_sigil(nqp::substr($name, 0, 1)) { # if is_sigil($name[0]) { # <sigil>
            # $pos := 0 <= nqp::index('.', $name[1]) ?? 2 !! 1; # <twigil>
            $pos := 1; # just skip <sigil> but <twigil>
        }
        nqp::iscclass(nqp::const::CCLASS_UPPERCASE, $name, $pos)
    }

    # Loads a module immediately, and also makes sure we load it
    # during the deserialization.
    method load_module($/, $module_name, @params, $GLOBALish) {
        my @module := nqp::gethllsym('mo', 'ModuleLoader').load_module(
            $module_name, @params, $GLOBALish);

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
                   QAST::SVal.new( :value($module_name) ), QAST::Op.new( :op<list> ),
                ),
            )));
        }

        $/.CURSOR.panic("missing module $module_name") unless +@module;

        my @result;
        if +@module {
            ## add the created object to sc
            my $final := nqp::split('::', $module_name).pop;
            self.add_object($GLOBALish.WHO{$final}) if nqp::defined($GLOBALish);

            # $_[0] is the module name
            # $_[1] is the module context
            for @module {
                @result.push(nqp::ctxlexpad($_[1])) if nqp::defined($_[1]) ;
            }
        }
        @result
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

    # Add currently visible symbols to a QAST block.
    method add_visible_symbols($block, $cur) {
        my %seen;
        my $mu := NQPMu;
        my $outer := $cur;
        while $outer {
            my %symbols := $outer.symtable();
            for %symbols {
                my str $name := $_.key;
                unless %seen{$name} {
                    my %sym   := $_.value;
                    my $value := nqp::existskey(%sym, 'value') || nqp::existskey(%sym, 'lazy_value_from')
                        ?? self.force_value(%sym, $name, 0)
                        !! $mu;
                    if nqp::isnull(nqp::getobjsc($value)) {
                        $value := self.try_add_to_sc($value, $mu);
                    }
                    $block.symbol($name, :scope<lexical>);
                    $block[0].push(QAST::Var.new(
                        :name($name), :scope<lexical>, :decl<var>, :$value
                    ));
                }
                %seen{$name} := 1;
            }
            $outer := $outer.ann('outer');
        }
    }

    method try_add_to_sc($value, $fallback) {
        self.add_object($value);
        CATCH { $value := $fallback; }
        $value
    }

    # Forces a value to be made available.
    method force_value(%sym, $key, int $die) {
        if nqp::existskey(%sym, 'value') {
            %sym<value>
        }
        elsif nqp::existskey(%sym, 'lazy_value_from') {
            %sym<value> := nqp::atkey(nqp::atkey(%sym, 'lazy_value_from'), $key)
        }
        else {
            $die ?? nqp::die("No compile-time value for $key") !! NQPMu
        }
    }

    # method install_variable(:$name) {
    #     my $variable_type := MO::Variable;
    #     my $variable := nqp::create($variable_type);
    #     self.add_object($variable);
    #     $variable;
    # }

    method install_package_symbol($package, $name, $value) {
        self.add_object($value);
        ($package.WHO){$name} := $value;
    }

    # Adds a fixup to install a specified QAST::Block in a package under the
    # specified name.
    method install_package_routine($package, $name, $code_ast) {
        my $code_type := MO::Routine;

        my $root_code_ref_idx;
        my $routine := nqp::create($code_type);

        my $file := nqp::getlexdyn('$?FILES');

        # Install stub that will dynamically compile the code if
        # we ever try to run it during compilation. (similar approach as Perl6)
        my $compiled_trunk;
        my $compiler_thunk := {
            my $wrapper := QAST::Block.new(QAST::Stmts.new(), $code_ast);
            $wrapper.annotate('DYNAMIC_COMPILE_WRAPPER', 1);
            # $wrapper[0].push(QAST::Op.new( :op<bind>,
            #     QAST::Var.new( :scope<lexical>, :name<MODEL>, :decl<var> ),
            #     QAST::WVal.new( :value(MO::Model.get) ),
            # ));

            self.add_visible_symbols($wrapper, $code_ast);

            # restore $?FILES for correct backtrace (e.g. on panics)
            my $?FILES := $file;

            # Compile the code in a new unit.
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
            my $wrapper_id := $wrapper.cuid();
            my @coderefs := $compiler.backend.compunit_coderefs($compiled);
            my int $num_subs := nqp::elems(@coderefs);
            my int $i := 0;
            while $i < $num_subs {
                my $coderef := @coderefs[$i];
                my $subid := nqp::getcodecuid($coderef);
                if $subid eq $wrapper_id {
                    # discard it...
                }
                elsif $subid eq $code_ast.cuid {
                    $compiled_trunk := $coderef;
                    nqp::bindattr($routine, $code_type, '$!code', $coderef);
                    nqp::setcodename($coderef, $code_ast.name);
                    nqp::setcodeobj($coderef, $routine);
                    nqp::markcodestatic($coderef);
                    # self.update_root_code_ref($root_code_ref_idx, $coderef);
                }
                else {
                    # TODO: say('DYNAMICALLY_COMPILED: '~$subid);
                }
                $i := $i + 1;
            }

            # Flag block as dynamically compiled.
            $code_ast.annotate('DYNAMICALLY_COMPILED', 1);
        };

        # This is a coderef to be installed to the code object.
        my $stub := nqp::freshcoderef(sub (*@args, *%named) {
            $compiler_thunk() unless $compiled_trunk;
            $compiled_trunk(|@args, |%named);
        });
        nqp::bindattr($routine, $code_type, '$!code', $stub);
        nqp::setcodename($stub, $code_ast.name);
        nqp::setcodeobj($stub, $routine);

        nqp::markcodestatic($stub);
        nqp::markcodestub($stub);

        # $root_code_ref_idx := self.add_root_code_ref($stub, $code_ast);

        # Add it to the dynamic compilation fixup todo list
        #%!dynamic_codeobjs_to_fix_up{$code_ast.cuid} := $routine;
        #%!dynamic_codeobj_types{$code_ast.cuid} := $code_type;

        # Install compile time code object.
        ($package.WHO){$name} := $routine;
        self.add_object( $routine );

        my $pkg_var_name := self.add_fixup_package($package);
        self.add_fixup(QAST::Op.new( :op<bindkey>,
            QAST::Var.new( :scope<local>, :name($pkg_var_name~'_who') ),
            QAST::SVal.new( :value($name) ),
            QAST::BVal.new( :value($code_ast) )
        ));

        # return the created code object
        $routine
    }

    method install_fixups() {
        self.add_fixup_task(:deserialize_ast($!fixups), :fixup_ast($!fixups));
        $!fixups := nqp::null();
        # %!fixupPackages := nqp::hash();
    }

    method add_fixup_package($package, $name = QAST::Node.unique('temp_pkg')) {
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

    method install_builtin_objects() {
        self.add_builtin_code($_.key, $_.value) for MO::Builtin.names;
        self.add_object($_.value<value>) for %builtins;
    }

    method install_interpreters() {
        my $compiler := nqp::getcomp('mo'); #HLL::Compiler.new();
        for %*LANG {
            my $lang := %*LANG{$_.key};
            my $actions := %*LANG{$_.key~'-actions'};
            #my $key := $_.key;
            #my $h := %*LANG;
            self.add_interpreter($_.key, -> $s, %opts {
                #my $lang := $h{$key};
                #my $actions := $h{$key~'-actions'};
                my $ast := $lang.parse(~$s, :$actions).made;
                $compiler.compile($ast, :from<ast>)();
            });
        }
        self.add_object($_.value) for %interpreters;
    }

    method has_interpreter($name) { nqp::existskey(%interpreters, $name) }
    method interpreter($name) { %interpreters{$name} }

    method new_routine($name, $code) {
        my $routine := nqp::create(MO::Routine);
        nqp::bindattr($routine, MO::Routine, '$!code', $code);
        nqp::setcodename($code, $name);
        nqp::setcodeobj($code, $routine);
        $routine
    }

    method add_builtin_code($name, $code) {
        my $routine := self.new_routine($name, $code);
        my %sym := nqp::hash();
        %sym<value> := $routine;
        %builtins{$name} := %sym;
    }

    method add_interpreter($name, $code) {
        my $routine := nqp::create(MO::Routine);
        nqp::bindattr($routine, MO::Routine, '$!code', $code);
        nqp::setcodename($code, $name);
        nqp::setcodeobj($code, $routine);
        %interpreters{$name} := $routine;
    }
}

MO::World.add_interpreter('shell', -> $s, %opts {
    if nqp::existskey(%opts, 'stdout') {
        my $h := nqp::open($s, 'rp');
        %opts<stdout> := $h.readall;
        $h.close;
    } else {
        # my @cl := [ 'sh', '-c', $s ];
        # nqp::spawn(@cl, nqp::cwd, nqp::getenvhash())
        nqp::shell($s, nqp::cwd, nqp::getenvhash())
    }
});
MO::World.add_interpreter('bash', -> $s, %opts {
    my @cl := [ 'bash', '-c', $s ];
    nqp::spawn(@cl, nqp::cwd, nqp::getenvhash())
});
MO::World.add_interpreter('Python', -> $s, %opts {
    my @cl := [ 'python', '-c', $s ];
    nqp::spawn(@cl, nqp::cwd, nqp::getenvhash())
});
MO::World.add_interpreter('Perl5', -> $s, %opts {
    my @cl := [ 'perl', '-E', $s ];
    nqp::spawn(@cl, nqp::cwd, nqp::getenvhash())
});
MO::World.add_interpreter('Perl6', -> $s, %opts {
    my @cl := [ 'perl6', '-e', $s ];
    nqp::spawn(@cl, nqp::cwd, nqp::getenvhash())
});
