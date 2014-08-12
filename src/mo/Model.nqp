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

    my method ensure($any) {
        if nqp::isnull($any) {
            $!current;
        } elsif nqp::can($any, 'get_how') && nqp::istype($any.HOW, NodeClassHOW) { # Can only use get_how on a SixModelObject
            $any;
        } elsif nqp::islist($any) && +$any { # QRPA
                #nqp::can($any, 'push') && nqp::can($any, 'pop') &&
                #nqp::can($any, 'shift') && nqp::can($any, 'unshift') &&
                #nqp::elems($any) && +$any { # QRPA
            nqp::atpos($any, 0);
        } else {
            nqp::die('Invalid node');
        }
    }

    method dot($name, $node = nqp::null()) { # .name, node.attribute
        $node := self.ensure($node);
        $name := '.'~$name unless $name eq '';
        nqp::getattr($node, $node, $name);
    }

    method arrow($name, $parent = nqp::null()) { # ->child, ->child[pos], parent->child
        $parent := self.ensure($parent);
        nqp::getattr($parent, $parent, $name);
    }

    method at($pos, $nodes) {
        if nqp::islist($pos) {
            my $nodes := nqp::list();
            $nodes.push(nqp::atpos($nodes, $_)) for $pos;
            $nodes;
        } else {
            my $node := nqp::atpos($nodes, $pos);
            $node;
        }
    }

    method query($selector, $nodes) { # ->child{ ... }
        ## see Parrot_QRPA_class_init in src/vm/parrot/pmc/qrpa.c
        my $list := nqp::list();
        $list.push($_) if $selector($_) for $nodes;
        $list;
    }
}
