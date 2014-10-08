say('1..7');

many isreg "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
{
  if $_ eq 't/mo/test.xml'
    say("ok - 1. $_");
  elsif $_ eq 't/mo/test/text.txt'
    say("ok - 2. $_");
  end
}

var $s = many isreg "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
if +$s == 2
    say("ok - 3. two items mapped");
end
if $s[0] eq 't/mo/test.xml'
    say("ok - 4. "~$s[0]);
end
if $s[1] eq 't/mo/test/text.txt'
    say("ok - 5. "~$s[1]);
end

many { isreg($_) } "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
{
  if $_ eq 't/mo/test.xml'
    say("ok - 6. $_");
  elsif $_ eq 't/mo/test/text.txt'
    say("ok - 7. $_");
  end
}
