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
    method term:sym<colonpair>($/) { make $<colonpair>.made; $/.prune; }
    method term:sym<name>($/) {
        my @name := nqp::split('::', ~$<name>);
        my $ast := $*W.symbol_ast($/, @name, 0);
        unless $ast {
            $ast := self.'select:sym<name>'($/);
            $ast.push( QAST::Var.new( :name<$_>, :scope<lexical> ) );
            $ast.push( QAST::IVal.new( :value(1) ) );
        }
        make $ast;
        $/.prune;
    }

    method term:sym«.»($/) {
        my $ast := $<post_dot>.made;
        $ast.unshift( QAST::Var.new( :name<$_>, :scope<lexical> ) );
        make $ast;
        $/.prune;
    }

    method term:sym«->»($/) {
        my $ast := $<post_arrow>.made;
        $ast.unshift( QAST::Var.new( :name<$_>, :scope<lexical> ) );
        make $ast;
        $/.prune;
    }

    method term:sym<def>($/) {
        my $scope := $*W.pop_scope();
        $scope.push( wrap_return_handler($scope, $<statements>.made) );
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

    method term:sym<map>($/) { make QAST::Op.new( :op<map>, $<pred>.made, expr_list_ast($<list>.made) ); }
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
        my $scope := $*W.get_package_scope;
        my $package := $scope.ann('package');

        my $rulehash;
        my $name := '~rules';
        if nqp::istype($package.HOW, MO::ClassHOW) {
            $rulehash := self.class_rule_hash($package, $scope);
        } else {
            $rulehash := $*W.symbol_ast($/, [$name], 0) // self.declare_unit_rules($name);
        }
        make QAST::Op.new( :op<callmethod>, :name<rule>, $rulehash, $<EXPR>.made );
        #$/.prune;
    }

    method postcircumfix:sym<( )>($/) {
        make $<arglist>.made;
        #$/.prune;
    }

    method postcircumfix:sym<[ ]>($/) {
        my $expr := $<EXPR>.made;
        if nqp::istype($expr, QAST::Op) && $expr.op eq 'list' {
            make QAST::Op.new( :op<poses>, $expr );
        } else {
            make QAST::Var.new( :scope('positional'), $expr );
        }
        #$/.prune;
    }

    method postcircumfix:sym<{ }>($/) {
        # make QAST::Var.new( :scope('associative'), $<EXPR>.made );
        my $expr := $<EXPR>.made;
        if nqp::istype($expr, QAST::Op) && $expr.op eq 'list' {
            make QAST::Op.new( :op<asses>, $expr );
        } else {
            make QAST::Var.new( :scope('associative'), $expr );
        }
        #$/.prune;
    }

    method postcircumfix:sym<ang>($/) {
        make QAST::Var.new( :scope('associative'), $<quote_EXPR>.made );
        #$/.prune;
    }

    method postfix:sym«.»($/)  { make $<post_dot>.made }
    method postfix:sym«->»($/) { make $<post_arrow>.made }

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
        my int $panic := 1
            && $*IN_DECL ne 'var'
            && $*IN_DECL ne 'member'
            && $*IN_DECL ne 'lang'
            ;

        my @name := nqp::split('::', ~$<name>);
        my $final_name := @name.pop;
        my $name := ~$<sigil> ~$<twigil> ~ $final_name;
        @name.push($name);

        make $*W.symbol_ast($/, @name, $panic);
    }

    method colonpair($/) {
        my $ast;
        if $<variable> {
            $ast := $<variable>.made;
            $ast.named( nqp::split('::', ~$<variable><name>).pop );
        } else {
            $ast := $<circumfix>.made;
            $ast.named( ~$<name> );
        }
        make $ast;
        $/.prune;
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

    method post_dot($/) {
        my $ast;
        if $<query> {
            $ast := QAST::Op.new( :op<can>, QAST::SVal.new(:value(~$<name>)) );
        } elsif $<args> {
            $ast := $<args>.made;
            $ast.op('callmethod');
            $ast.name(~$<name>);
        } else {
            $ast := QAST::Op.new( :node($/), :op<get>,  QAST::SVal.new(:value('$.'~$<name>)) );
        }
        make $ast;
    }

    method post_arrow($/) { make $<select>.made }

    method select:sym<name>($/) {
        make QAST::Op.new( :node($/), :op<select>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ),
            QAST::SVal.new( :value(~$<name>) ) );
    }

    method select:sym<{ }>($/) {
        make QAST::Op.new( :node($/), :op<filter>,
            QAST::Var.new( :scope<lexical>, :name<MODEL> ),
            QAST::Op.new( :op<takeclosure>, pop_newscope($/) ) );
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

    # method selector:sym«:»($/) {
    #     my $namespace := QAST::SVal.new( :value(~$<namespace>) );
    #     my $meth := 'select_namespace';
    #     $meth := $meth ~ '_query' if $<query>;
    #     make QAST::Op.new( :node($/), :op<callmethod>, :name($meth),
    #         QAST::Var.new( :scope<lexical>, :name<MODEL> ), $namespace );
    # }

    # method selector:sym«.»($/) {
    #     my $name := QAST::SVal.new( :value(~$<name>) );
    #     make QAST::Op.new( :node($/), :op<callmethod>, :name<dot>,
    #         QAST::Var.new( :scope<lexical>, :name<MODEL> ), $name );
    # }

    # method selector:sym«..»($/) {
    #     make QAST::Op.new( :node($/), :op<callmethod>, :name<dotdot>,
    #         QAST::Var.new( :scope<lexical>, :name<MODEL> ) );
    # }

    # method selector:sym«->»($/) {
    #     make $<select>.made;
    # }

    # method selector:sym<[ ]>($/) {
    #     my $expr := $<EXPR>.made;
    #     my $ast := QAST::Op.new( :node($/), :op<callmethod>,
    #         QAST::Var.new( :scope<lexical>, :name<MODEL> ), $expr );
    #     if nqp::istype($expr, QAST::Op) && $expr.op eq 'list' {
    #         my $countAll := +$expr.list;
    #         my $countIVal := 0;
    #         my $countSVal := 0;
    #         for $expr.list {
    #             $countIVal := $countIVal + 1 if nqp::istype($_, QAST::IVal);
    #             $countSVal := $countSVal + 1 if nqp::istype($_, QAST::SVal);
    #         }

    #         if $countIVal == $countAll {
    #             $ast.name('keyed_list_i');
    #         } elsif $countSVal == $countAll {
    #             $ast.name('keyed_list_s');
    #         } else {
    #             $ast.name('keyed_list');
    #         }
    #     } elsif nqp::istype($expr, QAST::IVal) {
    #         $ast.name('keyed_i');
    #     } elsif nqp::istype($expr, QAST::SVal) {
    #         $ast.name('keyed_s');
    #     } else {
    #         $ast.name('keyed');
    #     }
    #     make $ast;
    # }

    # method selector:sym<{ }>($/) {
    #     make QAST::Op.new( :node($/), :op<callmethod>, :name<filter>,
    #         QAST::Var.new( :scope<lexical>, :name<MODEL> ),
    #         QAST::Op.new( :op<takeclosure>, pop_newscope($/) ) );
    # }

    # method select:sym<name>($/) {
    #     my $name := QAST::SVal.new( :value(~$<name>) );
    #     # say('select:sym<name>: '~$/);
    #     make QAST::Op.new( :node($/), :op<callmethod>, :name<select_name>,
    #         QAST::Var.new( :scope<lexical>, :name<MODEL> ), $name );
    # }

    # method select:sym<quote>($/) {
    #     my $name := $<quote>.made;
    #     #say('select:sym<quote>: '~$/);
    #     make QAST::Op.new( :node($/), :op<callmethod>, :name<select_name>,
    #         QAST::Var.new( :scope<lexical>, :name<MODEL> ), $name );
    # }

    # method select:sym<path>($/) {
    #     my $path := $<quote> ?? $<quote>.made !! QAST::SVal.new( :value(~$<path>) );
    #     make QAST::Op.new( :node($/), :op<callmethod>, :name<select_path>,
    #         QAST::Var.new( :scope<lexical>, :name<MODEL> ), $path );
    # }

    # method select:sym<me>($/) {
    #     make QAST::Op.new( :node($/), :op<callmethod>, :name<select_me>,
    #         QAST::Var.new( :scope<lexical>, :name<MODEL> ) );
    # }

    # method select:sym<*>($/) {
    #     make QAST::Op.new( :node($/), :op<callmethod>, :name<select_all>,
    #         QAST::Var.new( :scope<lexical>, :name<MODEL> ) );
    # }

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

    sub new_lexical_routine_declarator($name, $block) {
        my $routine := nqp::create(MO::Routine);
        $*W.add_object($routine);
        QAST::Stmts.new(
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :$name, :scope<lexical>, :decl<var> ),
                QAST::WVal.new( :value($routine) ),
            ),
            QAST::Op.new( :op<callmethod>, :name<!code>,
                QAST::Var.new( :$name, :scope<lexical> ),
                QAST::BVal.new( :value($block) ),
            ),
            QAST::Op.new( :op<setcodeobj>,
                QAST::BVal.new( :value($block) ),
                QAST::Var.new( :$name, :scope<lexical> ),
            ),
        )
    }

    method prog($/) {
        my $moduleinit := QAST::Stmts.new();
        if nqp::defined($*MODULE_PARAMS) && nqp::islist($*MODULE_PARAMS) {
            my $params := $*MODULE_PARAMS;
            my $routine := $*W.new_routine('$*MODULE_PARAMS', -> { $params });
            $*W.add_object($routine);
            $moduleinit.push(QAST::Op.new(:op<bind>,
                QAST::Var.new( :scope<lexical>, :name<@ARGS> ),
                QAST::Op.new( :op<call>, QAST::WVal.new( :value($routine) ) ),
            ));
        }

        my $unitinit := QAST::Stmts.new(
            QAST::Var.new( :scope<lexical>, :name<@ARGS>, :decl<param>, :slurpy(1) ),

            new_lexical_routine_declarator('~init', $*INIT),
            new_lexical_routine_declarator('~load', $*LOAD),

            $*INIT, $*LOAD, $moduleinit,

            QAST::Op.new( :op<bind>,
                QAST::Var.new( :scope<lexical>, :decl<var>, :name<GLOBAL> ),
                QAST::Op.new( :op<getcurhllsym>, QAST::SVal.new( :value<GLOBAL> ) ),
            ),
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :scope<lexical>, :decl<var>, :name<EXPORT> ),
                QAST::Op.new( :op<getcurhllsym>, QAST::SVal.new( :value<EXPORT> ) ),
            ),
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :name<$_>, :scope<lexical>, :decl<var> ),
                QAST::Op.new( :op<callmethod>, :name<root>, QAST::Var.new( :scope<lexical>, :name<MODEL> ) ),
            ),

            QAST::Op.new( :op<call>,
                QAST::BVal.new( :value($*INIT) ),
                QAST::Var.new( :name<@ARGS>, :scope<lexical>, :flat(1) ),
            ),
        );

        $unitinit.push(self.CTXSAVE());

        $*W.install_fixups();

        my $scope := $*W.pop_scope();
        $scope.unshift( $unitinit );
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
            :load(QAST::Stmts.new(
                 QAST::Op.new( :op<call>, QAST::BVal.new( :value($scope) ) ),
            )),

            :main(QAST::Stmts.new(
                 QAST::Var.new( :name<ARGS>, :scope<local>, :decl<param>, :slurpy(1) ),
                 QAST::Op.new( :op<call>, QAST::BVal.new( :value($*INIT) ),
                     QAST::Var.new( :name<ARGS>, :scope<local>, :flat(1) ),
                 ),
                 QAST::Op.new( :op<call>, QAST::BVal.new( :value($scope) ),
                     QAST::Var.new( :name<ARGS>, :scope<local>, :flat(1) ),
                 ),
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
        make QAST::Op.new( :node($/), :op(~$<op>), $<EXPR>.made,
            $<loop_block>.made, #QAST::Op.new( :op<takeclosure>, $<loop_block>.made ),
        );
    }

    method control:sym<for>($/) {
        make QAST::Op.new( :node($/), :op<for>, $<EXPR>.made,
            $<for_block>.made, # QAST::Op.new( :op<takeclosure>, $<for_block>.made ),
        );
    }

    sub expr_list_ast($ast) {
        if nqp::istype($ast, QAST::Op) && $ast.op eq 'list' {
            $ast
        } else {
            QAST::Op.new( :op<list>, $ast )
        }
    }

    method control:sym<with>($/) {
        make QAST::Op.new( :node($/), :op<call>, $<with_block>.made, $<EXPR>.made );
    }

    method control:sym<any>($/) {
        my $op := QAST::Op.new( :op<any>, $<pred>.made, expr_list_ast($<list>.made) );
        $op.push( $<block>.made ) if $<block>;
        make $op;
    }

    method control:sym<many>($/) {
        my $op := QAST::Op.new( :op<many>, $<pred>.made, expr_list_ast($<list>.made) );
        $op.push( $<block>.made ) if $<block>;
        make $op;
    }

    method deprecated_control:sym<any>($/) {
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
            QAST::Op.new( :op<for>, expr_list_ast($<list>.made), QAST::Block.new(
                QAST::Var.new(:name<a>, :scope<local>, :decl<param>),
                QAST::Op.new( :op<if>,
                    QAST::Op.new(:op<call>, $<pred>.made, QAST::Var.new(:name<a>, :scope<local>)),
                    $stmts),
            )),
            QAST::Var.new( :scope<lexical>, :name($result.name) ),
        );
    }

    method deprecated_control:sym<many>($/) {
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
            QAST::Op.new( :op<for>, expr_list_ast($<list>.made), QAST::Block.new(
                QAST::Var.new(:name<a>, :scope<local>, :decl<param>),
                QAST::Op.new( :op<if>,
                    QAST::Op.new(:op<call>, $<pred>.made, QAST::Var.new(:name<a>, :scope<local>)),
                    $stmts),
            )),
            QAST::Var.new( :scope<lexical>, :name($result.name) ),
        );
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

    # method loop_block:sym<{ }>($/) { make pop_newscope($/); }
    # method loop_block:sym<end>($/) { make pop_newscope($/); }
    method loop_block:sym<{ }>($/) { make $<statements>.made; }
    method loop_block:sym<end>($/) { make $<statements>.made; }

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

    sub default_initializer($sigil) {
        if $sigil eq '@' {
            QAST::Op.new( :op<list> )
        } elsif $sigil eq '%' {
            QAST::Op.new( :op<hash> )
        } else {
            QAST::Op.new( :op<null> )
        }
    }

    method declaration:sym<var>($/, :$init?) {
        my @name := nqp::split('::', ~$<variable><name>);
        my $final_name := @name.pop;
        my $name := ~$<variable><sigil> ~ $<variable><twigil> ~ $final_name;

        my $scope := $*W.current_scope;

        my $who;
        if +@name {
            $who := $*W.symbol_ast($/, @name, 1);
            if nqp::istype($who, QAST::WVal) {
                # bind the key immediately to avoid undefined symbol
                ($who.value.WHO){$name} := nqp::null();
            }
        } elsif $*W.is_export_name($final_name) {
            ($*EXPORT.WHO){$name} := nqp::null(); # bind the key immediately to avoid undefined symbol
            $who := QAST::Op.new( :op<who>, QAST::WVal.new( :value($*EXPORT) ) );
        }

        my $initializer := $<initializer> ?? $<initializer>.made
            !! nqp::defined($init) ?? $init !! NQPMu;

        if nqp::defined($who) {
            my $initialize := nqp::defined($initializer)
                ?? QAST::Op.new( :op<bindkey>, $who, QAST::SVal.new( :value($name) ), $initializer )
                !! QAST::Stmts.new();
            make QAST::Stmts.new( $initialize,
                QAST::Var.new( :node($/), :scope<associative>,
                    $who, QAST::SVal.new( :value($name) ) ),
            );
        } elsif +@name == 0 {
            my $package := $scope.ann('package');
            if nqp::defined($package) {
                ($package.WHO){$name} := nqp::null(); # bind the key immediately to avoid undefined symbol
                $scope.symbol( $name, :scope<package>, :$package );
                my $initialize := nqp::defined($initializer)
                    ?? QAST::Op.new( :node($/), :op<bindkey>,
                           QAST::Op.new( :op<who>, QAST::WVal.new( :value($package) ) ),
                           QAST::SVal.new( :value($name) ), $initializer )
                    !! QAST::Stmts.new();
                make QAST::Stmts.new( $initialize,
                    QAST::Var.new( :node($/), :scope<associative>,
                        QAST::Op.new( :op<who>, QAST::WVal.new( :value($package) ) ),
                        QAST::SVal.new( :value($name) ) ),
                );
            } else {
                $scope.symbol( $name, :scope<lexical>, :decl<var> );
                my $decl := QAST::Var.new( :name($name), :scope<lexical>, :decl<var> );
                my $initialize := nqp::defined($initializer)
                    ?? QAST::Op.new( :node($/), :op<bind>, $decl, $initializer )
                    !! $decl ;
                make QAST::Stmts.new( $initialize,
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
        my $params_ast;
        my @params;
        if $<params> {
            $params_ast := $<params>.made;
            for $params_ast.list {
                unless isconst($_) {
                    $<params>.CURSOR.panic("expect constant value");
                }
            }

            my $compiler := nqp::getcomp('mo');
            my $eval := $compiler.compile($params_ast, :from<ast>, :lineposcache($*LINEPOSCACHE));
            my $v := $eval();
            if nqp::islist($v) {
                @params := $v;
            } else {
                @params := [$v];
            }
        }
#say('W_EXPORT: '~nqp::where($*W)~', '~nqp::where($*EXPORT));
        my @lexpads := $*W.load_module($/, ~$<name>, @params, $*GLOBALish);
#say('W_EXPORT: '~nqp::where($*W)~', '~nqp::where($*EXPORT));
        my $stmts := QAST::Stmts.new( :node($/) );
        for @lexpads {
            if nqp::isinvokable($_<~load>) {
                my $load := QAST::WVal.new(:value($_<~load>));
                my $callload := QAST::Op.new(:op<call>, $load);
                if nqp::defined($params_ast) {
                    if nqp::istype($params_ast, QAST::Op) && $params_ast.op eq 'list' {
                        $params_ast.flat(1);
                    }
                    $callload.push( $params_ast );
                }
                if +$<namedarg> {
                    my $args := QAST::Op.new(:op<hash>, :flat(1));
                    $callload.push( $args );
                    for $<namedarg> {
                        $args.push( QAST::SVal.new( :value(~$_<name>) ) );
                        $args.push( $_<value>.made );
                    }
                }
                $stmts.push($callload);
            }
        }
        make $stmts;
    }

    method declaration:sym<rule>($/) {
        my $build := $*W.pop_scope;
        $build.name( QAST::Node.unique('rule') );
        $build.push( $<statements>.made );

        my $name := '~rules';
        my $rulehash := $*W.symbol_ast($/, [$name], 0) // self.declare_unit_rules($name);

        my $stmts := self.build_rule_init($/, $build, $rulehash);
        $stmts.push( $build ); # push the build code
        make $stmts;
    }

    method declare_unit_rules($name) {
        unless $*UNIT.symbol($name) {
            $*UNIT.symbol($name, :scope<lexical>);
            $*UNIT[0].push( QAST::Op.new( :op<bind>,
                QAST::Var.new( :name($name), :scope<lexical>, :decl<var> ),
                QAST::Op.new( :op<callmethod>, :name<new_hash>,
                    QAST::WVal.new( :value(MO::RuleHashHOW) ),
                    QAST::SVal.new( :value('') ) ),
            ) );
        }
        QAST::Var.new( :name($name), :scope<lexical> );
    }

    method build_rule_init($/, $block, $rulehash) {
        my $stmts := QAST::Stmts.new( :node($/) );
        my $targets := QAST::Op.new( :op<list> );
        my $prerequisites := QAST::Op.new( :op<list> );
        for $<targets> { $targets.push($_.made) }
        for $<prerequisites> { $prerequisites.push($_.made) }
        $stmts.push( QAST::Op.new( :op<callmethod>, :name<link>,
            $rulehash, $targets, $prerequisites,
            QAST::BVal.new( :value( $block ) ) ) );
        $stmts
    }

    method build_rule_init_deprecated($/, $block) {
        my $stmts := QAST::Stmts.new( :node($/) );
        my $target := QAST::Var.new(:scope<lexical>, :name(QAST::Node.unique('rule_target')));
        my $how := QAST::WVal.new( :value(MO::FilesystemNodeHOW) );

        $stmts.push( QAST::Var.new(:scope<lexical>, :decl<var>, :name($target.name)) );
        for $<targets> {
            $stmts.push( QAST::Op.new( :op<bind>, $target,
                QAST::Op.new( :op<callmethod>, :name<get>,  $how, $_.made ) ) );
            $stmts.push( QAST::Op.new( :op<callmethod>, :name<install_build_code>, $target,
                QAST::BVal.new( :value( $block ) ) ) );
            for $<prerequisites> {
                $stmts.push(QAST::Op.new( :op<if>, QAST::Op.new( :op<isstr>, $_.made ),
                    QAST::Op.new( :op<callmethod>, :name<depend>, $target, $_.made ),
                    QAST::Op.new( :op<if>, QAST::Op.new( :op<islist>, $_.made ),
                        QAST::Op.new( :op<for>, $_.made, QAST::Block.new(
                            QAST::Var.new( :name<pre>, :scope<local>, :decl<param> ),
                            QAST::Op.new( :op<if>, QAST::Op.new( :op<isstr>, QAST::Var.new( :name<pre>, :scope<local> ) ),
                                QAST::Op.new( :op<callmethod>, :name<depend>, $target, QAST::Var.new( :name<pre>, :scope<local> ) ),
                                QAST::Op.new( :op<die>, QAST::SVal.new(:value('unsupported type')) ),
                            ),
                        )),
                        QAST::Op.new( :op<die>, QAST::SVal.new(:value('unsupported type')) ),
                    ),
                ));
            }
        }
        $stmts
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

    method template_atom:sym<\\>($/) {
        my $s := ~$<char>;
        $s := "\\\n" if $s eq "\n";
        make QAST::SVal.new( :node($/), :value($s) );
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

    method param:sym<$>($/) {
        my $scope := $*W.current_scope;
        make $scope[0].push( $<parvar>.made );
    }

    method param:sym<:>($/) {
        my $scope := $*W.current_scope;
        my $decl := $<parvar>.made;
        $decl.named(~$<parvar><name>);
        make $scope[0].push( $decl );
    }

    method parvar($/) {
        my $name := $<sigil> ~ $<name>;
        my $scope := $*W.current_scope;
        $/.CURSOR.panic('duplicated parameter '~$name)
            if $scope.symbol($name);

        my $sym := $scope.symbol($name, :scope<lexical>, :decl<param>);
        make QAST::Var.new(:node($/), :name($name), :decl<param>, :scope<lexical>);
    }

    method definition:sym<def>($/) {
        my $scope := $*W.pop_scope();
        $scope.push( wrap_return_handler($scope, $<def_block>.made) );
        make QAST::Var.new( :name('&'~$scope.name), :scope<lexical> );
    }

    method definition:sym<init>($/) {
        my $scope := $*W.pop_scope;
        $scope.node($/);
        $scope.push( wrap_return_handler($scope, $<statements>.made) );
        $*INIT.push(QAST::Op.new(:op<call>, QAST::BVal.new(:value($scope)),
            QAST::Var.new(:name<@_>, :scope<lexical>, :flat(1)),
            QAST::Var.new(:name<%_>, :scope<lexical>, :flat(1)),
        ));
        make $scope;
    }

    method definition:sym<load>($/) {
        my $scope := $*W.pop_scope;
        $scope.node($/);
        $scope.push( wrap_return_handler($scope, $<statements>.made) );
        $*LOAD.push(QAST::Op.new(:op<call>, QAST::BVal.new(:value($scope)),
            QAST::Var.new(:name<@_>, :scope<lexical>, :flat(1)),
            QAST::Var.new(:name<%_>, :scope<lexical>, :flat(1)),
        ));
        make $scope;
    }

    method definition:sym<class>($/) {
        my $ctor_name := '~ctor';
        my $ctor := $*W.pop_scope;
        my $class := $ctor.ann('package');
        $ctor.name( ~$<name> ~'::'~$ctor_name );
        $ctor[0].push(QAST::Var.new(:name<@_>, :scope<lexical>, :decl<param>, :slurpy(1)));
        $ctor[0].push(QAST::Var.new(:name<%_>, :scope<lexical>, :decl<param>, :slurpy(1), :named(1)));

        my $code := $*W.install_package_routine($class, $ctor_name, $ctor);
        $class.HOW.add_method($class, $ctor_name, $code);

        $*W.pkg_compose($class);
        make $ctor;
    }

    method class_member:sym<method>($/) {
        my $scope := $*W.pop_scope;
        my $meth := $<colon> ?? $*W.pop_scope !! $scope;
        my $ctor := $meth.ann('outer');
        $meth.name( $ctor.ann('class-name')~'::'~$<name> );

        my $class := $ctor.ann('package');

        if $<colon> {
            my $build := $scope;
            $build.name( $meth.name~':rule' );
            $build.push( $<statements>.made );

            my $rulehash := self.class_rule_hash($class, $ctor);

            $meth.push( $build );
            $meth.push( QAST::Op.new( :op<bind>,
                QAST::Var.new( :name<rules>, :scope<local>, :decl<var> ),
                $rulehash,
            ) );
            for $<targets> {
                $meth.push( QAST::Op.new( :op<callmethod>, :name<make>,
                    QAST::Op.new( :op<callmethod>, :name<rule>,
                        QAST::Var.new( :name<rules>, :scope<local> ), $_.made ),
                    QAST::Var.new( :name<me>, :scope<lexical> ),
                ) );
            }

            $ctor.push( self.build_rule_init($/, $build, $rulehash) );
        } else {
            $meth.push( $<statements>.made );
        }

        $ctor.push( $meth );

        my $code := $*W.install_package_routine($class, $meth.name, $meth);
        $class.HOW.add_method($class, ~$<name>, $code);
    }

    method class_member:sym<:>($/) {
        my $build := $*W.pop_scope;
        my $ctor := $build.ann('outer');
        my $class := $ctor.ann('package');
        $build.name( QAST::Node.unique($ctor.ann('class-name')~'::rule') );
        $build.push( $<statements>.made );

        my $rulehash := self.class_rule_hash($class, $ctor);
        $ctor.push( self.build_rule_init($/, $build, $rulehash) );
        $ctor.push( $build );
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

    method class_member:sym<{}>($/) {
        my $scope := pop_newscope($/);
        my $ctor := $scope.ann('outer');
        my $class := $ctor.ann('package');
        $scope.name( QAST::Node.unique($ctor.ann('class-name')~'::~ctor') );
        $ctor.push( QAST::Op.new( :op<call>, $scope ) );
    }

    method class_rule_hash($class, $ctor) {
        my $rulehash := $ctor.ann('~rule');
        unless nqp::defined($rulehash) {
            my $name := '~rules';
            my %lit_args;
            my %obj_args;
            %lit_args<name> := $name;

            my $attr := (%*HOW<attribute>).new(|%lit_args, |%obj_args);
            $class.HOW.add_attribute($class, $attr);

            my $how := QAST::WVal.new( :value(MO::RuleHashHOW) );

            $ctor[0].push( QAST::Op.new( :op<bindattr>,
                QAST::Var.new( :name<me>, :scope<lexical> ),
                QAST::WVal.new( :value($class) ),
                QAST::SVal.new( :value($name) ),
                QAST::Op.new( :op<callmethod>, :name<new_hash>,
                    QAST::WVal.new( :value(MO::RuleHashHOW) ),
                    QAST::SVal.new( :value($class.HOW.name($class)) ) ) ) );

            $rulehash := QAST::Op.new( :op<getattr>,
                QAST::Var.new( :name<me>, :scope<lexical> ),
                QAST::WVal.new( :value($class) ),
                QAST::SVal.new( :value($name) ) );

            $ctor.annotate('~rule', $rulehash);
        }
        $rulehash
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

        my $source;

        if $<externalfile> {
            $source := QAST::Op.new( :op<call>,
                $*W.symbol_ast($/, ['slurp'], 1), $<externalfile>.made,
            );
        } else {
            $source := $<source>.made;
        }

        my $langcode := QAST::Block.new( :node($/), QAST::Stmts.new(
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :name<options>, :scope<local>, :decl<var> ),
                $options,
            ),
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :name<result>, :scope<local>, :decl<var> ),
                QAST::Op.new( :op<call>,
                    QAST::WVal.new(:value($*W.interpreter($langname))),
                    $source, # QAST::Var.new( :name<source>, :scope<local>, :decl<param> ),
                    QAST::Var.new( :name<options>, :scope<local> ),
                )
            ),
        ));

        for $<lang_modifier> {
            $langcode[0].push($_.made) if nqp::defined($_.made);
        }

        $langcode[0].push(QAST::Var.new( :name<result>, :scope<local> ));

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
                QAST::Op.new( :op<takeclosure>, $langcode ),
            ) );

            if $*W.is_export_name($name) {
                $scope[0].push( QAST::Op.new( :node($/), :op<bindkey>,
                    QAST::Op.new( :op<who>, QAST::WVal.new( :value($*EXPORT) ) ),
                    QAST::SVal.new( :value($name) ),
                    QAST::Var.new( :name('&' ~ $name), :scope<lexical> ),
                ) );
            }

            make QAST::Var.new( :name('&' ~ $name), :scope<lexical> );
        } else {
            make QAST::Op.new( :op<call>, QAST::Op.new( :op<takeclosure>, $langcode ) );
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
