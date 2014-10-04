use NQPHLL;

grammar XML::Grammar is HLL::Grammar {
    method TOP(:$end?) {
        my $source_id := nqp::sha1(self.target() ~ nqp::time_n());
        my $file := nqp::getlexdyn('$?FILES');
        my $*W := nqp::isnull($file) ??
            XML::World.new(:handle($source_id)) !!
            XML::World.new(:handle($source_id), :description($file));

        self.go(:$end)
    }

    token go(:$end?) {
        <declaration>?\s* ~ $
        <markup_content>* || <.panic: 'syntax error'>
    }

    token declaration {
        '<?xml'\s+ ~ '?>' <declaration_info>*
    }

    rule declaration_info {
        <name: 'version','encoding'> '=' <value>
    }

    proto token markup_content { <...> }
    token markup_content:sym<tag>     { <tag> }
    token markup_content:sym<cdata>   { <cdata> }
    token markup_content:sym<content> { <content> }

    proto token tag { <...> }
    token tag:sym<start> {
        '<' <name=.tag_name> \s* <attribute>* $<delimiter>=['>'|'/>']
    }
    token tag:sym<end> {
        '</' <name=.tag_name> \s* $<delimiter>='>'
    }

    # Names can contain letters, numbers, and other characters
    # Names cannot start with a number or punctuation character
    # Names cannot start with the letters xml (or XML, or Xml, etc)
    # Names cannot contain spaces
    token tag_name {
        [<ns=.ident>':']? $<ident>=[
            [<!punct><!digit>\S]
            [<![<>?/]>\S]*
        ]
    }

    token cdata {
        '<![CDATA[' ~ ']]>' [<!before: ']]>'>.]*
    }

    token entity {
        '&' [ '#' $<code>=<![ 0..9 a..f A..F ]>+ | $<name>=<![;]>+ ] ';'
    }

    token content {
        [[<![<&$]>.]|<entity>]+
    }

    rule attribute {
        <name=.attribute_name> '=' <value>
    }

    token attribute_name {
        [<ns=.ident>':']? <.ident>
    }

    token name(*@names) {
        <.ident>
        {
            my $known := 0;
            for @names -> $s {
                if ~$/ eq $s {
                    $known := 1;
                    last;
                }
            }
            if +@names && !$known {
                self.panic('unknown name "'~$/~'"');
            }
        }
    }

    proto token value { <...> }
    # token value:sym<number> { <number> }
    token value:sym<quote> { <?["]> <quote_EXPR: ':qq'> }
}
