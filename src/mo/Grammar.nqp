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
    token term:sym<name>        { <name> }

    token term:sym«.»  {
        | <sym> <name=.ident> [$<query>='?'|<args>]
        | <?before <sym>> <selector>
    }
    token term:sym«->» { <?before <sym>> <selector> }

    token term:sym<def>  {:s
        <sym> '(' ~ ')' [ { self.push_scope( ~$<sym> ) } <params>? ]
        '{' ~ '}' <statements>
    }
    token term:sym<return> {:s <sym> [['(' ~ ')' <EXPR>] | <EXPR>]? }
    token term:sym<str>    {:s
        <sym>\s $<name>=[<.ident>['::'<.ident>]*] ['with' <EXPR>]?
    }

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
    token circumfix:sym<| |> { '|' ~ '|' <EXPR> }
    token circumfix:sym«< >» { '<' ~ '>' <EXPR=.quote> }

    token postcircumfix:sym<( )> { '(' ~ ')' <arglist> <O('%methodop')> }
    token postcircumfix:sym<[ ]> { '[' ~ ']' <EXPR> <O('%methodop')> }
    token postcircumfix:sym<{ }> { '{' ~ '}' <EXPR> <O('%methodop')> }
    token postcircumfix:sym<ang> { <?[<]> <quote_EXPR: ':q'> <O('%methodop')> }

    token postfix:sym«.»  {
        <sym> <name=.ident> [$<query>='?'|<args>]?
        <O('%methodop')>
    }
    token postfix:sym«->» {
        <sym> <name=.ident> <O('%methodop')>
    }

    proto token value           { <...> }
    token value:sym<quote>      { <quote> }
    token value:sym<number>     { <number> }

    proto token quote   { <...> }
    token quote:sym<'>  { <?[']> <quote_EXPR: ':q'>  }
    token quote:sym<">  { <?["]> <quote_EXPR: ':qq'> }

    token quote_escape:sym<$>   { <?[$]> <?quotemod_check('s')> <variable> }
    token quote_escape:sym<{ }> { <?[{]> <?quotemod_check('c')> <block> }
    token quote_escape:sym<esc> { \\ e <?quotemod_check('b')> }

    token number { $<sign>=[<[+\-]>?] [ <dec_number> | <integer> ] }

    token name { <!keyword> <.ident> ['::'<.ident>]* }

    token args { '(' ~ ')' <arglist> }
    token arglist {
        <.ws>
        [
        | <EXPR('b=')>
        | <?>
        ]
    }

    proto token kw      { <...> }
    token kw:sym<if>    { <sym> }
    token kw:sym<else>  { <sym> }
    token kw:sym<elsif> { <sym> }
    token kw:sym<for>   { <sym> }
    token kw:sym<while> { <sym> }
    token kw:sym<until> { <sym> }
    token kw:sym<yield> { <sym> }
    token kw:sym<str>   { <sym> }
    token kw:sym<def>   { <sym> }
    token kw:sym<end>   { <sym> }
    token kw:sym<le>    { <sym> }
    token kw:sym<ge>    { <sym> }
    token kw:sym<lt>    { <sym> }
    token kw:sym<gt>    { <sym> }
    token kw:sym<eq>    { <sym> }
    token kw:sym<ne>    { <sym> }
    token kw:sym<cmp>   { <sym> }
    token kw:sym<not>   { <sym> }
    token kw:sym<and>   { <sym> }
    token kw:sym<or>    { <sym> }
    token kw:sym<use>   { <sym> }
    token kw:sym<var>   { <sym> }
    token kw:sym<return>{ <sym> }
    token kw:sym<as>    { <sym> }
    token kw:sym<template>{ <sym> }
    token kw:sym<lang> { <sym> }
    token kw:sym<class> { <sym> }
    token kw:sym<method>{ <sym> }

    token keyword { <kw> <!ww> }

    method TOP() {
        # Language braid.
        my %*LANG;
        %*LANG<XML>         := XML::Grammar;
        %*LANG<XML-actions> := XML::Actions;

        # Package declarator to meta-package mapping. Starts pretty much empty;
        # we get the mappings either imported or supplied by the setting. One
        # issue is that we may have no setting to provide them, e.g. when we
        # compile the setting, but it still wants some kinda package. We just
        # fudge in knowhow for that.
        my %*HOW;
        %*HOW<knowhow>   := nqp::knowhow();
        %*HOW<package>   := nqp::knowhow();
        %*HOW<attribute> := MO::AttributeHOW;
        %*HOW<class>     := MO::ClassHOW;
        %*HOW<template>  := MO::TemplateHOW;

        my $*GLOBALish;
        my $*EXPORT;
        my $*UNIT; # the top-level block of the current compile unit.

        # Symbol table and serialization context builder - keeps track of
        # objects that cross the compile-time/run-time boundary that are
        # associated with this compilation unit.
        my $source_id := nqp::sha1(self.target() ~ nqp::time_n());
        my $file := nqp::getlexdyn('$?FILES');
        my $*W := nqp::isnull($file) ??
            MO::World.new(:handle($source_id)) !!
            MO::World.new(:handle($source_id), :description($file));

        $*W.create_data_models();
        $*W.add_builtin_objects();

        self.prog
    }

    my method push_scope($type, $params?) {
        my $scope := $*W.push_scope($/);
        $scope.annotate('type', $type);
        if $params {
           $params := [$params] unless nqp::islist($params);
           for $params {
               $scope.symbol($_, :scope<lexical>, :decl<param>);
               $scope[0].push( QAST::Var.new( :name($_), :scope<lexical>, :decl<param> ) );
           }
        }
        $scope;
    }

    method newscope($type, $params?, $with = 0) {
        my $scope := self.push_scope($type, $params);
        $scope.annotate('with', 1) if $with;
        self.statements;
    }

    proto token selector { <...> }
    token selector:sym<[ ]> {:s '[' ~ ']' <EXPR> <selector>? } #[<EXPR>+ %% ',']
    token selector:sym<{ }> {:s '{' ~ '}' <newscope: 'selector', '$_', 1> <selector>? }
    token selector:sym«:»  { <sym>
        [<?before '??'>$<namespace>='?'|<namespace=.ident>]?
        [<selector>|$<query>='?']?
    }
    token selector:sym«..» { <sym> }
    token selector:sym«.»  {:s <sym> $<name>=[[<.ident>':']?<.ident>] }
    token selector:sym«->» {:s <sym> [ <select> | <.panic: 'confused selector'> ] <selector>? }

    proto token select          { <...> }
    token select:sym<name>      { <name=.ident> }
    token select:sym<quote>     { <quote> }
    token select:sym<path>      { '<' ~ '>' [ <quote> | $<path>=[[<![>]>.]+] ] }
    token select:sym<me>        { <?before '['|'{'|':'|'.'> }
    token select:sym<*>         { <sym> }

    token xml  { <data=.LANG('XML','TOP')> }
    token json { <.panic: 'JSON parser not implemented yet'> }
    rule  prog {
        {
            # The GLOBAL view from the internal of the unit.
            $*GLOBALish := $*W.pkg_create_mo($/, %*HOW<package>, :name('GLOBAL'));
            $*W.pkg_compose($*GLOBALish);

            # The package from the user's view.
            $*EXPORT := $*W.pkg_create_mo($/, %*HOW<package>, :name('EXPORT'));
            $*W.pkg_compose($*EXPORT);

            # Add some very early fixup tasks.
            $*W.add_fixup_package($*GLOBALish, 'GLOBAL');
            $*W.add_fixup_package($*EXPORT, 'EXPORT');
            $*W.add_fixup(QAST::Stmts.new(
                QAST::Op.new( :op<bindcurhllsym>,
                    QAST::SVal.new( :value('GLOBAL') ),
                    QAST::Var.new( :scope<local>, :name<GLOBAL> )
                ),
                QAST::Op.new( :op<bindcurhllsym>,
                    QAST::SVal.new( :value('EXPORT') ),
                    QAST::Var.new( :scope<local>, :name<EXPORT> )
                ),
            ));

            $*UNIT := self.push_scope('unit');
            $*UNIT.symbol('@ARGS', :scope<lexical>, :decl<param>);
            $*UNIT.symbol('$_', :scope<lexical>, :decl<var>);
            $*UNIT.annotate('package', $*GLOBALish);
        }
        ^ ~ $ <statements> || <.panic: 'Confused'>
    }

    token sigil  { <[$@%&]> }
    token twigil { <[.]> } #{ <[*!?]> }
    token variable {
        <sigil> <twigil>? [$<name>=[<.ident> ['::'<.ident>]*]]
    }

    token initializer {
        '=' <.ws> <EXPR('f=')>
    }

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
        $<op>=['if'|'unless']\s <EXPR>
        [
        | '{' ~ '}' <statements> <else>?
        | <?> ~ 'end' [ <statements> <else>? ]
        ]
    }

    rule control:sym<loop> {
        $<op>=['while'|'until']\s <EXPR> <loop_block>
    }

    rule control:sym<for> {
        <sym>\s <EXPR> [ <for_block> | <.panic: "expect 'for' block"> ]
    }

    rule control:sym<with> {
        <sym>\s <EXPR> [ <with_block> | <.panic: "expect 'with' block"> ]
    }

    proto rule else { <...> }
    rule else:sym<if> { 'elsif'\s <EXPR> ~ <else>? [ '{' ~ '}' <statements> | <statements> ] }
    rule else:sym< > { 'else'\s [ '{' ~ '}' <statements> | <statements> ] }

    rule block { '{' ~ '}' <newscope:''> }

    proto rule loop_block { <...> }
    rule loop_block:sym<{ }> { 'do'? '{' ~ '}' <newscope: 'loop'> }
    rule loop_block:sym<end> { <![{]> ~ 'end' <newscope: 'loop'> }

    proto rule for_block { <...> }
    rule for_block:sym<{ }> { 'do'? '{' ~ '}' <newscope: 'for', '$_'> }
    rule for_block:sym<end> { <![{]> ~ 'end' <newscope: 'for', '$_'> }

    proto rule with_block { <...> }
    rule with_block:sym<{ }> { 'do'? '{' ~ '}' <newscope: 'with', '$_', 1> }
    rule with_block:sym<end> { <![{]> ~ 'end' <newscope: 'with', '$_', 1> }

    proto rule def_block { <...> }
    rule def_block:sym<{ }> { '{' ~ '}' <statements> }
    rule def_block:sym<end> { <![{]> ~ 'end' <statements> }

    proto rule declaration { <...> }

    rule declaration:sym<var> {
        :my $*IN_DECL;
        <sym>\s { $*IN_DECL := ~$<sym>; }
        <variable> <initializer>? ';'? { $*IN_DECL := 0; }
    }

    rule declaration:sym<use> {
        :my $*IN_DECL;
        <sym>\s { $*IN_DECL := ~$<sym>; }
        <name> ';'? { $*IN_DECL := 0; }
    }

    rule declaration:sym<rule> {
        <targets=.quote>+ ':' <prerequisites=.quote>*
        '{' ~ '}'
        [
            { self.push_scope( ~$<sym>, [ '$_', '@_' ] ) }
            <statements>
        ]
    }

    proto rule definition { <...> }

    rule definition:sym<template> {
        :my $outerpackage := $*W.get_package;
        <sym>\s <name=.ident>
        <template_starter> ~ <template_stopper>
        [
            {
                my $name := ~$<name>;
                my $how := %*HOW{~$<sym>};
                my $type := $how.new_type(:name($name));

                $*W.install_package_symbol($outerpackage, $name, $type);
                $*W.install_package_symbol($*EXPORT, $name, $type) if $*W.is_export_name($name);

                my $scope := self.push_scope( ~$<sym>, [ 'me', '$_' ] );
                $scope.annotate('package', $type);
            }
            <template_body>
        ]
    }
    rule template_starter { ^^ '-'**3..*\n? }
    rule template_stopper { \n? [<.template_starter>'end'|$] }
    rule template_body { <template_atom>* }

    proto token template_atom   { <...> }
    token template_atom:sym<$> { <variable> }
    token template_atom:sym<()> { '$(' ~ ')' <EXPR> }
    token template_atom:sym<{}> { '${' ~ '}' <statements> }
    token template_atom:sym<^^> { <template_statement> }
    token template_atom:sym<.>  { <template_char_atom>+ }

    token template_char_atom { <!before <.template_stopper>|<.tsp>><![$]>. }

    proto rule template_statement { <...> }
    token template_statement:sym< > { <.tsp>\n }
    token template_statement:sym<for> {
        <.tsp> ['for'\s+<EXPR>[';'<.eis>\n]?] ~ [<.tsp>'end'<.els>]
        [
            { self.push_scope( ~$<sym>, '$_' ) }
            <template_atom>*
        ]
    }
    token template_statement:sym<if> {
        <.tsp> ['if'\s+<EXPR>[';'<.eis>\n]?] ~ [<.tsp>'end'<.els>]
        [ <template_atom>* <else=.template_else>? ]
    }

    proto rule template_else { <...> }
    token template_else:sym<if> {
        <.tsp> ['elsif'\s+<EXPR><.eis>] ~ <else=.template_else>? <template_atom>*
    }
    token template_else:sym< > {
        <.tsp> 'else'<.eis> <template_atom>*
    }

    token eis { [<![\n]>\s]* } # eat inline space
    token els { <eis>\n }      # eat line space
    token tsp { ^^'.'<eis> }   # template statement prefix

    rule params { <param>+ %% ',' }
    token param { <sigil> <name=.ident> }

    rule definition:sym<def> {
        <sym>\s
        [
        | <?keyword> <.panic: 'keyword used as name'>
        | <name=.ident>
        ]
        '(' ~ ')' [ { self.push_scope( ~$<sym> ) } <params>? ]
        [ <def_block> | <.panic: 'expect function body'> ]
    }

    rule definition:sym<class> {
        :my $outerpackage := $*W.get_package;
        <sym>\s <name=.ident> '{' ~ '}'
        [
            {
                my $name := ~$<name>;
                my $how := %*HOW{~$<sym>};
                my $type := $how.new_type(:name($name));

                $*W.install_package_symbol($outerpackage, $name, $type);
                $*W.install_package_symbol($*EXPORT, $name, $type) if $*W.is_export_name($name);

                my $scope := self.push_scope( ~$<sym>, 'me' );
                $scope.annotate('package', $type);
            }
            <class_member>*
        ]
    }

    proto rule class_member { <...> }
    rule class_member:sym<method> {
        <sym>\s <name=.ident>
        '(' ~ ')' [ { self.push_scope( 'method', 'me' ) } <params> ]?
        '{' ~ '}' <statements>
    }

    rule class_member:sym<$> {
        :my $*IN_DECL;
        { $*IN_DECL := 'member'; }
        <variable> <initializer>? ';'? { $*IN_DECL := 0; }
    }

    rule definition:sym<lang> {
        :my $*IN_DECL; { $*IN_DECL := 'compile'; }
        <sym>\s <langname=.ident> ['as'\s [<variable>|<name=.ident>]]?
        #:my $lang; { $lang := ~$<langname> }
        #<template_starter> <langbody=.LANG($lang,'TOP')> <template_stopper>
        <template_starter> ~ <template_stopper> $<source>=[<template_char_atom>*]
    }
}
