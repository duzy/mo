say('1..4');

any isreg "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
{
  if $_ eq 't/mo/test.xml'
    say("ok - 1. $_");
  end
}

var $s = any isreg "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
if $s eq 't/mo/test.xml'
    say("ok - 2. $s");
end

any { isreg($_) } "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
{
  if $_ eq 't/mo/test.xml'
    say("ok - 3. $_");
  end
}

var $s = any { isreg($_) } "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
if $s eq 't/mo/test.xml'
    say("ok - 4. $s");
end
