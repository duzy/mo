class moop
{
    my $model;

    method set_root($m) { $model := $m }
    method root() { $model }

    method select($a, $name, $must = 0) { # ->child, parent->child
        my @result;
        if nqp::islist($a) {
            for $a {
                if nqp::can($_, 'children') {
                    my $children := $_.children($name);
                    if nqp::defined($children) {
                        @result.push($_) for $children;
                    }
                }
            }
        } elsif nqp::defined($a) {
            if nqp::can($a, 'children') {
                my $children := $a.children($name);
                @result := $children if nqp::defined($children);
            } else {
                nqp::die("$name is not Node, but "~$a.HOW.name($a));
            }
        }
        if $must && +@result < 1 {
            nqp::die("$name is undefined");
        }
        @result;
    }

    method filter($a, $selector) { # ->{ ... }
        my @result;
        if nqp::islist($a) {
            @result.push($_) if !nqp::isnull($_) && $selector($_) for $a;
        } else {
            @result.push($a) if !nqp::isnull($a) && $selector($a);
        }
        @result;
    }

    method any($pred, $data, $block?)
    {
        for $data {
            if nqp::islist($_) {
                my $v := self.any($pred, $_);
                return $v unless nqp::isnull($v);
            } elsif $pred($_) {
                $block($_) if nqp::defined($block);
                return $_;
            }
        }
        nqp::null()
    }

    method many($pred, $data, $block?)
    {
        my @result;
        for $data {
            if nqp::islist($_) {
                @result.push($_) for self.many($pred, $_, $block);
            } elsif $pred($_) {
                $block($_) if nqp::defined($block);
                @result.push($_);
            }
        }
        @result
    }

    method map($pred, $data)
    {
        my @result;
        for $data {
            my $v;
            if nqp::islist($_) {
                @result.push($_) for self.map($pred, $_);
            } elsif nqp::defined($v := $pred($_)) {
                @result.push($v);
            }
        }
        @result
    }
}
