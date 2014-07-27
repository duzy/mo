class MO::Actions is HLL::Actions {
    my $MODEL := QAST::Var.new( :scope<lexical>, :name<MODEL> );

    method term:sym<value>($/) { make $<value>.made; $/.prune; }
    method term:sym<variable>($/) { make $<variable>.made; $/.prune; }
    method term:sym<name>($/) {
        if +$<args> {
            my $name := ~$<name>;
            my $op := %MO::Grammar::builtins{$name};
            my $ast := $<args>[0].made;
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
        my $ast := QAST::Op.new( :op<callmethod>, :name<dot>, $MODEL,
            QAST::SVal.new( :value(~$<name>) ),
        );
        $ast.push( QAST::Var.new( :name<node>, :scope<lexical> ) )
            if $*PARSING_SELECTOR || $*PARSING_WITHDO;
        make $ast;
        $/.prune;
    }

    method term:sym«->»($/) {
        my $ast := QAST::Op.new( :op<callmethod>, :name<arrow>, $MODEL,
            QAST::SVal.new( :value(~$<name>) ),
        );
        $ast.push( QAST::Var.new( :name<node>, :scope<lexical> ) )
            if $*PARSING_SELECTOR || $*PARSING_WITHDO;
        my $sel := $<selector>;
        while +$sel {
            my $nxt := $sel[0].made;
            $nxt.push($ast);
            $ast := $nxt;
            $sel := $sel[0]<selector>;
        }
        make $ast;
        $/.prune;
    }

    method infix:sym<,>($/) {
        make QAST::Op.new(:op('null'));
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
        make $methodcall;
    }

    method postfix:sym«?»($/) {
        make QAST::Op.new( :op<can>, QAST::SVal.new( :value(~$<name>) ) );
    }

    method quote:sym<'>($/) { make $<quote_EXPR>.made; } #'
    method quote:sym<">($/) { make $<quote_EXPR>.made; } #"

    method value($/) {
        make $<quote> ?? $<quote>.made !! $<number>.made;
        $/.prune;
    }

    method number($/) {
        my $value := $<dec_number> ?? $<dec_number>.made !! $<integer>.made;
        if ~$<sign> eq '-' { $value := -$value; }
        make $<dec_number> ??
            QAST::NVal.new( :value($value) ) !!
            QAST::IVal.new( :value($value) );
        $/.prune;
    }

    method variable($/) {
        my $scope := $*W.current_scope();
        my $name := $<sigil> ~ $<name>;
        my $var := QAST::Var.new( :name($name), :scope<lexical> );
        if !$scope.symbol($name) {
            $var.decl('var');
            $scope.symbol($name, :scope<lexical>);
        }
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

    method selector:sym«.»($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<dot>, $MODEL,
            QAST::SVal.new( :value(~$<name>) ),
        );
    }

    method selector:sym«->»($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<arrow>, $MODEL,
            QAST::SVal.new( :value(~$<name>) ),
        );
    }

    method selector:sym<[ ]>($/) {
        make QAST::Op.new( :node($/), :op<callmethod>, :name<at>, $MODEL, $<EXPR>.made );
    }

    method selector:sym<{ }>($/) {
        my $block := $*W.pop_scope();
        $block.push( QAST::Var.new( :name<node>, :scope<lexical>, :decl<param> ) );
        $block.push( $<statements>.made );
        $block.symbol('node', :scope<lexical>);
        make QAST::Op.new( :node($/), :op<callmethod>, :name<query>, $MODEL, $block );
    }

    method xml($/) {
        my $data := $<data>.made;
        make QAST::Stmts.new(
            QAST::Op.new( :op('callmethod'), :name('init'),
                QAST::WVal.new( :value(MO::Model) ),
                QAST::Op.new( :op('call'), QAST::BVal.new( :value($data) ) ),
            ),
            $data
        );
    }

    method json($/) {
        make QAST::Op.new(:op('null'));
    }

    method prog($/) {
        my $block := $*W.pop_scope();
        $block.push( QAST::Op.new( :op<bind>,
            QAST::Var.new( :scope<lexical>, :decl<var>, :name($MODEL.name) ),
            QAST::Op.new( :op<callmethod>, :name<get>,
                QAST::WVal.new( :value(MO::Model) ),
            ),
        ) );
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

    method statement($/) {
        if $<control> {
            make $<control>.made;
        } elsif $<EXPR> {
            make $<EXPR>.made;
        } else {
            make QAST::Op.new(:op('null'));
        }
    }

    method control:sym<cond>($/) {
        my $ast := QAST::Op.new( :node($/), :op(~$<op>), $<EXPR>.made, $<statements>.made );
        $ast.push($<else>.made) if $<else>;
        make $ast;
    }

    method control:sym<loop>($/) {
        make QAST::Op.new( :node($/), :op(~$<op>), $<EXPR>.made, $<statements>.made );
    }

    method control:sym<with>($/) {
        my $block := $*W.pop_scope();
        $block.push( QAST::Var.new( :name<node>, :scope<lexical>, :decl<param> ) );
        $block.push( $<statements>.made );
        $block.symbol('node', :scope<lexical>);
        make QAST::Op.new( :node($/), :op<call>, $block, $<EXPR>.made );
    }

    method elsif($/) {
        my $ast := QAST::Op.new( :node($/), :op('if'), $<EXPR>.made, $<statements>.made );
        $ast.push($<else>.made) if $<else>;
        make $ast;
    }

    method else($/) {
        make $<statements>.made;
    }

    method template_definition($/) {
        nqp::say("template_definition");
        make QAST::Op.new(:op('null'));
    }

    method template_block($/) {
        nqp::say("template_block");
        make QAST::Op.new(:op('null'));
    }

    method template_body($/) {
        nqp::say("template_body");
        make QAST::Op.new(:op('null'));
    }
}
