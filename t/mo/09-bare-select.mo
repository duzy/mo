say('1..7')

var $s = '';
for child
    # unless $s eq '' { $s = "$s\n" }
    unless $s eq '' $s = "$s\n" end
    $s = $s ~ .name() ~ ' ' ~.name;
end

if $s eq "child test-child-1\nchild test-child-2"
    say("ok - \$s")
else
    say("xx - \$s = $s")
end

if child[0].name eq 'test-child-1'
    say("ok - child.name")
else
    say("xx - child.name = "~child.name)
end

if child[0].name() eq 'child'
    say("ok - child[0].name()")
else
    say("xx - child[0].name() = "~child[0].name())
end
if child[0].name eq 'test-child-1'
    say("ok - child[0].name")
else
    say("xx - child[0].name = "~child[0].name)
end

if child[1].name() eq 'child'
    say("ok - child[1].name()")
else
    say("xx - child[1].name() = "~child[1].name())
end
if child[1].name eq 'test-child-2'
    say("ok - child[1].name")
else
    say("xx - child[1].name = "~child[1].name)
end

if +child->child == 0
    say('ok - child->child is empty')
else
    say('xx - child->child '~+child->child)
end
