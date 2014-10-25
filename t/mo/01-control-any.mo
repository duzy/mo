say('1..5');

any isreg "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
{
  if $_ eq 't/mo/test.xml'
    say("ok - 1. $_");
  else
    say("xx - 1. $_");
  end
}

var $s = any isreg "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
if $s eq 't/mo/test.xml'
    say("ok - 2. $s");
else
    say("xx - 2. $s");
end

any { isreg($_) } "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
{
  if $_ eq 't/mo/test.xml'
    say("ok - 3. $_");
  else
    say("xx - 3. $_");
  end
}

var $s = any { isreg($_) } "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
if $s eq 't/mo/test.xml'
    say("ok - 4. $s");
else
    say("xx - 4. $s");
end

#var @a = list("test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo");
var @a = ("test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo");
var $s2 = any { isreg($_) } @a
if isnull($s2)
    say("xx - 5. \$s2 is null");
elsif $s eq $s2
    say("ok - 5. $s eq $s2");
else
    say("xx - 5. $s eq $s2");
end
