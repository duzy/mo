#include "parse.h"

namespace lab
{
    ast::stmts parse_file(const std::string & filename)
    {
        std::ifstream in(filename.c_str(), std::ios_base::in);
        in.unsetf(std::ios::skipws); // No white space skipping!
        std::istream_iterator<char> beg(in), end;
        return parse(beg, end);
    }
}

#endif//__LAB_PARSE_H____DUZY__
