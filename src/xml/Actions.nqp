use common;

class XML::Actions is HLL::Actions {
    my $NODEHOW := QAST::Var.new( :name<nodehow>, :scope<local> );
    my $NODETYPE := QAST::Var.new( :name<nodetype>, :scope<local> );
    my %NAMES;
    my $PREV;

    method go($/) {
        my $block := QAST::Block.new( :node($/) );
        my $stmts := $block.push( QAST::Stmts.new() );

        $stmts.push(QAST::Op.new( :op<bind>,
            QAST::Var.new( :name($NODEHOW.name), :scope<local>, :decl<var> ),
            QAST::WVal.new( :value(NodeClassHOW) ),
        ));
        $stmts.push(QAST::Op.new( :op<bind>,
            QAST::Var.new( :name($NODETYPE.name), :scope<local>, :decl<var> ),
            QAST::Op.new( :op<callmethod>, :name<type>, $NODEHOW ),
        ));

        if +$<markup_content> {
            for $<markup_content> -> $mc {
                $stmts.push($mc.made) if nqp::defined($mc.made);
            }
        }

        # returns the root node
        $block.push( $*W.root<node> );
        make $block;
    }

    method markup_content($/) {
        my $a;
        if $<tag> {
            $a := $<tag>.made;
        } elsif $<cdata> {
            # ...
        } elsif $<content> {
            $a := $<content>.made;
        } else {
            $/.CURSOR.panic("Unexpected tag: "~$/);
        }
        make $a;
    }

    method tag($/) {
        my $ast;
        if $<start> {
            $ast := $*W.push_node($/);

            my $parent := $ast<parent>;
            my $prev := $PREV;
            $PREV := $ast;

            my $prefix := '';
            my $num := 0;
            if 1 {
                $num := +%NAMES{~$<name>};
                %NAMES{~$<name>} := $num + 1;
            } elsif nqp::defined($parent) {
                $num := +$parent<TAGS>{~$<name>};
                $parent<TAGS>{~$<name>} := $num + 1;
                $prefix := $parent ?? $parent<node>.name~'.' !! '';
            }

            if $num eq 1 && $prev<name> eq ~$<name> {
                ## Rename the first child of the name $<name>
                $prev<node>.name($prefix ~ $<name> ~ '~0');
                $prev<node_decl>.name($prefix ~ $<name> ~ '~0');
            }

            my $lex := $prefix ~ $<name> ~ ($num ?? '~' ~ $num !! '');
            my $node := QAST::Var.new( :name(~$lex), :scope<lexical> );
            my $node_decl := QAST::Var.new( :name($node.name), :scope<lexical>, :decl<var> );
            my $node_type := QAST::Var.new( :name<nodetype>, :scope<local> );

            $ast<num>  := $num;
            $ast<name> := ~$<name>;
            $ast<node> := $node;
            $ast<node_decl> := $node_decl;

            $ast.push(QAST::Op.new( :op<bind>, $node_decl,
                QAST::Op.new( :op<create>, $node_type ), # repr_instance_of
            ));

            $ast.push(QAST::Op.new( :op<bind>,
                QAST::Var.new( :scope<attribute>, :name(''), $node, $node_type ),
                QAST::SVal.new( :value(~$<name>) ),
            ));

            $ast.push( QAST::Op.new( :op<callmethod>, :name<child>, $NODEHOW, $parent<node>, $node ) )
                if $parent;

            if +$<attribute> {
                $ast.push( QAST::Op.new( :op<callmethod>, :name<attr>, $NODEHOW, $node,
                    QAST::SVal.new(:value(~$_<name>)), $_<value>.made )
                ) for $<attribute>;
            }

            if ~$<delimiter> eq '/>' {
                $*W.pop_node();
            }
        } elsif $<end> {
            $*W.pop_node();
        } else {
            $/.CURSOR.panic("Unexpected tag: "~$<name>);
        }
        make $ast;
    }

    method content($/) {
        my $ast;
        my $cur := $*W.current;
        if nqp::defined($cur) {
            $ast := QAST::Op.new( :op<callmethod>, :name<concat>,
                $NODEHOW, $cur<node>, QAST::SVal.new( :value(~$/) ) );
        }
        make $ast;
    }

    method value($/) {
        my $str := nqp::join('', $<quote_EXPR><quote_delimited><quote_atom>);
        make QAST::SVal.new( :node($/), :value($str) );
    }

    method entity($/) {
    }

    method cdata($/) {
    }
}
