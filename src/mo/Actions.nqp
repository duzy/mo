class MO::Actions is HLL::Actions {
    my sub pop_newscope($/) {
        my $scope := $*W.pop_scope();
        $scope.push( $<newscope>.made );
        $scope.node( $/ );
        $scope
    }

    my sub fixup_block_variables($block, $count) {
        $block[0].unshift( QAST::Op.new( :op<bind>,
            QAST::Var.new( :scope<lexical>, :decl<var>, :name<MODEL> ),
            QAST::WVal.new( :value(MO::Model.get) ),
        ) );
    }

    my sub fixup_variables($node) {
        my int $count := 0;
        if nqp::istype($node, QAST::Var) {
            $count := 1 if $node.name eq 'MODEL';
        } elsif nqp::can($node, 'list') {
            $count := $count + fixup_variables($_) for $node.list;
            if nqp::istype($node, QAST::Block) && nqp::where($node) != nqp::where($*INIT) {
                fixup_block_variables($node, $count) if 0 < $count;
                $count := 0; # reset counter to discard in outer 
            }
        }
        $count
    }

    method term:sym<value>($/)    { make $<value>.made; $/.prune; }
    method term:sym<variable>($/) { make $<variable>.made; $/.prune; }
    method term:sym<name>($/) {
        my @name := nqp::split('::', ~$<name>);
        my $ast := $*W.symbol_ast($/, @name, 0);
        unless $ast {
            $ast := self.'select:sym<name>'($/);
            $ast.push( QAST::Var.new( :name<$_>, :scope<lexical> ) );
        }
        make $ast;
        $/.prune;
    }

    method term:sym«.»($/) {
        my $node := QAST::Var.new( :name<$_>, :scope<lexical> );
        my $ast;
        if $<query> {
            $ast := QAST::Op.new( :op<can>, $node, QAST::SVal.new(:value(~$<name>)) );
        } elsif $<args> {
            $ast := $<args>.made;
            $ast.op('callmethod');
            $ast.name(~$<name>);
            $ast.unshift($node);
        } elsif $<selector> {
            $ast := $<selector>.made;
            $ast.push($node);
        } else {
            $/.CURSOR.panic('confused');
        }
        make $ast;
        $/.prune;
    }

    method term:sym«->»($/) {
        my $sel := $<selector>;
        my $ast := $sel.made;
        $ast.push( QAST::Var.new( :name<$_>, :scope<lexical> ) );

        ## Chain all selectors
        $sel := $sel<selector>;
        while $sel {
            my $nxt := $sel.made;
            $nxt.push($ast);
            $ast := $nxt;
            $sel := $sel<selector>;
        }

        make $ast;
        $/.prune;
    }

    method term:sym<def>($/) {
        my $scope := $*W.pop_scope();
        $scope[0].push( wrap_return_handler($scope, $<statements>.made) );
        make QAST::Op.new( :node($/), :op<takeclosure>, $scope );
        $/.prune;
    }

    method term:sym<return>($/) {
        my $scope := $*W.current_scope;
        my $ast := QAST::Op.new( :node($/), :op<call>, :name<RETURN> );
        my $returns := $scope.ann('returns') // nqp::list();
        $returns.push( $ast );
        $scope.annotate('returns', $returns);
        if $<EXPR> {
            $ast.push($<EXPR>.made);
        } else {
            # $ast[0].push(QAST::WVal.new( :value($*W.find_sym(['NQPMu'])) ));
        }
        make $ast;
        $/.prune;
    }

    method term:sym<str>($/) {
        my $template := $*W.symbol_ast($/, nqp::split('::', ~$<name>), 1);
        my $call := QAST::Op.new( :node($/), :op<callmethod>, :name<!str>, $template );

        if $<EXPR> {
            $call.push( $<EXPR>.made );
        } else {
            my $node := $*W.symbol_ast($/, [ '$_' ], 1);
            $call.push( $node );
        }

        make $call;
        $/.prune;
    }

    method term:sym<any>($/) { make $<any>.made; }
    method term:sym<many>($/) { make $<many>.made; }

    method circumfix:sym<( )>($/) {
        make $<EXPR>.made;
        #$/.prune;
    }

    method circumfix:sym<| |>($/) {
        make QAST::Op.new( :op<abs>, $<EXPR>.made );
        #$/.prune;
    }

    method circumfix:sym«< >»($/) {
        make QAST::Op.new( :op<callmethod>, :name<get>,
            QAST::WVal.new( :value(MO::FilesystemNodeHOW) ), $<EXPR>.made );
        #$/.prune;
    }

    method postcircumfix:sym<( )>($/) {
        make $<arglist>.made;
        #$/.prune;
    }

    method postcircumfix:sym<[ ]>($/) {
        make QAST::Var.new( :scope('positional'), $<EXPR>.made );
        #$/.prune;
    }

    method postcircumfix:sym<{ }>($/) {
        make QAST::Var.new( :scope('associative'), $<EXPR>.made );
        #$/.prune;
    }

    method postcircumfix:sym<ang>($/) {
        make QAST::Var.new( :scope('associative'), $<quote_EXPR>.made );
        #$/.prune;
    }

    method postfix:sym«.»($/) {
        my $ast;
        if $<query> {
            $ast := QAST::Op.new( :op<can>, QAST::SVal.new(:value(~$<name>)) );
        } elsif $<args> {
            $ast := $<args>.made;
            $ast.op('callmethod');
            $ast.name(~$<name>);
        } else {
            $ast := QAST::Op.new( :node($/), :op<dot_name>,
                QAST::Var.new( :scope<lexical>, :name<MODEL> ),
                QAST::SVal.new( :value(~$<name>) ) );
        }
        make $ast;
    }

    method postfix:sym«->»($/) {
        #say('postfix:sym«->»: '~$/);
        make QAST::Op.new( :node($/), :op<select_name>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ),
            QAST::SVal.new( :value(~$<name>) ) );
    }

    method value:sym<quote>($/) { make $<quote>.made; }
    method value:sym<number>($/) { make $<number>.made; }

    method quote:sym<'>($/) { make $<quote_EXPR>.made; } #'
    method quote:sym<">($/) { make $<quote_EXPR>.made; } #"

    method quote_escape:sym<{ }>($/) {
        make QAST::Op.new( :op<stringify>, $<block>.made, :node($/) );
    }
    method quote_escape:sym<$>($/) { make $<variable>.made; }
    method quote_escape:sym<esc>($/) { make "\c[27]"; }

    method number($/) {
        my $value := $<dec_number> ?? $<dec_number>.made !! $<integer>.made;
        if ~$<sign> eq '-' { $value := -$value; }
        make $<dec_number> ??
            QAST::NVal.new( :value($value) ) !!
            QAST::IVal.new( :value($value) );
    }

    method variable($/) {
        my @name := nqp::split('::', ~$<name>);
        my $final_name := @name.pop;
        my $name := ~$<sigil> ~$<twigil> ~ $final_name;
        @name.push($name);

        my $ast := $*W.symbol_ast($/, @name, 0);
        if $ast {
            make $ast;
        } elsif +@name == 1 && $*W.is_export_name($final_name) {
            make QAST::Var.new( :node($/), :scope<associative>,
                QAST::Var.new( :name<EXPORT.WHO>, :scope<lexical> ),
                QAST::SVal.new( :value($name) ) );
        } elsif $*IN_DECL eq 'var' {
            # null, nothing made
        } elsif $*IN_DECL eq 'member' {
            # null, nothing made
        } elsif $*IN_DECL eq 'lang' {
            # null, nothing made
        } elsif ~$<twigil> eq '.' {
            my $class := $*W.get_package;
            my $how := $class.HOW;
            unless nqp::can($how, 'find_attribute') && nqp::can($how, 'add_attribute') {
                $/.CURSOR.panic($how.name($class)~' cannot have attributes');
            }

            my $attr := $how.find_attribute($class, $name);
            unless nqp::defined($attr) {
                $/.CURSOR.panic($how.name($class)~' has no attribute '~$name);
            }
            make QAST::Var.new( :node($/), :name($name), :scope<attribute>,
                QAST::Var.new( :name<me>, :scope<lexical> ),
                QAST::WVal.new( :value($class) ),
            );
        } else {
            $/.CURSOR.panic("undeclared variable "~$/);
        }
    }

    method initializer($/) {
        make $<EXPR>.made;
        $/.prune;
    }

    method args($/) { make $<arglist>.made; }
    method arglist($/) {
        my $ast := QAST::Op.new( :op<call>, :node($/) );
        if $<EXPR> {
            my $expr := $<EXPR>.made;
            if nqp::istype($expr, QAST::Op) && $expr.name eq '&infix:<,>' && !$expr.named {
                for $expr.list { $ast.push($_); }
            }
            else { $ast.push($expr); }
        }
        my $i := 0;
        my $n := +$ast.list;
        while $i < $n {
            if nqp::istype($ast[$i], QAST::Op) && $ast[$i].name eq '&prefix:<|>' {
                $ast[$i] := $ast[$i][0];
                $ast[$i].flat(1);
                $ast[$i].named(1) if nqp::istype($ast[$i], QAST::Var)
                    && nqp::substr($ast[$i].name, 0, 1) eq '%';
            }
            $i++;
        }
        make $ast;
    }

    method newscope($/) {
        make $<statements>.made;
    }

    my sub wrap_return_handler($scope, $statements) {
        if +$scope.ann('returns') {
            QAST::Op.new( :op<lexotic>, :name<RETURN>, $statements );
        } else {
            $statements;
        }
    }

    method selector:sym«:»($/) {
        my $namespace := QAST::SVal.new( :value(~$<namespace>) );
        my $meth := 'select_namespace';
        $meth := $meth ~ '_query' if $<query>;
        make QAST::Op.new( :node($/), :op<callmethod>, :name($meth),
            QAST::Var.new( :scope<lexical>, :name<MODEL> ), $namespace );
    }

    method selector:sym«.»($/) {
        my $name := QAST::SVal.new( :value(~$<name>) );
        make QAST::Op.new( :node($/), :op<callmethod>, :name<dot>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ), $name );
    }

    method selector:sym«..»($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<dotdot>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ) );
    }

    method selector:sym«->»($/) {
        make $<select>.made;
    }

    method selector:sym<[ ]>($/) {
        my $expr := $<EXPR>.made;
        my $ast := QAST::Op.new( :node($/), :op<callmethod>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ), $expr );
        if nqp::istype($expr, QAST::Op) && $expr.op eq 'list' {
            my $countAll := +$expr.list;
            my $countIVal := 0;
            my $countSVal := 0;
            for $expr.list {
                $countIVal := $countIVal + 1 if nqp::istype($_, QAST::IVal);
                $countSVal := $countSVal + 1 if nqp::istype($_, QAST::SVal);
            }

            if $countIVal == $countAll {
                $ast.name('keyed_list_i');
            } elsif $countSVal == $countAll {
                $ast.name('keyed_list_s');
            } else {
                $ast.name('keyed_list');
            }
        } elsif nqp::istype($expr, QAST::IVal) {
            $ast.name('keyed_i');
        } elsif nqp::istype($expr, QAST::SVal) {
            $ast.name('keyed_s');
        } else {
            $ast.name('keyed');
        }
        make $ast;
    }

    method selector:sym<{ }>($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<filter>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ),
            QAST::Op.new( :op<takeclosure>, pop_newscope($/) ) );
    }

    method select:sym<name>($/) {
        my $name := QAST::SVal.new( :value(~$<name>) );
        #say('select:sym<name>: '~$/);
        make QAST::Op.new( :node($/), :op<callmethod>, :name<select_name>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ), $name );
    }

    method select:sym<quote>($/) {
        my $name := $<quote>.made;
        #say('select:sym<quote>: '~$/);
        make QAST::Op.new( :node($/), :op<callmethod>, :name<select_name>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ), $name );
    }

    method select:sym<path>($/) {
        my $path := $<quote> ?? $<quote>.made !! QAST::SVal.new( :value(~$<path>) );
        make QAST::Op.new( :node($/), :op<callmethod>, :name<select_path>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ), $path );
    }

    method select:sym<me>($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<select_me>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ) );
    }

    method select:sym<*>($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<select_all>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ) );
    }

    method xml($/) {
        # my $data := $<data>.made;
        # make QAST::Stmts.new(
        #     QAST::Op.new( :op<callmethod>, :name<init>,
        #         QAST::WVal.new( :value(MO::Model) ),
        #         QAST::Op.new( :op<call>, QAST::BVal.new( :value($data) ) ),
        #     ),
        #     $data
        # );
        make $<data>.made;
    }

    method json($/) {
        make QAST::Op.new(:op('null'));
    }

    method prog($/) {
        my $argsinit := QAST::Stmts.new();
        if nqp::defined($*MODULE_PARAMS) && nqp::islist($*MODULE_PARAMS) {
            my $params := nqp::clone($*MODULE_PARAMS);
            my $routine := $*W.new_routine('$*MODULE_PARAMS', -> { $params });
            $*W.add_object($routine);
            $argsinit.push(QAST::Op.new(:op<bind>,
                QAST::Var.new( :scope<lexical>, :name<@ARGS> ),
                QAST::Op.new( :op<call>, QAST::WVal.new( :value($routine) ) ),
            ));
        }

        my $initroutine := nqp::create(MO::Routine);
        $*W.add_object($initroutine);

        my $init := QAST::Stmts.new(
            QAST::Var.new( :scope<lexical>, :name<@ARGS>, :decl<param>, :slurpy(1) ),
            $argsinit,

            QAST::Op.new( :op<bind>,
                QAST::Var.new( :name<~init>, :scope<lexical>, :decl<var> ),
                QAST::WVal.new( :value($initroutine) ),
            ),
            QAST::Op.new( :op<callmethod>, :name<!code>,
                QAST::Var.new( :name<~init>, :scope<lexical> ), $*INIT,
            ),
            QAST::Op.new( :op<setcodeobj>,
                QAST::BVal.new( :value($*INIT) ),
                QAST::Var.new( :name<~init>, :scope<lexical> ),
            ),

            QAST::Op.new( :op<bind>,
                QAST::Var.new( :scope<lexical>, :decl<var>, :name<GLOBAL> ),
                QAST::Op.new( :op<getcurhllsym>, QAST::SVal.new( :value<GLOBAL> ) ),
            ),
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :scope<lexical>, :decl<var>, :name<GLOBAL.WHO> ),
                QAST::Op.new( :op<who>, QAST::Var.new( :scope<lexical>, :name<GLOBAL> ) ),
            ),
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :scope<lexical>, :decl<var>, :name<EXPORT> ),
                QAST::Op.new( :op<getcurhllsym>, QAST::SVal.new( :value<EXPORT> ) ),
            ),
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :scope<lexical>, :decl<var>, :name<EXPORT.WHO> ),
                QAST::Op.new( :op<who>, QAST::Var.new( :scope<lexical>, :name<EXPORT> ) ),
            ),
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :name<$_>, :scope<lexical>, :decl<var> ),
                QAST::Op.new( :op<callmethod>, :name<root>, QAST::Var.new( :scope<lexical>, :name<MODEL> ) ),
            ),
        );

        $init.push(self.CTXSAVE());

        $*W.install_fixups();

        my $scope := $*W.pop_scope();
        $scope.unshift( $init );
        $scope.push( $<statements>.made );

        fixup_variables($scope);

        my $compunit := QAST::CompUnit.new(
            :hll('mo'),

            # Serialization related bits.
            :sc($*W.sc()),
            :code_ref_blocks($*W.code_ref_blocks()),
            :compilation_mode($*W.is_precompilation_mode()),
            :pre_deserialize($*W.load_dependency_tasks()),
            :post_deserialize($*W.fixup_tasks()),
            :repo_conflict_resolver(QAST::Op.new(
                :op<callmethod>, :name('resolve_repossession_conflicts'),
                QAST::Op.new( :op<getcurhllsym>,
                    QAST::SVal.new( :value('ModuleLoader') )
                )
            )),

            # If this unit is loaded as a module, we want it to automatically
            # execute the mainline code above after all other initializations
            # have occurred.
            :load(QAST::Op.new(:op<call>, QAST::BVal.new( :value($scope) ))),

            :main(QAST::Op.new(:op<call>, QAST::BVal.new( :value($scope) ),
                QAST::Var.new( :name<ARGS>, :scope<local>, :decl<param>, :slurpy(1), :flat(1) )
            )),

            # Finally, the outer block, which in turn contains all of the
            # other program elements.
            $scope
        );

        make $compunit;
    }

    method statements($/) {
        my $stmts := QAST::Stmts.new();
        if +$<statement> {
            $stmts.push($_.made) for $<statement>;
        }
        make $stmts;
    }

    method statement:sym<control>($/) {
        make $<control>.made;
    }

    method statement:sym<declaration>($/) {
        make $<declaration>.made;
    }

    method statement:sym<definition>($/) {
        make $<definition>.made;
    }

    method statement:sym<EXPR>($/) {
        make $<EXPR>.made;
    }

    method statement:sym<yield_t>($/) {
        my $scope := $*W.current_scope;
        my $ast := QAST::Op.new( :node($/), :op<call>, :name(~$<name>) );
        if $scope.symbol('$_') {
            $ast.push( QAST::Var.new( :name<$_>, :scope<lexical> ) );
        } else {
            $ast.push( QAST::Op.new( :op<callmethod>, :name<root>, QAST::Var.new( :scope<lexical>, :name<MODEL> ) ) );
        }
        make $ast;
    }

    method statement:sym<yield_x>($/) {
        make $<EXPR>.made;
    }

    method control:sym<cond>($/) {
        my $ast := QAST::Op.new( :node($/), :op(~$<op>), $<EXPR>.made, $<statements>.made );
        $ast.push($<else>.made) if $<else>;
        make $ast;
    }

    method control:sym<loop>($/) {
        make QAST::Op.new( :node($/), :op(~$<op>), $<EXPR>.made, $<loop_block>.made );
    }

    method control:sym<for>($/) {
        make QAST::Op.new( :node($/), :op<for>, $<EXPR>.made, $<for_block>.made );
    }

    method control:sym<any>($/) {
        my $result := QAST::Var.new( :scope<lexical>, :decl<var>, :name(QAST::Node.unique('map_ret')) );
        my $stmts := QAST::Stmts.new(
            QAST::Op.new(:op<bindlex>,
                QAST::SVal.new( :value($result.name) ),
                QAST::Var.new(:name<a>, :scope<local>),
            ),
        );

        $stmts.push(QAST::Op.new(:op<call>, $<block>.made,
            QAST::Var.new(:name<a>, :scope<local>))) if $<block>;

        $stmts.push(QAST::Op.new( :op<control>, :name<last> ));

        make QAST::Stmts.new( :node($/), $result,
            QAST::Op.new( :op<for>, $<list>.made, QAST::Block.new(
                QAST::Var.new(:name<a>, :scope<local>, :decl<param>),
                QAST::Op.new( :op<if>,
                    QAST::Op.new(:op<call>, $<pred>.made, QAST::Var.new(:name<a>, :scope<local>)),
                    $stmts),
            )),
            QAST::Var.new( :scope<lexical>, :name($result.name) ),
        );
    }

    method control:sym<many>($/) {
        my $result := QAST::Var.new( :scope<lexical>, :decl<var>, :name(QAST::Node.unique('map_ret')) );
        my $stmts := QAST::Stmts.new(
            QAST::Op.new( :op<callmethod>, :name<push>,
                QAST::Var.new( :scope<lexical>, :name($result.name) ),
                QAST::Var.new(:name<a>, :scope<local>),
            ),
        );

        $stmts.push(QAST::Op.new(:op<call>, $<block>.made,
            QAST::Var.new(:name<a>, :scope<local>))) if $<block>;

        make QAST::Stmts.new( :node($/),
            QAST::Op.new( :op<bind>, $result, QAST::Op.new( :op<list> ) ),
            QAST::Op.new( :op<for>, $<list>.made, QAST::Block.new(
                QAST::Var.new(:name<a>, :scope<local>, :decl<param>),
                QAST::Op.new( :op<if>,
                    QAST::Op.new(:op<call>, $<pred>.made, QAST::Var.new(:name<a>, :scope<local>)),
                    $stmts),
            )),
            QAST::Var.new( :scope<lexical>, :name($result.name) ),
        );
    }

    method control:sym<with>($/) {
        make QAST::Op.new( :node($/), :op<call>, $<with_block>.made, $<EXPR>.made );
    }

    method else:sym< >($/) { make $<statements>.made; }
    method else:sym<if>($/) {
        my $ast := QAST::Op.new( :node($/), :op<if>, $<EXPR>.made, $<statements>.made );
        $ast.push($<else>.made) if $<else>;
        make $ast;
    }

    method block($/) {
        my $scope := pop_newscope($/);
        $scope.blocktype('immediate');
        unless $scope.symtable() {
            my $stmts := QAST::Stmts.new( :node($/) );
            $stmts.push($_) for $scope.list;
            $scope := $stmts;
        }
        make $scope;
    }

    method loop_block:sym<{ }>($/) { make pop_newscope($/); }
    method loop_block:sym<end>($/) { make pop_newscope($/); }

    method for_block:sym<{ }>($/) { make pop_newscope($/); }
    method for_block:sym<end>($/) { make pop_newscope($/); }

    method with_block:sym<{ }>($/) { make pop_newscope($/); }
    method with_block:sym<end>($/) { make pop_newscope($/); }

    method def_block:sym<{ }>($/) { make $<statements>.made; }
    method def_block:sym<end>($/) { make $<statements>.made; }

    method map_block:sym<{ }>($/) { make pop_newscope($/); }
    method map_block:sym<end>($/) { make pop_newscope($/); }

    method map_pred:sym<name>($/) { self.'term:sym<name>'($/) }
    method map_pred:sym<{ }>($/) {
        my $pred := QAST::Block.new( :node($/),
            QAST::Stmts.new(
                QAST::Var.new(:name<$_>, :scope<lexical>, :decl<param>),
            ),
            $<statements>.made );
        make $pred;
    }

    method declaration:sym<var>($/, :$init?) {
        unless $<variable><name> {
            $/.CURSOR.panic('variable $ already defined');
        }

        my @name := nqp::split('::', ~$<variable><name>);
        my $final_name := @name.pop;
        my $name := ~$<variable><sigil> ~ $final_name;

        my $scope := $*W.current_scope;

        my $who;
        if +@name {
            $who := $*W.symbol_ast($/, @name, 1);
        } elsif $*W.is_export_name($final_name) {
            $who := QAST::Var.new( :name<EXPORT.WHO>, :scope<lexical> );
        }

        my $initializer := $<initializer> ?? $<initializer>.made
            !! nqp::defined($init) ?? $init !! QAST::Op.new( :op<null> );

        if nqp::defined($who) {
            make QAST::Stmts.new(
                QAST::Op.new( :op<bindkey>, $who,
                    QAST::SVal.new( :value($name) ), $initializer ),
                QAST::Var.new( :node($/), :scope<associative>,
                    $who, QAST::SVal.new( :value($name) ) ),
            );
        } elsif +@name == 0 {
            my $package := $scope.ann('package');
            if nqp::defined($package) {
                $scope.symbol($name, :scope<package>, :$package );
                make QAST::Stmts.new(
                    QAST::Op.new( :node($/), :op<bindkey>,
                        QAST::Op.new( :op<who>, QAST::WVal.new( :value($package) ) ),
                        QAST::SVal.new( :value($name) ), $initializer ),
                    QAST::Var.new( :node($/), :scope<associative>,
                        QAST::Op.new( :op<who>, QAST::WVal.new( :value($package) ) ),
                        QAST::SVal.new( :value($name) ) ),
                );
            } else {
                $scope.symbol( $name, :scope<lexical> );
                make QAST::Stmts.new(
                    QAST::Op.new( :node($/), :op<bind>,
                        QAST::Var.new( :name($name), :scope<lexical>, :decl<var> ),
                        $initializer ),
                    QAST::Var.new( :node($/), :name($name), :scope<lexical> ),
                );
            }
        } else {
            $/.CURSOR.panic('undefined '~$/);
        }
    }

    sub isconst($ast) {
        nqp::istype($ast, QAST::SVal) ||
        nqp::istype($ast, QAST::IVal) ||
        nqp::istype($ast, QAST::WVal)
    }

    method declaration:sym<use>($/) {
        my @params;
        if $<params> {
            my $ast := $<params>.made;
            for $ast.list {
                unless isconst($_) {
                    $<params>.CURSOR.panic("expect constant value");
                }
            }

            my $compiler := nqp::getcomp('mo');
            my $eval := $compiler.compile($ast, :from<ast>, :lineposcache($*LINEPOSCACHE));
            my $v := $eval();
            if nqp::islist($v) {
                @params := $v;
            } else {
                @params := [$v];
            }
        }
        my @lexpads := $*W.load_module($/, ~$<name>, @params, $*GLOBALish);
        my $stmts := QAST::Stmts.new( :node($/) );
        for @lexpads {
            if nqp::isinvokable($_<~init>) {
                my $init := QAST::WVal.new(:value($_<~init>));
                my $callinit;
                if $<initargs> {
                    $callinit := nqp::clone($<initargs>.made);
                    $callinit.unshift($init);
                } else {
                    $callinit := QAST::Op.new(:op<call>, $init);
                }
                $stmts.push($callinit);
            }
        }
        make $stmts;
    }

    method declaration:sym<rule>($/) {
        my $stmts := QAST::Stmts.new( :node($/) );
        my $target := QAST::Var.new(:scope<lexical>, :name(QAST::Node.unique('rule_target')));
        my $how := QAST::WVal.new( :value(MO::FilesystemNodeHOW) );
        my $build := $*W.pop_scope;
        $build.name( QAST::Node.unique('rule') );
        $build.push( $<statements>.made );
        $stmts.push( QAST::Var.new(:scope<lexical>, :decl<var>, :name($target.name)) );
        $stmts.push( $build );
        for $<targets> {
            $stmts.push( QAST::Op.new( :op<bind>, $target,
                QAST::Op.new( :op<callmethod>, :name<get>,  $how, $_.made ) ) );
            $stmts.push( QAST::Op.new( :op<callmethod>, :name<install_build_code>, $target,
                QAST::BVal.new( :value( $build ) ) ) );
            $stmts.push( QAST::Op.new( :op<callmethod>, :name<depend>, $target, $_.made ) )
                for $<prerequisites> ;
        }
        make $stmts;
    }

    method definition:sym<template>($/) {
        my $scope := $*W.pop_scope();
        my $template := $scope.ann('package');
        $scope.push( $<template_atoms>.made );
        $scope.node( $/ );

        my $code := $*W.install_package_routine($template, '!str', $scope);
        $template.HOW.add_method($template, '!str', $code);

        $*W.pkg_compose($template);
        make $scope;
    }

    method template_atoms($/) {
        my $ast := QAST::SVal.new(:value(''));
        if +$<template_atom> {
            for $<template_atom> {
                $ast := QAST::Op.new( :op<concat>, $ast, $_.made );
            }
        }
        make $ast;
    }

    method template_atom:sym<$>($/) {
        make $<variable>.made;
    }

    method template_atom:sym<()>($/) {
        make $<EXPR>.made;
    }

    method template_atom:sym<{}>($/) {
        make $<statements>.made;
    }

    method template_atom:sym<^^>($/) {
        make $<template_statement>.made;
    }

    method template_atom:sym<.>($/) {
        make QAST::SVal.new( :node($/), :value(~$/) );
    }

    method template_statement:sym<for>($/) {
        my $scope := $*W.pop_scope();
        $scope.node( $/ );

        my $result := QAST::Var.new(:scope<lexical>, :name(QAST::Node.unique('template_for')));
        my $outer := $scope.ann('outer');
        $outer[0].push( QAST::Op.new( :op<bind>,
            QAST::Var.new(:scope<lexical>, :decl<var>, :name($result.name)),
            QAST::SVal.new(:value('')),
        ) );

        $scope.push( QAST::Op.new( :op<bindlex>,
            QAST::SVal.new(:value($result.name)),
            QAST::Op.new( :op<concat>, $result, $<template_atoms>.made ) ) );

        make QAST::Op.new( :node($/), :op<for>, $<EXPR>.made, $scope );
    }

    method template_statement:sym<if>($/) { make template_if($/); }
    method template_else:sym<if>($/)      { make template_if($/); }
    method template_else:sym< >($/)       { make $<template_atoms>.made; }

    my sub template_if($/) {
        my $ast := QAST::Op.new( :node($/), :op<if>, $<EXPR>.made,
            $<template_atoms>.made );
        $ast.push($<else>.made) if $<else>;
        make $ast;
    }

    method param($/) {
        my $name := $<sigil> ~ $<name>;
        my $scope := $*W.current_scope;
        $/.CURSOR.panic('duplicated parameter '~$name)
            if $scope.symbol($name);

        my $sym := $scope.symbol($name, :scope<lexical>, :decl<param>);
        make $scope[0].push( QAST::Var.new( :node($/), :name($name),
            :decl($sym<decl>), :scope<lexical> ) );
    }

    method definition:sym<def>($/) {
        my $name := ~$<name>;
        my $scope := $*W.pop_scope();
        $scope.name($name);
        $scope[0].push( wrap_return_handler($scope, $<def_block>.made) );

        my $package := $*W.get_package($scope.ann('outer'));
        $*W.install_package_routine($package, $name, $scope);

        my $outer := $scope.ann('outer');
        $outer.symbol('&' ~ $name, :scope<lexical>, :proto(1), :declared(1) );
        $outer[0].push( QAST::Op.new( :op<bind>,
            QAST::Var.new( :name('&' ~ $name), :scope<lexical>, :decl<var> ),
            $scope
        ) );

        if $*W.is_export_name($name) {
            $outer[0].push( QAST::Op.new( :node($/), :op<bindkey>,
                QAST::Var.new( :name<EXPORT.WHO>, :scope<lexical> ),
                QAST::SVal.new( :value($name) ),
                QAST::Var.new( :name('&' ~ $name), :scope<lexical> ),
            ) );
        }

        make QAST::Var.new( :name('&' ~ $name), :scope<lexical> );
    }

    method definition:sym<init>($/) {
        my $scope := $*W.pop_scope;
        $scope.node($/);
        $scope.push($<statements>.made);
        $*INIT.push(QAST::Op.new(:op<call>, QAST::BVal.new(:value($scope)),
            QAST::Var.new(:name<@_>, :scope<lexical>, :flat(1)),
        ));
        make $scope;
    }

    method definition:sym<class>($/) {
        my $ctor_name := '~ctor';
        my $ctor := $*W.pop_scope;
        my $class := $ctor.ann('package');
        $ctor.name( ~$<name> ~'::'~$ctor_name );

        my $code := $*W.install_package_routine($class, $ctor_name, $ctor);
        $class.HOW.add_method($class, $ctor_name, $code);

        $*W.pkg_compose($class);
        make $ctor;
    }

    method class_member:sym<method>($/) {
        my $scope := $*W.pop_scope;
        my $ctor := $scope.ann('outer');
        my $class := $ctor.ann('package');
        $scope.push( $<statements>.made );
        $scope.name( ~$<name> );
        $ctor[0].push($scope);

        my $code := $*W.install_package_routine($class, $scope.name, $scope);
        $class.HOW.add_method($class, $scope.name, $code);
    }

    method class_member:sym<$>($/) {
        my $sigil := ~$<variable><sigil>;
        my $twigil := ~$<variable><twigil>;
        my $name := ~$<variable>;
        my $initializer := $<initializer>
            ?? $<initializer>.made !! QAST::Op.new( :op<null> );
        my $ctor := $*W.current_scope;
        my $class := $ctor.ann('package');
        if $twigil eq '.' {
            my %lit_args;
            my %obj_args;
            %lit_args<name> := $name;

            my $attr := (%*HOW<attribute>).new(|%lit_args, |%obj_args);
            $class.HOW.add_attribute($class, $attr);

            $ctor[0].push( QAST::Op.new( :node($/), :op<bindattr>,
                QAST::Var.new( :name<me>, :scope<lexical> ),
                QAST::WVal.new( :value($class) ),
                QAST::SVal.new( :value($name) ),
                $initializer ) );
        } else {
            $ctor.symbol($name, :scope<package>, :package($class) );
            $ctor[0].push( QAST::Op.new( :node($/), :op<bindkey>,
                QAST::Op.new( :op<who>, QAST::WVal.new( :value($class) ) ),
                QAST::SVal.new( :value($name) ), $initializer ) );
        }
    }

    method definition:sym<lang>($/) {
        my $langname := ~$<langname>;
        unless $*W.has_interpreter($langname) {
            $<langname>.CURSOR.panic("language $langname is not supported");
        }

        my $options := QAST::Op.new( :op<hash> );
        for %*option {
            if nqp::istype($_.value, QAST::Node) {
                $options.push(QAST::SVal.new(:value($_.key)));
                $options.push($_.value);
            } elsif nqp::isint($_.value) {
                $options.push(QAST::SVal.new(:value($_.key)));
                $options.push(QAST::IVal.new(:value($_.value)));
            } elsif nqp::isstr($_.value) {
                $options.push(QAST::SVal.new(:value($_.key)));
                $options.push(QAST::SVal.new(:value($_.value)));
            }
        }

        my $langcode := QAST::Block.new( :node($/),
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :name<options>, :scope<local>, :decl<var> ),
                $options,
            ),
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :name<result>, :scope<local>, :decl<var> ),
                QAST::Op.new( :op<call>,
                    QAST::WVal.new(:value($*W.interpreter($langname))),
                    $<source>.made,
                    QAST::Var.new( :name<options>, :scope<local> ),
                )
            ),
        );

        for $<lang_modifier> {
            $langcode.push($_.made) if nqp::defined($_.made);
        }

        $langcode.push(QAST::Var.new( :name<result>, :scope<local> ));

        if $<variable> {
            self.'declaration:sym<var>'($/, :init($langcode));
        } elsif $<name> {
            my $scope := $*W.current_scope();
            my $name := ~$<name>;

            my $package := $*W.get_package($scope);
            $*W.install_package_routine($package, $name, $langcode);

            $scope.symbol('&' ~ $name, :scope<lexical>, :declared(1) );
            $scope[0].push( QAST::Op.new( :op<bind>,
                QAST::Var.new( :name('&' ~ $name), :scope<lexical>, :decl<var> ),
                $langcode
            ) );

            if $*W.is_export_name($name) {
                $scope[0].push( QAST::Op.new( :node($/), :op<bindkey>,
                    QAST::Var.new( :name<EXPORT.WHO>, :scope<lexical> ),
                    QAST::SVal.new( :value($name) ),
                    QAST::Var.new( :name('&' ~ $name), :scope<lexical> ),
                ) );
            }

            make QAST::Var.new( :name('&' ~ $name), :scope<lexical> );
        } else {
            make QAST::Op.new( :op<call>, $langcode );
        }
    }

    method lang_modifier:sym<:stdout>($/) {
        self.'declaration:sym<var>'($/);
        my $stmts := $/.made;
        my $var := $stmts[+$stmts.list-1];
        my $scope := $*W.current_scope();
        $scope.push($stmts);
        make QAST::Stmts.new( :node($/),
            QAST::Op.new( :op<bind>, $var,
                QAST::Var.new( :scope<associative>,
                    QAST::Var.new( :name<options>, :scope<local> ),
                    QAST::SVal.new( :value<stdout> ),
                ),
            ),
        );
    }

    method lang_source:sym<raw>($/) { make QAST::SVal.new(:value(~$/)); }
    method lang_source:sym<esc>($/) { make $<template_atoms>.made; }
}
