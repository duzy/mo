class MO::Actions is HLL::Actions {
    my $MODEL := QAST::Var.new( :scope<lexical>, :name<MODEL> );

    method term:sym<value>($/) { make $<value>.made; $/.prune; }
    method term:sym<variable>($/) { make $<variable>.made; $/.prune; }
    method term:sym<name>($/) {
        if $<args> {
            my $name := ~$<name>;
            my $op := %MO::Grammar::builtins{$name};
            my $ast := $<args>.made;
            if $op {
                $ast.op($name);
            } else {
                $ast.name($name);
            }
            make $ast;
        } else {
            make QAST::Op.new(:op('call'), :node($/), :name(~$<name>));
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

    method term:sym<yield>($/) {
        make $<statement>.made;
        $/.prune;
    }

    method circumfix:sym<( )>($/) {
        make $<EXPR>.made;
        $/.prune;        
    }

    # method postcircumfix:sym<( )>($/) {
    #     nqp::say("postcircumfix:sym<( )>: "~$/);
    #     make QAST::Op.new(:op('null'));
    #     $/.prune;
    # }

    method postcircumfix:sym<[ ]>($/) {
        make QAST::Var.new( :scope('positional'), $<EXPR>.made );
    }

    method postcircumfix:sym<{ }>($/) {
        make QAST::Var.new( :scope('associative'), $<EXPR>.made );
    }

    method postcircumfix:sym<ang>($/) {
        make QAST::Var.new( :scope('associative'), $<quote_EXPR>.made );
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
        my $scope := $*W.current_scope<block>;
        my $name := $<sigil> ~ $<name>;
        my $var := QAST::Var.new( :name($name), :scope<lexical> );
        my $sym := $scope.symbol($name);
        unless $sym {
            $sym := $scope.symbol($name, :scope<lexical>, :decl<var>);
            $var.decl('var');
        }
        #$var.returns('P');
        make $var;
    }

    method arglist($/) {
        my $ast := QAST::Op.new( :op('call'), :node($/) );
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

    method selector:sym«.»($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<dot>, $MODEL,
            QAST::SVal.new( :value(~$<name>) ),
        );
    }

    method selector:sym«..»($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<dotdot>, $MODEL );
    }

    method selector:sym«->»($/) {
        if $<name> {
            my $name := QAST::SVal.new( :value(~$<name>) );
            make QAST::Op.new( :node($/), :op<callmethod>, :name<select_name>, $MODEL, $name );
        } elsif $<quote> {
            my $path := $<quote>.made;
            make QAST::Op.new( :node($/), :op<callmethod>, :name<select_path>, $MODEL, $path );
        } else {
            make QAST::Op.new( :node($/), :op<callmethod>, :name<select_all>, $MODEL );
        }
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
        my $block := $*W.pop_scope()<block>;
        $block.push( $<newscope>.made );
        make QAST::Op.new( :node($/), :op<callmethod>, :name<filter>, $MODEL, $block );
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

        my $block := $*W.pop_scope()<block>;
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
        make QAST::Op.new( :node($/), :op(~$<op>), $<EXPR>.made, $<statements>.made );
    }

    method control:sym<for>($/) {
        my $scope := $*W.pop_scope()<block>;
        $scope.push( $<newscope>.made );
        make QAST::Op.new( :node($/), :op<for>, $<EXPR>.made, $scope );
    }

    method control:sym<with-1>($/) {
        make QAST::Op.new( :node($/), :op<call>, $<with>.made, $<with><node>.made );
    }

    method control:sym<with-n>($/) {
        make QAST::Op.new( :node($/), :op<for>, $<with><node>.made, $<with>.made );
    }

    method with:sym«->»($/) { make $<with_action>.made; }
    method with:sym«$»($/)  { make $<with_action>.made; }

    method with_action:sym<scope>($/) {
        my $scope := $*W.pop_scope()<block>;
        $scope.push( $<newscope>.made );
        make $scope;
    }

    method with_action:sym<yield>($/) {
        nqp::say('with_action:sym<yield>: '~$/);
    }

    method elsif($/) {
        my $ast := QAST::Op.new( :node($/), :op('if'), $<EXPR>.made, $<statements>.made );
        $ast.push($<else>.made) if $<else>;
        make $ast;
    }

    method else($/) {
        make $<statements>.made;
    }

    method definition:sym<template>($/) {
        my $scope := $*W.pop_scope()<block>;
        #$scope.namespace( ['MO', 'Template'] );
        #$scope.blocktype('declaration_static');
        $scope.name( ~$<name> );
        $scope.push( $<template_body>.made );
        make $scope;
    }

    method template_body($/) {
        my $stmts := QAST::Stmts.new( :node($/) );
        $stmts.push( $_.made ) for $<template_atom>;
        make $stmts;
    }

    method template_atom:sym<()>($/) {
        #nqp::say("template_atom:sym<()>: "~$/);
        make QAST::SVal.new( :node($/), :value(~$/) );
    }

    method template_atom:sym<{}>($/) {
        #nqp::say('template_atom:sym<{}>: '~$/);
        make QAST::SVal.new( :node($/), :value(~$/) );
    }

    method template_atom:sym<.>($/) {
        #nqp::say("template_atom:sym<.>: "~$/);
        make QAST::SVal.new( :node($/), :value(~$/) );
    }
}
