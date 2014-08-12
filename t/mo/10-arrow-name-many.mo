say "1..8"

$subset = ->child[0]
with $subset do { say .okay }

$subset = ->child[0, 1, 2]
for $subset do { say .okay }

$subset = ->child[0, 1, 2]{ .. eq 'child' }
for $subset do { say .okay }

$subset = ->child{ .. eq 'child' }
for $subset do { say .okay }
