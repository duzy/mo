//#include <boost/config/warning_disable.hpp>
#include <boost/spirit/include/qi.hpp>
#include <boost/spirit/include/phoenix_core.hpp>
#include <boost/spirit/include/phoenix_operator.hpp>
#include <boost/spirit/include/phoenix_fusion.hpp>
#include <boost/spirit/include/phoenix_stl.hpp>
#include <boost/spirit/include/phoenix_object.hpp>
#include <boost/fusion/include/adapt_struct.hpp>
//#include <boost/variant/recursive_variant.hpp>
//#include <boost/foreach.hpp>
#include <iostream>
#include <fstream>

namespace lab
{
    namespace ast
    {
        struct node
        {
            std::string name;
        };
    }
}

BOOST_FUSION_ADAPT_STRUCT(lab::ast::node, (std::string, name));

namespace lab
{
    template
    <
        class Iterator,
        class Locals = boost::spirit::qi::locals<std::string>,
        class SpaceType = boost::spirit::ascii::space_type
    >
    struct grammar : boost::spirit::qi::grammar<Iterator, ast::node(), Locals, SpaceType>
    {
        grammar() : grammar::base_type(top, "lab")
        {
            using boost::spirit::qi::int_;
            using boost::spirit::qi::double_;
            using boost::spirit::qi::char_;
            using boost::spirit::qi::lit;
            using boost::spirit::qi::string;
            using boost::spirit::qi::alpha;
            using boost::spirit::qi::alnum;
            using boost::spirit::qi::lexeme;
            using boost::spirit::qi::on_error;
            using boost::spirit::qi::fail;
            using boost::spirit::ascii::space;
            using boost::spirit::eol;
            using boost::spirit::eoi;
            using boost::spirit::eps; // eps[ error() ]
            using boost::spirit::repeat;
            using boost::spirit::inf;
            using boost::spirit::skip;
            using boost::spirit::lazy;

            using namespace boost::spirit::qi::labels;

            using boost::phoenix::construct;
            using boost::phoenix::val;

            top %= stmts > eoi;

            stmt %= decl | ctrl | expr ;
            stmts %= *( stmt | comment | ';' ) ;

            decl %= def_var | def_func | def_type | def_temp ;

            ctrl %= with | _case ;

            with %= "with" > expr > ( ';' | sblock ) ;

            _case %= "case" ;

            comment = lexeme[ "#" >> *(char_ - eol) >> eol ];

            prop %= ':' > identifier >> -arglist;

            identifier = lexeme[ alpha >> *alnum ];
            name = identifier >> *( '.' >> identifier );

            expr %= nodector
                | value
                | prop
                | call
                | variable
                ;

            value %= quote | number ;

            quote = (
                ( '\'' >> *(char_ - '\'') >> '\'' ) |
                ( '"' >> *(char_ - '"') >> '"' ) ) ;

            number = double_ | int_;

            nodector %= "{" > ( ( identifier > ":" > expr ) % "," ) > "}" ;

            arglist = '(' >> ( expr % ',' ) >> ')' ;
            call = name > arglist ;


            dashes = repeat(3, inf)[ '-' ];
            sblock = dashes > stmts > dashes ;


            def_var = "var" > ((identifier >> -( '=' > expr )) % ',') > ';';
            def_type = "type" > identifier ;
            def_temp = "temp" > identifier ;

            top         .name("top");
            stmt        .name("stmt");
            stmts       .name("stmts");
            def_var     .name("var-def");
            def_func    .name("func-def");
            def_type    .name("type-def");
            def_temp    .name("temp-def");
            expr        .name("expr");
            with        .name("with");
            prop        .name("prop");
            variable    .name("variable");
            nodector    .name("nodector");
            arglist     .name("arglist");
            call        .name("call");
            identifier  .name("identifier");
            name        .name("name");
            value       .name("value");
            dashes      .name("dashes");
            sblock      .name("statement-block");

            on_error<fail>
            (
                top, std::cout
                << val("error: ") << _4 << ", at: "
                << construct<std::string>(_3, _2) 
                << std::endl
            );
        }

        template <class Spec = void()>
        using rule = boost::spirit::qi::rule<Iterator, Spec, Locals, SpaceType>;

        rule< ast::node() > top;
        rule<> stmt;
        rule<> stmts;
        rule<> decl;
        rule<> def_var;
        rule<> def_func;
        rule<> def_type;
        rule<> def_temp;
        rule<> ctrl;
        rule< ast::node() > with;
        rule<> _case;
        rule<> expr;
        rule<> nodector;
        rule<> arglist;
        rule<> call;
        rule<> comment;
        rule<> prop;
        rule<> identifier;
        rule<> name;
        rule<> value;
        rule<> quote;
        rule<> number;
        rule<> variable;
        rule<> dashes;
        rule<> sblock;
    };

    ast::node parse_file(const std::string & filename)
    {
        std::ifstream in(filename.c_str(), std::ios_base::in);
        in.unsetf(std::ios::skipws); // No white space skipping!

        std::string source; // We will read the contents here.
        std::copy(std::istream_iterator<char>(in),
                  std::istream_iterator<char>(),
                  std::back_inserter(source));

        grammar<std::string::const_iterator> gmr;
        ast::node prog;

        using boost::spirit::ascii::space;
        std::string::const_iterator iter = source.begin();
        std::string::const_iterator end = source.end();
        auto status = boost::spirit::qi::phrase_parse(iter, end, gmr, space, prog);
        if (status && iter == end) {
            // okay
        } else {
            // not okay
        }
        return prog;
    }
}
