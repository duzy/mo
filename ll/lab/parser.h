#include <boost/spirit/home/qi.hpp>
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

BOOST_FUSION_ADAPT_STRUCT(ast::node, (std::string, name));

namespace lab
{
    template < class Iterator >
    struct grammar : boost::spirit::qi::grammar<Iterator, ast::node(), boost::spirit::ascii::space_type>
    {
        grammar()
            : grammar::base_type(top, "lab")
            , top("top")
        {
            using boost::spirit::qi::int_;
            using boost::spirit::qi::char_;
            using boost::spirit::qi::lit;

            top %= *char_;
        }

        boost::spirit::qi::rule< Iterator, ast::node(), boost::spirit::ascii::space_type > top;
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
