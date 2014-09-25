class MO::Actions is HLL::Actions {
    my $MODEL := QAST::Var.new( :scope<lexical>, :name<MODEL> );

    method term:sym<value>($/) { make $<value>.made; $/.prune; }
    method term:sym<variable>($/) { make $<variable>.made; $/.prune; }
    method term:sym<name>($/) {
        my @name := nqp::split('::', ~$<name>);
        make $*W.symbol_ast($/, @name);
        $/.prune;
    }

    method term:sym«.»($/) {
        my $ast := $<selector>.made;
        $ast.push( QAST::Var.new( :name<$>, :scope<lexical> ) );
        make $ast;
        $/.prune;
    }

    my sub next_selector($sel) {
        my $a := $sel<arrow_consequence>;
        $a ?? $a<selector> !! $sel<selector>;
    }

    method term:sym«->»($/) {
        my $sel := $<selector>;
        my $ast := $sel.made;
        $ast.push( QAST::Var.new( :name<$>, :scope<lexical> ) );

        ## Chain all selectors
        $sel := next_selector($sel); #$sel<selector>;
        while $sel {
            my $nxt := $sel.made;
            $nxt.push($ast);
            $ast := $nxt;
            $sel := next_selector($sel); #$sel<selector>;
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

    method term:sym<yield>($/) {
        make $<statement>.made;
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

    method circumfix:sym<( )>($/) {
        make $<EXPR>.made;
        $/.prune;        
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
        my $methodcall;
        if $<args> {
            $methodcall := $<args>.made;
            $methodcall.op('callmethod');
            $methodcall.name(~$<name>);
        } else {
            $methodcall := QAST::Op.new( :op<callmethod>, :name(~$<name>) );
        }
        #$methodcall.returns('P');
        make $methodcall;
    }

    method postfix:sym«?»($/) {
        make QAST::Op.new( :op<can>, QAST::SVal.new( :value(~$<name>) ) );
    }

    method value:sym<quote>($/) { make $<quote>.made; }
    method value:sym<number>($/) { make $<number>.made; }

    method quote:sym<'>($/) { make $<quote_EXPR>.made; } #'
    method quote:sym<">($/) { make $<quote_EXPR>.made; } #"

    method number($/) {
        my $value := $<dec_number> ?? $<dec_number>.made !! $<integer>.made;
        if ~$<sign> eq '-' { $value := -$value; }
        make $<dec_number> ??
            QAST::NVal.new( :value($value) ) !!
            QAST::IVal.new( :value($value) );
    }

    method variable($/) {
        unless $<name> {
            make $*W.symbol_ast($/, [ ~$<sigil> ]);
            return;
        }

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
            # null
        } elsif $*IN_DECL eq 'member' {
            # null
        } elsif ~$<twigil> eq '.' {
            my $class := $*PACKAGE;
            my $attr := $class.HOW.find_attribute($class, $name);
            unless nqp::defined($attr) {
                $/.CURSOR.panic(($class.HOW).name($class)~' has no attribute '~$name);
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

    method selector:sym«.»($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<dot>, $MODEL,
            QAST::SVal.new( :value(~$<name>) ),
        );
    }

    method selector:sym«..»($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<dotdot>, $MODEL );
    }

    method selector:sym«->»($/) {
        make $<select>.made;
    }

    method selector:sym<[ ]>($/) {
        my $expr := $<EXPR>.made;
        my $ast := QAST::Op.new( :node($/), :op<callmethod>, $MODEL, $expr );
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
        my $scope := $*W.pop_scope();
        $scope.push( $<newscope>.made );
        make QAST::Op.new( :node($/), :op<callmethod>, :name<filter>, $MODEL,
            QAST::Op.new( :op<takeclosure>, $scope ) );
    }

    method select:sym<name>($/) {
        my $name := QAST::SVal.new( :value(~$<name>) );
        make QAST::Op.new( :node($/), :op<callmethod>, :name<select_name>, $MODEL, $name );
    }

    method select:sym<quote>($/) {
        my $path := $<quote>.made;
        make QAST::Op.new( :node($/), :op<callmethod>, :name<select_path>, $MODEL, $path );
    }

    method select:sym<[>($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<select_all>, $MODEL );
    }

    method xml($/) {
        my $data := $<data>.made;
        make QAST::Stmts.new(
            QAST::Op.new( :op<callmethod>, :name<init>,
                QAST::WVal.new( :value(MO::Model) ),
                QAST::Op.new( :op<call>, QAST::BVal.new( :value($data) ) ),
            ),
            $data
        );
    }

    method json($/) {
        make QAST::Op.new(:op('null'));
    }

    method prog($/) {
        my $init := QAST::Stmts.new(
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :scope<lexical>, :decl<var>, :name($MODEL.name) ),
                QAST::Op.new( :op<getcurhllsym>, QAST::SVal.new( :value<MODEL> ) ),
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
                QAST::Var.new( :name<$>, :scope<lexical>, :decl<var> ),
                QAST::Op.new( :op<callmethod>, :name<root>, $MODEL ),
            ),
        );

        $init.push(self.CTXSAVE());

        $*W.install_fixups();

        my $scope := $*W.pop_scope();
        $scope.unshift( $init );
        $scope.push( $<statements>.made );

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

            :main(QAST::Op.new(:op<call>, QAST::BVal.new( :value($scope) ))),

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
        if $scope.symbol('$') {
            $ast.push( QAST::Var.new( :name<$>, :scope<lexical> ) );
        } else {
            $ast.push( QAST::Op.new( :op<callmethod>, :name<root>, $MODEL ) );
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
        my $scope := $*W.pop_scope();
        $scope.push( $<for_block>.made );
        make QAST::Op.new( :node($/), :op<for>, $<EXPR>.made, $scope );
    }

    method control:sym<with>($/) {
        my $scope := $*W.pop_scope();
        $scope.push( $<with_block>.made );
        make QAST::Op.new( :node($/), :op<call>, $scope, $<EXPR>.made );
    }

    method else:sym< >($/) { make $<statements>.made; }
    method else:sym<if>($/) {
        my $ast := QAST::Op.new( :node($/), :op('if'), $<EXPR>.made, $<statements>.made );
        $ast.push($<else>.made) if $<else>;
        make $ast;
    }

    method loop_block:sym<{ }>($/) { make $<newscope>.made; }
    method loop_block:sym<end>($/) { make $<newscope>.made; }

    method for_block:sym<{ }>($/) { make $<newscope>.made; }
    method for_block:sym<end>($/) { make $<newscope>.made; }

    method with_block:sym<{ }>($/) { make $<newscope>.made; }
    method with_block:sym<end>($/) { make $<newscope>.made; }
    method with_block:sym<yield>($/) {
        make QAST.Op.new( :node($/), :op<say>,
            QAST.SVal.new( :value('with_block:sym<yield>: '~$/) ) );
    }

    method def_block:sym<{ }>($/) { make $<statements>.made; }
    method def_block:sym<end>($/) { make $<statements>.made; }

    method declaration:sym<var>($/) {
        unless $<variable><name> {
            $/.CURSOR.panic('variable $ already defined');
        }

        my @name := nqp::split('::', ~$<variable><name>);
        my $final_name := @name.pop;
        my $name := ~$<variable><sigil> ~ $final_name;

        my $who;
        if +@name {
            $who := $*W.symbol_ast($/, @name, 1);
        } elsif $*W.is_export_name($final_name) {
            $who := QAST::Var.new( :name<EXPORT.WHO>, :scope<lexical> );
        }

        my $scope := $*W.current_scope;
        my $initializer := $<initializer> ?? $<initializer>.made
            !! QAST::Op.new( :op<null> );

        if nqp::defined($who) {
            $scope[0].push( QAST::Op.new( :op<bindkey>, $who,
                QAST::SVal.new( :value($name) ), $initializer ) );
            make QAST::Var.new( :node($/), :scope<associative>,
                $who, QAST::SVal.new( :value($name) ) );
        } elsif +@name == 0 {
            # $scope.symbol( $name, :scope<lexical>, :decl<var> );
            # $scope[0].push( QAST::Op.new( :op<bind>, :node($/),
            #     QAST::Var.new( :name($name), :scope<lexical>, :decl<var> ),
            #     $initializer ) );
            # make QAST::Var.new( :node($/), :name($name), :scope<lexical> );

            # TODO: need a replacement for this 'attribute' approach!
            my $var := $*W.install_variable(:$name);
            my $ast := QAST::Var.new( :node($/), :name('$!value'), :scope<attribute>,
                QAST::WVal.new( :value($var) ), QAST::WVal.new( :value(MO::Variable) ) );
            $scope.symbol( $name, :scope<lexical>, :$ast );
            make QAST::Stmts.new(
                QAST::Op.new( :op<bindattr>, :node($/),
                    QAST::WVal.new( :value($var) ), QAST::WVal.new( :value(MO::Variable) ),
                    QAST::SVal.new( :value('$!value') ), $initializer ),
                $ast );
        } else {
            $/.CURSOR.panic('undefined '~$/);
        }
    }

    method declaration:sym<use>($/) {
        my $module := $*W.load_module($/, ~$<name>, $*GLOBALish);
        make QAST::Stmts.new( :node($/) );
    }

    method definition:sym<template>($/) {
        my $scope := $*W.pop_scope();
        #$scope.namespace( ['MO', 'Template'] );
        #$scope.blocktype('declaration_static');
        $scope.name( ~$<name> );
        $scope.push( $<template_body>.made );
        make QAST::Op.new( :node($/), :op<takeclosure>, $scope );
    }

    method template_body($/) {
        my $stmts := QAST::Stmts.new( :node($/) );
        $stmts.push( $_.made ) for $<template_atom>;
        make $stmts;
    }

    method template_atom:sym<()>($/) {
        make QAST::SVal.new( :node($/), :value(~$/) );
    }

    method template_atom:sym<{}>($/) {
        make QAST::SVal.new( :node($/), :value(~$/) );
    }

    method template_atom:sym<.>($/) {
        make QAST::SVal.new( :node($/), :value(~$/) );
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
        my $scope := $*W.pop_scope();
        my $name := ~$<name>;
        $scope.name($name);
        $scope[0].push( wrap_return_handler($scope, $<def_block>.made) );

        my $outer := $scope.ann('outer');
        $outer.symbol('&' ~ $name, :scope<lexical>, :proto(1), :declared(1) );
        $outer[0].push( QAST::Op.new( :op<bind>,
            QAST::Var.new( :name('&' ~ $name), :scope<lexical>, :decl<var> ),
            $scope
        ) );

        $*W.install_package_routine($*PACKAGE, $name, $scope);

        if $*W.is_export_name($name) {
            $outer[0].push( QAST::Op.new( :op<bind>,
                QAST::Var.new( :node($/), :scope<associative>,
                    QAST::Var.new( :name<EXPORT.WHO>, :scope<lexical> ),
                    QAST::SVal.new( :value($name) ) ),
                QAST::Var.new( :name('&' ~ $name), :scope<lexical> ),
            ) );
        }

        make QAST::Var.new( :name('&' ~ $name), :scope<lexical> );
    }

    method definition:sym<class>($/) {
        my $ctor_name := '~ctor';
        my $ctor := $*W.pop_scope;
        my $class := $ctor.ann('class');
        $ctor.name( ~$<name> ~'::'~$ctor_name );

        my $code := $*W.install_package_routine($class, $ctor_name, $ctor);
        $class.HOW.add_method($class, $ctor_name, $code);

        $*W.pkg_compose($class);
        make $ctor;
    }

    method class_member:sym<method>($/) {
        my $scope := $*W.pop_scope;
        my $ctor := $scope.ann('outer');
        my $class := $ctor.ann('class');
        $scope.push( $<statements>.made );
        $scope.name( ~$<name> );
        $ctor[0].push($scope);

        my $code := $*W.install_package_routine($class, $scope.name, $scope);
        $class.HOW.add_method($class, $scope.name, $code);
    }

    method class_member:sym<$>($/) {
        my $sigil := ~$<variable><sigil>;
        my $twigil := ~$<variable><twigil>;
        my $ctor := $*W.current_scope;
        my $class := $ctor.ann('class');
        if ~$twigil eq '.' {
            my $name := ~$<variable>;
            my %lit_args;
            my %obj_args;
            %lit_args<name> := $name;

            my $attr := (%*HOW<attribute>).new(|%lit_args, |%obj_args);
            $class.HOW.add_attribute($class, $attr);

            if $<initializer> {
                $ctor[0].push( QAST::Op.new( :node($/), :op<bindattr>,
                    QAST::Var.new( :name<me>, :scope<lexical> ),
                    QAST::WVal.new( :value($class) ),
                    QAST::SVal.new( :value($name) ),
                    $<initializer>.made ) );
            }
        } else {
            
        }
    }
}
