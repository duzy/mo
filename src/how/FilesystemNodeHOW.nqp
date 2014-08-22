knowhow MO::FilesystemNodeHOW {
    my $type;

    method type() {
        unless $type {
            my $metaclass := nqp::create(self);
            $type := nqp::newtype($metaclass, 'HashAttrStore'); #P6opaque

            if 0 { #######################################################
            my @repr_info;
            my @type_info;
            nqp::push(@repr_info, @type_info);
            nqp::push(@type_info, $type);

            my @attrs;
            nqp::push(@type_info, @attrs);

            my @parents;
            nqp::push(@type_info, @parents);

            #nqp::push(@parents, MO::NodeClassHOW.type);

            my $protocol := nqp::hash();
            $protocol<attribute> := @repr_info;
            nqp::composetype($type, $protocol);
            } ############################################################
        }
        $type;
    }
}
