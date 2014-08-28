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
        $node.get($name) if !nqp::isnull($node) && nqp::can($node, 'get');
    }

    method dotdot($node) {
        $node := nqp::atpos($node, 0) if nqp::islist($node);
        $node.name;
    }

    method select_name($name, $nodes) { # ->child, parent->child
        my $result := nqp::list();
        if nqp::islist($nodes) {
            for $nodes -> $node {
                $result.push($_) for $node.children($name);
            }
        } else {
            my $node := $nodes;
            $result := $node.children($name);
        }
        $result;
    }

    method select_all($nodes) { # ->, node->
        my $result := nqp::list();
        if nqp::islist($nodes) {
            for $nodes -> $node {
                $result.push($_) for $node.children;
            }
        } else {
            $result := $nodes.children;
        }
        $result;
    }

    method select_path($path, $nodes) { # ->child, parent->child
        if nqp::islist($nodes) {
            my $result := nqp::list();
            for $nodes -> $node {
                my $s := $node.path ~ '/' ~ $path;
                my $new := MO::FilesystemNodeHOW.open(:path($s));
                $result.push($new);
            }
            $result;
        } else {
            MO::FilesystemNodeHOW.open(:path($path));
        }
    }

    method keyed_i($key, $nodes) { # [0]
        nqp::atpos($nodes, $key);
    }

    method keyed_s($key, $nodes) { # ['key']
        if nqp::islist($nodes) {
            my $result := nqp::list();
            for $nodes -> $node {
                $result.push($_) for $node.children($key);
            }
            $result;
        } else {
            $nodes.children($key);
        }
    }

    method keyed($key, $nodes) { # [0], ['key']
        if nqp::isint($key) {
            self.keyed_i($key, $nodes);
        } elsif nqp::isstr($key) {
            self.keyed_s($key, $nodes);
        } else {
            nqp::die('keyed: bad key');
        }
    }

    method keyed_list_i($keys, $nodes) { # [1, 2, 3]
        my $list := nqp::list();
        $list.push(self.keyed_i($_, $nodes)) for $keys;
        $list;
    }

    method keyed_list_s($keys, $nodes) { # ['key1', 'key2', 'key3']
        my $list := nqp::list();
        $list.push(self.keyed_s($_, $nodes)) for $keys;
        $list;
    }

    method keyed_list($keys, $nodes) { # ['key1', 'key2', 'key3', 0, 1, 2]
        my $list := nqp::list();
        $list.push(self.keyed($_, $nodes)) for $keys;
        $list;
    }

    method filter($selector, $nodes) { # ->child{ ... }
        my $list := nqp::list();
        # if nqp::islist($nodes) {
        #     $list.push($_) if !nqp::isnull($_) && $selector($_) for $nodes;
        # } else {
        #     $list.push($nodes) if !nqp::isnull($nodes) && $selector($nodes);
        # }
        $list.push($_) if !nqp::isnull($_) && $selector($_) for $nodes;
        $list;
    }
}
