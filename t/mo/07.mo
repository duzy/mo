## attributes of the current node
say('dotdot: .. = '~..)
say('dot: .name = '~.name)
say('select: child.name = '~child.name)
say('select: ->child = '~->child)
say('select: ->child[0].. = '~->child[0]..)
say('select: ->child[0].name = '~->child[0].name)
say('select: ->child.name = '~->child.name)
say('select: ->child[0, 1, 2] = '~->child[0, 1, 2])
say('select: ->child[0, 1, 2][0].name = '~->child[0, 1, 2][0].name)
say('select: ->child[0, 1, 2][1].name = '~->child[0, 1, 2][1].name)
say('select: ->child->{ 1 } = '~->child->{ 1 })
say('select: ->child->{ 0 } = '~->child->{ 0 })
say('select: ->child->{ 1 }[0].name = '~->child->{ 1 }[0].name)
say('select: ->child->{ .name eq \'test-child-1\' }[0].name = '~->child->{ .name eq 'test-child-1' }[0].name)
say('select: ->* = '~->*)
say('select: ->*[0] = '~->*[0])
say('select: ->*[1] = '~->*[1].name)
say('select: .xmlns:test = '~.xmlns:test)
say('select: .test:name = '~.test:name)
say('select: .* = '~.*)
say('select: $_.xmlns:test = '~$_.xmlns:test)
say('select: $_.test:name = '~$_.test:name)
say('select: $_.* = '~$_.*)
say('select: ->test:* = '~->test:*)
say('select: ->test:child = '~->test:child)
say('select: ->test:child->{ .name eq \'test-child-1\' } = '~->test:child->{ .name eq 'test-child-1' })
say('select: ->test:child[0].name = '~->test:child[0].name)
say('select: ->test:child[0].test:name = '~->test:child[0].test:name)
#say('select: ->test:{ .name eq \'test-child-1\' } = '~->test:{ .name eq 'test-child-1' })
#say('select: ->child->test:{ .name eq \'test-child-1\' } = '~->child->test:{ .name eq 'test-child-1' })
#say('select: ->child->test:{ .name eq \'test-child-1\' } = '~->child->test:{ .name eq 'test-child-1' })
say('select: child = '~child);

var $l = ('a', 'b', 'c', 'd');
say('select: $l[0] = '~$l[0]);
say('select: $l[0, 1, 2] = '~$l[0, 1, 2]);
say('select: $l->{ 1 } = '~$l->{ 1 });
say('select: $l->{ 1 } = '~join(', ', $l->{ 1 }));

say('select: glob = '~glob);
say('TODO: glob: * = '~glob('*'));

var $nodes = readdir('.');
say('readdir: '~$nodes);
for $nodes { say('readdir: '~$_.name()~",\t"~$_.path()) }
say('select: '~$nodes->{ isnull($_) });
say('select: '~$nodes->{ .name() eq '' });

#class a { $.name = 'foo' }
#var $a = new(a);
#say($a.name);

with ->child->{ .name eq "test-child-2" } do
{
    say("ok\t\t- with ->child\{ .name eq \"test-child-2\" \}");
    if .name eq "test-child-2"
        say("ok\t\t- .name eq \"test-child-2\"");
    else
        say("xx\t\t- .name eq \"test-child-2\"");
    end
}
