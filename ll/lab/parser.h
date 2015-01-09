#include <boost/spirit/home/qi.hpp>

namespace lab
{
    class parser
    {
    public:
        parser()
        {
        }

        virtual ~parser() = default;

        int parse(const std::string & filename) {
            // ...
            return 0;
        }
    };
}
