use NQPHLL;
use xml;
use json;

grammar MO::Grammar is HLL::Grammar {
    INIT {
        # obj.method
        MO::Grammar.O(':prec<z=>, :assoc<unary>', '%methodop');

        # y: **
        MO::Grammar.O(':prec<y=>, :assoc<left>',  '%exponentiation');
        # x: ! ~ + - (unary)
        MO::Grammar.O(':prec<x=>, :assoc<unary>', '%unary');
        # w: * / %
        MO::Grammar.O(':prec<w=>, :assoc<left>',  '%multiplicative');
        # u: + -
        MO::Grammar.O(':prec<u=>, :assoc<left>',  '%additive');
        # t: >> <<
        MO::Grammar.O(':prec<t=>, :assoc<left>',  '%bitshift');
        # s: &
        MO::Grammar.O(':prec<s=>, :assoc<left>',  '%bitand');
        # r: ^ |
        MO::Grammar.O(':prec<r=>, :assoc<left>',  '%bitor');
        # q: <= < > >= le lt gt ge
        MO::Grammar.O(':prec<q=>, :assoc<left>',  '%comparison');
        # n: <=> == === != =~ !~ eq ne cmp
        MO::Grammar.O(':prec<n=>, :assoc<left>',  '%equality');
        # l: &&
        MO::Grammar.O(':prec<l=>, :assoc<left>',  '%logical_and');
        # k: ||
        MO::Grammar.O(':prec<k=>, :assoc<left>',  '%logical_or');
        # q: ?:
        MO::Grammar.O(':prec<g=>, :assoc<right>', '%conditional');
        # f: = %= { /= -= += |= &= >>= <<= *= &&= ||= **=
        MO::Grammar.O(':prec<f=>, :assoc<right>', '%assignment');
        # e: not (unary)
        MO::Grammar.O(':prec<e=>, :assoc<unary>', '%loose_not');
        # c: or and
        MO::Grammar.O(':prec<c=>, :assoc<left>',  '%loose_logical');

        # b: ,
        MO::Grammar.O(':prec<b=>, :assoc<list>, :nextterm<nulltermish>',  '%comma');

        #MO::Grammar.O(':prec<e=>, :assoc<list>',  '%list_infix');
        #MO::Grammar.O(':prec<d=>, :assoc<unary>', '%list_prefix');
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
    token term:sym<name>  { # call
        <name> <?{ ~$<name> ne 'return' }> <args>**0..1
    }
    token term:sym«.»  { <sym> <name=.ident> <.ws> <selector>**0..1 }
    token term:sym«->» { <sym> <.ws> <name=.ident> <.ws> <selector>**0..1 }

    # Operators - mostly stolen from NQP's Rubyish example
    token infix:sym<**> { <sym>  <O('%exponentiation, :op<pow_n>')> }

    token prefix:sym<+> { <sym>  <O('%unary, :op<numify>')> }
    token prefix:sym<~> { <sym>  <O('%unary, :op<stringify>')> }
    token prefix:sym<-> { <sym><![>]>  <O('%unary, :op<neg_n>')> }
    token prefix:sym<!> { <sym>  <O('%unary, :op<not_i>')> }

    token infix:sym<*>  { <sym> <O('%multiplicative, :op<mul_n>')> }
    token infix:sym</>  { <sym> <O('%multiplicative, :op<div_n>')> }
    token infix:sym<%>  { <sym><![>]> <O('%multiplicative, :op<mod_n>')> }

    token infix:sym<+>  { <sym> <O('%additive, :op<add_n>')> }
    token infix:sym<->  { <sym> <O('%additive, :op<sub_n>')> }
    token infix:sym<~>  { <sym> <O('%additive, :op<concat>')> }

    token infix:sym«<<»   { <sym>  <O('%bitshift, :op<bitshiftl_i>')> }
    token infix:sym«>>»   { <sym>  <O('%bitshift, :op<bitshiftr_i>')> }

    token infix:sym<&>  { <sym> <O('%bitand, :op<bitand_i>')> }
    token infix:sym<|>  { <sym> <O('%bitor,  :op<bitor_i>')> }
    token infix:sym<^>  { <sym> <O('%bitor,  :op<bitxor_i>')> }

    token infix:sym«<=»   { <sym><![>]>  <O('%comparison, :op<isle_n>')> }
    token infix:sym«>=»   { <sym>  <O('%comparison, :op<isge_n>')> }
    token infix:sym«<»    { <sym>  <O('%comparison, :op<islt_n>')> }
    token infix:sym«>»    { <sym>  <O('%comparison, :op<isgt_n>')> }
    token infix:sym«le»   { <sym>  <O('%comparison, :op<isle_s>')> }
    token infix:sym«ge»   { <sym>  <O('%comparison, :op<isge_s>')> }
    token infix:sym«lt»   { <sym>  <O('%comparison, :op<islt_s>')> }
    token infix:sym«gt»   { <sym>  <O('%comparison, :op<isgt_s>')> }

    token infix:sym«==»   { <sym>  <O('%equality, :op<iseq_n>')> }
    token infix:sym«!=»   { <sym>  <O('%equality, :op<isne_n>')> }
    token infix:sym«<=>»  { <sym>  <O('%equality, :op<cmp_n>')> }
    token infix:sym«eq»   { <sym>  <O('%equality, :op<iseq_s>')> }
    token infix:sym«ne»   { <sym>  <O('%equality, :op<isne_s>')> }
    token infix:sym«cmp»  { <sym>  <O('%equality, :op<cmp_s>')> }

    token infix:sym<&&>   { <sym>  <O('%logical_and, :op<if>')> }
    token infix:sym<||>   { <sym>  <O('%logical_or,  :op<unless>')> }

    token infix:sym<? :> {:s '?' <EXPR('i=')>
                             ':' <O('%conditional, :reducecheck<ternary>, :op<if>')>
    }

    token infix:sym<=>  { <sym><![>]> <O('%assignment, :op<bind>')> }

    token prefix:sym<not> { <sym>  <O('%loose_not,     :op<not_i>')> }
    token infix:sym<and>  { <sym>  <O('%loose_logical, :op<if>')> }
    token infix:sym<or>   { <sym>  <O('%loose_logical, :op<unless>')> }

    token infix:sym<,> { <sym>  <O('%comma, :op<list>')> }

    token circumfix:sym<( )> { '(' ~ ')' <EXPR> <O('%methodop')> }

    token postcircumfix:sym<[ ]> { '[' ~ ']' <EXPR> <O('%methodop')> }
    token postcircumfix:sym<{ }> { '{' ~ '}' <EXPR> <O('%methodop')> }
    token postcircumfix:sym<ang> { <?[<]> <quote_EXPR: ':q'> <O('%methodop')> }

    token postfix:sym«.» { <sym> <name=.ident> <O('%methodop')> }
    token postfix:sym«->» { <sym> <name=.ident> <O('%methodop')> }

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
            MO::World.new(:handle($source_id)) !!
            MO::World.new(:handle($source_id), :description($file));

        my $*PARSING_SELECTOR;

        nqp::say('parsing: ' ~ $file);
        
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

    proto token selector { <...> }
    token selector:sym«.» { <sym> <name=.ident> }
    token selector:sym«->» { <sym> <name=.ident> [<.ws> <selector>]**0..1 }
    token selector:sym<[ ]> { '[' ~ ']' <EXPR> [<.ws> <selector>]**0..1 }
    token selector:sym<{ }> {
        '{' ~ '}' [ { $*PARSING_SELECTOR := 1; } <statements> ]
        [<.ws> <selector>]**0..1
        { $*PARSING_SELECTOR := nqp::null(); }
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
