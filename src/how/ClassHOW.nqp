knowhow MO::ClassHOW {
    has str $!name;

    has @!attributes;
    has %!methods;
    has @!method_order;
    has @!parents;

    has @!mro;

    has $!composed;

    # Create a new instance of this meta-class.
    method new(:$name = '<class>') {
        my $obj := nqp::create(self);
        $obj.BUILD(:$name);
        $obj;
    }

    # Create a new meta-class instance, and then a new type object to go with
    # it, and return the new type.
    method new_type(:$name = '<class>', :$repr = 'P6opaque') {
        my $metaclass := self.new(:$name);
        nqp::setwho(nqp::newtype($metaclass, $repr), {});
    }

    # Construct the meta-class instance.
    method BUILD(:$name = '<class>') {
        $!name := $name;
        @!attributes := [];
        %!methods := {};
        @!parents := [];
    }

    method add_method($obj, $name, $code_obj) {
        if nqp::existskey(%!methods, $name) {
            nqp::die("This class already has a method named " ~ $name);
        }
        if nqp::isnull($code_obj) || !nqp::defined($code_obj) {
            nqp::die("Cannot add a null method '$name' to class '$!name'");
        }
        nqp::setmethcacheauth($obj, 0);
        # %!caches{nqp::where(self)} := {} unless nqp::isnull(%!caches);
        nqp::push(@!method_order, %!methods{$name} := $code_obj);
    }

    method add_attribute($obj, $meta_attr) {
        my $name := $meta_attr.name;
        for @!attributes {
            if $_.name eq $name {
                nqp::die("This class already has an attribute named " ~ $name);
            }
        }
        nqp::push(@!attributes, $meta_attr);
    }

    method attributes($obj, :$local = 0) {
        my @attrs;
        if $local {
            for @!attributes {
                nqp::push(@attrs, $_);
            }
        }
        else {
            for @!mro {
                for $_.HOW.attributes($_, :local) {
                    nqp::push(@attrs, $_);
                }
            }
        }
        @attrs
    }

    method methods($obj) {
        %!methods
    }

    method parents($obj, :$local = 0) {
        $local ?? @!parents !! @!mro
    }

    method name() { $!name }

    # Compose the type (MRO entries).
    method compose($obj) {
        @!mro := compute_mro($obj);

        # Compose attributes.
        #for self.attributes($obj) { $_.compose($obj) }

        nqp::settypecache($obj, @!mro);

        self.publish_type_cache($obj);
        self.publish_method_cache($obj);
        self.publish_boolification_spec($obj);

        self.compose_repr($obj) unless $!composed;

        # Mark as composed.
        $!composed := 1;

        $obj
    }

    # Compose the representation (attributes).
    method compose_repr($obj) {
        # The attribute protocol data.
        my @attribute;

        for @!mro -> $type {
            my @attrs;
            for $type.HOW.attributes($type) -> $attr {
                my %attr_info;
                %attr_info<name> := $attr.name;
                %attr_info<type> := $attr.type;
                if $attr.box_target {
                    # Merely having the key serves as a "yes".
                    %attr_info<box_target> := 1;
                }
                if nqp::can($attr, 'auto_viv_container') {
                    %attr_info<auto_viv_container> := $attr.auto_viv_container;
                }
                if $attr.positional_delegate {
                    %attr_info<positional_delegate> := 1;
                }
                if $attr.associative_delegate {
                    %attr_info<associative_delegate> := 1;
                }
                nqp::push(@attrs, %attr_info);
            }

            # Each MRO entry is an array containing the type of the MRO entry,
            # and following an array of hashes per attribute, and a list of
            # immediate parents.
            my @type_info;
            nqp::push(@type_info, @attrs);
            nqp::push(@type_info, $type);
            nqp::push(@type_info, $type.HOW.parents($type));

            nqp::push(@attribute, @type_info);
        }

        my %info; # The REPR compose protocol info.
        %info<attribute> := @attribute;
        nqp::composetype($obj, %info);
    }

    # Compute the MRO.
    my sub compute_mro($class) {
        my @immediate_parents := $class.HOW.parents($class, :local);
        @immediate_parents;
    }

    my method publish_type_cache($obj) {
        my @typecache;
        for @!mro { nqp::push(@typecache, $_); }
        nqp::settypecache($obj, @typecache)
    }

    my method publish_method_cache($obj) {
        # Walk MRO and add methods to cache, unless another method
        # lower in the class hierarchy "shadowed" it.
        my %cache;
        my @mro_reversed := reverse(@!mro);
        for @mro_reversed {
            for $_.HOW.methods($_) {
                %cache{nqp::iterkey_s($_)} := nqp::iterval($_);
            }
        }
        nqp::setmethcache($obj, %cache);
        nqp::setmethcacheauth($obj, 1);
    }

    my method publish_boolification_spec($obj) {
        my $bool_meth := self.find_method($obj, 'Bool');
        if nqp::defined($bool_meth) {
            nqp::setboolspec($obj, 0, $bool_meth)
        }
        else {
            nqp::setboolspec($obj, 5, nqp::null())
        }
    }

    my sub reverse(@in) {
        my @out;
        for @in { nqp::unshift(@out, $_) }
        @out
    }
}
