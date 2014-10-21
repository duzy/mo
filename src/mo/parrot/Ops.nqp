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

$ops.add_hll_op('mo', 'dot_name', -> $qastcomp, $op {
    $qastcomp.as_post(
        QAST::Op.new( :node($/), :op<callmethod>, :name<dot>,
            $op[1], $op[2], $op[0] )
    )
});

$ops.add_hll_op('mo', 'select_name', -> $qastcomp, $op {
    $qastcomp.as_post(
        QAST::Op.new( :node($/), :op<callmethod>, :name<select_name>,
            $op[1], $op[2], $op[0] )
    )
});
