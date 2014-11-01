use NQPHLL;

grammar MakeFile::Grammar is HLL::Grammar {
    method TOP() {
        my $source_id := nqp::sha1(self.target() ~ nqp::time_n());
        my $file := nqp::getlexdyn('$?FILES');
        my $*W := nqp::isnull($file) ??
            MakeFile::World.new(:handle($source_id)) !!
            MakeFile::World.new(:handle($source_id), :description($file));

        my $*SCOPE := QAST::Block.new( :node($/), QAST::Stmts.new() );
        $*SCOPE[0].push( QAST::Op.new( :op<bind>,
            QAST::Var.new( :decl<var>, :scope<local>, :name<builtin> ),
            QAST::WVal.new( :value(MakeFile::Builtin) ),
        ) );

        self.go
    }

    rule go {
        <statement>* [ $ || <.panic: 'Confused'> ]
    }

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
    token ts { <[\t\ ]> }

    token special_rule_name {
        | '.DEFAULTS'
        | '.DELETE_ON_ERROR'
        | '.EXPORT_ALL_VARIABLES'
        | '.IGNORE'
        | '.INTERMEDIATE'
        | '.LOW_RESOLUTION_TIME'
        | '.NOTPARALLEL'
        | '.PHONY'
        | '.PRECIOUS'
        | '.SECONDARY'
        | '.SECONDEXPANSION'
        | '.SILENT'
        | '.SUFFIXES'
    }

    proto rule statement         { <...> }
    rule statement:sym<assign>   { <.ws><name=text \s*<equal>|\n> <equal> <value=text <eol>> }
    rule statement:sym<define>   { <sym> }
    rule statement:sym<undefine> { <sym> }
    rule statement:sym<override> { <sym> }
    rule statement:sym<include>  { <sym> }
    rule statement:sym<:>        { <rule> }
    rule statement:sym<$>        { <reference> }

    token equal { '='|':='|'::='|'?=' }

    token text($stop) { [<!before $stop><text_atom>]+ }

    proto token text_atom  { <...> }
    token text_atom:sym<$> { <reference> }
    token text_atom:sym<q> { <quote> }
    token text_atom:sym<.> { <-[$]> }

    proto token quote  { <...> }
    token quote:sym<'> { <?[']> <quote_EXPR: ':q'>  }
    token quote:sym<"> { <?["]> <quote_EXPR: ':qq'> }

    proto token reference    { <...> }
    token reference:sym<$()> { '$(' ~ ')' <nameargs ')'> }
    token reference:sym<${}> { '${' ~ '}' <nameargs '}'> }
    token reference:sym<$>   { <sym>$<name>=<-[({]> }

    token nameargs($a) { <name=text $a|' '> \s* <args $a>? }
    token args($a) { <text ','|$a>? %% ',' }

    token rule {
        [ <target=text ':'|' '><ts>* ]+ ':'<ts>*
        [ <!before '|'><prerequisite=text '|'|' '|<eol>><ts>* ]*
        [ '|'<ts>* [ <post=text ' '|<eol>><ts>* ]* ]?
        [ ';'<recipe> | [\n\t<recipe>]* ]
    }

    token recipe { [[\\\n]?<text \\\n|<eol>>]* }
}
