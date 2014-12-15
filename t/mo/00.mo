template test0
--------------------------
.
.
.
-----------------------end

template test1
--------------------------
.var $a = list()
.for $a
 ...
.end
-----------------------end

template test2
--------------------------
.var $a = list()
.for $a
 ...
.end
-----------------------end

template test3
--------------------------
.   if .type eq 'string'
std::$(.type) $(.name);
.elsif .type eq 'strings'
std::list<std::$(.type)> $(.name);
.var $a = list()
.for $a
 ...
.end
.elsif .type eq 'number'
.      if .size == 4
uint32_t $(.name);
.   elsif .size == 2
uint16_t $(.name);
.   else
uint8_t $(.name);
.   end
.else
???
.end
-----------------------end
