say('1..3');

if isnull(any isreg "test.xml")
    say('ok - 1. isnull(any isreg test.xml)')
else
    say('xx - 1. isnull(any isreg test.xml)')
end

if isnull(any isreg "t/mo/test.xml")
    say("xx - 2. isnull(any isreg t/mo/test.xml)")
else
    say("ok - 2. isnull(any isreg t/mo/test.xml)")
    if (any isreg "t/mo/test.xml") eq 't/mo/test.xml'
        say("ok - 3. any isreg t/mo/test.xml")
    else
        say("xx - 3. any isreg t/mo/test.xml")
    end
end
