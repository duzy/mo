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
            std::string _name;
            stmts _stmts;
        };

        enum opcode
        {
            op_nil,

            // get a reference to attribute
            op_attr,

            // filtering children
            op_select,

            // call a procedure (function)
            op_call,

            // unary
            op_unary_plus,
            op_unary_minus,
            op_unary_not,
            op_unary_dot,
            op_unary_arrow,

            // multiplicative
            op_mul,
            op_div,

            // additive
            op_add,
            op_sub,

            // relational
            op_lt, // less then
            op_le, // less or equal
            op_gt, // greater then
            op_ge, // greater or equal

            // equality
            op_eq,
            op_ne,

            // logical and/or
            op_a,
            op_o,

            // assign
            op_set,

            op_br,   // conditional branch
            op_swi,  // switch
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
            opcode _operator;
            operand _operand;
        };

        struct expr
        {
            operand _operand;
            std::list<op> _operators;

            expr() : _operand(), _operators() {}
            explicit expr(const operand & o) : _operand(o), _operators() {}
            explicit expr(const op & o) : _operand(), _operators({ o }) {}
        };

        struct declsym
        {
            std::string _name;
            boost::optional<expr> _expr;
        };

        struct decl : std::list<declsym> {};

        struct proc
        {
            std::string _name;
            std::list<std::string> _params;
            block _block;
        };

        struct type
        {
            std::string _name;
            boost::optional<std::list<std::string>> _params;
            block _block;
        };

        struct with
        {
            expr _expr;
            boost::optional<block> _block;
        };

        struct see
        {
            expr _expr;
            block _block;
        };

        struct speak
        {
            std::list<std::string> _langs;
            std::string _source;
        };
    }
}

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::declsym,
    (std::string, _name)
    (boost::optional<lyre::ast::expr>, _expr)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::speak,
    (std::list<std::string>, _langs)
    (std::string, _source)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::proc,
    (std::string, _name)
    (std::list<std::string>, _params)
    (lyre::ast::block, _block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::type,
    (std::string, _name)
    (boost::optional<std::list<std::string>>, _params)
    (lyre::ast::block, _block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::with,
    (lyre::ast::expr, _expr)
    (boost::optional<lyre::ast::block>, _block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::see,
    (lyre::ast::expr, _expr)
    (lyre::ast::block, _block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::block,
    (std::string, _name)
    (lyre::ast::stmts, _stmts)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::expr,
    (lyre::ast::operand, _operand)
    (std::list<lyre::ast::op>, _operators)
)

BOOST_FUSION_ADAPT_STRUCT(
    lyre::ast::op,
    (lyre::ast::opcode, _operator)
    (lyre::ast::operand, _operand)
)

#endif//__LYRE_AST_H____DUZY__
