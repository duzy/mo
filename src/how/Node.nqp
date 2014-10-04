class MO::Node {
    has $!name;
    has $!type;
    has $!parent;
    has @!attributes;
    has @!children;
    has %!children;

    method name() { $!name }
    method type() { $!type }
    method parent() { $!parent }
    method text() {}
    method attributes() {}
    method get() {}
    method set() {}
    method count() {}
    method children() {}
}
