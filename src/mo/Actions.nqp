class MO::Actions is HLL::Actions {
    method term:sym<value>($/) { make $<value>.made; $/.prune; }
    method term:sym<name>($/) {
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

    method identifier($/) {
        nqp::say("identifier: "~$/);
        make QAST::Op.new(:op('null'));
    }

    method name($/) {
        nqp::say("name: "~$/);
        make QAST::Op.new(:op('null'));
    }

    method arglist($/) {
        nqp::say("arglist: "~$/);
        make QAST::Op.new(:op('null'));
    }

    method args($/) {
        nqp::say("args: "~$/);
        make QAST::Op.new(:op('null'));
    }

    method TOP($/) {
        nqp::say("TOP");
        make QAST::Op.new(:op('say'), QAST::SVal.new(:value('MO::TOP')));
    }

    method xml($/) {
        my $data := $<data>.made;
        my $test := QAST::Block.new(:node($/), :name('test'), :blocktype('declaration'), QAST::Stmts.new(
            QAST::Op.new(:op('say'), QAST::Var.new(:name('.name'), :scope('lexical'), :returns('string'))),
        ));
        $data.push($test);
        make QAST::Op.new(:op('call'), $data, $test);
    }

    method json($/) {
        make QAST::Op.new(:op('null'));
    }

    method prog($/) {
        nqp::say("prog: ");
        make QAST::Op.new(:op('null'));
    }

    method statements($/) {
        nqp::say("statements: ");
        make QAST::Op.new(:op('null'));
    }

    method statement($/) {
        nqp::say("statement: "~$/);
        make QAST::Op.new(:op('null'));
    }

    method control:sym<for>($/) {
        nqp::say("for: "~$/<expr>);
        make QAST::Op.new(:op('null'));
    }

    method control:sym<if>($/) {
        nqp::say("if: "~$/);
        make QAST::Op.new(:op('null'));
    }

    method code_block($/) {
        nqp::say("code_block");
        make QAST::Op.new(:op('null'));
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
