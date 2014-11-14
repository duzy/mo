class MO::Glob
{
    has str $!init;
    has int $!skip;
    has @!parts;
    has @!stems;
    has @!acc;

    method new($s) { nqp::create(MO::Glob)."!INIT"($s) }
    method !INIT(str $s) {
        $!init  := $s;
        @!parts := [];
        @!stems := [];
        @!acc   := [];
        $!skip  := 0;
        self
    }

    method add($part) { @!parts.push($part) }

    method wildcard:<*>(int $n, $part) {
        $!skip := -1;
        if +@!stems {
            
        } else {
            my @result;
            for @!acc -> str $s {
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

                my int $prelen := nqp::chars($prefix);
                my @names := VMCall::readdir($path);
                for @names -> str $name {
                    my int $l := nqp::chars($name);
                    if $prelen <= $l && nqp::substr($name, 0, $prelen) eq $prefix {
                        @result.push(nqp::substr($name, $prelen));
                    }
                }
            }
            @!stems := @result;
        }
    }

    method wildcard:<?>(int $n, $part) {
        if nqp::isnull(@!stems) {
            $!skip := 1;
            #@!stems := VMCall::readdir($!path);
        } elsif +@!stems {
            my @result;
            @!stems := @result;
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

        if nqp::chars($suffix) {
            my @a;
            for @!stems -> str $stem {
                my int $l := nqp::chars($stem);
                my int $sl := nqp::chars($suffix);
                # say($stem~', '~nqp::substr($stem, $l-$sl, $sl)~', '~$suffix);
                if $sl <= $l && nqp::substr($stem, $l-$sl, $sl) eq $suffix {
                    @a.push($stem);
                }
            }
            say("stems: "~nqp::join(',',@a));
            @!stems := @a;
        }

        if nqp::defined($subpath) && nqp::chars($subpath) {
            
        } else {
            
        }

        my int $suflen := nqp::chars($suffix);
        if $suflen {
            # my @names;
            # for @!stems {
            #     @names.push($_);
            # }
            # @!stems := @names;
        }
    }

    method collect() {
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
            if +@!parts {
                @!acc.push($s);

                my int $n := 0;
                while $n < +@!parts {
                    my $part := @!parts[$n];
                    my $op := $part<wildcard> // 'lit';
                    self."wildcard:<$op>"($n, $part);
                    $n := $n + 1;
                }

                my @a;
                if +@!stems {
                    for @!acc -> str $prefix {
                        for @!stems -> str $stem {
                            my str $s := "$prefix$stem";
                            @a.push($s) if nqp::stat($s, 0);
                        }
                    }
                    @!stems := [];
                } elsif +@!acc {
                    for @!acc {
                        @a.push($_) if $s ne $_ && nqp::stat($_, 0);
                    }
                }
                @!acc := @a;
            } elsif nqp::stat($s, 0) {
                @!acc.push($s);
            }
        }
        @!acc
    }
}

grammar MO::GlobGrammar is HLL::Grammar {
    token TOP { :my $*GLOB; <atom>* }
    proto token atom        { <...> }
    token atom:sym<quest>   { '?' }
    token atom:sym<star>    { '*'+ }
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
