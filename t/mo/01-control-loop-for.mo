say("1..12")

for ->child do
  {
    if .name eq 'test-child-1'
      say(.okay)
    elsif .name eq 'test-child-2'
      say(.okay)
    else
      say("fail\t- "~.name)
    end

    var $s = $_.get('okay')
    if .okay eq $s
      say($_.get('okay'))
    else
      say("fail\t- .okay eq $_.okay")
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

    var $s = $_.get('okay')
    if .okay eq $s
      say($_.get('okay'))
    else
      say("fail\t- .okay eq $_.okay")
    end
  }

var $list = ->child
for $list
  if .name eq 'test-child-1'
    say(.okay)
  elsif .name eq 'test-child-2'
    say(.okay)
  else
    say("fail\t- "~.name)
  end

  var $s = $_.get('okay')
  if .okay eq $s
    say($_.get('okay'))
  else
    say("fail\t- .okay eq $_.okay")
  end
end
