use QAST;

class moop
{
    my $model;

    method set_root($m) { $model := $m }
    method root() { $model }

    method select($a, $name, $must = 0) { # ->child, parent->child
        my @result;
        if nqp::islist($a) {
            for $a {
                my $children := $_.children($name);
                if nqp::defined($children) {
                    @result.push($_) for $children;
                }
            }
        } elsif nqp::defined($a) {
            if nqp::can($a, 'children') {
                my $children := $a.children($name);
                @result := $children if nqp::defined($children);
            } else {
                nqp::die("$name is not Node, but "~$a.HOW.name($a));
            }
        }
        if $must && +@result < 1 {
            nqp::die("$name is undefined");
        }
        @result;
    }

    method filter($a, $selector) { # ->{ ... }
        my @result;
        if nqp::islist($a) {
            @result.push($_) if !nqp::isnull($_) && $selector($_) for $a;
        } else {
            @result.push($a) if !nqp::isnull($a) && $selector($a);
        }
        @result;
    }

    method any($pred, $data, $block?)
    {
        for $data {
            if nqp::islist($_) {
                my $v := self.any($pred, $_);
                return $v unless nqp::isnull($v);
            } elsif $pred($_) {
                $block($_) if nqp::defined($block);
                return $_;
            }
        }
        nqp::null()
    }

    method many($pred, $data, $block?)
    {
        my @result;
        for $data {
            if nqp::islist($_) {
                @result.push($_) for self.many($pred, $_, $block);
            } elsif $pred($_) {
                $block($_) if nqp::defined($block);
                @result.push($_);
            }
        }
        @result
    }

    method map($pred, $data)
    {
        my @result;
        for $data {
            my $v;
            if nqp::islist($_) {
                @result.push($_) for self.map($pred, $_);
            } elsif nqp::defined($v := $pred($_)) {
                @result.push($v);
            }
        }
        @result
    }
}

my $ops := QAST::Compiler.operations();

$ops.add_hll_op('mo', 'numify', -> $qastcomp, $op {
    $qastcomp.as_post($op[0], :want('n'))
});

$ops.add_hll_op('mo', 'stringify', -> $qastcomp, $op {
    $qastcomp.as_post($op[0], :want('s'))
});

$ops.add_hll_op('mo', 'falsey', -> $qastcomp, $op { # from nqp/src/vm/parrot/NQP/Ops.nqp
    my $res := $*REGALLOC.fresh_i();
    my $ops := PIRT::Ops.new(:result($res));
    my $arg_post := $qastcomp.as_post($op[0]);
    if nqp::lc($qastcomp.infer_type($arg_post.result)) eq 'i' {
        $ops.push($arg_post);
        $ops.push_pirop('not', $res, $arg_post);
    } else {
        $arg_post := $qastcomp.coerce($arg_post, 'P');
        $ops.push($arg_post);
        $ops.push_pirop('isfalse', $res, $arg_post);
    }
    $ops
});

$ops.add_hll_op('mo', 'get', -> $qastcomp, $op {
    my $ast;
    if (nqp::istype($op[0], QAST::Op) && ($op[0].op eq 'select' || $op[0].op eq 'filter' || $op[0].op eq 'list'))
    || (nqp::istype($op[0], QAST::Var) && (nqp::substr($op[0].name, 0, 1) eq '@'))
    {
        my $v := QAST::Var.new( :scope<positional>, $op[0], QAST::IVal.new(:value(0)) );
        $ast := QAST::Op.new( :op<getattr>, $v, $v, $op[1] );
    } else {
        $ast := QAST::Op.new( :op<getattr>, $op[0], $op[0], $op[1] );
    }
    $qastcomp.as_post( $ast );
});

$ops.add_hll_op('mo', 'root', -> $qastcomp, $op {
    #$qastcomp.as_post( QAST::WVal.new( :value(moop.root) ) )
    my $ast := QAST::Op.new( :op<callmethod>, :name<root>,
        QAST::WVal.new( :value(moop) ) );
    $qastcomp.as_post( $ast )
});

$ops.add_hll_op('mo', 'select', -> $qastcomp, $op {
    my $ast := QAST::Op.new( :op<callmethod>, :name<select>,
        QAST::WVal.new( :value(moop) ), $op[0], $op[1] );
    $ast.push( $op[2] ) if nqp::defined($op[2]);
    $qastcomp.as_post( $ast )
});

$ops.add_hll_op('mo', 'filter', -> $qastcomp, $op {
    $qastcomp.as_post(
        QAST::Op.new( :op<callmethod>, :name<filter>,
            QAST::WVal.new( :value(moop) ), $op[0], $op[1] )
    )
});

$ops.add_hll_op('mo', 'poses', -> $qastcomp, $op {
    my $list := QAST::Op.new( :op<list> );
    for $op[1].list {
        $list.push( QAST::Var.new( :scope('positional'), $op[0], $_ ) );
    }
    $qastcomp.as_post( $list );
});

$ops.add_hll_op('mo', 'asses', -> $qastcomp, $op {
    my $list := QAST::Op.new( :op<list> );
    for $op[1].list {
        $list.push( QAST::Var.new( :scope('associative'), $op[0], $_ ) );
    }
    $qastcomp.as_post( $list );
});

$ops.add_hll_op('mo', 'map', -> $qastcomp, $op {
    my $ast := QAST::Op.new( :op<callmethod>, :name<map>,
        QAST::WVal.new( :value(moop) ), $op[0], $op[1] );
    $qastcomp.as_post( $ast )
});

$ops.add_hll_op('mo', 'any', -> $qastcomp, $op {
    my $ast := QAST::Op.new( :op<callmethod>, :name<any>,
        QAST::WVal.new( :value(moop) ), $op[0], $op[1] );
    if nqp::defined($op[2]) {
        $ast.push( $op[2] );
    }
    $qastcomp.as_post( $ast )
});

$ops.add_hll_op('mo', 'many', -> $qastcomp, $op {
    my $ast := QAST::Op.new( :op<callmethod>, :name<many>,
        QAST::WVal.new( :value(moop) ), $op[0], $op[1] );
    if nqp::defined($op[2]) {
        $ast.push( $op[2] );
    }
    $qastcomp.as_post( $ast )
});
