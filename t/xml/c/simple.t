# -*- nqp -*-
plan(24);

ok(!nqp::isnull($result), '$result');
if !nqp::isnull($result) {
    ok(nqp::how($result).name, 'how($result).name = Node');
    ok($result.name eq 'root', '$result.name = root');
    ok($result.count('node') eq 4, '$result.count(node) = 4');
    ok(nqp::getattr($result, $result, '') eq 'root', 'root."" = root');
    ok(nqp::getattr($result, $result, '.count') eq '4', 'root.count = 4');
}

my $nodes := nqp::getattr($result, $result, 'node');
ok(!nqp::isnull($nodes), 'root.node');
if !nqp::isnull($nodes) {
    ok(+$nodes eq 4, '+$node = 4');
    my $i := 1;
    for $nodes -> $node {
        ok(nqp::how($node).name, 'how($node).name = Node');
        ok($node.name eq 'node', '$node.name = node');
        ok(nqp::getattr($node, $node, '') eq 'node', 'node."" = node');
        ok(nqp::getattr($node, $node, '.name') eq 'node-'~$i, 'node.name = node-'~$i);
        $i := $i + 1;
    }
}
