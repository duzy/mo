say('1..16');

var $tag_root = 'root';
var $tag_child = 'child';

lang XML :escape as root
--------------------------
  <?xml version="1.0"?>
  <$tag_root>
    <$tag_child name="child-1" />
    <$tag_child name="child-2" />
    <$tag_child name="child-3">
      <$tag_child name="child-3-1" />
      <$tag_child name="child-3-2" />
      <$tag_child name="child-3-3" />
    </$tag_child>
  </$tag_root>
-----------------------end

var $node = root();
if $node.type() eq 'data'
  say("ok - "~$node.type());
end
if $node.name() eq 'root'
  say("ok - "~$node.name());
end

var $children = $node.children('child');
if +$children == 3 { say("ok - 3 children") }

if $children[0].name() eq 'child' { say("ok - 1. child") }
if $children[1].name() eq 'child' { say("ok - 2. child") }
if $children[2].name() eq 'child' { say("ok - 3. child") }
if $children[0].name eq 'child-1' { say("ok - child-1") }
if $children[1].name eq 'child-2' { say("ok - child-2") }
if $children[2].name eq 'child-3' { say("ok - child-3") }

$children = $children[2].children('child');
if +$children == 3 { say("ok - 3 grand-children") }
if $children[0].name() eq 'child' { say("ok - 4. child") }
if $children[1].name() eq 'child' { say("ok - 5. child") }
if $children[2].name() eq 'child' { say("ok - 6. child") }
if $children[0].name eq 'child-3-1' { say("ok - child-3-1") }
if $children[1].name eq 'child-3-2' { say("ok - child-3-2") }
if $children[2].name eq 'child-3-3' { say("ok - child-3-3") }
