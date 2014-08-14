use QAST;

my $ops := QAST::Compiler.operations();

$ops.add_hll_op('mo', 'numify', -> $qastcomp, $op {
    $qastcomp.as_post($op[0], :want('n'))
});

$ops.add_hll_op('mo', 'stringify', -> $qastcomp, $op {
    $qastcomp.as_post($op[0], :want('s'))
});
