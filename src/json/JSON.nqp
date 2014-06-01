grammar JSON::Grammar is HLL::Grammar {
    rule TOP { <value> }

    proto token value { <...> }

    token value:sym<string> { <string> }

    token value:sym<number> {
        '-'?
        [ <[1..9]> <[0..9]>+ | <[0..9]> ]
        [ '.' <[0..9]>+ ]?
        [ <[Ee]> <[+\-]>? <[0..9]>+ ]?
    }

    rule value:sym<array> {
        '[' [ <value>+ %',' ]? ']'
    }

    rule value:sym<object> {
        '{'
        [ [ <string> ':' <value> ]+ %',' ]?
        '}'
    }

    token string {
        <?["]> <quote_EXPR: ':qq'>  #"
    }
}
