class MakeFile::Actions is HLL::Actions {
    method go($/) {
        my $block := QAST::Block.new( :node($/) );

        my $compunit := QAST::CompUnit.new(
            :hll('MakeFile'),

            # Serialization related bits.
            :sc($*W.sc()),
            :code_ref_blocks($*W.code_ref_blocks()),
            :compilation_mode($*W.is_precompilation_mode()),
            :pre_deserialize($*W.load_dependency_tasks()),
            :post_deserialize($*W.fixup_tasks()),
            #:repo_conflict_resolver(),

            # If this unit is loaded as a module, we want it to automatically
            # execute the mainline code above after all other initializations
            # have occurred.
            :load(QAST::Stmts.new(
                 QAST::Op.new( :op<call>, QAST::BVal.new( :value($block) ) ),
            )),

            :main(QAST::Stmts.new(
                 QAST::Var.new( :name<ARGS>, :scope<local>, :decl<param>, :slurpy(1) ),
                 QAST::Op.new( :op<call>, QAST::BVal.new( :value($block) ),
                     QAST::Var.new( :name<ARGS>, :scope<local>, :flat(1) ),
                 ),
            )),

            # Finally, the outer block, which in turn contains all of the
            # other program elements.
            $block
        );

        make $compunit;
    }

    sub trim($s) {
        $s
    }

    method statement:sym<assign>($/) {
        say('assign: '~trim(~$<name>)~'='~$<value>);
    }

    method statement:sym<:>($/) {
        say('rule: '~$/);
    }

    method statement:sym<$>($/) {
        say('expend: '~$/);
    }

    # method text_atom:sym<$>($/) {   }
    # method text_atom:sym<.>($/) {   }

    method expandable:sym<$()>($/) {
    }

    method expandable:sym<${}>($/) {
    }

    method expandable:sym<$>($/) {
    }

    method rule ($/) {
    }
}
