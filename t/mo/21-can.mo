say("1..5")

var $v = ->child
if $v?push
  say("ok\t\t- $v?push")
else
  say("fail\t\t- $v?push")
end

if $v?pop
  say("ok\t\t- $v?pop")
else
  say("fail\t\t- $v?pop")
end

if $v?shift
  say("ok\t\t- $v?shift")
else
  say("fail\t\t- $v?shift")
end

if $v?unshift
  say("ok\t\t- $v?unshift")
else
  say("fail\t\t- $v?unshift")
end

if $v?sort
  say("ok\t\t- $v?sort")
else
  say("fail\t\t- $v?sort")
end
