use NQPHLL;
use xml;
#use json;

grammar MO::Grammar is HLL::Grammar {
    INIT {
        MO::Grammar.O(':prec<y=>, :assoc<unary>', '%attrop');
        MO::Grammar.O(':prec<x=>, :assoc<unary>', '%methodop');
        MO::Grammar.O(':prec<g=>, :assoc<list>, :nextterm<nulltermish>',  '%comma');
        MO::Grammar.O(':prec<f=>, :assoc<list>',  '%list_infix');
        MO::Grammar.O(':prec<e=>, :assoc<unary>', '%list_prefix');
    }

    our %builtins;

    BEGIN {
        %builtins := nqp::hash(
            'die',    'die',
            'say',    'say',
            'exit',   'exit',
            'print',  'print',
            'sleep',  'sleep',
            );
    }

    token term:sym<value> { <value> }
    token term:sym<name>  {
        <name> <?{ ~$<name> ne 'return' }> <args>**0..1
    }
    token term:sym«.»  { <sym> <name> }
    token term:sym«->» { <sym> <name> }

    token infix:sym<,> { <sym>  <O('%comma, :op<list>')> }

    token postcircumfix:sym<( )> {
        '(' <.ws> <arglist> ')'  <O('%methodop')>
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

    token name { <!keyword> <.ident> ['::'<.ident>]* }

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

    token keyword {
        [
        | 'if' | 'else' | 'elsif' | 'end'
        | 'for' | 'def'
        ] <!ww>
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
    rule  prog {
        ^ ~ $ <statements> || <.panic('Syntax Error')>
    }

    rule statements {
        <.ws>
        <statement>*
    }

    rule statement {
        [
        | <control>
        | <EXPR>
        ]
    }

    proto rule control { <...> }

    token control:sym<cond> {
        $<op>=['if'|'unless'] ~ ['end'|<?{ +$<statements><statement> eq 1 }>';']
        [ \s+ <EXPR> <statements> [<else=.elsif>|<else>]? ]
    }

    token control:sym<loop> {
        $<op>=['while'|'until'] ~ 'end'
        [ \s+ <EXPR> <statements> ]
    }

    token elsif { 'elsif' ~ [<else=.elsif>|<else>]? [ <.ws> <EXPR> <statements> ] }
    token else { 'else' <statements> }

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
