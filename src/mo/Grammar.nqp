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

    our %builtins; # ops

    BEGIN {
        %builtins := nqp::hash(
            'die',      'die',
            'say',      'say',
            'exit',     'exit',
            'print',    'print',
            'sleep',    'sleep',
            'open',     'open',
            'pipe',     'openpipe',
            'system',   'system',
            'shell',    'shell',
            'execname', 'execname',
            'env',      'getenvhash',
            'null',     'null',
        );
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

    token term:sym<value>       { <value> }
    token term:sym<variable>    { <variable> }
    token term:sym<name>  { <name> <?{ ~$<name> ne 'return' }> <args>? }
    token term:sym«.»  { <?before <sym>> <selector> }
    token term:sym«->» { <?before <sym>> <selector> }

    token term:sym<yield> { <?before <sym>> <statement> }

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

    token infix:sym<? :> {:s '?' <EXPR('g=')>
                             ':' <O('%conditional, :reducecheck<ternary>, :op<if>')>
    }

    token infix:sym<=>  { <sym><![>]> <O('%assignment, :op<bind>')> }

    token prefix:sym<not> { <sym>  <O('%loose_not,     :op<not_i>')> }
    token infix:sym<and>  { <sym>  <O('%loose_logical, :op<if>')> }
    token infix:sym<or>   { <sym>  <O('%loose_logical, :op<unless>')> }

    token infix:sym<,>    { <sym>  <O('%comma, :op<list>')> }

    token circumfix:sym<( )> { '(' ~ ')' <EXPR> <O('%methodop')> }

    token postcircumfix:sym<[ ]> { '[' ~ ']' <EXPR> <O('%methodop')> }
    token postcircumfix:sym<{ }> { '{' ~ '}' <EXPR> <O('%methodop')> }
    token postcircumfix:sym<ang> { <?[<]> <quote_EXPR: ':q'> <O('%methodop')> }

    token postfix:sym«.» { <sym> <name=.ident> <args>? <O('%methodop')> }
    token postfix:sym«?» { <sym> <name=.ident> <O('%methodop')> }

    proto token value { <...> }
    token value:sym<quote> { <quote> }
    token value:sym<number> { <number> }

    proto token quote { <...> }
    token quote:sym<'> { <?[']> <quote_EXPR: ':q'>  }
    token quote:sym<"> { <?["]> <quote_EXPR: ':qq'> }

    token number { $<sign>=[<[+\-]>?] [ <dec_number> | <integer> ] }

    token name { <!keyword> <.ident> ['::'<.ident>]* }

    token args { '(' <arglist> ')' }
    token arglist {
        <.ws>
        [
        | <EXPR('b=')>
        | <?>
        ]
    }

    # | 'if' | 'else' | 'elsif' | 'for' | 'while' | 'until' | 'yield'
    # | 'def' | 'end'
    # | 'le' | 'ge' | 'lt' | 'gt' | 'eq' | 'ne' | 'cmp' | 'not' | 'and' | 'or'
    proto token kw      { <...> }
    token kw:sym<if>    { <sym> }
    token kw:sym<else>  { <sym> }
    token kw:sym<elsif> { <sym> }
    token kw:sym<for>   { <sym> }
    token kw:sym<while> { <sym> }
    token kw:sym<until> { <sym> }
    token kw:sym<yield> { <sym> }
    token kw:sym<def>   { <sym> }
    token kw:sym<end>   { <sym> }
    token kw:sym<use>   { <sym> }
    token kw:sym<sub>   { <sym> }
    token kw:sym<method>{ <sym> }

    token keyword { <kw> <!ww> }

    method TOP() {
        my %*LANG;
        %*LANG<XML>         := XML::Grammar;
        %*LANG<XML-actions> := XML::Actions;

        my $source_id := nqp::sha1(self.target() ~ nqp::time_n());
        my $file := nqp::getlexdyn('$?FILES');
        my $*W := nqp::isnull($file) ??
            MO::World.new(:handle($source_id)) !!
            MO::World.new(:handle($source_id), :description($file));

        # nqp::say('parsing: ' ~ $file);
        
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

    my method push_scope($type, $params?) {
        my $scope := $*W.push_scope($/);
        my $block := $scope<block>;
        $scope<type> := $type;
        if $params {
           $params := [$params] unless nqp::islist($params);
           for $params {
               $block.symbol($_, :scope<lexical>, :decl<param>);
               $block.push( QAST::Var.new( :name($_), :scope<lexical>, :decl<param> ) );
           }
        }
        $scope;
    }

    method newscope($type, $params?, $with = 0) {
        my $scope := self.push_scope($type, $params);
        $scope<with> := 1 if $with;
        self.statements;
    }

    proto token selector { <...> }
    token selector:sym<[ ]> {:s '[' ~ ']' <EXPR> <selector>? } #[<EXPR>+ %% ',']
    token selector:sym<{ }> {:s '{' ~ '}' <newscope: 'selector', '$', 1> <selector>? }
    token selector:sym«..» { <sym> }
    token selector:sym«.»  {:s <sym> <name=.ident> }
    token selector:sym«->» {:s <sym>
        [ <select> | <.panic: 'confused selector'> ] <selector>?
    }

    proto token select { <...> }
    token select:sym<name> { <name=.ident> }
    token select:sym<quote> { <quote> }
    token select:sym<[> { <?before '['> }

    token xml  { <data=.LANG('XML','TOP')> }
    token json { <.panic: 'JSON parser not implemented yet'> }
    rule  prog {
        {
            my $scope := self.push_scope('prog');
            my $*UNIT := $scope<block>;
            $*UNIT.symbol('$', :scope<lexical>, :decl<var>);
            # $*UNIT.push( QAST::Op.new( :op<bind>,
            #     QAST::Var.new( :name<$>, :scope<lexical>, :decl<var> ),
            #     QAST::Op.new( :op<callmethod>, :name<root>,
            #         QAST::Var.new( :scope<lexical>, :name($MODEL.name) ),
            #     ),
            # ) );
        }
        ^ ~ $ <statements> || <.panic: 'Confused'>
    }

    token variable {
        #<sigil> <twigil>? <name=.ident>
        <sigil> <name=.ident>?
    }

    token sigil  { <[$@%&]> }
    token twigil { <[*!?]> }

    rule statements { <.ws> <statement>* }

    proto rule statement                { <...> }
    rule statement:sym<control>         { <control> }
    rule statement:sym<declaration>     { <declaration> }
    rule statement:sym<definition>      { <definition> }
    rule statement:sym<EXPR>            { <EXPR> ';'? }

    rule statement:sym<yield_t> { 'yield' <name=.ident> ';'? }
    rule statement:sym<yield_x> { 'yield' <EXPR> ';'? }

    proto rule control { <...> }

    rule control:sym<cond> {
        [ $<op>=['if'|'unless']\s <EXPR> ] ~ 'end'
        [ <statements> <else>? ]
    }

    rule control:sym<loop> {
        $<op>=['while'|'until']\s <EXPR> <loop_block>
    }

    rule control:sym<for> {
        <sym>\s <EXPR> [ <for_block> | <.panic: "expects 'for' block"> ]
    }

    rule control:sym<with> {
        <sym>\s <EXPR> [ <with_block> | <.panic: "expects 'with' block"> ]
    }

    proto rule else { <...> }
    rule else:sym<if> { [ 'elsif'\s ] ~ <else>? [ <EXPR> <statements> ] }
    rule else:sym< > { 'else'\s <statements> }

    proto rule loop_block { <...> }
    rule loop_block:sym<{ }> { 'do'? '{' ~ '}' <newscope: 'loop'> }
    rule loop_block:sym<end> { <![{]> ~ 'end' <newscope: 'loop'> }

    proto rule for_block { <...> }
    rule for_block:sym<{ }> { 'do'? '{' ~ '}' <newscope: 'for', '$'> }
    rule for_block:sym<end> { <![{]> ~ 'end' <newscope: 'for', '$'> }

    proto rule with_block { <...> }
    rule with_block:sym<{ }> { 'do'? '{' ~ '}' <newscope: 'with', '$', 1> }
    rule with_block:sym<end> { <![{]> ~ 'end' <newscope: 'with', '$', 1> }
    rule with_block:sym<yield> { 'yield' <statement> }

    proto rule declaration { <...> }
    rule declaration:sym<use> {
        <sym>\s <name> ';'?
    }

    proto rule definition { <...> }

    rule definition:sym<template> {
        <sym>\s <name=.ident>
        <template_starter> ~ <template_stopper>
        [ { self.push_scope( 'template', '$' ) } <template_body> ]
    }
    rule template_starter { ^^ '-'**3..*\n }
    rule template_stopper { \n? <.template_starter> 'end' }
    rule template_body { <template_atom>* }

    proto token template_atom   { <...> }
    token template_atom:sym<()> { '$(' ~ ')' <EXPR> }
    token template_atom:sym<{}> { '${' ~ '}' <statements> }
    token template_atom:sym<.>  { [<!before <.template_stopper>><![$]>.]+ }

    rule params { <param>+ %% ',' }
    token param { <sigil> <name=.ident> }

    rule definition:sym<sub> {
        <sym>\s <name>
        '(' ~ ')' [ { self.push_scope( 'sub' ) } <params> ]?
        '{' ~ '}' <statements>
    }

    rule definition:sym<class> {
        <sym>\s <name> '{' ~ '}' [<class_member>*]
    }

    proto rule class_member { <...> }
    rule class_member:sym<method> {
        <sym>\s <name>
        '(' ~ ')' [ { self.push_scope( 'method' ) } <params> ]?
        '{' ~ '}' <statements>
    }
}
