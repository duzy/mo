class MO::Actions is HLL::Actions {
    method term:sym<value>($/) { make $<value>.made; $/.prune; }
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

    method term:sym«.»($/)  {
        nqp::say('term:sym«.»: '~$/);
        #my $var := QAST::Var.new( :node($<name>), :name() );
        #make QAST::Op.new(:op('bind'));
        make QAST::SVal.new(:value('TODO: '~$<name>));
        $/.prune;        
    }

    method term:sym«->»($/) {
        nqp::say('term:sym«->»: '~$/);
        make QAST::Op.new(:op('null'));
        $/.prune;        
    }

    method infix:sym<,>($/) {
        make QAST::Op.new(:op('null'));
        $/.prune;        
    }

    method postcircumfix:sym<( )>($/) {
        nqp::say("postcircumfix:sym<( )>: "~$/);
        make QAST::Op.new(:op('null'));
        $/.prune;
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

    # method identifier($/) {
    #     make QAST::Op.new(:op('null'));
    # }

    # method name($/) {
    #     make QAST::Op.new(:op('null'));
    # }

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

    method xml($/) {
        my $data := $<data>.made;
        my $test := QAST::Block.new(:node($/), :name('test'), :blocktype('declaration'), QAST::Stmts.new(
            #QAST::Op.new(:op('say'), QAST::Var.new(:name('.name'), :scope('lexical'), :returns('string'))),
        ));
        $data.push($test);
        make QAST::Op.new(:op('call'), $data, $test);
    }

    method json($/) {
        make QAST::Op.new(:op('null'));
    }

    method prog($/) {
        #make QAST::Op.new(:op('say'), QAST::SVal.new(:value('prog')));
        make QAST::Block.new(
            $<statements>.made
        );
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
