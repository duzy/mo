template C_h
--------------
.var $class = .name;
/** $(license[0].text()) */
\#ifndef __$($class)_H__INCLUDED__
\#define __$($class)_H__INCLUDED__ 1

/* These are the $class messages:
.for message ;

   $(.name) - 
.   for field ;
        $(.name) $(.type)
.   end
.end
 */

\#include <czmq.h>



\#endif//__$($class)_H__INCLUDED__
