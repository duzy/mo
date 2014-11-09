use QRegex;

grammar MO::GlobGrammar is HLL::Grammar {
    method TOP() {
        my %*LANG;
        %*LANG<Regex>         := QRegex::P6Regex::Grammar;
        %*LANG<Regex-actions> := QRegex::P6Regex::Actions;

        my $rule := %*COMPILING<%?OPTIONS><rule>;
        if nqp::defined($rule) && $rule eq 'regex' {
            self.regex
        } else {
            self.glob
        }
    }
    token regex {
        #:my %*RX;
        #<p6regex=.LANG('Regex','nibbler')>
        <p6regex=.LANG('Regex','TOP')>
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

class MO::GlobActions is HLL::Actions {
    method regex($/) {
        # my $codeobj := nqp::create(NQPRegex);
        # make %*LANG<Regex-actions>.qbuildsub($<p6regex>.ast, :code_obj($codeobj));

        # make $<p6regex>.ast

        make QAST::Block.new( :node($/), $<p6regex>.ast );
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

my $comp := MO::GlobCompiler.new();
$comp.language('MO::Glob');
$comp.parsegrammar(MO::GlobGrammar);
$comp.parseactions(MO::GlobActions);

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
