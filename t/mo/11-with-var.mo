say "1..3"

$node0 = ->child[0]
$nodes = ->child[0, 1]

with $node0 do {
    say .okay
}

for $nodes do {
    say .okay
}
