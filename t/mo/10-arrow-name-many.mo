# Children selectors
$subset = ->child{ .name eq 'foo' }
$subset = ->child[0, 1, 2, 3]{ .name eq 'foo' }
$subset = ->child[0];
