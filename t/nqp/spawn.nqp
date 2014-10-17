my @c1 := [
    'python',
    '-c',
    'print "hello";',
];
my @c2 := [
    'ls',
    '-l',
];
my $s := nqp::spawn(@c1, nqp::cwd, nqp::getenvhash);
say($s);
