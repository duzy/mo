say('1..5');

if isnull(many isreg "test.xml")
    say('xx - 1. isnull(many isreg test.xml)')
else
    say('ok - 1. !isnull(many isreg test.xml)')
    if 0 == +many isreg "test.xml"
        say('ok - 2. 0 == +many isreg test.xml')
    else
        say('xx - 2. 0 != +many isreg test.xml : '~+many isreg "test.xml")
    end
end

if isnull(many isreg "t/mo/test.xml")
    say("xx - 3. isnull(many isreg t/mo/test.xml)")
else
    say("ok - 3. !isnull(many isreg t/mo/test.xml)")
    if 1 == +many isreg "t/mo/test.xml"
        say("ok - 4. 1 == +many isreg t/mo/test.xml")
        if (many isreg "t/mo/test.xml")[0] eq 't/mo/test.xml'
            say("ok - 5. many isreg t/mo/test.xml")
        else
            say("xx - 5. many isreg t/mo/test.xml")
        end
    else
        say("xx - 4. 1 != +many isreg t/mo/test.xml")
    end
end
