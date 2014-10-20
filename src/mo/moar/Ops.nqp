use QAST;

my $MVM_reg_int64           := 4;
my $MVM_reg_num64           := 6;
my $MVM_reg_str             := 7;
my $MVM_reg_obj             := 8;

my $ops := QAST::MASTCompiler.operations();

$ops.add_hll_op('mo', 'numify', -> $qastcomp, $op {
    $qastcomp.as_mast($op[0], :want($MVM_reg_num64))
});

$ops.add_hll_op('mo', 'stringify', -> $qastcomp, $op {
    $qastcomp.as_mast($op[0], :want($MVM_reg_str))
});

$ops.add_hll_op('mo', 'dot_name', -> $qastcomp, $op {
    $qastcomp.as_mast(
        QAST::Op.new( :node($/), :op<callmethod>, :name<dot>,
            $op[1], $op[2], $op[0] )
    )
});

$ops.add_hll_op('mo', 'select_name', -> $qastcomp, $op {
    $qastcomp.as_mast(
        QAST::Op.new( :node($/), :op<callmethod>, :name<select_name>,
            $op[1], $op[2], $op[0] )
    )
});
