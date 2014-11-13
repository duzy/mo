class MO::Glob
{
    has str $!init;
    has @!parts;

    method new($s) { nqp::create(MO::Glob)."!INIT"($s) }
    method !INIT(str $s) {
        $!init := $s;
        @!parts := [];
        self
    }

    method add($part) { @!parts.push($part) }

    has @!acc;

    has $!path;
    has $!prefix;
    has $!names;

    method wildcard:<*>(int $n, $part) {
        if nqp::isnull($!names) {
            my @result;
            my int $prelen := nqp::chars($!prefix);
            my @names := VMCall::readdir($!path);
            for @names {
                my int $l := nqp::chars($_);
                if $prelen <= $l && nqp::substr($_, 0, $prelen) eq $!prefix {
                    @result.push($_);
                }
            }
            $!names := @result;
        } else {
            $!skip := -1;
        }
    }

    method wildcard:<?>(int $n, $part) {
        if nqp::isnull($!names) {
            $!names := VMCall::readdir($!path);
            $!skip := 1;
        } elsif +$!names {
            my @result;
            $!names := @result;
        }
    }

    method wildcard:<[]>(int $n, $part) {
        # say("part: "~$part<enum>);
    }

    method wildcard:<{}>(int $n, $part) {
        # say("part: "~nqp::join(',', $part<alt>));
    }

    method wildcard:<lit>(int $n, $part) {
        my str $s := ~$part;
        my int $i := nqp::index($s, '/', 0);
        my str $suffix := '';
        my str $subpath;
        if 0 <= $i {
            $suffix := nqp::substr($s, 0, $i);
            $subpath := nqp::substr($s, $i);
        } else {
            $suffix := $s;
        }

        my int $suflen := nqp::chars($suffix);
        if $suflen {
            my @names;
            for $!names {
                @names.push($_);
            }
            $!names := @names;
        }
    }

    method iterate() {
        my str $s := $!init;
        my str $path := '.';
        my str $prefix := '';
        my int $i := nqp::rindex($s, '/');
        if 0 < $i {
            $path := nqp::substr($s, 0, $i);
            $prefix := nqp::substr($s, $i+1);
        } elsif 0 == $i {
            $path := '/';
            $prefix := nqp::substr($s, $i+1);
        } else {
            $prefix := $s;
        }
        if nqp::stat($path, nqp::const::STAT_ISDIR) {
            $!path := $path;
            $!prefix := $prefix;
            if +@!parts {
                my int $n := 0;
                while $n < +@!parts {
                    my $part := @!parts[$n];
                    my $op := $part<wildcard> // 'lit';
                    self."wildcard:<$op>"($n, $part);
                    $n := $n + 1;
                }
                @!acc := $!names;
            } elsif nqp::stat("$s", 0) {
                @!acc.push($s);
            }
        }
        1
    }

    method collect() {
        @!acc := [];
        self.iterate();
        @!acc
    }
}

grammar MO::GlobGrammar is HLL::Grammar {
    token TOP { :my $*GLOB; <atom>* }
    proto token atom        { <...> }
    token atom:sym<quest>   { '?' }
    token atom:sym<star>    { '*' }
    token atom:sym<enum>    { '[' ~ ']' <enum> }
    token atom:sym<alt>     { '{' ~ '}' <alt>* %% ',' }
    token atom:sym<literal> { <literal> }
    token literal { <-[*?[{]>+ }
    token enum { <-[\]]>* }
    token alt { <-[,}]>+ }
}

class MO::GlobActions is HLL::Actions {
    sub wildcard($/, $op) {
        $/<wildcard> := $op;
        $*GLOB := MO::Glob.new('.') unless nqp::defined($*GLOB);
        $*GLOB.add($/);
    }

    method TOP($/)               { make $*GLOB }
    method atom:sym<alt>($/)     { wildcard($/, '{}') }
    method atom:sym<star>($/)    { wildcard($/, '*') }
    method atom:sym<enum>($/)    { wildcard($/, '[]') }
    method atom:sym<quest>($/)   { wildcard($/, '?') }
    method atom:sym<literal>($/) {
        if nqp::defined($*GLOB) {
            $*GLOB.add($/);
        } else {
            $*GLOB := MO::Glob.new(~$/);
        }
    }
}

# my $match;
#
# $match := MO::GlobGrammar.parse('path/to/somewhere/*.pir', :rule<TOP>);
# ok( !$match, 'parse method works on negative match');
# say( $match<atom> );
#
# $match := MO::GlobGrammar.parse('path/[abc]/somewhere/*.{pir,mo}', :rule<TOP>);
# ok( !$match, 'parse method works on negative match');
# say( $match<atom> );
