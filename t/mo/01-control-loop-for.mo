say("1..8")

for ->child do
  {
    if .name eq 'test-child-1'
      say(.okay)
    elsif .name eq 'test-child-2'
      say(.okay)
    else
      say("fail\t- "~.name)
    end

    $s = $.okay
    if .okay eq $s
      say($.okay)
    else
      say("fail\t- .okay eq $.okay")
    end
  }

for ->child{1} do
  {
    if .name eq 'test-child-1'
      say(.okay)
    elsif .name eq 'test-child-2'
      say(.okay)
    else
      say("fail\t- "~.name)
    end

    $s = $.okay
    if .okay eq $s
      say($.okay)
    else
      say("fail\t- .okay eq $.okay")
    end
  }

$list = ->child
for $list
  if .name eq 'test-child-1'
    say(.okay)
  elsif .name eq 'test-child-2'
    say(.okay)
  else
    say("fail\t- "~.name)
  end

  $s = $.okay
  if .okay eq $s
    say($.okay)
  else
    say("fail\t- .okay eq $.okay")
  end
end
