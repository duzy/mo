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
    token term:sym<colonpair>   { <colonpair> }

    token term:sym«.»  { <post_dot> }
    token term:sym«->» { <post_arrow> }

    token term:sym<def> {:s
        <sym> '(' ~ ')' [ { self.push_scope( ~$<sym> ) } <params>? ]
        '{' ~ '}' <statements>
    }
    token term:sym<return> {:s <sym> [['(' ~ ')' <EXPR>] | <EXPR>]? }
    token term:sym<str>    {:s <sym>\s $<name>=[[<.ident>['::'<.ident>]*]|<.panic: 'expecting template identifier'>] ['with' <EXPR>]? }
    token term:sym<map>    {:s <sym>\s <pred=.map_pred> <list=.EXPR> }
    token term:sym<lang>   { <sym>\s <lang(1)> }
    token term:sym<any>    { <?before <sym>><any=.control> }
    token term:sym<many>   { <?before <sym>><many=.control> }

    # Operators - mostly stolen from NQP's Rubyish example
    token infix:sym<**> { <sym>  <O('%exponentiation, :op<pow_n>')> }

    token prefix:sym<+> { <sym> <O('%unary, :op<numify>')> }
    token prefix:sym<~> { <sym> <O('%unary, :op<stringify>')> }
    token prefix:sym<-> { <sym><![>]> <O('%unary, :op<neg_n>')> }
    token prefix:sym<!> { <sym> <O('%unary, :op<falsey>')> } #{ <sym> <O('%unary, :op<not_i>')> }

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
    token infix:sym<:=> { <sym><.panic: '":=" as an assignment is not supported'> }

    token prefix:sym<not> { <sym>  <O('%loose_not,     :op<not_i>')> }
    token infix:sym<and>  { <sym>  <O('%loose_logical, :op<if>')> }
    token infix:sym<or>   { <sym>  <O('%loose_logical, :op<unless>')> }

    token infix:sym<,>    { <sym>  <O('%comma, :op<list>')> }

    token circumfix:sym<( )> { '(' ~ ')' <EXPR> <O('%methodop')> }
    token circumfix:sym<| |> { '|' ~ '|' <EXPR> }
    token circumfix:sym«< >» { '<' ~ '>' <EXPR=.quote> }

    token postcircumfix:sym<( )> {:s '(' ~ ')' <arglist> <O('%methodop')> }
    token postcircumfix:sym<[ ]> {:s '[' ~ ']' <EXPR> <O('%methodop')> }
    token postcircumfix:sym<{ }> { <!after \s*['any'|'map'|'many']> '{' ~ '}' [:s<EXPR>] <O('%methodop')> }
    token postcircumfix:sym<ang> { <?[<]> <quote_EXPR: ':q'> <O('%methodop')> }

    token postfix:sym«.»  { <post_dot> <O('%methodop')> }
    token postfix:sym«->» { <post_arrow> <O('%methodop')> }

    proto token value           { <...> }
    token value:sym<quote>      { <quote> }
    token value:sym<number>     { <number> }

    proto token quote   { <...> }
    token quote:sym<'>  { <?[']> <quote_EXPR: ':q'>  }
    token quote:sym<">  { <?["]> <quote_EXPR: ':qq'> }

    token quote_escape:sym<{ }> { <?[{]> <?quotemod_check('c')> <block> }
    token quote_escape:sym<$()> { <?before '$('> <?quotemod_check('s')> '$(' ~ ')' <EXPR> }
    token quote_escape:sym<$>   { <?[$]> <?quotemod_check('s')> <variable> }
    token quote_escape:sym<esc> { \\ e <?quotemod_check('b')> }

    token number { $<sign>=[<[+\-]>?] [ <dec_number> | <integer> ] }

    token name { <!keyword> <.ident> ['::'<.ident>]* }

    token post_dot { '.'$<name>=['*'|'^'|'.'|'?'|[<ns=.ident>':']?<ident>] [$<query>='?'|<args>]? }
    token post_arrow { '->'<select> }

    proto token select     { <...> }
    token select:sym<name> { $<name>=[[<ns=.ident>?':']? ['*'|<ident>]] }
    token select:sym<quote>{ <quote> }
    token select:sym<{ }>  { '{' ~ '}' <newscope: 'selector', '$_'> }

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
    token kw:sym<any>   { <sym> }
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
    token kw:sym<lang>  { <sym> }
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
        my $*INIT; # the unit's init block to be invoked before any statements.
        my $*LOAD; # the unit's load block to be invoked on 'use'.

        # Symbol table and serialization context builder - keeps track of
        # objects that cross the compile-time/run-time boundary that are
        # associated with this compilation unit.
        my $source_id := nqp::sha1(self.target() ~ nqp::time_n());
        my $file := nqp::getlexdyn('$?FILES');
        my $*W := nqp::isnull($file) ??
            MO::World.new(:handle($source_id)) !!
            MO::World.new(:handle($source_id), :description($file));

        $*W.create_data_models();
        $*W.install_builtin_objects();
        $*W.install_interpreters();

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

            $*INIT := QAST::Block.new( :name<init>, QAST::Stmts.new() );
            $*INIT.symbol('@_', :scope<lexical>, :decl<param>, :slurpy(1));
            $*INIT.symbol('%_', :scope<lexical>, :decl<param>, :slurpy(1), :named(1));
            $*INIT[0].push(QAST::Var.new(:name<@_>, :scope<lexical>, :decl<param>, :slurpy(1)));
            $*INIT[0].push(QAST::Var.new(:name<%_>, :scope<lexical>, :decl<param>, :slurpy(1), :named(1)));

            $*LOAD := QAST::Block.new( :name<load>, QAST::Stmts.new() );
            $*LOAD.symbol('@_', :scope<lexical>, :decl<param>, :slurpy(1));
            $*LOAD.symbol('%_', :scope<lexical>, :decl<param>, :slurpy(1), :named(1));
            $*LOAD[0].push(QAST::Var.new(:name<@_>, :scope<lexical>, :decl<param>, :slurpy(1)));
            $*LOAD[0].push(QAST::Var.new(:name<%_>, :scope<lexical>, :decl<param>, :slurpy(1), :named(1)));

            $*UNIT := self.push_scope('unit');
            $*UNIT.symbol('@ARGS', :scope<lexical>, :decl<param>);
            $*UNIT.symbol('$_',    :scope<lexical>, :decl<var>);
            $*UNIT.symbol('~init', :scope<lexical>);
            $*UNIT.symbol('~load', :scope<lexical>);
            $*UNIT.annotate('package', $*GLOBALish);
        }
        ^ ~ $ <statements> || <.panic: 'Confused'>
    }

    token sigil  { <[$@%&]> }
    token twigil { <[.]> } #{ <[*!?]> }
    token variable {
        <sigil> <twigil>? [$<name>=[<.ident> ['::'<.ident>]*] || <.panic: 'expects variable name'>]
    }

    token colonpair {
        ':'
        [
        | <name=.ident> <circumfix>?
        | <circumfix>
        | <variable>
        ]
    }

    token initializer { '=' <.ws> [<EXPR('f=')>|<.panic: 'unexpected initializer'>] }

    rule statements { <.ws> <statement>* }

    proto rule statement                { <...> }
    rule statement:sym<control>         { <control> }
    rule statement:sym<declaration>     { <declaration> }
    rule statement:sym<definition>      { <definition> }
    rule statement:sym<expr>            { <EXPR> ';'? } ## A singular <EXPR> must be the last to try.

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

    rule control:sym<any> {
        <sym>\s <pred=.map_pred> <list=.EXPR> <block=.map_block>?
    }

    rule control:sym<many> {
        <sym>\s <pred=.map_pred> <list=.EXPR> <block=.map_block>?
    }

    rule control:sym<with> {
        <sym>\s <EXPR> [ <with_block> | <.panic: "expect 'with' block"> ]
    }

    proto rule map_pred { <...> }
    token map_pred:sym<name> { <name> }
    token map_pred:sym<{ }> { '{' ~ '}' <statements> }

    proto rule else { <...> }
    rule else:sym<if> { 'elsif'\s <EXPR> ~ <else>? [ '{' ~ '}' <statements> | <statements> ] }
    rule else:sym< > { 'else'\s [ '{' ~ '}' <statements> | <statements> ] }

    rule block { '{' ~ '}' <newscope:''> }

    proto rule loop_block { <...> }
    # rule loop_block:sym<{ }> { 'do'? '{' ~ '}' <newscope: 'loop'> }
    # rule loop_block:sym<end> { <![{]> ~ 'end' <newscope: 'loop'> }
    rule loop_block:sym<{ }> { 'do'? '{' ~ '}' <statements> }
    rule loop_block:sym<end> { <![{]> ~ 'end'  <statements> }

    proto rule for_block { <...> }
    rule for_block:sym<{ }> { 'do'? '{' ~ '}' <newscope: 'for', '$_'> }
    rule for_block:sym<end> { <![{]> ~ 'end' <newscope: 'for', '$_'> }

    proto rule map_block { <...> }
    rule map_block:sym<{ }> { '{' ~ '}' <newscope: 'any', '$_'> }
    #rule map_block:sym<end> { <![{]> ~ 'end' <newscope: 'any', '$_'> }

    proto rule with_block { <...> }
    rule with_block:sym<{ }> { 'do'? '{' ~ '}' <newscope: 'with', '$_', 1> }
    rule with_block:sym<end> { <![{]> ~ 'end' <newscope: 'with', '$_', 1> }

    proto rule def_block { <...> }
    rule def_block:sym<{ }> { '{' ~ '}' <statements> }
    rule def_block:sym<end> { <![{]> ~ 'end' <statements> }

    proto rule declaration { <...> }
    rule declaration:sym<var> { <var_declaration> ';'? }
    rule declaration:sym<use> { <use_declaration> ';'? }

    rule var_declaration {
        :my $*IN_DECL;
        'var'\s { $*IN_DECL := 'var'; }
        <variable> <initializer>? { $*IN_DECL := 0; }
    }

    rule use_declaration {
        :my $*IN_DECL;
        'use'\s { $*IN_DECL := 'use'; }
        <name> <params=.EXPR>? <namedarg>* %% ','
        { $*IN_DECL := 0; }
    }

    rule namedarg { ':'<name=.ident> '(' ~ ')' <value=.EXPR>  }

    proto rule definition { <...> }

    rule definition:sym<rule> {
        :my $*IN_DECL; { $*IN_DECL := 'rule'; }
        <targets=.EXPR>+ $<colon>=':' <prerequisites=.EXPR>*
        {
            my $scope := $*W.current_scope;
            unless nqp::defined($scope.ann('package')) {
                $<colon>.CURSOR.panic("rule declared in non-package scope");
            }
            self.push_scope( ~$<sym>, [ 'me', '$_', '@_' ] );
        }
        '{' ~ '}' <statements> { $*IN_DECL := 0; }
    }

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

                my $scope := self.push_scope( ~$<sym>, [ 'me', 'cache', '$_' ] );
                $scope.annotate('package', $type);
            }
            <template_atoms>
        ]
    }
    rule template_starter { ^^ '-'**3..*\n? }
    rule template_stopper { \n? [<.template_starter>'end'|$] }

    token template_atoms { <template_atom>* }
    token template_atoms_scoped { [<!before <.tsp>['else'|'elsif'|'end']><template_atom>]* }

    proto token template_atom   { <...> }
    token template_atom:sym<$>  { <variable> }
    token template_atom:sym<()> { '$(' ~ ')' <x=.EXPR> }
    token template_atom:sym<{}> { '${' ~ '}' <statements> }
    token template_atom:sym<^^> { <.tsp> ~ <.tst> <template_statement> }
    token template_atom:sym<\\> { \\$<char>=. }
    token template_atom:sym<.>  { [<![$\\]><template_char_atom>]+ }

    token template_char_atom { <!before <.tsp>|<.template_stopper>>. }

    proto rule template_statement       { <...> }
    token template_statement:sym< >     { <?before <.tst>> }
    token template_statement:sym<for>   {
        ['for'\s+<tx:'for'><.tst>] ~ [<.tsp>'end']
        [ { self.push_scope( ~$<sym>, '$_' ) } <atoms=.template_atoms_scoped> ]
    }
    token template_statement:sym<if>    {
        ['if'\s+<tx:'if'><.tst>] ~ [<.tsp>'end']
        [ <atoms=.template_atoms_scoped> [<.tsp><else=.template_else>]? ]
    }
    token template_statement:sym<var>   { <var_declaration> [<?before <.eis>';'>|<.panic: 'template variable declaration must be terminated with ";"'>] }
    token template_statement:sym<expr>  { <tx:'bare'> } ## A singular <EXPR> must be the last to try.

    proto rule template_else    { <...> }
    token template_else:sym< >  { 'else'<.tst> <atoms=.template_atoms_scoped> }
    token template_else:sym<if> {
        ['elsif'\s+<tx:'elsif'><.tst>] ~ [<.tsp><else=.template_else>]?
        <atoms=.template_atoms_scoped>
    }

    token tx($tag) { <EXPR>|<.panic: "unexpected '$tag' expresion"> }

    token eis { [<![\n]>\s]* }  # eat inline space
    token els { <.eis>\n }      # eat line space
    token tsp { ^^'.'<.eis> }   # template statement prefix
    token tst { # template statement terminator
        <.eis>
        [
        | [';'<.eis>]? \n
        | <?before <.tsp>|<.template_stopper>>
        | <?before <.template_char_atom>>
        | <.panic: "unexpected terminator">
        ]
    }

    rule params { <param>+ %% ',' }
    proto token param { <...> }
    token param:sym<$> { <parvar> }
    token param:sym<:> { <sym><parvar> }
    token parvar { <sigil> <name=.ident> }

    rule definition:sym<def> {
        <sym>\s
        [
        | <?keyword> <.panic: 'keyword used as name'>
        | <name=.ident>
        ]
        {
            my $scope := self.push_scope( ~$<sym> );
            $scope.name( ~$<name> );

            my $package := $*W.get_package($scope.ann('outer'));
            $*W.install_package_routine($package, $scope.name, $scope);

            my $outer := $scope.ann('outer');
            $outer.symbol('&'~$scope.name, :scope<lexical>, :proto(1), :declared(1) );
            $outer[0].push( QAST::Op.new( :op<bind>,
                QAST::Var.new( :name('&'~$scope.name), :scope<lexical>, :decl<var> ),
                $scope
            ) );

            $outer[0].push( QAST::Op.new( :node($/), :op<bindkey>,
                QAST::Op.new( :op<who>, QAST::WVal.new( :value($*EXPORT) ) ),
                QAST::SVal.new( :value($scope.name) ),
                QAST::Var.new( :name('&'~$scope.name), :scope<lexical> ),
            ) ) if $*W.is_export_name($scope.name);
        }
        '(' ~ ')' <params>?
        [ <def_block> | <.panic: 'expect function body'> ]
    }

    rule definition:sym<init> {
        <sym>\s '{' ~ '}'
        [
            {
                my $scope := self.push_scope( ~$<sym> );
                $scope.symbol('@_', :scope<lexical>, :decl<param>, :slurpy(1));
                $scope.symbol('%_', :scope<lexical>, :decl<param>, :slurpy(1), :named(1));
                $scope[0].push(QAST::Var.new(:name<@_>, :scope<lexical>, :decl<param>, :slurpy(1)));
                $scope[0].push(QAST::Var.new(:name<%_>, :scope<lexical>, :decl<param>, :slurpy(1), :named(1)));
            }
            <statements>
        ]
    }

    rule definition:sym<load> {
        <sym>\s '{' ~ '}'
        [
            {
                my $scope := self.push_scope( ~$<sym> );
                $scope.symbol('@_', :scope<lexical>, :decl<param>, :slurpy(1));
                $scope.symbol('%_', :scope<lexical>, :decl<param>, :slurpy(1), :named(1));
                $scope[0].push(QAST::Var.new(:name<@_>, :scope<lexical>, :decl<param>, :slurpy(1)));
                $scope[0].push(QAST::Var.new(:name<%_>, :scope<lexical>, :decl<param>, :slurpy(1), :named(1)));
            }
            <statements>
        ]
    }

    rule definition:sym<class> {
        <sym>\s <name=.ident>
        {
            my $name := ~$<name>;
            my $how := %*HOW{~$<sym>};
            my $type := $how.new_type(:name($name));
            my $outerpackage := $*W.get_package;

            $*W.install_package_symbol($outerpackage, $name, $type);
            $*W.install_package_symbol($*EXPORT, $name, $type) if $*W.is_export_name($name);

            my $scope := self.push_scope( ~$<sym>, 'me' );
            $scope.symbol('@_', :scope<lexical>, :decl<param>, :slurpy(1));
            $scope.symbol('%_', :scope<lexical>, :decl<param>, :slurpy(1), :named(1));
            $scope.annotate('class-name', $name);
            $scope.annotate('package', $type);
        }
        [ '<' ~ '>' <params>? ]?
        '{' ~ '}' <class_member>*
    }

    proto rule class_member { <...> }
    rule class_member:sym<method> {
        <sym>\s <name=.ident> { self.push_scope( 'method', 'me' ) }
        [
        | '(' ~ ')' <params>?
        | ':' <targets=.EXPR>+ $<colon>=':' <prerequisites=.EXPR>*
          { self.push_scope( 'member-rule', ['me', '$_', '@_'] ) }
        ]
        '{' ~ '}' <statements>
    }

    rule class_member:sym<{}> {
        '{' ~ '}' <newscope: 'ctor-block'>
    }

    rule class_member:sym<$> {
        :my $*IN_DECL; { $*IN_DECL := 'member'; }
        'var' <variable> <!before ':'> <initializer>? ';'? { $*IN_DECL := 0; }
    }

    rule class_member:sym<:> {
        $<name>=<?>
        <targets=.EXPR>+ $<colon>=':' <prerequisites=.EXPR>*
        { self.push_scope( 'member-rule', ['me', '$_', '@_'] ) }
        '{' ~ '}' <statements>
    }

    rule definition:sym<lang> { <sym>\s <lang(0)> }
    rule lang(int $imm) {
        :my $*IN_DECL;
        :my %*option;
        { $*IN_DECL := 'lang'; %*option<escape> := 0; }
        <langname=.ident> <lang_modifier>*
        ['as'\s [<?{ $imm }><.panic: '"as" is unexpected in this context'>|<variable>|<name=.ident>]]?
        <lang_body> { $*IN_DECL := 0; }
    }

    proto rule lang_body { <...> }
    rule lang_body:sym<in> { <sym> <externalfile=.EXPR> ';'? }
    rule lang_body:sym<template> {
        <template_starter> ~ <template_stopper>
            [ { $*IN_DECL := 'lang-source' }<source=.lang_source> ]
    }

    proto rule lang_modifier { <...> }
    token lang_modifier:sym<:escape> { <sym>{ %*option<escape> := 1 } }
    token lang_modifier:sym<:stdout> { <sym>'(':s ~ ')' [<variable>{ %*option<stdout> := ~$<variable> }] }

    proto rule lang_source { <...> }
    token lang_source:sym<raw> { <!{%*option<escape>}> <template_char_atom>* }
    token lang_source:sym<esc> { <?{%*option<escape>}> <template_atoms> }
}
