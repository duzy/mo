
template C
------------
.var $class = .name;

\#include "$class.h"

struct $class {
.for message ;
    /**
     *  MESSAGE `$(.name)`
     */
.   for field ;
        $(.type) $(.name) ;
.   end
.end
};
