def load_protocol($protocol) {
    lang XML in $protocol
}

var $protocol = load_protocol('apps/protocol/test_proto.xml'); # @ARGS[0]
with $protocol {
     say(.name);
}
