class MO::Actions is HLL::Actions {
    method TOP($/) {
        nqp::say("TOP");
        make $/.ast;
    }

    method statements($/) {
        nqp::say("statements");
        make $/.ast;
    }

    method statement($/) {
        nqp::say("statement: "~$/);
        make $/.ast;
    }

    method expr($/) {
        nqp::say("expr: "~$/);
        make $/.ast;
    }

    method control:sym<for>($/) {
        nqp::say("for: "~$/<expr>);
        make $/.ast;
    }

    method control:sym<if>($/) {
        nqp::say("if: "~$/);
        make $/.ast;
    }

    method code_block($/) {
        nqp::say("code_block");
        make $/.ast;
    }

    method template_definition($/) {
        nqp::say("template_definition");
        make $/.ast;
    }

    method template_block($/) {
        nqp::say("template_block");
        make $/.ast;
    }

    method template_body($/) {
        nqp::say("template_body");
        make $/.ast;
    }

    method identifier($/) {
        nqp::say("identifier: "~$/);
        make $/.ast;
    }
}
