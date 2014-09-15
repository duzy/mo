class MO::Actions is HLL::Actions {
    my $MODEL := QAST::Var.new( :scope<lexical>, :name<MODEL> );

    method term:sym<value>($/) { make $<value>.made; $/.prune; }
    method term:sym<variable>($/) { make $<variable>.made; $/.prune; }
    method term:sym<name>($/) {
        my $name := ~$<name>;
        my $op := %MO::Grammar::builtins{$name};
        if $<args> {
            my $ast := $<args>.made;
            if $op {
                $ast.op($op);
            } else {
                my %sym := $*W.find_symbol(['&' ~ $name]);
                if nqp::defined(%sym) {
                    if 0 {
                        $ast.unshift($*W.symbol_ast(%sym, '&' ~ $name, 1));
                    } else {
                        $ast.name('&' ~ $name);
                    }
                } else {
                    $ast.name($name);
                }
            }
            make $ast;
        } elsif $op {
            make QAST::Op.new(:op($op), :node($/));
        } else {
            my %sym := $*W.find_symbol(['&' ~ $name]);
            if nqp::defined(%sym) {
                make QAST::Op.new(:op<call>, :node($/), $*W.symbol_ast(%sym, '&' ~ $name, 1));
            } else {
                make QAST::Op.new(:op<call>, :node($/), :name($name));
            }
        }
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
        my $block := $scope<block>;
        $block[0].push( wrap_return_handler($scope, $<statements>.made) );
        make QAST::Op.new( :node($/), :op<takeclosure>, $block );
        $/.prune;
    }

    method term:sym<yield>($/) {
        make $<statement>.made;
        $/.prune;
    }

    method term:sym<return>($/) {
        my $scope := $*W.current_scope;
        my $block := $scope<block>;
        my $ast := QAST::Op.new( :node($/), :op<call>, :name<RETURN> );
        $scope<returns> := nqp::list() unless +$scope<returns>;
        $scope<returns>.push( $ast );
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
        my $name := $<sigil> ~ $<name>;
        my %sym := $*W.find_symbol([$name]);
        if nqp::defined(%sym) {
            make $*W.symbol_ast(%sym, $name, 1);
        } else {
            my $scope := $*W.current_scope;
            my $block := $scope<block>;
            $block.symbol($name, :scope<lexical>, :decl<var>);
            $block[0].push( QAST::Op.new( :op<bind>, :node($/),
                QAST::Var.new( :name($name), :scope<lexical>, :decl<var> ),
                QAST::Op.new( :op<null> ),
            ) );
            make QAST::Var.new( :node($/), :name($name), :scope<lexical> );
        }
    }

    method arglist($/) {
        my $ast := QAST::Op.new( :op<call>, :node($/) );
        if $<EXPR> {
            my $expr := $<EXPR>.ast;
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

    method args($/) {
        make $<arglist>.made;
    }

    method newscope($/) {
        make $<statements>.made;
    }

    my sub wrap_return_handler($scope, $statements) {
        if +$scope<returns> {
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
        my $block := $scope<block>;
        $block.push( $<newscope>.made );
        make QAST::Op.new( :node($/), :op<callmethod>, :name<filter>, $MODEL,
            QAST::Op.new( :op<takeclosure>, $block ) );
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
                QAST::Op.new( :op<callmethod>, :name<get>,
                    QAST::WVal.new( :value(MO::Model) ),
                ),
            ),
            QAST::Op.new( :op<bind>,
                QAST::Var.new( :name<$>, :scope<lexical>, :decl<var> ),
                QAST::Op.new( :op<callmethod>, :name<root>, $MODEL ),
            ),
        );

        $init.push(self.CTXSAVE());

        my $scope := $*W.pop_scope();
        my $block := $scope<block>;
        $block.unshift( $init );
        $block.push( $<statements>.made );

        my $compunit := QAST::CompUnit.new(
            :hll('mo'),

            $block
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
        my $scope := $*W.current_scope<block>;
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
        my $block := $scope<block>;
        $block.push( $<for_block>.made );
        make QAST::Op.new( :node($/), :op<for>, $<EXPR>.made, $block );
    }

    method control:sym<with>($/) {
        my $scope := $*W.pop_scope();
        my $block := $scope<block>;
        $block.push( $<with_block>.made );
        make QAST::Op.new( :node($/), :op<call>, $block, $<EXPR>.made );
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

    method declaration:sym<use>($/) {
        # my $module := $*W.load_module(~$<name>, $*GLOBALish);
        # if nqp::defined($module) {
        #     $*W.import($module<EXPORT>.WHO<DEFAULT>.WHO)
        #         if nqp::existskey($module, 'EXPORT') &&
        #             nqp::existskey($module<EXPORT>.WHO, 'DEFAULT');
        #     import_HOW_exports($module);
        # }
        my $ast := QAST::Stmts.new( :node($/) );
        my $op := QAST::Op.new(
            :op('callmethod'), :name('load_module'),
            QAST::Op.new( :op('getcurhllsym'),
                QAST::SVal.new( :value('ModuleLoader') ) ),
            QAST::SVal.new( :value(~$<name>) ),
            QAST::Op.new( :op('hash') ),
            # $*W.symbol_lookup(['GLOBAL'], $/),
        );
        $ast.push( $op );
        make $ast;
    }

    method definition:sym<template>($/) {
        my $scope := $*W.pop_scope();
        my $block := $scope<block>;
        #$block.namespace( ['MO', 'Template'] );
        #$block.blocktype('declaration_static');
        $block.name( ~$<name> );
        $block.push( $<template_body>.made );
        make QAST::Op.new( :node($/), :op<takeclosure>, $block );
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
        my $block := $*W.current_scope<block>;
        $/.CURSOR.panic('duplicated parameter '~$name)
            if $block.symbol($name);

        my $sym := $block.symbol($name, :scope<lexical>, :decl<param>);
        make $block[0].push( QAST::Var.new( :node($/), :name($name),
            :decl($sym<decl>), :scope<lexical> ) );
    }

    method definition:sym<def>($/) {
        my $scope := $*W.pop_scope();
        my $block := $scope<block>;
        my $name := ~$<name>;
        $block.name($name);
        $block[0].push( wrap_return_handler($scope, $<def_block>.made) );

        # TODO: using code object (check rakudo or NQP implementations)
        #my $code := QAST::Var.new( :name('&' ~ $name), :scope<lexical> );

        my $outer := $scope<outer><block>;
        $outer.symbol('&' ~ $name, :scope<lexical>, :proto(1), :declared(1) );
        $outer[0].push( QAST::Op.new( :op<bind>,
            QAST::Var.new( :name('&' ~ $name), :scope<lexical>, :decl<var> ),
            $block
        ) );

        make QAST::Var.new( :name('&' ~ $name), :scope<lexical> );
    }

    method definition:sym<class>($/) {
        make QAST::Stmts.new();
    }
}
