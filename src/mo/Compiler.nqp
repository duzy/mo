class MO::Compiler is HLL::Compiler {
}

my $mocomp := MO::Compiler.new();
$mocomp.language('mo');
$mocomp.parsegrammar(MO::Grammar);
$mocomp.parseactions(MO::Actions);

#nqp::say(~%*COMPILING<%?OPTIONS>);

sub MAIN(*@ARGS) {
    for @ARGS {
        nqp::say("arg: "~$_);
    }
    $mocomp.command_line(@ARGS, :encoding('utf8'));
}
