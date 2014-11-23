use codec

for include {
    say("$(.filename)")
}

#def protocol($protocol) { lang XML in $protocol }
#var $protocol = protocol('apps/protocol/test_proto.xml')
#var $code = str codec::Class with $protocol

var $lang = .lang;

if $lang eq 'c' {
    var $h = str codec::C_h;
    var $code = str codec::C;
    say($h);
    say("----------");
    say($code);
} elsif $lang eq 'c++' {
    var $h = str codec::Cpp_h;
    var $code = str codec::Cpp;
    say($h);
    say("----------");
    say($code);
} elsif $lang eq 'go' {
    say('TODO: ...');
} elsif $lang eq 'java' {
    say('TODO: ...');
}
