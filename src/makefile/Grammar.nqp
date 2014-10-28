use NQPHLL;

grammar MakeFile::Grammar is HLL::Grammar {
    method TOP() {
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

    # token ws { \s* | '#' \N* \n? }
    token ws {
        ||  <?MARKED('ws')>
        ||  <!ww>
            [ \v+
            | '#' \N*
            | \h+
            ]*
            <?MARKER('ws')>
    }

    token eol { \n|'#'\N*\n? }

    proto rule statement { <...> }
    rule statement:sym<assign> { <.ws><name=text '='|\n> <equal> <value=text <eol>> }
    rule statement:sym<:> { <rule> }
    rule statement:sym<$> { <expandable> }

    token equal { '='|':='|'?=' }

    token text($stop) { [<!before $stop><text_atom>]+ }

    proto token text_atom { <...> }
    token text_atom:sym<$> { <expandable> }
    token text_atom:sym<q> { <quote> }
    token text_atom:sym<.> { <-[$]> }

    proto token quote  { <...> }
    token quote:sym<'> { <?[']> <quote_EXPR: ':q'>  }
    token quote:sym<"> { <?["]> <quote_EXPR: ':qq'> }

    proto token expandable { <...> }
    token expandable:sym<$()> { '$(' ~ ')' <text ')'> }
    token expandable:sym<${}> { '${' ~ '}' <text '}'> }
    token expandable:sym<$> { <sym><-[({]> }

    rule rule {
        <text ':'> ':' <text '|'|<eol>>? ['|' <text <eol>>]?\n?[^^\t<text <eol>>\n?]*
    }
}
