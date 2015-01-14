#include <boost/config/warning_disable.hpp>
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
    template < class Iterator >
    struct skipper : boost::spirit::qi::grammar<Iterator>
    {
        skipper() : skipper::base_type(skip, "skipper")
        {
            boost::spirit::ascii::space_type    space;
            boost::spirit::qi::char_type        char_;
            boost::spirit::qi::lexeme_type      lexeme;
            boost::spirit::eol_type             eol;
            skip
                = space // tab/space/CR/LF
                | lexeme[ "#" >> *(char_ - eol) >> eol ]
                | lexeme[ "#*" >> *(char_ - "*#") >> "*#" ]
                ;
        }
        boost::spirit::qi::rule<Iterator> skip;
    };

    template < class Iterator, class Locals, class SpaceType = skipper<Iterator> >
    struct expression : boost::spirit::qi::grammar<Iterator, ast::node(), Locals, SpaceType>
    {
        expression() : expression::base_type(expr, "expression")
        {
            using boost::spirit::qi::on_error;
            using boost::spirit::qi::fail;

            using boost::phoenix::construct;
            using boost::phoenix::val;

            boost::spirit::qi::_1_type          _1;
            boost::spirit::qi::_2_type          _2;
            boost::spirit::qi::_3_type          _3;
            boost::spirit::qi::_4_type          _4;
            boost::spirit::qi::int_type         int_;
            boost::spirit::qi::double_type      double_;
            boost::spirit::qi::char_type        char_;
            boost::spirit::qi::lit_type         lit;
            boost::spirit::qi::string_type      string;
            boost::spirit::qi::alpha_type       alpha;
            boost::spirit::qi::alnum_type       alnum;
            boost::spirit::qi::lexeme_type      lexeme;
            boost::spirit::qi::raw_type         raw;
            boost::spirit::ascii::space_type    space;

            logical_or_op.add
                ("||")
                ;
            
            logical_and_op.add
                ("&&")
                ;

            equality_op.add
                ("==")
                ("!=")
                ;

            relational_op.add
                ("<")
                ("<=")
                (">")
                (">=")
                ;

            additive_op.add
                ("+")
                ("-")
                ;
            
            multiplicative_op.add
                ("*")
                ("/")
                ;

            unary_op.add
                ("+")
                ("-")
                ("!")
                ;

            keywords.add
                ("decl")  // declare variables, constants, fields
                ("speak") // 
                ("type")  // 
                ("func")  // 
                ("see")   // 
                ("with")  // 
                ("any")   // loop on a list or range
                ;

            ////////////////////
            expr = logical_or.alias();

            logical_or
                =  logical_and
                >> *(logical_or_op > logical_and)
                ;

            logical_and
                =  equality
                >> *(logical_and_op > equality)
                ;

            equality
                =  relational
                >> *(equality_op > relational)
                ;

            relational
                =  additive
                >> *(relational_op > additive)
                ;

            additive
                =  multiplicative
                >> *(additive_op > multiplicative)
                ;

            multiplicative
                =  unary
                >> *(multiplicative_op > unary)
                ;

            unary
                = primary
                | (unary_op > unary)
                ;

            primary
                =   name
                |   value
                |   prop
                |   '(' > expr > ')'
                ;

            /*
                |  nodector
                |  name
                |  value
                |  prop
                |  invoke
                |  dotted
            */

            identifier
                = !keywords
                >> lexeme[ ( alpha | '_' ) >> *( alnum | '_' ) ]
                ;

            name
                = identifier //+( '.' >> identifier )
                ;

            value
                %= quote
                |  number
                ;

            quote
                = (
                    ( '\'' >> *(char_ - '\'') >> '\'' ) |
                    ( '"' >> *(char_ - '"') >> '"' )
                  )
                ;

            number
                = double_
                | int_
                ;

            prop %= ':'
                >  identifier
                >> -( '(' >> arglist >> ')' )
                ;

            nodector
                %= "{"
                > ( ( identifier > ":" > expr ) % "," )
                >  "}"
                ;

            arglist
                =  expr % ','
                ;

            invoke // after name
                =  '('
                >> arglist
                >> ')'
                ;

            dotted
                = '.' > identifier
                ;

            BOOST_SPIRIT_DEBUG_NODES(
                (expr)
            );

            on_error<fail>
            (
                expr, std::cout
                << val("bad expression: ") << _4 << ", at: "
                << construct<std::string>(_3, _2) 
                << std::endl
            );
        }

        template <class Spec = void()>
        using rule = boost::spirit::qi::rule<Iterator, Spec, Locals, SpaceType>;

        rule< ast::node() > expr;
            
        rule<> equality;
        rule<> relational;
        rule<> logical_or;
        rule<> logical_and;
        rule<> additive;
        rule<> multiplicative;
        rule<> unary;
        rule<> primary;

        rule<> identifier ;

        rule<> nodector;
        rule<> arglist;
        rule<> invoke;
        rule<> dotted;
        rule<> prop;
        rule<> name;
        rule<> value;
        rule<> quote;
        rule<> number;

        boost::spirit::qi::symbols<char>
            equality_op,
            relational_op,
            logical_or_op,
            logical_and_op,
            additive_op,
            multiplicative_op,
            unary_op ;

        boost::spirit::qi::symbols<char>
            keywords ;
    };

    template < class Iterator, class Locals, class SpaceType = skipper<Iterator> >
    struct statement : boost::spirit::qi::grammar<Iterator, ast::node(), Locals, SpaceType>
    {
        statement() : statement::base_type(stmts, "statement")
        {
            using boost::spirit::qi::on_error;
            using boost::spirit::qi::fail;
            using boost::spirit::lazy;

            using boost::phoenix::construct;
            using boost::phoenix::val;

            boost::spirit::qi::_1_type          _1; // qi::labels
            boost::spirit::qi::_2_type          _2; // qi::labels
            boost::spirit::qi::_3_type          _3; // qi::labels
            boost::spirit::qi::_4_type          _4; // qi::labels
            boost::spirit::qi::char_type        char_;
            boost::spirit::qi::lit_type         lit;
            boost::spirit::qi::lexeme_type      lexeme;
            boost::spirit::ascii::space_type    space;
            boost::spirit::repeat_type          repeat;
            boost::spirit::eol_type             eol;
            boost::spirit::eps_type             eps; // eps[ error() ]
            boost::spirit::inf_type             inf;
            boost::spirit::skip_type            skip;

            identifier = expr.identifier.alias();

            stmts %= +stmt ;
            stmt
                %=decl
                | func
                | type
                | speak
                | with
                | see
                | assignment
                | expr
                | ';'
                ;

            assignment
                = expr.name
                > '='
                > expr
                > ';'
                ;

            /*
            funcall
                = expr.name 
                > expr.invoke
                ;
            */

            with
                %= lexeme["with" > space]
                > expr
                > ( ';' | sblock )
                ;

            see
                %= lexeme["see" > space]
                ;


            dashes = repeat(3, inf)[ '-' ];
            sblock
                = dashes
                > stmts
                > dashes
                ;


            params = '(' > -( identifier % ',' ) > ')' ;

            decl
                = lexeme["decl" >> space]
                > ( ( identifier >> -( '=' > expr ) ) % ',')
                > ';'
                ;

            func
                = lexeme["func" >> space]
                > identifier > params
                > sblock
                ;

            type
                = lexeme["type" >> space]
                > identifier >> -params
                > sblock
                ;

            speak
                = lexeme["speak" >> space]
                > ( identifier % '>' )
                > dashes
                // > temp
                > dashes
                ;

            BOOST_SPIRIT_DEBUG_NODES(
                (stmts)
                (stmt)
                (decl)
                (func)
                (type)
                (speak)
                (assignment)
                (with)
                (see)
                (dashes)
                (sblock)
            );

            on_error<fail>
            (
                stmts, std::cout
                << val("bad statement: ") << _4 << ", at: "
                << construct<std::string>(_3, _2) 
                << std::endl
            );
        }

        template <class Spec = void()>
        using rule = boost::spirit::qi::rule<Iterator, Spec, Locals, SpaceType>;

        rule< ast::node() > stmts;
        rule<> stmt;
        rule<> decl;
        rule<> func;
        rule<> type;
        rule<> speak;
        rule<> params;
        rule<> with;
        rule<> see;

        rule<> assignment;
        rule<> identifier;

        rule<> dashes;
        rule<> sblock;

        expression<Iterator, Locals, SpaceType> expr;
    };

    template
    <
        class Iterator,
        class Locals = boost::spirit::qi::locals<std::string>,
        class SpaceType = skipper<Iterator>
    >
    struct grammar : boost::spirit::qi::grammar<Iterator, ast::node(), Locals, SpaceType>
    {
        grammar() : grammar::base_type(top, "lab")
        {
            using boost::spirit::qi::on_error;
            using boost::spirit::qi::fail;

            using boost::phoenix::construct;
            using boost::phoenix::val;

            //using namespace boost::spirit::qi::labels;

            boost::spirit::qi::_1_type          _1;
            boost::spirit::qi::_2_type          _2;
            boost::spirit::qi::_3_type          _3;
            boost::spirit::qi::_4_type          _4;
            boost::spirit::eoi_type             eoi;

            top = body ; // = body > eoi;

            on_error<fail>
            (
                top, std::cout
                << val("error: ") << _4 << ", at: "
                << construct<std::string>(_3, _2) 
                << std::endl
            );
        }

        boost::spirit::qi::rule<Iterator, ast::node(), Locals, SpaceType> top;
        statement<Iterator, Locals, SpaceType> body;
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

        std::string::const_iterator iter = source.begin();
        std::string::const_iterator end = source.end();

#if 1
        //boost::spirit::ascii::space_type space; // using boost::spirit::ascii::space;
        skipper<std::string::const_iterator> space;
        auto status = boost::spirit::qi::phrase_parse(iter, end, gmr, space, prog);
#else
        auto status = boost::spirit::qi::parse(iter, end, gmr, prog);
#endif

        if (status && iter == end) {
            // okay
        } else {
            // not okay
        }
        return prog;
    }
}
