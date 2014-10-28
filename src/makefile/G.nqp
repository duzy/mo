use NQPHLL;

grammar MakeFile::Grammar is HLL::Grammar {
    method TOP(:$end?) {
        my $source_id := nqp::sha1(self.target() ~ nqp::time_n());
        my $file := nqp::getlexdyn('$?FILES');
        my $*W := nqp::isnull($file) ??
            MakeFile::World.new(:handle($source_id)) !!
            MakeFile::World.new(:handle($source_id), :description($file));

        self.go
    }

    rule go {
        <statement>* [ $ || <.panic: 'smart: * Unsupported statement'> ]
    }

rule statement {
    | <function_definition>
    | <macro_declaration>
    | <rule>
    | <include>
}

token macro_declaration {
    [ $<override>=['override'] <.ws> ]?
    [
      |[ $<sign>=['define'] <[ \ \t ]>+ <.ws_inline>
         $<name>=[ <-[ : = # \ \t \n ]> <-[ : = # + ? \n ]>*: ] <.ws_inline> \n
         $<value>=[ [<!before [\n'endef'|'endef']> .]* ] \n?
         'endef' <.ws_inline> \n
       ]
      |[ $<name>=[ <-[ : = # \ \t \n ]> <-[ : = # + ? \n ]>*: ]
         $<sign>=[ '=' | ':=' | '?=' | '+=' ] <.ws_inline> [\\\n<.ws_inline>]?
         [ $<item>=[<-[ \\ \n ]>+] [\\\n<.ws_inline>]? ]*
         [ [\n | $] || <.panic: 'smart: * Unterminated makefile variable declaration'> ]
       ]
    ] {*}
}

token expandable {
    [
      |[ $<lp>=['$'] <-[({]> ]
      |[ $<lp>=['$('] <expandable_text>+ $<rp>=[')'] ]
      |[ $<lp>=['${'] <expandable_text>+ $<rp>=['}'] ]
    ]
    {*}
}
token expandable_text {
    [
      |[<expandable> $<suf>=[[<!before [')'|'$']><-[\n]>]+]]
      |[$<pre>=[[<!before [')'|'$']><-[\n]>]+] <expandable>]
      |<expandable>
      |$<all>=<-[$)\n]>+
    ]
    {*}
}

token expanded_targets {
    |[ $<pre>=[[<!before [':']><-[\\\n$\ \t:;|]>]*]
       <expandable>
       $<suf>=[[<!before [':']><-[\\\n$\ \t:;|]>]*]
     ] {*}                                              #= mixed
    | $<txt>=[[<!before [':']><-[\\\n$\ \t:;|]>]+] {*}  #= text
    | <expandable> {*}                                  #= pure
}

token rule {
    |[ <make_special_rule> ] {*}
    |[ <.ws_inline>
       [<expanded_targets><.ws_inline>[\\\n<.ws_inline>]*]+
       ':' <.ws_inline> [\\\n<.ws_inline>]*
       [
         ## If static pattern rule, <expanded_prerequisites> represents
         ## static pattern target, in this case, the coninual match will be ':'
         <expanded_prerequisites>
         [ ':' <.ws_inline> [[\\\n<.ws_inline>]* <static_prereq_pattern>]? ]?
         [ '|' <.ws_inline> [\\\n<.ws_inline>]* <expanded_orderonly> ]?
       ]
       [
         |[ ';' <.ws_inline>
            [<action> | [<make_action> [ \n \t <make_action> ]*]]
          ]
         |[ <action>
            |[
               [ \n <[ \ ]>* [ [ '#' \N* ] | <.comment_block> ] ]*
               [ \n [[\t <make_action>] | ['#' \N*]]]*
             ]
          ]
       ]
     ] {*}
}
# token static_target_pattern {
#     [<expanded_targets><.ws_inline>[\\\n<.ws_inline>]*]+
#     {*}
# }
token static_prereq_pattern {
    [<expanded_targets><.ws_inline>[\\\n<.ws_inline>]*]+
    {*}
}
token expanded_prerequisites {
    [<expanded_targets><.ws_inline>[\\\n<.ws_inline>]*]*
    {*}
}
token expanded_orderonly {
    [<expanded_targets><.ws_inline>[\\\n<.ws_inline>]*]*
    {*}
}
token make_action {
    [[<!before \\\n><-[\n]>]+ [\\\n]?]*
}
rule action {
    '{'
    <statement>*
    '}'
    {*}
}
token make_special_rule {
    <.ws_inline>
    $<name>=[
    | '.PHONY'
    | '.SUFFIXES'
    | '.DEFAULTS'
    | '.PRECIOUS'
    | '.INTERMEDIATE'
    | '.SECONDARY'
    | '.SECONDEXPANSION'
    | '.DELETE_ON_ERROR'
    | '.IGNORE'
    | '.LOW_RESOLUTION_TIME'
    | '.SILENT'
    | '.EXPORT_ALL_VARIABLES'
    | '.NOTPARALLEL'
    ]
    <.ws_inline>
    ':' [ <.ws_inline> $<item>=[ <-[ \n \t \ ]>+ ] ]* <.ws_inline>
    [ \n\t[<!before [\\\n|\n]>.]*[\\\n<.ws_inline>]? ]*
    {*}
}

rule make_conditional_statement {
    $<csta>=['ifeq'|'ifneq']
    [
      |[ '('
         $<arg1>=[[<-[,)$]>|<.macro_reference>]*]
         ','
         $<arg2>=[[<-[)$]>|<.macro_reference>]*]
         ')'
       ]
      |[ | \' $<arg1>=[<-[ ' ]>*] \' <[ \ \t ]>*
         | \" $<arg1>=[<-[ " ]>*] \" <[ \ \t ]>* ]
       [ | \' $<arg2>=[<-[ ' ]>*] \' <[ \ \t ]>*
         | \" $<arg2>=[<-[ " ]>*] \" <[ \ \t ]>* ]
    ]
    {{
      $S0 = match['csta']
      $S1 = match['arg1']
      $S2 = match['arg2']
      $S1 = 'expand'( $S1 )
      $S2 = 'expand'( $S2 )
      get_hll_global $P0, ['smart';'Grammar';'Actions'], '$VAR_ON'
      get_hll_global $P1, ['smart';'Grammar';'Actions'], '@VAR_SWITCHES'
      push $P1, $P0 ## save the the previous $VAR_ON value
      $I0 = $S1 == $S2
      if $S0 == 'ifeq' goto update_flag
      $I0 = !$I0 # 'ifneq'
    update_flag:
      $P0 = new 'Integer'
      $P0 = $I0
      set_hll_global ['smart';'Grammar';'Actions'], '$VAR_ON', $P0
    }}
    <if_stat=statement>*
    [ 'else'
      {{
        get_hll_global $P0, ['smart';'Grammar';'Actions'], '$VAR_ON'
        $I0 = $P0
        $I0 = !$I0
        $P0 = $I0
        set_hll_global ['smart';'Grammar';'Actions'], '$VAR_ON', $P0
      }}
      <else_stat=statement>*
    ]*
    [ 'endif'
      {{
        get_hll_global $P1, ['smart';'Grammar';'Actions'], '@VAR_SWITCHES'
        pop $P0, $P1
        set_hll_global ['smart';'Grammar';'Actions'], '$VAR_ON', $P0
      }}
      | <.panic: "smart: * No 'endif'">
    ]
    {*}
}

