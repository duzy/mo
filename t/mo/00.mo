say('1..1');

any isreg "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
{
    say($_);
}

var $s = any isreg "test.xml", "t/mo/test.xml", "t/mo/test/text.txt", "t/mo"
say($s);
