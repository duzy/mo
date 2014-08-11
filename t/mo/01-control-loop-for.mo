say "1..8"

for ->child do
  {
    say .okay
    say $_.okay
  }

$list = ->child
for $list
  say .okay
  say $_.okay
end