token include {
    'include' <.ws_inline> [\\\n<.ws_inline>]* <expanded_prerequisites>
    [ '\n' | $ ]
    {*}
}

rule function_definition {
    <identifier>
    '('
    [<variable> [',' <variable>]* ','? ]?
    ')'
    <block>
    {*}
}

rule block {
    '{' {*} #= enter
    <statement>*
    '}' {*} #= leave
}

rule function_call {
    $<name>=[<identifier>]
    [
      | <arguments>  ## fun( x, y, z )
      | <parameters> ## call x, y, z
    ]
    {*}
}

## <assignable> = xxx
## <assignable>.xxx()
## Synopsis:
##      
rule on_assignable {
    <assignable>
    [
      | <?before '='> <assignment> {*}    #= assignment
      | <?before '.'> <dotty> <arguments>? {*}   #= method
    ]
}

rule assignment {
    '='
    <expression>
    {*}
}

## Synopsis:
##      $obj.method()
##      $obj.attribute
##      $var[0].method()
##      $var[0].attribute
##      $var.attribute.method()
##      $var.method().method()
rule method_call {
    [
      | <variable>
      | <macro_reference>
    ]
#    <assignable>
    <dotty> <arguments>
    {*}
}

## All entities which could be assigned with a value and represents a value,
## such variable, attribute, indexed array element, etc.
## Synopsis:
##      $var
##      $var.attribute
##      $var.method( arg )
##      $var[0]
##      $var<name>
## Examples:
##      $var = 'value';
##      $var.attribute = 'value';
##      $var.substr( 0, 1 ) = 'value';
##      $var[0] = 'value';
##      $var<name> = 'value';
rule assignable {
    [
      | <variable>
      | <macro_reference>
    ]
    [
      <dotty> <arguments>?
    ]?
    {*}
}

