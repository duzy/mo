class MO::Glob 
{
    method collect($filename) {
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

# my $match;
#
# $match := MO::GlobGrammar.parse('path/to/somewhere/*.pir', :rule<TOP>);
# ok( !$match, 'parse method works on negative match');
# say( $match<atom> );
#
# $match := MO::GlobGrammar.parse('path/[abc]/somewhere/*.{pir,mo}', :rule<TOP>);
# ok( !$match, 'parse method works on negative match');
# say( $match<atom> );

class MO::GlobActions is HLL::Actions {
    sub glob($/) {
        unless nqp::defined($*GLOB) {
            if $<literal> {
                $*GLOB := MO::Glob.new(~$<literal>);
            } else {
                $*GLOB := MO::Glob.new('.');
            }
        }
        $*GLOB
    }

    sub quest($m, $nxt) {
    }

    sub star($m, $nxt) {
    }

    sub enum($m, $nxt) {
    }

    sub alt($m, $nxt) {
    }

    sub literal($m, $nxt) {
        if nqp::defined($*GLOB) {
            
        } elsif nqp::defined($nxt) {
            $*GLOB := nqp::create(MO::Glob);
            $*GLOB.collect(~$m);
        } else {
            
        }
    }
    
    sub literal0($m, %x) {
        my $s := ~$m;
        my $path := '.';
        my $prefix := '';
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
        my $names := VMCall::readdir($path);
        %x<path> := $path;
        %x<names> := $names;
        %x<prefix> := $prefix;
        1
    }

    method atom:sym<literal>($/) { make &literal }
    method atom:sym<quest>($/)   { make &quest }
    method atom:sym<star>($/)    { make &star }
    method atom:sym<enum>($/)    { make &enum }
    method atom:sym<alt>($/)     { make &alt }

    method TOP($/) {
        my int $n := 0;
        while ($n < +$<atom>) {
            my $m := $<atom>[$n];
            ($m.made)($m, $<atom>[$n+1]);
            $n := $n + 1;
        }
        make $*GLOB;
    }
}
