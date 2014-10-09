say("1..5")

var $v = ->child
if $v.push?
  say("ok\t\t- $v.push?")
else
  say("xx\t\t- $v.push?")
end

if $v.pop?
  say("ok\t\t- $v.pop?")
else
  say("xx\t\t- $v.pop?")
end

if $v.shift?
  say("ok\t\t- $v.shift?")
else
  say("xx\t\t- $v.shift?")
end

if $v.unshift?
  say("ok\t\t- $v.unshift?")
else
  say("xx\t\t- $v.unshift?")
end

if $v.sort?
  say("ok\t\t- $v.sort?")
else
  say("xx\t\t- $v.sort?")
end
