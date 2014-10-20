# -*- nqp -*-
plan(28); #plan(76);

my $f := MO::FilesystemNodeHOW.open('t/xml/c/filesystem.t');
ok($f.name eq 't/xml/c/filesystem.t', "\$f.name eq 't/xml/c/filesystem.t'");
ok($f.get('NAME') eq 'filesystem.t', "\$f.get('NAME') eq 'filesystem.t'");
ok($f.get('PATH') eq nqp::cwd~'/'~$f.name, "\$f.get('PATH') eq "~nqp::cwd~'/'~$f.name);
ok($f.get('EXISTS'), "\$f.get('EXISTS')");
if $f.get('EXISTS') {
    ok($f.get('ISDIR') == 0, "\$f.get('ISDIR') == 0");
    ok($f.get('ISREG') == 1, "\$f.get('ISREG') == 1");
    ok($f.get('ISDEV') == 0, "\$f.get('ISDEV') == 0");
    ok($f.get('FILESIZE') > 0, "\$f.get('FILESIZE') > 0");
}

my $d := MO::FilesystemNodeHOW.open('t/xml/c/test');
ok($d.name eq 't/xml/c/test', "\$d.name eq 't/xml/c/test'");
ok($d.get('NAME') eq 'test', "\$d.get('NAME') eq 'test'");
ok($d.get('PATH') eq nqp::cwd~'/'~$d.name, "\$d.get('PATH') eq "~nqp::cwd~'/'~$d.name);
ok($d.get('EXISTS'), "\$d.get('EXISTS')");
if $d.get('EXISTS') {
    ok($d.get('ISDIR') == 1, "\$d.get('ISDIR') == 1");
    ok($d.get('ISREG') == 0, "\$d.get('ISREG') == 0");
    ok($d.get('ISDEV') == 0, "\$d.get('ISDEV') == 0");
    ok($d.get('FILESIZE') > 0, "\$d.get('FILESIZE') > 0");
    my $c1 := $d.children('t1.txt');
    my $c2 := $d.children('t2.txt');
    ok(nqp::defined($c1), "\$c1 defined");
    ok(nqp::defined($c2), "\$c2 defined");
    if nqp::defined($c1) {
        ok($c1.name eq $d.name~'/'~$c1.get('NAME'), "\$c1.name eq "~$d.name~'/'~$c1.get('NAME'));
        ok($c1.get('EXISTS'), "\$c1.get('EXISTS')");
        ok($c1.get('NAME') eq 't1.txt', "\$c1.get('NAME') eq t1.txt");
        ok($c1.get('PATH') eq nqp::cwd~'/'~$d.name~'/'~$c1.get('NAME'), "\$c1.get('PATH') eq "~nqp::cwd~'/'~$d.name~'/'~$c1.get('NAME'));
        ok($c1.get('ISDIR') == 0, "\$c1.get('ISDIR') == 0");
        ok($c1.get('ISREG') == 1, "\$c1.get('ISREG') == 1");
        ok($c1.get('ISDEV') == 0, "\$c1.get('ISDEV') == 0");
    }
    if nqp::defined($c2) {
        ok($c2.name eq $d.name~'/'~$c2.get('NAME'), "\$c2.name eq "~$d.name~'/'~$c2.get('NAME'));
        ok($c2.get('EXISTS'), "\$c2.get('EXISTS')");
        ok($c2.get('NAME') eq 't2.txt', "\$c2.get('NAME') eq t2.txt");
        ok($c2.get('PATH') eq nqp::cwd~'/'~$d.name~'/'~$c2.get('NAME'), "\$c2.get('PATH') eq "~nqp::cwd~'/'~$d.name~'/'~$c2.get('NAME'));
        ok($c2.get('ISDIR') == 0, "\$c2.get('ISDIR') == 0");
        ok($c2.get('ISREG') == 1, "\$c2.get('ISREG') == 1");
        ok($c2.get('ISDEV') == 0, "\$c2.get('ISDEV') == 0");
    }   

if 0 {
    my $cache1 := nqp::getattr($d, $d, '/t1.txt');
    my $cache2 := nqp::getattr($d, $d, '/t2.txt');
    ok(nqp::defined($cache1), "\$cache1 defined");
    ok(nqp::defined($cache2), "\$cache2 defined");
    ok(nqp::where($c1) == nqp::where($cache1), 'where($c1) == where($cache1)');
    ok(nqp::where($c2) == nqp::where($cache2), 'where($c2) == where($cache2)');
}

    $c1 := $d.children('more/t1.txt');
    $c2 := $d.children('more/t2.txt');
    ok(nqp::defined($c1), "\$c1 defined");
    ok(nqp::defined($c2), "\$c2 defined");
    if nqp::defined($c1) {
        ok($c1.name eq $d.name~'/more/'~$c1.get('NAME'), "\$c1.name eq "~$d.name~'/more/'~$c1.get('NAME'));
        ok($c1.get('EXISTS'), "\$c1.get('EXISTS')");
        ok($c1.get('NAME') eq 't1.txt', "\$c1.get('NAME') eq t1.txt");
        ok($c1.get('PATH') eq nqp::cwd~'/'~$d.name~'/more/'~$c1.get('NAME'), "\$c1.get('PATH') eq "~nqp::cwd~'/'~$d.name~'/more/'~$c1.get('NAME'));
        ok($c1.get('ISDIR') == 0, "\$c1.get('ISDIR') == 0");
        ok($c1.get('ISREG') == 1, "\$c1.get('ISREG') == 1");
        ok($c1.get('ISDEV') == 0, "\$c1.get('ISDEV') == 0");
    }
    if nqp::defined($c2) {
        ok($c2.name eq $d.name~'/more/'~$c2.get('NAME'), "\$c2.name eq "~$d.name~'/more/'~$c2.get('NAME'));
        ok($c2.get('EXISTS'), "\$c2.get('EXISTS')");
        ok($c2.get('NAME') eq 't2.txt', "\$c2.get('NAME') eq t2.txt");
        ok($c2.get('PATH') eq nqp::cwd~'/'~$d.name~'/more/'~$c2.get('NAME'), "\$c2.get('PATH') eq "~nqp::cwd~'/'~$d.name~'/more/'~$c2.get('NAME'));
        ok($c2.get('ISDIR') == 0, "\$c2.get('ISDIR') == 0");
        ok($c2.get('ISREG') == 1, "\$c2.get('ISREG') == 1");
        ok($c2.get('ISDEV') == 0, "\$c2.get('ISDEV') == 0");
    }

if 0 {
    my $cache3 := nqp::getattr($d, $d, '/more');
    ok(nqp::defined($cache3), "\$cache3 defined");
    ok($cache3.get('EXISTS'), "\$cache3.get('EXISTS')");
    ok($cache3.get('ISDIR') == 1, "\$cache3.get('ISDIR') == 1");
    ok($cache3.get('ISREG') == 0, "\$cache3.get('ISREG') == 0");
    ok($cache3.get('ISDEV') == 0, "\$cache3.get('ISDEV') == 0");
    ok($cache3.get('FILESIZE') > 0, "\$cache3.get('FILESIZE') > 0");
    my $cache1 := nqp::getattr($cache3, $cache3, '/t1.txt');
    my $cache2 := nqp::getattr($cache3, $cache3, '/t2.txt');
    ok(nqp::defined($cache1), "\$cache1 defined");
    ok($cache1.name eq $d.name~'/more/'~$cache1.get('NAME'), "\$cache1.name eq "~$d.name~'/more/'~$cache1.get('NAME'));
    ok($cache1.get('EXISTS'), "\$cache1.get('EXISTS')");
    ok($cache1.get('NAME') eq 't1.txt', "\$cache1.get('NAME') eq t1.txt");
    ok($cache1.get('PATH') eq nqp::cwd~'/'~$d.name~'/more/'~$cache1.get('NAME'), "\$cache1.get('PATH') eq "~nqp::cwd~'/'~$d.name~'/more/'~$cache1.get('NAME'));
    ok($cache1.get('ISDIR') == 0, "\$cache1.get('ISDIR') == 0");
    ok($cache1.get('ISREG') == 1, "\$cache1.get('ISREG') == 1");
    ok($cache1.get('ISDEV') == 0, "\$cache1.get('ISDEV') == 0");
    ok(nqp::defined($cache2), "\$cache2 defined");
    ok($cache2.name eq $d.name~'/more/'~$cache2.get('NAME'), "\$cache2.name eq "~$d.name~'/more/'~$cache2.get('NAME'));
    ok($cache2.get('EXISTS'), "\$cache2.get('EXISTS')");
    ok($cache2.get('NAME') eq 't2.txt', "\$cache2.get('NAME') eq t2.txt");
    ok($cache2.get('PATH') eq nqp::cwd~'/'~$d.name~'/more/'~$cache2.get('NAME'), "\$cache2.get('PATH') eq "~nqp::cwd~'/'~$d.name~'/more/'~$cache2.get('NAME'));
    ok($cache2.get('ISDIR') == 0, "\$cache2.get('ISDIR') == 0");
    ok($cache2.get('ISREG') == 1, "\$cache2.get('ISREG') == 1");
    ok($cache2.get('ISDEV') == 0, "\$cache2.get('ISDEV') == 0");
    ok(nqp::where($c1) == nqp::where($cache1), 'where($c1) == where($cache1)');
    ok(nqp::where($c2) == nqp::where($cache2), 'where($c2) == where($cache2)');
}
}
