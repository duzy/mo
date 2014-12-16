knowhow MO::TemplateHOW {
    has str $!name;

    has @!attributes;
    has %!methods; # methods keyed by name

    has int $!composed;

    # Create a new instance of this meta-class.
    method new(:$name = '<template>') {
        my $obj := nqp::create(self);
        $obj.BUILD(:$name);
        $obj;
    }

    # Create a new meta-class instance, and then a new type object to go with
    # it, and return the new type.
    method new_type(:$name = '<template>', :$repr = 'P6opaque') {
        my $metaclass := self.new(:$name);
        nqp::setwho(nqp::newtype($metaclass, $repr), {});
    }

    # Construct the meta-class instance.
    method BUILD(:$name = '<template>') {
        $!name := $name;
        @!attributes := [];
        %!methods := {};
        $!composed := 0;

        my %lit_args;
        my %obj_args;
        %lit_args<name> := $name;
        @!attributes.push(AttributeHow.new(|%lit_args, |%obj_args));
    }

    method name($obj) { $!name }
    method attributes($obj) { @!attributes }

    method find_method($obj, $name, :$no_fallback = 0, :$no_trace = 0) {
        return %!methods{$name};
    }

    method set_code_object($obj, $code_obj) {
        nqp::setmethcacheauth($obj, 0);
        %!methods<!str> := $code_obj;
    }

    method compose($obj) {
        self.publish_method_cache($obj);
        self.publish_boolification_spec($obj);

        self.compose_repr($obj) unless $!composed;

        # Mark as composed.
        $!composed := 1;

        $obj
    }

    # Compose the representation (attributes).
    my method compose_repr($obj) {
        # The attribute protocol data.
        my @mro := [ $obj ];
        my @attribute;

        for @mro -> $type {
            my @attrs;
            for $type.HOW.attributes($type) -> $attr {
                my %attr_info;
                %attr_info<name> := $attr.name;
                %attr_info<type> := $attr.type;
                if $attr.box_target {
                    # Merely having the key serves as a "yes".
                    %attr_info<box_target> := 0;
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
            nqp::push(@type_info, $type);
            nqp::push(@type_info, @attrs);
            nqp::push(@type_info, []); # parents
            nqp::push(@attribute, @type_info);
        }

        my %info; # The REPR compose protocol info.
        %info<attribute> := @attribute;
        nqp::composetype($obj, %info);
    }

    my method publish_method_cache($obj) {
        my %cache := %!methods;
        nqp::setmethcache($obj, %cache);
        nqp::setmethcacheauth($obj, 1);
    }

    my method publish_boolification_spec($obj) {
        nqp::setboolspec($obj, 5, nqp::null())
    }
}
