use QAST;

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
        # $ast := QAST::Var.new( :scope<attribute>, $v, $op[1] );
    } else {
        $ast := QAST::Op.new( :op<getattr>, $op[0], $op[0], $op[1] );
        # $ast := QAST::Var.new( :scope<attribute>, $op[0], $op[1] );
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
