class XML::Actions is HLL::Actions {
    INIT {
    }

    BEGIN {
        #my $*NODE_TYPE := nqp::newtype('node', 'HashAttrStore');
    }

    method go($/) {
        my $block := QAST::Block.new( :node($/) );
        my $stmts := $block.push( QAST::Stmts.new() );
        # if $<markup_content> {
        #     for $<markup_content> -> $mc {
        #         my $ast := QAST::Op.new( :op('call'), $mc.ast );
        #         if $ast {
        #             $stmts.push($ast);
        #         }
        #     }
        # }

        # if $*W.root {
        #     my $test := QAST::Block.new(
        #         :node($*W.root.node()), :blocktype('declaration'),
        #         QAST::Stmts.new(
        #             QAST::Op.new(:op('say'), QAST::Var.new(:name('.count'), :scope('lexical'), :returns('string'))),
        #             #QAST::Op.new(:op('say'), QAST::Var.new(:name('node'), :scope('lexical'))),
        #         ));
        #     $*W.root.push($test);
        #     $stmts.push(QAST::Op.new( :op('call'), $*W.root, $test ));
        # }

        $stmts.push(QAST::Op.new( :op('call'), $*W.root,
            QAST::Var.new(:name('@'), :scope('local'), :decl('param'))));
        make $block;
    }

    method declaration($/) {
        make QAST::Op.new( :op('null') );
    }

    method declaration_info($/) {
        make QAST::Op.new( :op('null') );
    }

    method markup_content($/) {
        my $a;
        if $<tag> {
            $a := $<tag>.ast;
        } elsif $<cdata> {
            $a := QAST::Op.new( :op('null') );
        } elsif $<content> {
            $a := QAST::Op.new( :op('null') );
        } else {
            $/.CURSOR.panic("Unexpected tag: "~$/);
        }
        make $a;
    }

    method tag($/) {
        my $ast;
        if $<start> {
            $ast := $*W.push_datascope($/);
            #$ast.blocktype('immediate');
            #$ast.blocktype('decl');

            my $stmts := $ast[0];
            #$stmts.push( QAST::Op.new( :op('say'), QAST::SVal.new(:value(~$<name>)) ) );

            if $<attribute> {
                for $<attribute> -> $a {
                    my $s := nqp::join('', $a<value><quote_EXPR><quote_delimited><quote_atom>);
                    $stmts.push( QAST::Op.new(:op('bind'), $a.ast,
                        QAST::SVal.new(:value($s)) ) );
                    #$stmts.push( QAST::Op.new( :op('say'),
                    #    QAST::Var.new(:name('.'~$a<name>), :scope('lexical')) ) );
                }
            }

            if ~$<delimiter> eq '/>' {
                $*W.pop_datascope();
            }
        } elsif $<end> {
            $ast := QAST::Op.new( :op('null') );
            $*W.pop_datascope();
        } else {
            $/.CURSOR.panic("Unexpected tag: "~$<name>);
        }
        make $ast;
    }

    method attribute($/) {
        my $name := '.' ~ $<name>;
        my $ast := QAST::Var.new( :node($/), :name($name), :scope('lexical'), :decl('var'), :returns('string') );
        make $ast;
    }

    method entity($/) {
        make QAST::Op.new( :op('null') );
    }

    method content($/) {
        make QAST::Op.new( :op('null') );
    }

    method name($/) {
        make QAST::Op.new( :op('null') );
    }

    method value($/) {
        make QAST::Op.new( :op('null') );
    }
}
