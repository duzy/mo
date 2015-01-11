//#include <boost/config/warning_disable.hpp>
#include <boost/spirit/include/qi.hpp>
#include <boost/spirit/include/phoenix_core.hpp>
#include <boost/spirit/include/phoenix_operator.hpp>
#include <boost/spirit/include/phoenix_fusion.hpp>
#include <boost/spirit/include/phoenix_stl.hpp>
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
    template < class Iterator >
    struct grammar : boost::spirit::qi::grammar<Iterator, ast::node(), boost::spirit::qi::locals<std::string>, boost::spirit::ascii::space_type>
    {
        grammar() : grammar::base_type(top, "lab")
        {
            using boost::spirit::qi::int_;
            using boost::spirit::qi::char_;
            using boost::spirit::qi::lit;
            using boost::spirit::qi::alpha;
            using boost::spirit::qi::alnum;
            using boost::spirit::qi::lexeme;
            using boost::spirit::qi::on_error;
            using boost::spirit::qi::fail;
            using boost::spirit::lazy;
            //using boost::spirit::ascii::char_;
            //using boost::spirit::ascii::string;
            //using namespace boost::spirit::qi::labels;

            using boost::phoenix::val;

            top %= *( stmt | expr ) ;

            stmt = decl | ctrl ;

            ctrl = with | ctrl_case ;

            with = lit("with") > with_X ;

            with_X
                = with_newnode
                | with_attribute
                | with_variable
                ;

            with_newnode
                = lit("{")
                > lit("}")
                ;

            with_attribute = lexeme
                [ ":" >> name ]
                ;

            ctrl_case = lit("case") ;

            comment = "#" ;

            prop = ":" >> name >> -( "(" >> ( expr % "," ) >> ")" );

            name = lexeme[ alpha >> *alnum ];

            expr = expr_call ;



            top         .name("top");
            stmt        .name("stmt");
            expr        .name("expr");

            on_error<fail>
            (
             top, std::cout << val("error") << std::endl
            );
        }

        boost::spirit::qi::rule< Iterator, ast::node(), boost::spirit::qi::locals<std::string>, boost::spirit::ascii::space_type > top;
        boost::spirit::qi::rule< Iterator > stmt;
        boost::spirit::qi::rule< Iterator > decl;
        boost::spirit::qi::rule< Iterator > ctrl;
        boost::spirit::qi::rule< Iterator > with;
        boost::spirit::qi::rule< Iterator > with_X;
        boost::spirit::qi::rule< Iterator > with_newnode;
        boost::spirit::qi::rule< Iterator > with_attribute;
        boost::spirit::qi::rule< Iterator > with_variable;
        boost::spirit::qi::rule< Iterator > ctrl_case;
        boost::spirit::qi::rule< Iterator > expr;
        boost::spirit::qi::rule< Iterator > expr_call;
        boost::spirit::qi::rule< Iterator > comment;
        boost::spirit::qi::rule< Iterator > prop;
        boost::spirit::qi::rule< Iterator > name;
    };

    ast::node parse_file(const std::string & filename)
    {
        std::ifstream in(filename.c_str(), std::ios_base::in);
        in.unsetf(std::ios::skipws); // No white space skipping!

        std::string source; // We will read the contents here.
        std::copy(std::istream_iterator<char>(in),
                  std::istream_iterator<char>(),
                  std::back_inserter(source));

        grammar<std::string::const_iterator> g;
        ast::node prog;

        using boost::spirit::ascii::space;
        std::string::const_iterator iter = source.begin();
        std::string::const_iterator end = source.end();
        auto status = boost::spirit::qi::phrase_parse(iter, end, g, space, prog);
        if (status && iter == end) {
            // okay
        } else {
            // not okay
        }
        return prog;
    }
}
