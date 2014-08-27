# -*- nqp -*-
plan(51);

ok(!nqp::isnull($result), '$result');
if !nqp::isnull($result) {
    ok($result.name eq 'root', '$result.name = root');
    ok($result.type eq 'data', '$result.type = data');
    ok($result.count('node') == 4, '$result.count(node) = 4');
    ok($result.count == 9, '$result.count = 9');
}

my $nodes := $result.children('node');
ok(!nqp::isnull($nodes), 'root.node');
if !nqp::isnull($nodes) {
    ok(+$nodes eq 4, '+$nodes = 4');
    my $i := 1;
    for $nodes -> $node {
        ok($node.name eq 'node', '$node.name = node');
        ok($node.get('name') eq 'node-'~$i, 'node.name = node-'~$i);
        my $attributes := $node.attributes;
        if $i eq 1 {
            ok(+$attributes eq 1, '+node.attributes = 1');
            ok(+$attributes[0] eq 2, '+node.attributes[0] = 2');
            ok($attributes[0][0] eq 'name', '+node.attributes[0][0] = name');
            ok($attributes[0][1] eq 'node-1', '+node.attributes[0][1] = node-1');
        } elsif $i eq 2 {
            ok(+$attributes eq 2, '+node.attributes = 2');
            ok(+$attributes[0] eq 2, '+node.attributes[0] = 2');
            ok($attributes[0][0] eq 'name', '+node.attributes[0][0] = name');
            ok($attributes[0][1] eq 'node-2', '+node.attributes[0][1] = node-2');
            ok($attributes[1][0] eq 'type', '+node.attributes[1][0] = type');
            ok($attributes[1][1] eq 'child', '+node.attributes[1][1] = child');
            ok($node.get('type') eq 'child', 'node.get(type) = child');
        } elsif $i eq 3 {
            ok(+$attributes eq 2, '+node.attributes = 2');
            ok(+$attributes[0] eq 2, '+node.attributes[0] = 2');
            ok($attributes[0][0] eq 'name', '+node.attributes[0][0] = name');
            ok($attributes[0][1] eq 'node-3', '+node.attributes[0][1] = node-3');
            ok($attributes[1][0] eq 'age', '+node.attributes[1][0] = age');
            ok($attributes[1][1] eq '10', '+node.attributes[1][1] = 10');
            ok($node.get('age') eq '10', 'node.get(age) = 10');
        } elsif $i eq 4 {
            ok(+$attributes eq 1, '+node.attributes = 1');
            ok(+$attributes[0] eq 2, '+node.attributes[0] = 2');
            ok($attributes[0][0] eq 'name', '+node.attributes[0][0] = name');
            ok($attributes[0][1] eq 'node-4', '+node.attributes[0][1] = node-4');
            ok($node.count('node') eq 3, '+$node.count(node) = 3');
            my $subnodes := $node.children('node');
            ok(!nqp::isnull($subnodes), 'root.node[4].node');
            if !nqp::isnull($subnodes) {
                ok(+$subnodes eq 3, '+$subnodes = 3');
                my $j := 1;
                for $subnodes -> $subnode {
                    ok($subnode.name eq 'node', '$subnode.name = node');
                    ok($subnode.get('name') eq 'node-'~$i~'-'~$j, 'node.get(name) = node-'~$i~'-'~$j);
                    if $j eq 3 {
                        my $all := $subnode.children;
                        ok(!nqp::isnull($all), 'node.children is not null');
                        if !nqp::isnull($all) {
                            my $text := nqp::join('', $all);
                            ok(+$all, '+node.children = 1');
                            ok($text eq 'text', 'node.children = text');
                            ok($subnode.text eq 'text', 'node.text = text');
                            ok($subnode.count eq 1, 'node.count = 1');
                        }
                    }
                    $j := $j + 1;
                }
            }
        }
        $i := $i + 1;
    }
}
