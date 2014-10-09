say('1..7');

var $ns = ->:test?
if $ns eq 'http://www.example.com/xml'
    say("ok\t xmlns:test="~$ns);
else
    say("xx\t xmlns:test="~$ns);
end

$ns = ->:?
if isnull($ns)
    say("ok\t no default namespace");
else
    say("xx\t no default namespace");
end

$ns = ->:??
if isnull($ns)
    say("ok\t no selected namespace by default");
else
    say("xx\t no selected namespace by default");
end

var $name1 = ->:test->.name;
$ns = ->:??
if $ns eq 'test'
    say("ok\t namespace is test");
else
    say("xx\t namespace is test");
end
if $name1 eq 'test-namespace'
    say("ok\t test:name = test-namespace");
else
    say("xx\t test:name = test-namespace");
end

var $name2 = ->:->.name;
$ns = ->:??
if $ns eq ''
    say("ok\t namespace is empty");
else
    say("xx\t namespace is test");
end
if $name2 eq 'test-name-value'
    say("ok\t name = test-name-value");
else
    say("xx\t name = test-name-value");
end
