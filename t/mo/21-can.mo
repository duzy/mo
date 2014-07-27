say "1..1"

$v = ->child
if $v?push
  say "ok\t\t- $v?push"
else
  say "fail\t\t- $v?push"
end

if $v?elems
  say "ok\t\t- $v?elems"
else
  say "fail\t\t- $v?elems"
end
