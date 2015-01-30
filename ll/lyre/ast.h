#ifndef __LYRE_AST_H____DUZY__
#define __LYRE_AST_H____DUZY__ 1
#include <boost/variant/recursive_variant.hpp>
#include <boost/fusion/include/adapt_struct.hpp>
#include <boost/optional.hpp>
#include <list>

namespace lyre
{
    namespace ast
    {
        struct none {};
        struct decl;
        struct proc;
        struct type;
        struct see;
        struct with;
        struct speak;
        struct per;
        struct ret;
        struct expr;
        struct op;
        
        typedef boost::variant<
            none
            , boost::recursive_wrapper<decl>
            , boost::recursive_wrapper<proc>
            , boost::recursive_wrapper<type>
            , boost::recursive_wrapper<see>
            , boost::recursive_wrapper<with>
            , boost::recursive_wrapper<speak>
            , boost::recursive_wrapper<per>
            , boost::recursive_wrapper<ret>
            , boost::recursive_wrapper<expr>
            >
        stmt;
        
        struct stmts : std::list<stmt> {};

        struct block
        {
            std::string name;
            ast::stmts stmts;
        };

        enum class opcode : int
        {
            nil,

            // get a reference to attribute
            attr,

            // filtering children
            select,

            // call a procedure (function)
            call,

            // unary
            unary_plus,
            unary_minus,
            unary_not,
            unary_dot,
            unary_arrow,

            // multiplicative
            mul,
            div,

            // additive
            add,
            sub,

            // relational
            lt, // less then
            le, // less or equal
            gt, // greater then
            ge, // greater or equal

            // equality
            eq,
            ne,

            // logical and/or/xor
            a,
            o,
            xo,

            // assign
            set,

            // list (comma)
            list,

            br,   // conditional branch
            swi,  // switch

            unr,  // unreachable
        };

        struct identifier
        {
            std::string string;
        };

        typedef boost::variant<
            none
        /*
            , int8_t
            , int16_t
            , int32_t
            , int64_t
            , uint8_t
            , uint16_t
            , uint32_t
            , uint64_t
        */
            , int
            , unsigned int
            , float
            , double
            , std::string
            , identifier
            , boost::recursive_wrapper<expr>
            >
        operand;

        struct op
        {
            ast::opcode opcode;
            ast::operand operand;
        };

        struct expr
        {
            ast::operand operand;
            std::list<op> operators;

            expr() : operand(), operators() {}
            explicit expr(const ast::operand & o) : operand(o), operators() {}
            explicit expr(const op & o) : operand(), operators({ o }) {}
        };

        struct declsym
        {
            identifier id;
            //identifier type;
            boost::optional<ast::expr> expr;
        };

        struct decl : std::list<declsym> {};

        struct param
        {
            identifier name;
            identifier type;
        };

        struct proc
        {
            identifier name;
            std::list<param> params;
            boost::optional<identifier> type;
            ast::block block;
        };

        struct type
        {
            identifier name;
            boost::optional<std::list<param>> params;
            ast::block block;
        };

        struct with
        {
            ast::expr expr;
            boost::optional<ast::block> block;
        };

        struct see
        {
            ast::expr expr;
            ast::block block;
        };

        struct speak
        {
            std::list<identifier> langs;
            std::string source;
        };
        
        struct per
        {
        };

        struct ret
        {
            boost::optional<ast::expr> expr;
        };
    }
}

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::declsym,
    (lyre::ast::identifier, id)
    //(lyre::ast::identifier, type)
    (boost::optional<lyre::ast::expr>, expr)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::speak,
    (std::list<lyre::ast::identifier>, langs)
    (std::string, source)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::param,
    (lyre::ast::identifier, name)
    (lyre::ast::identifier, type)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::proc,
    (lyre::ast::identifier, name)
    (std::list<lyre::ast::param>, params)
    (boost::optional<lyre::ast::identifier>, type)
    (lyre::ast::block, block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::type,
    (lyre::ast::identifier, name)
    (boost::optional<std::list<lyre::ast::param>>, params)
    (lyre::ast::block, block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::with,
    (lyre::ast::expr, expr)
    (boost::optional<lyre::ast::block>, block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::see,
    (lyre::ast::expr, expr)
    (lyre::ast::block, block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::ret,
    (boost::optional<lyre::ast::expr>, expr)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::block,
    (std::string, name)
    (lyre::ast::stmts, stmts)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::identifier,
    (std::string, string)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::expr,
    (lyre::ast::operand, operand)
    (std::list<lyre::ast::op>, operators)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::op,
    (lyre::ast::opcode, opcode)
    (lyre::ast::operand, operand)
)

#endif//__LYRE_AST_H____DUZY__
