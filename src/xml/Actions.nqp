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
            QAST::WVal.new( :value(MO::NodeHOW) ),
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

    method markup_content:sym<tag>($/)     { make $<tag>.made; }
    method markup_content:sym<cdata>($/)   { make $<cdata>.made; }
    method markup_content:sym<content>($/) { make $<content>.made; }

    method tag:sym<start>($/) {
        my $ast;
        my $nodestub := $*W.push_node($/);
        $ast := $nodestub<ast>;

        my $parent := $nodestub<parent>;
        my $prev := $PREV;
        $PREV := $nodestub;

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

        $nodestub<num>  := $num;
        $nodestub<name> := ~$<name>;
        $nodestub<node> := $node;
        $nodestub<node_decl> := $node_decl;

        $ast.push(QAST::Op.new( :op<bind>, $node_decl,
            QAST::Op.new( :op<callmethod>, :name<node_new>, $NODEHOW ),
        ));

        $ast.push(QAST::Op.new( :op<bind>,
            QAST::Var.new( :scope<attribute>, :name(''), $node, $NODETYPE ),
            QAST::SVal.new( :value(~$<name>) ),
        ));

        $ast.push( QAST::Op.new( :op<callmethod>, :name<node_child>, $NODEHOW, $parent<node>, $node ) )
            if $parent;

        if +$<attribute> {
            $ast.push( QAST::Op.new( :op<callmethod>, :name<node_bindattr>, $NODEHOW, $node,
                QAST::SVal.new(:value(~$_<name>)), $_<value>.made )
            ) for $<attribute>;
        }

        if ~$<delimiter> eq '/>' {
            $*W.pop_node();
        }
        make $ast;
    }

    method tag:sym<end>($/) {
        $*W.pop_node();
    }

    method content($/) {
        my $ast;
        my $cur := $*W.current;
        if nqp::defined($cur) {
            $ast := QAST::Op.new( :op<callmethod>, :name<node_concat>,
                $NODEHOW, $cur<node>, QAST::SVal.new( :value(~$/) ) );
        }
        make $ast;
    }

    method value:sym<quote>($/) {
        my $str := nqp::join('', $<quote_EXPR><quote_delimited><quote_atom>);
        make QAST::SVal.new( :node($/), :value($str) );
    }

    method entity($/) {
    }

    method cdata($/) {
    }
}
