## attributes of the current node
.name

## Node
->child
->child.name
->child[0]
->child[0].name
->child[0, 1, 2]
->child[0, 1, 2]->{ 1 }
->child[0, 1, 2]->{ 0 }
->child[0, 1, 2]->child
->child->child
->child->{ .name eq 'child-1' }

->*[1, 3]
->*[1, 3, 'child-1']

->ns:child
->ns:child.name
->ns:child.ns:name

ns 'http://www.example.com/xml' {
}

ns test {
     ->child
     ->child.name
     ->child[0, 1, 2]
}

## FilesystemNode
#<t/mo/test>
#<t/mo>['test']
#<t/mo>['test1', 'test2']
#<t/mo>[0, 1, 2, 3]
#<t/mo>[ "test/many/*.txt" ]
#<t/mo>[ "test/many/*.txt" ]->{ .ISREG }
#<.>->{ .ISREG }
#<.>['test/text.txt']->{ .ISREG }
#<.>['test/many/1.txt', "test/many/2.txt"]
#<.>['test/many/1.txt', "test/many/2.txt"]->{ .ISREG }

glob('*')->{ .ISREG }
glob("test/many/*.txt")->{ .ISREG }
glob('test/many/1.txt', "test/many/2.txt")->{ .ISREG }

# TODO: remove "->child do { ... }", check map, any, many instead
