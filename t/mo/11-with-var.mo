say "1..6"

$node0 = ->child[0]
$nodes = ->child[0, 1]

with $node0 do {
    if .name eq 'test-child-1'
      say .okay
    else
      say "fail\t- $node0"
    end
}

with $node0 {
    if .name eq 'test-child-1'
      say .okay
    else
      say "fail\t- $node0"
    end
}

for $nodes do {
    if .name eq 'test-child-1'
      say .okay
    elsif .name eq 'test-child-2'
      say .okay
    else
      say "fail\t- $nodes"
    end
}

for $nodes {
    if .name eq 'test-child-1'
      say .okay
    elsif .name eq 'test-child-2'
      say .okay
    else
      say "fail\t- $nodes"
    end
}
