use common;

class XML::Actions is HLL::Actions {
    INIT {
    }

    BEGIN {
    }

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

    my %NAMES := nqp::hash();
    method tag($/) {
        my $ast;
        if $<start> {
            $ast := $*W.push_node($/);

            my $num := +%NAMES{~$<name>};
            my $lex := $<name> ~ ($num ?? '~' ~ $num !! '');
            %NAMES{~$<name>} := $num + 1;

            my $node := QAST::Var.new( :name(~$lex), :scope<lexical> );
            my $node_type := QAST::Var.new( :name('NodeType'), :scope('lexical') );
            $ast.push(QAST::Op.new( :op('bind'),
                QAST::Var.new( :name($node.name), :scope<lexical>, :decl<var> ),
                QAST::Op.new( :op('create'), $node_type ), # repr_instance_of
            ));

            $ast<node> := $node;
            $ast<name> := ~$<name>;

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
                    my $str := nqp::join('', $a<value><quote_EXPR><quote_delimited><quote_atom>);
                    my $val := QAST::SVal.new( :value($str) );
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
            $ast := QAST::Op.new( :op('null') );
            $*W.pop_node();
        } else {
            $/.CURSOR.panic("Unexpected tag: "~$<name>);
        }
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
