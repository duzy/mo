# -*- nqp -*-
plan(67);

# Node
# 
# node['']                - tag name
# node['*']               - all children (including text)
# node['.*']              - all attributes in their represented order
# node['.attribute']      - attribute of that name
# node['name']            - sub-nodes of the specified 'name'
#

ok(!nqp::isnull($result), '$result');
if !nqp::isnull($result) {
    ok(nqp::how($result).name, 'how($result).name = Node');
    ok(nqp::how($result).node_name($result) eq 'root', '$result.name = root');
    ok(nqp::how($result).node_count($result, 'node') eq 4, '$result.count(node) = 4');
    ok(nqp::getattr($result, $result, '') eq 'root', 'root."" = root');
    ok(nqp::getattr($result, $result, '.*') eq 1, '+root.* = 1');
    ok(nqp::getattr($result, $result, '.count') eq '4', 'root.count = 4');
}

my $nodes := nqp::getattr($result, $result, 'node');
ok(!nqp::isnull($nodes), 'root.node');
if !nqp::isnull($nodes) {
    ok(+$nodes eq 4, '+$nodes = 4');
    my $i := 1;
    for $nodes -> $node {
        ok(nqp::how($node).name, 'how($node).name = Node');
        ok(nqp::how($node).node_name($node) eq 'node', '$node.name = node');
        ok(nqp::getattr($node, $node, '') eq 'node', 'node."" = node');
        ok(nqp::getattr($node, $node, '.name') eq 'node-'~$i, 'node.name = node-'~$i);
        my $attributes := nqp::getattr($node, $node, '.*');
        if $i eq 1 {
            ok(+$attributes eq 1, '+node.* = 1');
            ok(+$attributes[0] eq 2, '+node.*[0] = 2');
            ok($attributes[0][0] eq 'name', '+node.*[0][0] = name');
            ok($attributes[0][1] eq 'node-1', '+node.*[0][1] = node-1');
        } elsif $i eq 2 {
            ok(+$attributes eq 2, '+node.* = 2');
            ok(+$attributes[0] eq 2, '+node.*[0] = 2');
            ok($attributes[0][0] eq 'name', '+node.*[0][0] = name');
            ok($attributes[0][1] eq 'node-2', '+node.*[0][1] = node-2');
            ok($attributes[1][0] eq 'type', '+node.*[1][0] = type');
            ok($attributes[1][1] eq 'child', '+node.*[1][1] = child');
            ok(nqp::getattr($node, $node, '.type') eq 'child', 'node.type = child');
        } elsif $i eq 3 {
            ok(+$attributes eq 2, '+node.* = 2');
            ok(+$attributes[0] eq 2, '+node.*[0] = 2');
            ok($attributes[0][0] eq 'name', '+node.*[0][0] = name');
            ok($attributes[0][1] eq 'node-3', '+node.*[0][1] = node-3');
            ok($attributes[1][0] eq 'age', '+node.*[1][0] = age');
            ok($attributes[1][1] eq '10', '+node.*[1][1] = 10');
            ok(nqp::getattr($node, $node, '.age') eq '10', 'node.age = 10');
        } elsif $i eq 4 {
            ok(+$attributes eq 1, '+node.* = 1');
            ok(+$attributes[0] eq 2, '+node.*[0] = 2');
            ok($attributes[0][0] eq 'name', '+node.*[0][0] = name');
            ok($attributes[0][1] eq 'node-4', '+node.*[0][1] = node-4');
            ok(nqp::how($node).node_count($node, 'node') eq 3, '+$node.count(node) = 3');
            my $subnodes := nqp::getattr($node, $node, 'node');
            ok(!nqp::isnull($subnodes), 'root.node[4].node');
            if !nqp::isnull($subnodes) {
                ok(+$subnodes eq 3, '+$subnodes = 3');
                my $j := 1;
                for $subnodes -> $subnode {
                    ok(nqp::how($subnode).name, 'how($subnode).name = Node');
                    ok(nqp::how($subnode).node_name($subnode) eq 'node', '$subnode.name = node');
                    ok(nqp::getattr($subnode, $subnode, '') eq 'node', 'node."" = node');
                    ok(nqp::getattr($subnode, $subnode, '.name') eq 'node-'~$i~'-'~$j, 'node.name = node-'~$i~'-'~$j);
                    if $j eq 3 {
                        my $all := nqp::getattr($subnode, $subnode, '*');
                        ok(!nqp::isnull($all), 'node.* is not null');
                        if !nqp::isnull($all) {
                            my $text := nqp::join('', $all);
                            ok(+$all, '+node.* = 1');
                            ok($text eq 'text', 'node.* = text');
                            ok(nqp::how($subnode).node_text($subnode) eq 'text', 'node.text = text');
                            ok(nqp::how($subnode).node_count($subnode) eq 1, 'node.count = 1');
                        }
                    }
                    $j := $j + 1;
                }
            }
        }
        $i := $i + 1;
    }
}
