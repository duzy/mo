class MO::Glob
{
    has str $!init;
    has int $!prev;
    has int $!skip;
    has @!parts;
    has @!stems;
    has @!acc;

    method new(str $s) { nqp::create(MO::Glob)."!INIT"($s) }
    method !INIT(str $s) {
        $!init  := $s;
        @!parts := [];
        @!stems := [];
        @!acc   := [];
        $!prev  := 0;
        $!skip  := 0;
        self
    }

    method add($part) { @!parts.push($part) }

    my method wildcard() {
        my @stems;
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
                    @stems.push(nqp::substr($name, $prelen));
                }
            }
        }
        @stems
    }

    method wildcard:<*>($part) {
        @!stems := self.wildcard unless +@!stems; # only scan if no stems cached
        $!prev := 1;
        $!skip := 0;
    }

    method wildcard:<?>($part) {
        @!stems := self.wildcard unless +@!stems; # scan if no stems cached

        if +@!stems {
            my int $ql := nqp::chars(~$part);
            my @a;
            for @!stems -> str $stem {
                @a.push($stem) if $ql <= nqp::chars($stem);
            }
            @!stems := @a;
            $!skip := $ql;
        }

        $!prev := 2;
    }

    method wildcard:<[]>($part) {
        my $enum := $part<enum>;
        say("enum: $enum, $part");
        my @a;
        # if +@!stems {
        #     for @!stems -> str $stem {
        #         @a.push("$stem$_") for $enum
        #     }
        # } else {
        #     @a.push($_) for $enum;
        # }
        @!stems := @a;
        $!prev := 3;
        $!skip := 0;
    }

    method wildcard:<{}>($part) {
        my @a;
        if +$part<alt> {
            if +@!stems {
                for $part<alt> -> str $alt {
                    for @!stems -> str $stem {
                        @a.push("$stem$alt");
                    }
                }
            } else {
                for $part<alt> -> str $alt {
                    @a.push($alt);
                }
            }
        }
        @!stems := @a;
        $!prev := 4;
        $!skip := 0;
    }

    method wildcard:<lit>($part) {
        my str $s := ~$part;    # format: 'suffix'~'/subpath/'~'tail'
        my int $i := nqp::index($s, '/', 0);
        my str $suffix := '';
        my str $tail := '';
        my str $subpath;
        if 0 <= $i {
            my int $j := nqp::rindex($s, '/');
            $suffix  := nqp::substr($s, 0, $i);
            $subpath := nqp::substr($s, $i, $j-$i+1);
            $tail    := nqp::substr($s, $j+1);
        } else {
            $suffix := $s;
        }

        if +@!stems && nqp::chars($suffix) {
            my @a;
            if $!prev == 1 { # *
                for @!stems -> str $stem {
                    my int $l := nqp::chars($stem);
                    my int $sl := nqp::chars($suffix);
                    if $sl <= $l && nqp::substr($stem, $l-$sl, $sl) eq $suffix {
                        @a.push($stem);
                    }
                }
            } elsif $!prev == 2 { # ?
                for @!stems -> str $stem {
                    my int $l := nqp::chars($stem);
                    my int $sl := nqp::chars($suffix);
                    if $sl == $l-$!skip && nqp::substr($stem, $l-$sl, $sl) eq $suffix {
                        @a.push($stem);
                    }
                }
            } else { # [], {}
                for @!stems -> str $stem {
                    @a.push("$stem$suffix");
                }
            }
            @!stems := @a;
        }

        if +@!stems && nqp::defined($subpath) && nqp::chars($subpath) { # has a '/sub/'
            my @a;
            for @!acc -> str $prefix {
                for @!stems -> str $stem {
                    my $s := "$prefix$stem$subpath";
                    @a.push("$s$tail") if nqp::stat($s, nqp::const::STAT_ISDIR);
                }
            }
            @!stems := []; # clear stems
            @!acc := @a;
        }
        $!prev := 0;
        $!skip := 0;
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
                    self."wildcard:<$op>"($part);
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
    token atom:sym<quest>   { '?'+ }
    token atom:sym<star>    { '*'+ }
    token atom:sym<enum>    { '[' ~ ']' [$<neg>=<[!^]>? <enum>*] }
    token atom:sym<alt>     { '{' ~ '}' <alt>* %% ',' }
    token atom:sym<literal> { <literal> }
    token literal { <-[*?[{]>+ }
    token alt { <-[,}]>+ }
    proto token enum { <...> }
    token enum:sym<-> { <a=.e> '-' <b=.e> }
    token enum:sym<.> { <e> }
    token e { <-[\]]> }
}

class MO::GlobActions is HLL::Actions {
    sub wildcard($/, $op) {
        $/<wildcard> := $op;
        $*GLOB := MO::Glob.new('') unless nqp::defined($*GLOB);
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
            $*GLOB := MO::Glob.new($/);
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
