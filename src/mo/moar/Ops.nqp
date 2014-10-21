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

$ops.add_hll_op('mo', 'falsey', -> $qastcomp, $op { # from nqp/src/vm/moar/NQP/Ops.nqp
    unless $op.list == 1 {
        nqp::die('falsey op requires one child');
    }
    my $val      := $qastcomp.as_mast($op[0]);
    my $regalloc := $*REGALLOC;
    if $val.result_kind == $MVM_reg_int64 {
        my $not_reg := $regalloc.fresh_register($MVM_reg_int64);
        my @ins := $val.instructions;
        push_op(@ins, 'not_i', $not_reg, $val.result_reg);
        MAST::InstructionList.new(@ins, $not_reg, $MVM_reg_int64)
    }
    elsif $val.result_kind == $MVM_reg_num64 {
        my $not_reg := $regalloc.fresh_register($MVM_reg_int64);
        my $ir := $regalloc.fresh_register($MVM_reg_int64);
        my @ins := $val.instructions;
        push_op(@ins, 'set', $ir, $val.result_reg);
        push_op(@ins, 'not_i', $not_reg, $ir);
        MAST::InstructionList.new(@ins, $not_reg, $MVM_reg_int64)
    }
    elsif $val.result_kind == $MVM_reg_obj {
        my $not_reg := $regalloc.fresh_register($MVM_reg_int64);
        my $dc := $regalloc.fresh_register($MVM_reg_obj);
        my @ins := $val.instructions;
        push_op(@ins, 'decont', $dc, $val.result_reg);
        push_op(@ins, 'isfalse', $not_reg, $dc);
        $regalloc.release_register($dc, $MVM_reg_obj);
        MAST::InstructionList.new(@ins, $not_reg, $MVM_reg_int64)
    }
    elsif $val.result_kind == $MVM_reg_str {
        my $not_reg := $regalloc.fresh_register($MVM_reg_int64);
        my @ins := $val.instructions;
        push_op(@ins, 'isfalse_s', $not_reg, $val.result_reg);
        MAST::InstructionList.new(@ins, $not_reg, $MVM_reg_int64)
    }
    else {
        nqp::die("This case of nqp falsey op NYI");
    }
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

sub push_op(@dest, str $op, *@args) {
    nqp::push(@dest, MAST::Op.new_with_operand_array( :$op, @args ));
}
