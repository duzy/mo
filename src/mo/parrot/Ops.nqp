use QAST;

my $ops := QAST::Compiler.operations();

$ops.add_hll_op('mo', 'numify', -> $qastcomp, $op {
    $qastcomp.as_post($op[0], :want('n'))
});

$ops.add_hll_op('mo', 'stringify', -> $qastcomp, $op {
    $qastcomp.as_post($op[0], :want('s'))
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
