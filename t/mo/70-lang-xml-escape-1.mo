say('1..1');

var $tag = 'node';

lang XML :escape as run
--------------------------
<$tag />
-----------------------end

if run().name() eq $tag
    say("ok - $tag escaped");
end
