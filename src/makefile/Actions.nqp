class MakeFile::Actions is HLL::Actions {
    sub trim_left($s) {
        my int $n := nqp::chars($s);
        my int $a := nqp::findnotcclass(nqp::const::CCLASS_WHITESPACE, $s, 0, $n);
        nqp::substr($s, $a, $n)
    }

    sub trim($s) {
        my int $n := nqp::chars($s);
        my int $a := nqp::findnotcclass(nqp::const::CCLASS_WHITESPACE, $s, 0, $n);
        while $a < $n && nqp::iscclass(nqp::const::CCLASS_WHITESPACE, $s, $n-1) { $n := $n-1 }
        nqp::substr($s, $a, $n)
    }

    sub expend($text_ast) {
        my $text := '';
        if $text_ast<text_atom> {
            for $text_ast<text_atom> {
                if $_<expandable> {
                    $text := $text ~ value($_<expandable>);
                } elsif $_<quote> {
                    my $str := nqp::join('', $_<quote><quote_EXPR><quote_delimited><quote_atom>);
                    $text := $text ~ $str;
                } else {
                    $text := $text ~ ~$_;
                }
            }
        } else {
            $text := ~$text_ast;
        }
        $text
    }

    sub value($ast) {
        my $scope := $*SCOPE;
        my $name;
        if $ast<nameargs> {
            $name := $ast<nameargs><name>;
        } elsif $ast<name> {
            $name := $ast<name>;
        } else {
            nqp::die("unknown ast "~$ast);
        }

        my %sym := $scope.symbol(expend($name));
        #unless %sym { nqp::die("no value for "~$name) }
        #%sym<value>
        %sym ?? %sym<value> !! ''
    }

    method go($/) {
        my $block := $*SCOPE;
        my $stmts := $block.push( QAST::Stmts.new( :node($/) ) );
        $stmts.push($_.made) for $<statement>;

        my $compunit := QAST::CompUnit.new(
            :hll('MakeFile'),

            # Serialization related bits.
            :sc($*W.sc()),
            :code_ref_blocks($*W.code_ref_blocks()),
            :compilation_mode($*W.is_precompilation_mode()),
            :pre_deserialize($*W.load_dependency_tasks()),
            :post_deserialize($*W.fixup_tasks()),
            #:repo_conflict_resolver(),

            # If this unit is loaded as a module, we want it to automatically
            # execute the mainline code above after all other initializations
            # have occurred.
            :load(QAST::Stmts.new(
                 QAST::Op.new( :op<call>, QAST::BVal.new( :value($block) ) ),
            )),

            :main(QAST::Stmts.new(
                 QAST::Var.new( :name<ARGS>, :scope<local>, :decl<param>, :slurpy(1) ),
                 QAST::Op.new( :op<call>, QAST::BVal.new( :value($block) ),
                     QAST::Var.new( :name<ARGS>, :scope<local>, :flat(1) ),
                 ),
            )),

            # Finally, the outer block, which in turn contains all of the
            # other program elements.
            $block
        );

        make $compunit;
    }

    method statement:sym<assign>($/) {
        my $scope := $*SCOPE;
        my $name := expend($<name>);
        my $value := trim_left(~$<value>);

        $scope.symbol($name, :$value, :value_ast($<value>), :source(~$<equal>));

        make QAST::Op.new( :node($<equal>), :op<bind>,
            QAST::Var.new( :decl<var>, :scope<lexical>, :$name ),
            QAST::SVal.new( :$value ),
        );
    }

    method statement:sym<:>($/) {
        make QAST::Stmts.new(:node($/));
    }

    method statement:sym<$>($/) {
        make $<expandable>.made;
    }

    method text_atom:sym<$>($/) {
        make $<expandable>.made;
    }

    method text_atom:sym<q>($/) {
        make $<quote>.made;
    }

    method text_atom:sym<.>($/) {
        make QAST::SVal.new( :value(~$/) );
    }

    #method quote:sym<'>($/) { make $<quote_EXPR>.made; } #'
    #method quote:sym<">($/) { make $<quote_EXPR>.made; } #"

    method expandable:sym<$()>($/) { make $<nameargs>.made }
    method expandable:sym<${}>($/) { make $<nameargs>.made }
    method expandable:sym<$>($/) { self.nameargs($/) }

    method nameargs($/) {
        my $name := expend($<name>);
        if $<args> && nqp::can(MakeFile::Builtin, $name) {
            my $ast := $<args>.made;
            $ast.name($name);
            make $ast;
        } else {
            make QAST::Var.new( :decl<var>, :scope<lexical>, :$name );
        }
    }

    method args($/) {
        my $ast := QAST::Op.new(:op<callmethod>, :node($/), QAST::WVal.new(:value(MakeFile::Builtin)));
        if +$<text> {
            $ast.push(QAST::SVal.new(:value(expend($_)))) for $<text>;
        } else {
            $ast.push(QAST::SVal.new(:value(expend($<text>))));
        }
        make $ast;
    }

    method rule ($/) {
        make QAST::SVal.new( :value(~$/) );
    }
}
