say('1..23')

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

var $t = new(test0);
var $cache = $t.generate(list(), $_);
if +$cache == 0
   say("ok - test0.generate")
else
   say("xx - test0.generate")
end

template test1
--------------------------
.var $a = list();
.for $a
 ...
.end
-----------------------end
if str test1 eq ""
    say("ok - test1")
else
    say("xx - test1: "~str test1)
end
if +($cache = new(test1).generate(list(), $_)) == 0
   say("ok - test1.generate")
else
   say("xx - test1.generate: "~+$cache)
end

template test2
--------------------------
.var $a = list();
.if +$a
 ...
.end
-----------------------end
if str test2 eq ""
    say("ok - test2")
else
    say("xx - test2: "~str test2)
end
if +($cache = new(test2).generate(list(), $_)) == 0
   say("ok - test2.generate")
else
   say("xx - test2.generate: "~+$cache)
end

template test3
--------------------------
.var $a = list();
.if +$a
 ...
.else
blah...
.end
-----------------------end
if str test3 eq "blah...\n"
    say("ok - test3")
else
    say("xx - test3: "~str test3)
end
if +($cache = new(test3).generate(list(), $_)) == 1
   say("ok - test3.generate")
else
   say("xx - test3.generate: "~+$cache)
end


template test4
--------------------------
.   if .type eq 'string'
std::$(.type) $(.name);
.elsif .type eq 'strings'
std::list<std::string> $(.name);
.   var $a = list();
.   for $a
 ...
.   end
.elsif .type eq 'number'
.      if .size == 8
uint64_t $(.name);
.   elsif .size == 4
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

.set('type', 'string')
.set('name', 'foo')
if str test4 eq "std::string foo;\n"
    say("ok - test4")
else
    say("xx - test4: "~str test4)
end
if +($cache = new(test4).generate(list(), $_)) == 5
   say("ok - test4.generate")
else
   say("xx - test4.generate: "~+$cache)
end

.set('type', 'strings')
.set('name', 'foo')
if str test4 eq "std::list<std::string> foo;\n"
    say("ok - test4")
else
    say("xx - test4: "~str test4)
end
if +($cache = new(test4).generate(list(), $_)) == 3
   say("ok - test4.generate")
else
   say("xx - test4.generate: "~+$cache)
end

.set('type', 'number')
.set('name', 'foo')
.set('size', '0')
if str test4 eq "uint8_t foo;\n"
    say("ok - 0, test4")
else
    say("xx - 0, test4: "~str test4)
end
if +($cache = new(test4).generate(list(), $_)) == 3
   say("ok - 0, test4.generate")
else
   say("xx - 0, test4.generate: "~+$cache)
end

.set('type', 'number')
.set('name', 'foo')
.set('size', '1')
if str test4 eq "uint8_t foo;\n"
    say("ok - 1, test4")
else
    say("xx - 1, test4: "~str test4)
end
if +($cache = new(test4).generate(list(), $_)) == 3
   say("ok - 1, test4.generate")
else
   say("xx - 1, test4.generate: "~+$cache)
end

.set('type', 'number')
.set('name', 'foo')
.set('size', '2')
if str test4 eq "uint16_t foo;\n"
    say("ok - 2, test4")
else
    say("xx - 2, test4: "~str test4)
end
if +($cache = new(test4).generate(list(), $_)) == 3
   say("ok - 2, test4.generate")
else
   say("xx - 2, test4.generate: "~+$cache)
end

.set('type', 'number')
.set('name', 'foo')
.set('size', '4')
if str test4 eq "uint32_t foo;\n"
    say("ok - 4, test4")
else
    say("xx - 4, test4: "~str test4)
end
if +($cache = new(test4).generate(list(), $_)) == 3
   say("ok - 4, test4.generate")
else
   say("xx - 4, test4.generate: "~+$cache)
end

.set('type', 'number')
.set('name', 'foo')
.set('size', '8')
if str test4 eq "uint64_t foo;\n"
    say("ok - 8, test4")
else
    say("xx - 8, test4: "~str test4)
end
if +($cache = new(test4).generate(list(), $_)) == 3
   say("ok - 8, test4.generate")
else
   say("xx - 8, test4.generate: "~+$cache)
end

template test5
--------------------------
namespace $(.name)
{
    enum
    {
.for child ;
        $(.name);
.end
    };
}
-----------------------end

template test5_expected
--------------------------
namespace foo
{
    enum
    {
        test-child-1;
        test-child-2;
    };
}
-----------------------end

if str test5 eq str test5_expected
    say("ok - test5");
else
    say("xx - test5:\n"~str test5);
    say(str test5_expected)
end
