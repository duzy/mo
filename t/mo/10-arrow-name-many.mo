say("1..11")

$subset = ->child{ .. eq 'child' }
for $subset {
    if .name eq 'test-child-1'
      say(.okay)
    elsif .name eq 'test-child-2'
      say(.okay)
    else
      say("fail\t\t- { .. eq 'child' }; " ~ .name)
    end
}

$subset = ->child[0]
with $subset {
    if .name eq 'test-child-1'
      say(.okay)
    else
      say("fail\t\t- [0]; " ~ .name)
    end
}

for ->child[0, 1] do {
    if .name eq 'test-child-1'
      say(.okay)
    elsif .name eq 'test-child-2'
      say(.okay)
    else
      say("fail\t- [0, 1]; " ~ .name)
    end
}

$subset = ->child[0, 1]
if +$subset == 2
  say("ok\t- +$subset == 2")
else
  say("fail\t- +$subset == 2")
end
for $subset do {
    if .name eq 'test-child-1'
      say(.okay)
    elsif .name eq 'test-child-2'
      say(.okay)
    else
      say("fail\t- [0, 1]; " ~ .name)
    end
}

$subset = ->child[0, 1, 2]{ .. eq 'child' }
if +$subset == 2
  say("ok\t- +$subset == 2")
else
  say("fail\t- +$subset == 2")
end
for $subset do {
    if .name eq 'test-child-1'
      say(.okay)
    elsif .name eq 'test-child-2'
      say(.okay)
    else
      say("fail\t- [0, 1, 2]{ .. eq 'child' }; " ~ .name)
    end
}
