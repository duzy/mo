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
            , boost::recursive_wrapper<expr>
            >
        stmt;
        
        struct stmts : std::list<stmt> {};

        struct block
        {
            std::string name_;
            stmts stmts_;
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

            // logical and/or
            a,
            o,

            // assign
            set,

            br,   // conditional branch
            swi,  // switch

            unr,  // unreachable
        };

        struct identifier
        {
            std::string name;
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
            , boost::recursive_wrapper<expr>
            >
        operand;

        struct op
        {
            opcode operator_;
            operand operand_;
        };

        struct expr
        {
            operand operand_;
            std::list<op> operators_;

            expr() : operand_(), operators_() {}
            explicit expr(const operand & o) : operand_(o), operators_() {}
            explicit expr(const op & o) : operand_(), operators_({ o }) {}
        };

        struct declsym
        {
            std::string name_;
            boost::optional<expr> expr_;
        };

        struct decl : std::list<declsym> {};

        struct proc
        {
            std::string name_;
            std::list<std::string> params_;
            block block_;
        };

        struct type
        {
            std::string name_;
            boost::optional<std::list<std::string>> params_;
            block block_;
        };

        struct with
        {
            expr expr_;
            boost::optional<block> block_;
        };

        struct see
        {
            expr expr_;
            block block_;
        };

        struct speak
        {
            std::list<std::string> langs_;
            std::string source_;
        };
    }
}

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::declsym,
    (std::string, name_)
    (boost::optional<lyre::ast::expr>, expr_)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::speak,
    (std::list<std::string>, langs_)
    (std::string, source_)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::proc,
    (std::string, name_)
    (std::list<std::string>, params_)
    (lyre::ast::block, block_)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::type,
    (std::string, name_)
    (boost::optional<std::list<std::string>>, params_)
    (lyre::ast::block, block_)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::with,
    (lyre::ast::expr, expr_)
    (boost::optional<lyre::ast::block>, block_)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::see,
    (lyre::ast::expr, expr_)
    (lyre::ast::block, block_)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::block,
    (std::string, name_)
    (lyre::ast::stmts, stmts_)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::expr,
    (lyre::ast::operand, operand_)
    (std::list<lyre::ast::op>, operators_)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::op,
    (lyre::ast::opcode, operator_)
    (lyre::ast::operand, operand_)
)

#endif//__LYRE_AST_H____DUZY__
