template test0
--------------------------
.
. 
.       
-----------------------end
if str test0 eq ""
    say("ok - test0")
else
    say("xx - test0: "~str test0)
end

var $t = new(test0)
say($t.generate($_));

template test1
--------------------------
.var $a = list()
.for $a
 ...
.end
-----------------------end
if str test1 eq ""
    say("ok - test1")
else
    say("xx - test1: "~str test1)
end

template test2
--------------------------
.var $a = list()
.if +$a
 ...
.end
-----------------------end
if str test2 eq ""
    say("ok - test2")
else
    say("xx - test2: "~str test2)
end

template test3
--------------------------
.var $a = list()
.if +$a
 ...
.else
blah...
.end
-----------------------end
if str test3 eq "blah..."
    say("ok - test3")
else
    say("xx - test3: "~str test3)
end

template test4
--------------------------
.   if .type eq 'string'
std::$(.type) $(.name);
.elsif .type eq 'strings'
std::list<std::$(.type)> $(.name);
.   var $a = list()
.   for $a
 ...
.   end
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
say(str test4)