## Synopsis:
##      .attribute
##      .method
## Examples:
##      $obj = new SomeType;
##      $obj.attribute = 'value';
##      $obj.method( 'arg' );
rule dotty {
    '.' <identifier>
    {*}
}

rule variable_declarator {
    'the' <variable>
    [
    '=' <expression>
    ]?
    {*}
}

token variable {
    $<sigil>=['$']
    [
      | $<special>=[<[@%<?^+|*]>['D'|'F']?]
      | <identifier>
    ]
    {*}
}

rule new_operator {
    'new' <identifier> ['(' <parameters> ')']?
    {*}
}

token identifier {
    <.ident>
}

##  terms
token term {
    | <value> {*}                               #= value
    | <assignable> {*}                          #= assignable
    | <macro_reference> {*}                     #= macro_reference
    | <new_operator> {*}                        #= new_operator
    | <function_call> {*}                       #= function_call
    | <method_call> {*}                         #= method_call
}

rule value {
    | <integer> {*}                             #= integer
    | <quote> {*}                               #= quote
}

rule integer { \d+ {*} }

rule quote {
    [ \' <string_literal: '\'' > \' | \" <string_literal: '"' > \" ]
    {*}
}

# rule make_variable_method_call {
#     <macro_reference> '.' <identifier>
#         '(' <parameters>
#         [ ')' || <.panic: "smart: * Require an ')' to terminate parameter list"> ]
#     {*}
# }

rule arguments {
    '(' <parameters> ')'
    {*}
}

rule parameters {
    [ <expression> [ ',' <expression> ]* ]?
    {*}
}

token macro_reference {
    '$'
    [
     | <macro_reference1>
     | <macro_reference2>
    ]
    {*}
#    {{
#    $S0 = match.'text'()
#    say $S0
#    }}
}
token macro_reference1 {
#    [ '(' $<name>=[[<!before ')'><-[\n:=#$]>|<.macro_reference>]+]
    [ '(' $<name>=[<expandable_text>+]
    [ ')' || <.panic: "smart: * Macro referencing expects ')'"> ]]
}
token macro_reference2 {
#    [ '{' $<name>=[[<!before '}'><-[\n:=#$]>|<.macro_reference>]+]
    [ '{' $<name>=[[<!before '}'><-[\n:=#$]>|<.macro_reference>]+]
    [ '}' || <.panic: "smart: * Macro referencing expects '}'"> ]]
}
}
