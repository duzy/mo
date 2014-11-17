use QRegex;

class MO::Glob::World is QRegex::P6Regex::World {
}

grammar MO::GlobGrammar is HLL::Grammar {
    # my $cur_handle := 0;
    method TOP() {
        my %*LANG;
        %*LANG<Regex>         := QRegex::P6Regex::Grammar;
        %*LANG<Regex-actions> := QRegex::P6Regex::Actions;

        # my $handle := '__MO_GLOB__' ~ $cur_handle++;
        # my $*W := MO::Glob::World.new(:$handle);

        my $rule := %*COMPILING<%?OPTIONS><rule>;
        if nqp::defined($rule) && $rule eq 'regex' {
            self.regex
        } else {
            self.glob
        }
    }
    token regex {
        :my %*RX; <p6regex=.LANG('Regex','nibbler')>
        # <p6regex=.LANG('Regex','TOP')>
    }
    token glob {
        :my $*STAR;
        :my $*BLOCK;
        {
            my $wrx := QAST::WVal.new( :value(QRegex::P6Regex::Grammar) );
            $*STAR := 0;
            $*BLOCK := QAST::Block.new( :node($/), QAST::Stmts.new(
                QAST::Var.new( :decl<param>, :scope<local>, :name<str> ),
                QAST::Op.new( :op<bind>,
                    QAST::Var.new( :decl<var>, :scope<local>, :name<wrx> ), $wrx,
                ),
                QAST::Op.new( :op<bind>,
                    QAST::Var.new( :decl<var>, :scope<local>, :name<len>, :returns<int> ),
                    QAST::Op.new( :op<chars>, QAST::Var.new( :scope<local>, :name<str> ) ),
                ),
                QAST::Op.new( :op<bind>,
                    QAST::Var.new( :decl<var>, :scope<local>, :name<pos>, :returns<int> ),
                    QAST::IVal.new( :value(0) ),
                ),
            ) );
        }
        <atom>*
    }
    proto token atom { <...> }
    token atom:sym<quest>   { '?' { $*STAR := 0 }}
    token atom:sym<star>    { '*' { $*STAR := 1 }}
    token atom:sym<enum>    { '[' ~ ']' <enum> { $*STAR := 0 }}
    token atom:sym<alt>     { '{' ~ '}' <alt>* %% ',' { $*STAR := 0 }}
    token atom:sym<literal> { <-[*?[{]>+ { $*STAR := 0 }}
    token enum { <-[\]]>* }
    token alt { <-[,}]>+ }
}

# my $match;
#
# $match := MO::GlobGrammar.parse('path/to/somewhere/*.pir', :rule<TOP>);
# ok( !$match, 'parse method works on negative match');
# say( $match<atom> );
#
# $match := MO::GlobGrammar.parse('path/[abc]/somewhere/*.{pir,mo}', :rule<TOP>);
# ok( !$match, 'parse method works on negative match');
# say( $match<atom> );

# class MO::GlobRegex is NQPRegex {
#     method new($code) { self.bless(:code($code)); }
# }
# nqp::setinvokespec(MO::GlobRegex, NQPRegex, '$!code', nqp::null);

class MO::GlobActions is HLL::Actions {
    method regex($/) {
        # my $block := %*LANG<Regex-actions>.qbuildsub($<p6regex>.ast);
        # make QAST::CompUnit.new(
        #     :hll('MO::GlobRegex'),
        #     :sc($*W.sc()),
        #     :code_ref_blocks($*W.code_ref_blocks()),
        #     :compilation_mode(0),
        #     :pre_deserialize($*W.load_dependency_tasks()),
        #     :post_deserialize($*W.fixup_tasks()),
        #     $block
        # );

        # make QAST::Block.new(
        #     QAST::Op.new( :op<say>, QAST::Var.new( :decl<param>, :scope<local>, :name<str> ) ),
        #     # $<p6regex>.ast,
        # );



        #make $<p6regex>.ast;



        # my $block := QAST::Block.new( :node($/), QAST::Stmts.new() );
        # $block[0].push(QAST::Var.new(:name<self>, :scope<lexical>, :decl<param>));
        # $block[0].push(QAST::Op.new( :op<bind>,
        #     QAST::Var.new(:name<self>, :scope<local>, :decl<var> ),
        #     QAST::Var.new( :name<self>, :scope<lexical> )));
        # $block[0].push(QAST::Var.new(:name<$¢>, :scope<lexical>, :decl('var')));
        # $block[0].push(QAST::Var.new(:name<$/>, :scope<lexical>, :decl('var')));
        # $block.symbol('$¢', :scope<lexical>);
        # $block.symbol('$/', :scope<lexical>);

        # my $regex := %*LANG<Regex-actions>.qbuildsub($<p6regex>.ast, $block);
        # my $ast := QAST::Op.new( :op<callmethod>, :name<new>,
        #     QAST::WVal.new( :value(MO::GlobRegex) ), $regex);

        # # In sink context, we don't need the Regex::Regex object.
        # $ast.annotate('sink', $regex);
        # make $ast;
    }
    method glob($/) {
        my $stmts := $*BLOCK.push( QAST::Stmts.new() );
        $stmts.push( QAST::Op.new( :op<iseq_i>,
            QAST::Var.new( :scope<local>, :name<len> ),
            QAST::Var.new( :scope<local>, :name<pos> ),
        ) );
        make $*BLOCK
    }
    method atom:sym<quest>($/) {
        $*BLOCK.push( QAST::Op.new( :op<bind>,
            QAST::Var.new( :scope<local>, :name<pos> ),
            QAST::Op.new( :op<add_i>,
                QAST::Var.new( :scope<local>, :name<pos> ),
                QAST::IVal.new( :value(1) ),
            ),
        ) );
    }
    method atom:sym<star>($/) {}
    method atom:sym<enum>($/) {
        $*BLOCK.push( QAST::Stmts.new(
        ) );
    }
    method atom:sym<alt>($/) {
        $*BLOCK.push( QAST::Stmts.new(
        ) );
    }
    method atom:sym<literal>($/) {
        $*BLOCK.push( QAST::Stmts.new(
        ) );
    }
}

class MO::GlobCompiler is HLL::Compiler {
}

# my $comp := MO::GlobCompiler.new();
# $comp.language('MO::Glob');
# $comp.parsegrammar(MO::GlobGrammar);
# $comp.parseactions(MO::GlobActions);

# my $code;
# $code := $comp.compile('?');
# say('match: '~$code('a'));
# say('match: '~$code('b'));
# say('match: '~$code('cdef'));
# $code := $comp.compile('path/to/somewhere/*.pir');
# say('match: '~$code('path/to/somewhere/abc.pir'));
# say('match: '~$code('path/to/somewhere/abcdef.pir'));
# $code := $comp.compile('path/[abc]/somewhere/*.{pir,mo}');
# say('match: '~$code('path/a/somewhere/abc.pir'));
# say('match: '~$code('path/b/somewhere/abc.pir'));
# say('match: '~$code('path/c/somewhere/abc.pir'));

#my $m := QRegex::P6Regex::Grammar.parse('"path/to/somewhere/".*".pir"', :rule<nibbler>);
#say( !$m );

#my $rx := $comp.compile('"path/to/somewhere/".*".pir"', :rule<regex>);
#my $rx := $comp.compile('.*', :rule<regex>);
#my $m := $rx('path/to/somewhere/abc.pir');
#say($m);

#sub MAIN(@ARGS) {
#    $comp.command_line(@ARGS, :encoding('utf8'));
#}

