# -*- nqp -*-
plan(41);

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
    ok(+$nodes eq 4, '+$nodes = 4');
    my $i := 1;
    for $nodes -> $node {
        ok(nqp::how($node).name, 'how($node).name = Node');
        ok($node.name eq 'node', '$node.name = node');
        ok(nqp::getattr($node, $node, '') eq 'node', 'node."" = node');
        ok(nqp::getattr($node, $node, '.name') eq 'node-'~$i, 'node.name = node-'~$i);
        if $i eq 2 {
            ok(nqp::getattr($node, $node, '.type') eq 'child', 'node.type = child');
        } elsif $i eq 3 {
            ok(nqp::getattr($node, $node, '.age') eq '10', 'node.age = 10');
        } elsif $i eq 4 {
            ok($node.count('node') eq 3, '+$node.count(node) = 3');
            my $subnodes := nqp::getattr($node, $node, 'node');
            ok(!nqp::isnull($subnodes), 'root.node[4].node');
            if !nqp::isnull($subnodes) {
                ok(+$subnodes eq 3, '+$subnodes = 3');
                my $j := 1;
                for $subnodes -> $subnode {
                    ok(nqp::how($subnode).name, 'how($subnode).name = Node');
                    ok($subnode.name eq 'node', '$subnode.name = node');
                    ok(nqp::getattr($subnode, $subnode, '') eq 'node', 'node."" = node');
                    ok(nqp::getattr($subnode, $subnode, '.name') eq 'node-'~$i~'-'~$j, 'node.name = node-'~$i~'-'~$j);
                    if $j eq 3 {
                        # TODO: more test cases going here...
                    }
                    $j := $j + 1;
                }
            }
        }
        $i := $i + 1;
    }
}
