use NQPHLL;
use xml;
#use json;

grammar MO::Grammar is HLL::Grammar {
    INIT {
        MO::Grammar.O(':prec<y=>, :assoc<unary>', '%methodop');
        MO::Grammar.O(':prec<g=>, :assoc<list>, :nextterm<nulltermish>',  '%comma');
        MO::Grammar.O(':prec<f=>, :assoc<list>',  '%list_infix');
        MO::Grammar.O(':prec<e=>, :assoc<unary>', '%list_prefix');
    }

    token term:sym<value> { <value> }
    token term:sym<name> {
        <name> <?{ ~$<name> ne 'return' }> <args>**0..1
    }

    token infix:sym<,> { <sym>  <O('%comma, :op<list>')> }

    token postcircumfix:sym<( )> {
        '(' <.ws> <arglist> ')' <O('%methodop')>
    }

    proto token quote { <...> }
    token quote:sym<'> { <?[']> <quote_EXPR: ':q'>  }
    token quote:sym<"> { <?["]> <quote_EXPR: ':qq'> }

    token value {
        | <quote>
        | <number>
    }

    token number {
        $<sign>=[<[+\-]>?]
        [ <dec_number> | <integer> ]
    }

    token identifier { <.ident> }

    token name { <identifier> ['::'<identifier>]* }

    token arglist {
        <.ws>
        [
        | <EXPR('f=')>
        | <?>
        ]
    }

    token args {
        | '(' <arglist> ')'
        | \s+ <arglist>
    }

    method TOP() {
        my %*LANG;
        %*LANG<XML>         := XML::Grammar;
        %*LANG<XML-actions> := XML::Actions;

        my $source_id := nqp::sha1(self.target() ~ nqp::time_n());
        my $file := nqp::getlexdyn('$?FILES');
        my $*W := nqp::isnull($file) ??
            XML::World.new(:handle($source_id)) !!
            XML::World.new(:handle($source_id), :description($file));

        nqp::say('parsing: '~$file);
        
        if $file ~~ / .*\.xml$ / {
            self.xml
        } elsif $file ~~ / .*\.json$ / {
            self.json;
        } elsif $file ~~ / .*\.mo$ / {
            self.prog;
        } else {
            self.panic("Unrecognized source: "~$file);
        }
    }

    token xml  { <data=.LANG('XML','TOP')> }
    token json { <.panic: 'JSON parser not implemented yet'> }
    rule prog  {
        ^ ~ $ <statements> || <.panic('Syntax Error')>
    }

    rule statements {
        <statement>*
    }

    rule statement {
        [
        | <control>
        | <template_definition>
        | <EXPR> <.ws>
        ]
    }

    proto rule control { <...> }

    rule control:sym<for> {
        'for' <EXPR>
        [
        | <statement>
        | <code_block> 'end'
        ]
    }

    rule control:sym<if> {
        'if' <EXPR>
        [
        | <statement>
        | <code_block> 'end'
        ]
    }

    rule code_block {
        '{{' ~ '}}' <statements>
    }

    rule template_definition {
        'template' <name> ':' <template_block>
    }

    rule template_block {
        ^^ '---{{' ~ '---}}' <template_body>
    }

    rule template_body {
        [<!before ^^ '---}}'>.]*
    }
}
