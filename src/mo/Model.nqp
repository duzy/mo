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

    method select_me($a) { $a }

    method select_name($name, $a) { # ->child, parent->child
        my @result;
        if nqp::islist($a) {
            for $a {
                @result.push($_) for $_.children($name);
            }
        } else {
            @result := $a.children($name);
        }
        @result;
    }

    method select_all($a) { # ->, node->
        my @result;
        if nqp::islist($a) {
            for $a -> $node {
                @result.push($_) for $node.children;
            }
        } else {
            @result := $a.children;
        }
        @result;
    }

    method select_path($path, $a) { # ->child, parent->child
        if nqp::islist($a) {
            my @result := nqp::list();
            for $a -> $node {
                my $s := $node.path ~ '/' ~ $path;
                my $new := MO::FilesystemNodeHOW.open(:path($s));
                @result.push($new);
            }
            @result;
        } else {
            MO::FilesystemNodeHOW.open(:path($path));
        }
    }

    method keyed_i($key, $a) { # [0]
        if nqp::islist($a) {
            nqp::atpos($a, $key);
        } else {
            $a;
        }
    }

    method keyed_s($key, $a) { # ['key']
        if nqp::islist($a) {
            my @result;
            for $a -> $node {
                if !nqp::isstr($node) && nqp::can($node, 'children') {
                    my $children := $node.children($key);
                    if nqp::defined($children) {
                        @result.push($_) for $children;
                    }
                }
            }
            @result;
        } elsif nqp::defined($a) && nqp::can($a, 'children') {
            $a.children($key);
        }
    }

    method keyed($key, $a) { # [0], ['key']
        if nqp::isint($key) {
            self.keyed_i($key, $a);
        } elsif nqp::isstr($key) {
            self.keyed_s($key, $a);
        } else {
            nqp::die('keyed: bad key');
        }
    }

    method keyed_list_i($keys, $a) { # [1, 2, 3]
        my @result;
        @result.push(self.keyed_i($_, $a)) for $keys;
        @result;
    }

    method keyed_list_s($keys, $a) { # ['key1', 'key2', 'key3']
        my @result;
        @result.push(self.keyed_s($_, $a)) for $keys;
        @result;
    }

    method keyed_list($keys, $a) { # ['key1', 'key2', 'key3', 0, 1, 2]
        my @result;
        @result.push(self.keyed($_, $a)) for $keys;
        @result;
    }

    method filter($selector, $a) { # ->child{ ... }
        my @result;
        if nqp::islist($a) {
            @result.push($_) if !nqp::isnull($_) && $selector($_) for $a;
        } else {
            @result.push($a) if !nqp::isnull($a) && $selector($a);
        }
        @result;
    }
}
