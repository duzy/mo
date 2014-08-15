# my native NodeList is repr('QRPA') { }
class MO::Model {
    my $instance;
    method get() { $instance; }

    has $!root;
    has $!current;

    method init($data) {
        my $one := nqp::create(self);
        $one.BUILD( :data($data) );
        $instance := $one;
    }

    method BUILD(:$data){
        $!root := $data;
        $!current := $data;
    }

    method root() {
        $!root;
    }

    method current() {
        $!current;
    }

    method dot($name, $node) { # .name, node.attribute
        $node := nqp::atpos($node, 0) if nqp::islist($node);
        #if !nqp::isnull($node) {
            $name := '.'~$name unless $name eq '';
            nqp::getattr($node, $node, $name);
        #}
    }

    method arrow($name, $parent) { # ->child, ->child[pos], parent->child
        $parent := nqp::atpos($parent, 0) if nqp::islist($parent);
        nqp::getattr($parent, $parent, $name); # if !nqp::isnull($parent);
    }

    method atpos($poses, $nodes) {
        if nqp::islist($poses) {
            my $list := nqp::list();
            $list.push(nqp::atpos($nodes, $_)) for $poses;
            $list;
        } else {
            nqp::atpos($nodes, $poses);
        }
    }

    method keyed($keys, $nodes) {
        if nqp::islist($keys) {
            nqp::say('keys: '~nqp::join(', ', $keys));
            my $list := nqp::list();
            $list.push(nqp::atpos($nodes, $_)) for $keys;
            $list;
        } else {
            nqp::say('key: '~$keys);
            nqp::atpos($nodes, $keys);
        }
    }

    method query($selector, $nodes) { # ->child{ ... }
        my $list := nqp::list();
        if nqp::islist($nodes) {
            $list.push($_) if !nqp::isnull($_) && $selector($_) for $nodes;
        } else {
            $list.push($nodes) if !nqp::isnull($nodes) && $selector($nodes);
        }
        $list;
    }
}
