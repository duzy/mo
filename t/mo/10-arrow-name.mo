say("1..13")

if ->child == 2
  say("ok\t\t- ->child == 2")
else
  say("fail\t\t- ->child == 2")
end

if ->child[0].name eq "test-child-1"
  say(->child[0].okay)
else
  say("fail\t\t- ->child[0].name")
end

if ->child[1].name eq "test-child-2"
  say(->child[1].okay)
else
  say("fail\t\t- ->child[1].name")
end

-> child {
  say(.okay ~ ' -- ' ~ .name ~ ' -- <selector>')
  0
}

if ->child { 0 } == 0
  say("ok\t\t- ->child { 0 } == 0")
else
  say("fail\t\t- ->child { 0 } == 0")
end

if ->child { 1 } == 2
  say("ok\t\t- ->child{1} == 2")
else
  say("fail\t\t- ->child{1} == 2")
end

if ->child { 1 } == ->child
  say("ok\t\t- ->child{1} == ->child")
else
  say("fail\t\t- ->child{1} == ->child")
end

if ->child{ .name eq "test-child-1" } == 1
  say("ok\t\t- ->child\{ .name eq \"test-child-1\" \} == 1")
else
  say("fail\t\t- ->child\{ .name eq \"test-child-1\" \} == 1")
end
if ->child{ .name eq "test-child-2" } == 1
  say("ok\t\t- ->child\{ .name eq \"test-child-2\" \} == 1")
else
  say("fail\t\t- ->child\{ .name eq \"test-child-2\" \} == 1")
end

say(->child.okay ~ ' -- ' ~ ->child.name ~ ' -- (first child)')

if ->child.name eq 'test-child-1'
  say("ok\t\t- ->child.name eq 'test-child-1'")
else
  say("fail\t\t- ->child.name eq 'test-child-1'")
end

if +->end == 1
  say("ok\t\t- ->end == 1")
end
