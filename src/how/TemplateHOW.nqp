knowhow MO::TemplateHOW {
    has str $!name;

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
        $!composed := 0;
        $!name := $name;
        %!methods := {};
        %!methods<!str> := -> $tt, $node {
            nqp::create($tt).'!gen'($node)
        };
        %!methods<!put> := -> $t, $v {
            my $cache := nqp::getattr($t, $t, '$.cache');
            nqp::bindattr($t, $t, '$.cache', $cache := nqp::list())
                unless nqp::defined($cache);
            nqp::push($cache, ~$v);
        };

        %!methods<generate> := -> $t, $node { $t.'!gen'($node) };
    }

    method name($obj) { $!name }

    method find_method($obj, $name, :$no_fallback = 0, :$no_trace = 0) {
        return %!methods{$name};
    }

    method set_code_object($obj, $code_obj) {
        nqp::setmethcacheauth($obj, 0);
        %!methods<!gen> := $code_obj;
    }

    method compose($obj) {
        my @typecache;
        @typecache.push($obj);
        nqp::settypecache($obj, @typecache);
        
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
        my @attribute;

        if 1 {
            my %attr_info;
            %attr_info<name> := '$.cache';
            %attr_info<type> := nqp::null();
            %attr_info<box_target> := 0;
            %attr_info<auto_viv_container> := 0;
            %attr_info<positional_delegate> := 0;
            %attr_info<associative_delegate> := 0;

            my @attrs;
            nqp::push(@attrs, %attr_info);

            my @parents;
            my @type_info;
            nqp::push(@type_info, $obj); # the type itself
            nqp::push(@type_info, @attrs);
            nqp::push(@type_info, @parents);
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
