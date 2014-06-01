use NQPHLL;

grammar MO::Grammar is HLL::Grammar {
    rule TOP {
        ^ ~ $ <statements> || <.panic('Syntax Error')>
    }

    rule statements {
        <statement>*
    }

    rule statement {
        [
        | <control>
        | <template_definition>
        | <call>
        ]
    }

    INIT {
        nqp::say("MO::Grammar::INIT");
    }

    rule expr {
        [
        | '.' <identifier>
        | <identifier>
        ]
    }

    proto rule control { <...> }

    rule control:sym<for> {
        'for' <expr> ':'
        [
        | <statement>
        | <code_block>
        ]
    }

    rule control:sym<if> {
        'if' <expr> ':'
        [
        | <statement>
        | <code_block>
        ]
    }

    rule code_block {
        '{{' ~ '}}' <statements>
    }

    rule call {
        <name> <args>
    }

    token args {
        | '(' <arglist> ')'
    }

    token arglist {
        <expr> +% ','
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

    token name { <identifier> ['::'<identifier>]* }

    token identifier {
        <.ident>
    }
}
