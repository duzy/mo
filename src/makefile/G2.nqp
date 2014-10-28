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
    ]
}

token expandable {
    [
      |[ $<lp>=['$'] <-[({]> ]
      |[ $<lp>=['$('] <expandable_text>+ $<rp>=[')'] ]
      |[ $<lp>=['${'] <expandable_text>+ $<rp>=['}'] ]
    ]
}
token expandable_text {
    [
      |[<expandable> $<suf>=[[<!before [')'|'$']><-[\n]>]+]]
      |[$<pre>=[[<!before [')'|'$']><-[\n]>]+] <expandable>]
      |<expandable>
      |$<all>=<-[$)\n]>+
    ]
}

token expanded_targets {
    |[ $<pre>=[[<!before [':']><-[\\\n$\ \t:;|]>]*]
       <expandable>
       $<suf>=[[<!before [':']><-[\\\n$\ \t:;|]>]*]
     ]
    | $<txt>=[[<!before [':']><-[\\\n$\ \t:;|]>]+]
    | <expandable>
}

token rule {
    |[ <make_special_rule> ]
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
     ]
}
# token static_target_pattern {
#     [<expanded_targets><.ws_inline>[\\\n<.ws_inline>]*]+
# }
token static_prereq_pattern {
    [<expanded_targets><.ws_inline>[\\\n<.ws_inline>]*]+
}
token expanded_prerequisites {
    [<expanded_targets><.ws_inline>[\\\n<.ws_inline>]*]*
}
token expanded_orderonly {
    [<expanded_targets><.ws_inline>[\\\n<.ws_inline>]*]*
}
token make_action {
    [[<!before \\\n><-[\n]>]+ [\\\n]?]*
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
    <if_stat=statement>*
    [ 'else'
      <else_stat=statement>*
    ]*
    [ 'endif'
      | <.panic: "smart: * No 'endif'">
    ]
}

token include {
    'include' <.ws_inline> [\\\n<.ws_inline>]* <expanded_prerequisites>
    [ '\n' | $ ]
}

token identifier {
    <.ident>
}

rule quote {
    [ \' <string_literal: '\'' > \' | \" <string_literal: '"' > \" ]
}

token macro_reference {
    '$'
    [
     | <macro_reference1>
     | <macro_reference2>
    ]
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
