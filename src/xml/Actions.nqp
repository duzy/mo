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
            $a := $<tag>.made;
        } elsif $<cdata> {
            $a := QAST::Op.new( :op('null') );
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
            my $node_type := QAST::Var.new( :name('NodeType'), :scope('lexical') );

            $ast<num>  := $num;
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

            $ast<*>.push( $node );
            $ast<*>.push( $node_type );
            $ast<.*>.push( $node );
            $ast<.*>.push( $node_type );

            if $parent {
                my $attr := QAST::Var.new( :scope('attribute'), :name($<name>),
                    $parent<node>, $node_type );
                $ast.push(QAST::Op.new( :op('ifnull'), $attr,
                    QAST::Op.new( :op('bind'), $attr, QAST::Op.new( :op('list') ) ),
                ));
                $ast.push( QAST::Op.new( :op('callmethod'), :name('push'), $attr, $node ) );

                my $all := $parent<*>;
                $ast.push(QAST::Op.new( :op('ifnull'), $all,
                    QAST::Op.new( :op('bind'), $all, QAST::Op.new( :op('list') ) ),
                ));
                $ast.push( QAST::Op.new( :op('callmethod'), :name('push'), $all, $node ) );
            }

            if +$<attribute> {
                my $all := $ast<.*>;
                $ast.push(QAST::Op.new( :op('ifnull'), $all,
                    QAST::Op.new( :op('bind'), $all, QAST::Op.new( :op('list') ) ),
                ));
                for $<attribute> -> $a {
                    my $val := $a<value>.made;
                    my $attr := QAST::Var.new( :node($/), :scope('attribute'),
                        :name('.' ~ $a<name>), $node, $node_type );
                    $ast.push( QAST::Op.new(:op('bind'), $attr, $val ) ); # repr_bind_attr_obj
                    $ast.push( QAST::Op.new( :op('callmethod'), :name('push'), $all,
                        QAST::Op.new(:op('list'), QAST::SVal.new(:value($a<name>)), $attr) ) );
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

    method content($/) {
        my $ast;
        my $cur := $*W.current;
        if nqp::defined($cur) {
            my $all := $cur<*>;
            $ast := QAST::Stmts.new( :node($/),
                QAST::Op.new( :op('ifnull'), $all,
                    QAST::Op.new( :op('bind'), $all, QAST::Op.new( :op('list') ) ),
                ),
                QAST::Op.new( :op('callmethod'), :name('push'), $all,
                    QAST::SVal.new( :value(~$/) ),
                ),
            );
        } else {
            $ast := QAST::Op.new( :node($/), :op('null') );
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
