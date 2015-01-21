#ifndef __LAB_AST_H____DUZY__
#define __LAB_AST_H____DUZY__ 1
#include <boost/variant/recursive_variant.hpp>
#include <boost/fusion/include/adapt_struct.hpp>
#include <boost/optional.hpp>
#include <list>

namespace lab
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
            none, int, unsigned int, float, double, std::string
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
    lab::ast::declsym,
    (std::string, _name)
    (boost::optional<lab::ast::expr>, _expr)
)

BOOST_FUSION_ADAPT_STRUCT(
    lab::ast::speak,
    (std::list<std::string>, _langs)
    (std::string, _source)
)

BOOST_FUSION_ADAPT_STRUCT(
    lab::ast::proc,
    (std::string, _name)
    (std::list<std::string>, _params)
    (lab::ast::block, _block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lab::ast::type,
    (std::string, _name)
    (boost::optional<std::list<std::string>>, _params)
    (lab::ast::block, _block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lab::ast::with,
    (lab::ast::expr, _expr)
    (boost::optional<lab::ast::block>, _block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lab::ast::see,
    (lab::ast::expr, _expr)
    (lab::ast::block, _block)
)

BOOST_FUSION_ADAPT_STRUCT(
    lab::ast::block,
    (std::string, _name)
    (lab::ast::stmts, _stmts)
)

BOOST_FUSION_ADAPT_STRUCT(
    lab::ast::expr,
    (lab::ast::operand, _operand)
    (std::list<lab::ast::op>, _operators)
)

BOOST_FUSION_ADAPT_STRUCT(
    lab::ast::op,
    (lab::ast::opcode, _operator)
    (lab::ast::operand, _operand)
)

#endif//__LAB_AST_H____DUZY__
