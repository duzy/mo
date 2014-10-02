use HLL;

class MO::Compiler is HLL::Compiler {
    method my_command_line(@args, *%adverbs) {
        my $program-name := @args[0];
        my $res  := self.process_args(@args);
        my %opts := $res.options;
        my @a    := $res.arguments;

        for %opts {
            %adverbs{$_.key} := $_.value;
        }

        self.usage($program-name) if %adverbs<help> || %adverbs<h>;

        my $cwd := nqp::cwd;
        my @search_paths;
        my @datafiles;
        my @codefiles;
        for @a {
            if $_ ~~ / .*\.[xml|json]$  / {
                @datafiles.push($_);
            } elsif $_ ~~ / .*\.[mo]$  / {
                my int $i := nqp::rindex($_, '/');
                if $i == 0 {
                    @search_paths.push('/') if $cwd ne '/';
                } elsif 0 < $i {
                    @search_paths.push("$cwd/" ~ nqp::substr($_, 0, $i+1));
                }
                @codefiles.push($_);
            } else {
                self.panic('Unknown source '~$_);
            }
        }

        @search_paths.push("$cwd/");

        # self.command_eval_data(|@datafiles, :encoding('utf8'));
        # self.command_eval_code(|@codefiles, |%adverbs);

        my $*SEARCHPATHS := @search_paths;
        my $*DATAFILES := @datafiles;
        self.command_eval(|@codefiles, |%adverbs)
    }

    method command_eval_data(*@a, *%adverbs) {
        my $data := self.command_eval(|@a, |%adverbs);
    }

    method command_eval_code(*@a, *%adverbs) {
        my $res := self.command_eval(|@a, |%adverbs);
    }
}

my $mocomp := MO::Compiler.new();
$mocomp.language('mo');
$mocomp.parsegrammar(MO::Grammar);
$mocomp.parseactions(MO::Actions);

#nqp::say(~%*COMPILING<%?OPTIONS>);

sub MAIN(@ARGS) {
    # my $p := HLL::CommandLine::Parser.new(nqp::split(' ', 'e=s help|h target=s trace|t=s encoding=s output|o=s combine version|v show-config verbose-config|V stagestats=s? ll-exception rxtrace nqpevent=s profile profile-compile'));
    # $p.add-stopper('-e');
    # $p.stop-after-first-arg;
    # my $res;
    # try {
    #     $res := $p.parse(@ARGS);
    #     CATCH {
    #         nqp::say($_);
    #         nqp::exit(1);
    #     }
    # }
    # if $res {
    #     nqp::say(~$res.options());
    #     nqp::say(nqp::join(' ', $res.arguments()));
    # }

    #$mocomp.command_line(@ARGS, :encoding('utf8'));
    $mocomp.my_command_line(@ARGS, :encoding('utf8'));
}
