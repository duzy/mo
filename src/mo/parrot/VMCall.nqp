class VMCall {
    our sub readdir($path) {
        pir::new__PS('OS').readdir($path)
    }

    our sub readall($filename, :$encoding = 'utf8') {
        my $fh := nqp::open("$filename", 'r');
        $fh.encoding($encoding);
        my $source := $fh.readall();
        $fh.close();
        $source
    }
}
