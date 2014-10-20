class VMCall {
    our sub readdir($path) {
        my @names;
        my $dirh := nqp::opendir(self.absolute.Str);
        while 1 {
            my str $elem := nqp::nextfiledir($dirh);
            if nqp::isnull_s($elem) || nqp::chars($elem) == 0 {
                nqp::closedir($dirh);
                last;
            }
            @names.push($elem);
        }
        @names
    }
}
