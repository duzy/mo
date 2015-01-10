#include <boost/spirit/home/qi.hpp>
#include <boost/fusion/include/adapt_struct.hpp>
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
    //struct grammar : boost::spirit::qi::grammar<Iterator, ast::node(), boost::spirit::qi::locals<std::string>, boost::spirit::ascii::space_type>
    struct grammar : boost::spirit::qi::grammar< Iterator >
    {
        grammar()
            : grammar::base_type(top, "lab")
            , top("top")
            , stmt("stmt")
            , expr("expr")
        {
            using boost::spirit::qi::int_;
            using boost::spirit::qi::char_;
            using boost::spirit::qi::lit;
            using boost::spirit::qi::lit;
            using boost::spirit::qi::lexeme;
            using boost::spirit::qi::on_error;
            using boost::spirit::qi::fail;
            //using boost::spirit::ascii::char_;
            //using boost::spirit::ascii::string;
            using namespace qi::labels;

            top %= *( stmt | expr ) ;

            stmt %= stmt_decl | stmt_ctrl ;

            expr %= expr_call ;
        }

        //boost::spirit::qi::rule< Iterator, ast::node(), boost::spirit::qi::locals<std::string>, boost::spirit::ascii::space_type > top;
        boost::spirit::qi::rule< Iterator > top;
        boost::spirit::qi::rule< Iterator > stmt;
        boost::spirit::qi::rule< Iterator > stmt_decl;
        boost::spirit::qi::rule< Iterator > stmt_ctrl;
        boost::spirit::qi::rule< Iterator > stmt_ctrl_with;
        boost::spirit::qi::rule< Iterator > stmt_ctrl_case;
        boost::spirit::qi::rule< Iterator > expr;
        boost::spirit::qi::rule< Iterator > expr_call;
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
