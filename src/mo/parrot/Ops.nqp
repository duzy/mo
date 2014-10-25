use QAST;

class moop
{
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

$ops.add_hll_op('mo', 'dot_name', -> $qastcomp, $op {
    $qastcomp.as_post(
        QAST::Op.new( :op<callmethod>, :name<dot>,
            $op[1], $op[2], $op[0] )
    )
});

$ops.add_hll_op('mo', 'select_name', -> $qastcomp, $op {
    $qastcomp.as_post(
        QAST::Op.new( :op<callmethod>, :name<select_name>,
            $op[1], $op[2], $op[0] )
    )
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
