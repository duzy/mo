class MakeFile::Compiler is HLL::Compiler {
}

sub MAIN(@ARGS) {
    my $c := MakeFile::Compiler.new();
    $c.language('MakeFile');
    $c.parsegrammar(MakeFile::Grammar);
    $c.parseactions(MakeFile::Actions);
    $c.command_line(@ARGS, :encoding('utf8'));
}
