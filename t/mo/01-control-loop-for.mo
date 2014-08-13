say "1..8"

for ->child do
  {
    if .name eq 'test-child-1'
      say .okay
    elsif .name eq 'test-child-2'
      say .okay
    else
      say "fail\t- "~.name
    end

    if .okay eq $_.okay
      say $_.okay
    else
      say "fail\t- .okay eq $_.okay"
    end
  }

for ->child{1} do
  {
    if .name eq 'test-child-1'
      say .okay
    elsif .name eq 'test-child-2'
      say .okay
    else
      say "fail\t- "~.name
    end

    if .okay eq $_.okay
      say $_.okay
    else
      say "fail\t- .okay eq $_.okay"
    end
  }

$list = ->child
for $list
  if .name eq 'test-child-1'
    say .okay
  elsif .name eq 'test-child-2'
    say .okay
  else
    say "fail\t- "~.name
  end

  if .okay eq $_.okay
    say $_.okay
  else
    say "fail\t- .okay eq $_.okay"
  end
end
