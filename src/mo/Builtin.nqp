knowhow MO::Builtin {
    sub new($t, *@pos, *%named) {
        my $obj := nqp::create($t);
        $obj.'~ctor'(|@pos, |%named) if nqp::can($obj, '~ctor');
        $obj
    }

    sub getattr($o, $n) { nqp::getattr($o, $o, $n) }
    sub setattr($o, $n, $v) { nqp::bindattr($o, $o, $n, $v) }

    sub print($s) { nqp::print($s) }
    sub say($s) { nqp::say($s) }
    sub die($s) { nqp::die($s) }
    sub exit($n) { nqp::exit($n) }
    sub open($s, $m) { nqp::open($s, $m) }

    sub slurp($s, *%opts) {
        my $h := nqp::open($s, 'r');
        $h.encoding(%opts<encoding>) if nqp::existskey(%opts, 'encoding');
        $s := $h.readall();
        $h.close();
        $s
    }

    sub shell($s, $m?, $e?) {
        nqp::shell($s, $m // nqp::cwd, $e // nqp::getenvhash())
    }

    sub system($s, *%opts) {
        nqp::shell($s, %opts<wd> // nqp::cwd, %opts<env> // nqp::getenvhash())
    }

    sub cwd() { nqp::cwd }

    sub basename($s, $ext?) {
        my int $i := nqp::rindex($s, '/') + 1;
        my int $d := nqp::chars($s);
        if nqp::defined($ext) {
            my int $el := nqp::chars($ext);
            my int $di := $d - $el;
            if $el < $d && $i < $di && nqp::substr($s, $di, $d) eq $ext {
                $d := $di;
            }
        }
        nqp::substr($s, $i, $d-$i);
    }

    sub dirname($s) {
        my int $i := nqp::rindex($s, '/');
        nqp::substr($s, 0, $i);
    }

    sub isdir($s) {
        nqp::stat($s, nqp::const::STAT_EXISTS) && nqp::stat($s, nqp::const::STAT_ISDIR)
    }

    sub isreg($s) {
        nqp::stat($s, nqp::const::STAT_EXISTS) && nqp::stat($s, nqp::const::STAT_ISREG)
    }

    sub isdev($s) {
        nqp::stat($s, nqp::const::STAT_EXISTS) && nqp::stat($s, nqp::const::STAT_ISDEV)
    }

    sub islink($s) {
        nqp::stat($s, nqp::const::STAT_EXISTS) && nqp::stat($s, nqp::const::STAT_ISLNK)
    }

    sub isreadable($s) { nqp::filereadable($s) }
    sub iswritable($s) { nqp::filewritable($s) }
    sub isexecutable($s) { nqp::fileexecutable($s) }

    sub islist($a) { nqp::islist($a) }
    sub isstr($a)  { nqp::isstr($a) }
    sub isnull($a) { nqp::isnull($a) }

    sub defined($a) { nqp::defined($a) }
    sub addr($a) { nqp::where($a) }

    sub list() { nqp::list() }
    sub hash() { nqp::hash() }

    sub elems($l) { nqp::elems($l) }
    sub splice($l, $a, $pos, $sz) { nqp::splice($l, $a, $pos, $sz) }

    sub slice($l, $pos, $sz?) {
        my @result;
        my int $m := nqp::elems($l);
        $sz := $m - $pos unless nqp::defined($sz);
        while $pos < $m && nqp::elems(@result) < $sz {
            @result.push($l[$pos]);
            $pos := $pos + 1;
        }
        @result
    }

    sub split($l, $s) { nqp::split($l, $s) }
    sub join($s, $a) { nqp::join($s, $a) }
    sub concat($a, $b) { nqp::concat($a, $b) }
    sub chars($s) { nqp::chars($s) }
    sub index($s, $c) { nqp::index($s, $c) }
    sub rindex($s, $c) { nqp::rindex($s, $c) }
    sub endswith($s, *@a) {
        my int $res := 0;
        my int $sl := nqp::chars($s);
        for @a {
            my int $l := nqp::chars($_);
            if $l < $sl && nqp::substr($s, $sl-$l, $l) eq $_ {
                $res := 1;
                last;
            }
        }
        $res
    }
    sub startswith($s, *@a) {
        my int $res := 0;
        my int $sl := nqp::chars($s);
        for @a {
            my int $l := nqp::chars($_);
            if $l < $sl && nqp::substr($s, 0, $l) eq $_ {
                $res := 1;
                last;
            }
        }
        $res
    }
    sub substr($s, $a, $b?) {
        nqp::defined($b) ?? nqp::substr($s, $a, $b) !! nqp::substr($s, $a)
    }
    sub strip($s) {
        my int $i := 0;
        my int $e := nqp::chars($s);
        while $i < $e && nqp::iscclass(nqp::const::CCLASS_WHITESPACE, $s, $i) {  $i := $i + 1 }
        while $i < $e-1 && nqp::iscclass(nqp::const::CCLASS_WHITESPACE, $s, $e-1) { $e := $e - 1 }
        nqp::substr($s, $i, $e)
    }
    sub addprefix($prefix, $s) {
        nqp::isnull($s) ?? $s !! nqp::isnull($prefix) ?? $s !! "$prefix$s"
    }
    sub addsuffix($s, $suffix) {
        nqp::isnull($s) ?? $s !! nqp::isnull($suffix) ?? $s !! "$s$suffix"
    }
    sub addinfix($prefix, $s, $suffix) {
        $s := nqp::isnull($s) ?? $s !! nqp::isnull($prefix) ?? $s !! "$prefix$s";
        $s := nqp::isnull($s) ?? $s !! nqp::isnull($suffix) ?? $s !! "$s$suffix";
        $s
    }

    sub do_glob($pattern) {
        my $match := MO::GlobGrammar.parse($pattern, :p(0), :actions(MO::GlobActions));
        my $glob := $match.made;
        $glob.collect
    }

    sub glob(*@patterns) {
        my @result;
        for @patterns -> $pattern {
            @result.push($_) for do_glob($pattern)
            # try { @result.push($_) for do_glob($pattern) }
        }
        @result
    }

    sub readdir(*@dirs) {
        my @result;
        for @dirs {
            my @names := VMCall::readdir($_);
            my $prefix := $_ eq '.' ?? "" !! "$_/";
            for @names {
                if $_ ne '.' && $_ ne '..' {
                    @result.push(MO::FilesystemNodeHOW.open("$prefix$_"));
                }
            }
        }
        @result
    }

    method names() {
        my %names;

        %names<new>     := &new;

        %names<getattr> := &getattr;
        %names<setattr> := &setattr;

        %names<print>   := &print;
        %names<say>     := &say;
        %names<die>     := &die;
        %names<exit>    := &exit;
        %names<open>    := &open;
        %names<slurp>   := &slurp;
        %names<shell>   := &shell;
        %names<system>  := &system;
        %names<cwd>     := &cwd;
        %names<basename>:= &basename;
        %names<dirname> := &dirname;
        %names<glob>    := &glob;
        %names<readdir> := &readdir;
        %names<isdir>   := &isdir;
        %names<isreg>   := &isreg;
        %names<isdev>   := &isdev;
        %names<islink>  := &islink;
        %names<isreadable> := &isreadable;
        %names<iswritable> := &iswritable;
        %names<isexecutable> := &isexecutable;
    
        %names<islist> := &islist;
        %names<isstr> := &isstr;

        %names<isnull> := &isnull;
        %names<defined> := &defined;
        %names<addr> := &addr;

        %names<list> := &list;
        %names<hash> := &hash;

        %names<elems> := &elems;
        %names<splice> := &splice;
        %names<slice> := &slice;

        # String manipulation..
        %names<split> := &split;
        %names<join> := &join;
        %names<concat> := &concat;
        %names<chars> := &chars;
        %names<index> := &index;
        %names<rindex> := &rindex;
        %names<endswith> := &endswith;
        %names<startswith> := &startswith;
        %names<substr> := &substr;
        %names<strip> := &strip;
        %names<addprefix> := &addprefix;
        %names<addsuffix> := &addsuffix;
        %names<addinfix> := &addinfix;

        %names
    }
}
