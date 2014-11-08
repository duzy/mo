grammar MO::GlobGrammar is HLL::Grammar {
    token TOP  { <atom>* }
    token atom {
        | <quest>
        | <star>
        | <enum>
        | <alt>
        | <literal>
    }
    token quest   { '?' }
    token star    { '*' }
    token enum    { '[' ~ ']' <-[\]]>* }
    token alt     { '{' ~ '}' [<-[,}]>+]* %% ',' }
    token literal { <-[*?[{]>+ }
}

my $match;

$match := MO::GlobGrammar.parse('path/to/somewhere/*.pir', :rule<TOP>);
ok( !$match, 'parse method works on negative match');
say( $match<atom> );

$match := MO::GlobGrammar.parse('path/[abc]/somewhere/*.{pir,mo}', :rule<TOP>);
ok( !$match, 'parse method works on negative match');
say( $match<atom> );
