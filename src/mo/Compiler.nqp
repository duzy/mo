class MO::Compiler is HLL::Compiler {
}

my $xmlcomp := XML::Compiler.new();
$xmlcomp.language('xml');
$xmlcomp.parsegrammar(XML::Grammar);
$xmlcomp.parseactions(XML::Actions);

#my $jsoncomp := MO::Compiler.new();
#$jsoncomp.language('json');
#$jsoncomp.parsegrammar(JSON::Grammar);
#$jsoncomp.parseactions(JSON::Actions);

my $mocomp := MO::Compiler.new();
$mocomp.language('mo');
$mocomp.parsegrammar(MO::Grammar);
$mocomp.parseactions(MO::Actions);

#nqp::say(~%*COMPILING<%?OPTIONS>);

sub MAIN(@ARGS) {
    my @flags := [];
    my @files := [];
    for @ARGS -> $a {
        if $a ~~ / ^\- / {
            @flags.push($a);
        } elsif $a ~~ / .*\.[xml|json|mo]$ / {
            @files.push($a);
        } else {
            #panic("Unrecognized argument: "~$a);
        }
    }

    for @files -> $fn {
        my @args := nqp::clone(@flags);
        @args.unshift(@ARGS[0]);
        @args.push($fn);
        if $fn ~~ / .*\.xml$ / {
            $xmlcomp.command_line(@args, :encoding('utf8'));
        } elsif $fn ~~ / .*\.json$ / {
            #$jsoncomp.command_line(@args, :encoding('utf8'));
        } elsif $fn ~~ / .*\.mo$ / {
            $mocomp.command_line(@args, :encoding('utf8'));
        } else {
            #panic()
        }
    }
}
