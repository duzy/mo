class XML::Compiler is HLL::Compiler {
}

sub MAIN(@ARGS) {
    my $xmlc := XML::Compiler.new();
    $xmlc.language('xml');
    $xmlc.parsegrammar(XML::Grammar);
    $xmlc.parseactions(XML::Actions);
    $xmlc.command_line(@ARGS, :encoding('utf8'));
}
