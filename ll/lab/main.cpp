#include "parser.h"

template<class T>
struct is
{
    typedef bool result_type;
    bool operator()(const T &) { return true; }
    template<class A> bool operator()(const A &) { return false; }
};

struct stmt_visitor
{
    typedef void result_type;

    int _indent;

    stmt_visitor() : _indent(0) {}

    std::string indent() const { return 0 < _indent ? std::string(_indent, ' ') : std::string(); }

    void operator()(int v)
    {
        std::clog<<indent()<<"(int) "<<v<<std::endl;
    }

    void operator()(unsigned int v)
    {
        std::clog<<indent()<<"(unsigned int) "<<v<<std::endl;
    }

    void operator()(float v)
    {
        std::clog<<indent()<<"(float) "<<v<<std::endl;
    }

    void operator()(double v)
    {
        std::clog<<indent()<<"(double) "<<v<<std::endl;
    }

    void operator()(const std::string & v)
    {
        std::clog<<indent()<<"(string) "<<v<<std::endl;
    }

    void operator()(const lab::ast::expr & e)
    {
        is<lab::ast::none> isNone;
        if (e._operators.size() == 0 && boost::apply_visitor(isNone, e._operand)) {
            std::clog<<indent()<<"expr: none"<<std::endl;
            return;
        }
        std::clog<<indent()<<"expr: ("<<e._operators.size()<<" ops)"<<std::endl;
        _indent += 4;
        boost::apply_visitor(*this, e._operand);
        for (auto op : e._operators) {
            std::clog<<indent()<<"op: "<<op._operator<<std::endl;
            _indent += 4;
            boost::apply_visitor(*this, op._operand);
            _indent -= 4;
        }
        _indent -= 4;
    }

    void operator()(const lab::ast::none &)
    {
        std::clog<<indent()<<"none:"<<std::endl;
    }

    void operator()(const lab::ast::decl & s)
    {
        std::clog<<indent()<<"decl: "<<std::endl;
    }

    void operator()(const lab::ast::proc & s)
    {
        std::clog<<indent()<<"proc: "<<s._name<<std::endl;
    }

    void operator()(const lab::ast::type & s)
    {
        std::clog<<indent()<<"type: "<<std::endl;
    }

    void operator()(const lab::ast::see & s)
    {
        std::clog<<indent()<<"see: "<<std::endl;
    }

    void operator()(const lab::ast::with & s)
    {
        std::clog<<indent()<<"with: "<<std::endl;
    }

    void operator()(const lab::ast::speak & s)
    {
        std::clog<<indent()<<"speak: "<<std::endl;
    }

    template <class T>
    void operator()(const T &)
    {
        std::clog<<indent()<<"stmt: ?"<<std::endl;
    }
};

int main() {
    auto stmts = lab::parse_file("00.lab");
    stmt_visitor visit;
    std::clog<<"stmts: "<<stmts.size()<<std::endl;
    for (auto stmt : stmts) {
        boost::apply_visitor(visit, stmt);
    }
    return 0;
}
