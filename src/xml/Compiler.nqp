class XML::Compiler is HLL::Compiler {
}

my $xmlc := XML::Compiler.new();
$xmlc.language('xml');
$xmlc.parsegrammar(XML::Grammar);
$xmlc.parseactions(XML::Actions);

sub MAIN(@ARGS) {
    $xmlc.command_line(@ARGS, :encoding('utf8'));
}
