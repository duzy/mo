#include <boost/spirit/home/qi.hpp>

namespace lab
{
    namespace ast
    {
        
    }

    template < class Iterator >
    struct grammar : boost::qi::grammar<Iterator>
    {
    };

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
