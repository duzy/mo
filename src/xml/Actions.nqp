use common;

class XML::Actions is HLL::Actions {
    my %NAMES;
    my $PREV;

    method go($/) {
        my $block := QAST::Block.new( :node($/) );
        my $stmts := $block.push( QAST::Stmts.new() );

        my $node_type := QAST::Op.new( :op('callmethod'), :name('new_type'),
            QAST::WVal.new( :value(NodeClassHOW) ),
            QAST::SVal.new( :value('Node'), :named('name') ),
        );

        $stmts.push(QAST::Op.new( :op('bind'),
            QAST::Var.new( :name('NodeType'), :scope('lexical'), :decl('var') ),
            $node_type,
        ));

        if +$<markup_content> {
            for $<markup_content> -> $mc {
                $stmts.push($mc.made);
            }
        }

        # returns the root node
        $block.push( $*W.root<node> );
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
            $ast := $*W.push_node($/);

            my $prev := $PREV;
            $PREV := $ast;

            my $num := +%NAMES{~$<name>};
            %NAMES{~$<name>} := $num + 1;

            if $num eq 1 && $prev<node>.name eq ~$<name> {
                ## Rename the first child of the name $<name>
                $prev<node>.name($<name> ~ '~0');
                $prev<node_decl>.name($<name> ~ '~0');
            }

            my $lex := $<name> ~ ($num ?? '~' ~ $num !! '');
            my $node := QAST::Var.new( :name(~$lex), :scope<lexical> );
            my $node_decl := QAST::Var.new( :name($node.name), :scope<lexical>, :decl<var> );
            my $node_type := QAST::Var.new( :name('NodeType'), :scope('lexical') );

            $ast<name> := ~$<name>;
            $ast<node> := $node;
            $ast<node_decl> := $node_decl;

            $ast.push(QAST::Op.new( :op('bind'), $node_decl,
                QAST::Op.new( :op('create'), $node_type ), # repr_instance_of
            ));

            $ast.push(QAST::Op.new( :op('bind'),
                QAST::Var.new( :scope('attribute'), :name(''), $node, $node_type ),
                QAST::SVal.new( :value(~$<name>) ),
            ));

            my $parent := $ast<parent>;
            if $parent {
                my $attr := QAST::Var.new( :scope('attribute'), :name($<name>),
                    $parent<node>, $node_type );
                $ast.push(QAST::Op.new( :op('ifnull'), $attr,
                    QAST::Op.new( :op('bind'), $attr, QAST::Op.new( :op('list') ) ),
                ));
                $ast.push( QAST::Op.new( :op('callmethod'), :name('push'), $attr, $node ) );
            }

            if +$<attribute> {
                for $<attribute> -> $a {
                    my $val := $a<value>.made;
                    my $attr := QAST::Var.new( :node($/), :scope('attribute'),
                        :name('.' ~ $a<name>), $node, $node_type );
                    $ast.push( QAST::Op.new(:op('bind'), $attr, $val ) ); # repr_bind_attr_obj
                    #$ast.push( QAST::Op.new(:op('say'), $attr ) ); # repr_get_attr_obj
                }
            }

            if ~$<delimiter> eq '/>' {
                $*W.pop_node();
            }
        } elsif $<end> {
            $*W.pop_node();
            $ast := QAST::Op.new( :node($/), :op('null') );
        } else {
            $/.CURSOR.panic("Unexpected tag: "~$<name>);
        }
        make $ast;
    }

    method value($/) {
        my $str := nqp::join('', $<quote_EXPR><quote_delimited><quote_atom>);
        make QAST::SVal.new( :node($/), :value($str) );
    }
}
