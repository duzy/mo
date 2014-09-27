say('1..6');

var $ns = ->:test?
if $ns eq 'http://www.example.com/xml'
    say("ok\t xmlns:test="~$ns);
end

$ns = ->:?
if $ns eq ''
    say("ok\t no namespace by default");
end

var $name1 = ->:test->.name;
$ns = ->:?
if $ns eq 'test'
    say("ok\t namespace is test");
end
if $name1 eq 'test-namespace'
    say("ok\t test:name = test-namespace");
end

var $name2 = ->:->.name;
$ns = ->:?
if $ns eq ''
    say("ok\t namespace is empty");
end
if $name2 eq 'test-name-value'
    say("ok\t name = test-name-value");
end
