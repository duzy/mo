use NQPHLL;

grammar MakeFile::Grammar is HLL::Grammar {
    method TOP(:$end?) {
        my $source_id := nqp::sha1(self.target() ~ nqp::time_n());
        my $file := nqp::getlexdyn('$?FILES');
        my $*W := nqp::isnull($file) ??
            MakeFile::World.new(:handle($source_id)) !!
            MakeFile::World.new(:handle($source_id), :description($file));

        self.go
    }

    rule go {
        <statement>* [ $ || <.panic: 'Confused'> ]
    }

    proto rule statement { <...> }
    rule statement:sym<assign> {
        <expandable> <equal> <text>
    }

    proto token expandable { <...> }

    token equal { '='|':='|'?=' }

    token text {
        
    }
}
