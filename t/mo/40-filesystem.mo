say("1..18")

with readdir('t/mo')->{ .NAME eq 'test' }
{
    if .EXISTS
        say("ok\t\t- test exists");
    else
        say("xx\t\t- test not exists: " ~ .EXISTS);
    end

    if .NAME eq 'test'
        say("ok\t\t- .NAME eq 'test'");
    else
        say("xx\t\t- .NAME eq 'test' : " ~ .NAME);
    end

    if $_.name() eq 't/mo/test'
        say("ok\t\t- \$_.name() eq 't/mo/test'");
    else
        say("xx\t\t- \$_.name() eq 't/mo/test' : "~$_.name());
    end
}

with readdir("t/mo")->{ .NAME eq 'test' }
{
    if .EXISTS
        say("ok\t\t- test exists");
    else
        say("xx\t\t- test not exists: " ~ .EXISTS);
    end

    if .NAME eq 'test'
        say("ok\t\t- .NAME eq 'test'");
    else
        say("xx\t\t- .NAME eq 'test' : " ~ .NAME);
    end

    if $_.name() eq 't/mo/test'
        say("ok\t\t- \$_.name() eq 't/mo/test'");
    else
        say("xx\t\t- \$_.name() eq 't/mo/test' : "~$_.name());
    end
}

for readdir("t/mo/test/many")->{ .NAME eq '1.txt' || .NAME eq "2.txt" }
{
    if $_.name() eq 't/mo/test/many/1.txt'
        say("ok\t\t- \$_.name() eq 't/mo/test/many/1.txt'");
    elsif $_.name() eq 't/mo/test/many/2.txt'
        say("ok\t\t- \$_.name() eq 't/mo/test/many/2.txt'");
    else
        say("xx\t\t- \$_.name() : "~$_.name());
    end

    if .NAME eq '1.txt'
        say("ok\t\t- .NAME eq 1.txt");
    elsif .NAME eq '2.txt'
        say("ok\t\t- .NAME eq 2.txt");
    else
        say("xx\t\t- unexpected: " ~ .NAME);
    end
}

var $a = readdir("t/mo/test/many")->{ .NAME eq '1.txt' || .NAME eq "2.txt" }->{
    if $_.name() eq 't/mo/test/many/1.txt'
        say("ok\t\t- \$_.name() eq 't/mo/test/many/1.txt'");
    elsif $_.name() eq 't/mo/test/many/2.txt'
        say("ok\t\t- \$_.name() eq 't/mo/test/many/2.txt'");
    else
        say("xx\t\t- \$_.name() : "~$_.name());
    end

    if .NAME eq '1.txt'
        say("ok\t\t- .NAME eq 1.txt");
    elsif .NAME eq '2.txt'
        say("ok\t\t- .NAME eq 2.txt");
    else
        say("xx\t\t- unexpected .NAME: " ~ .NAME);
    end

    1
}

if +$a == 2
    say("ok\t\t- +\$a == 2");
else
    say("xx\t\t- +\$a == 2");
end

$a = readdir("t/mo/test/many")->{ .NAME eq '1.txt' || .NAME eq "2.txt" }->{
    if .NAME eq '1.txt'
        say("ok\t\t- .NAME eq 1.txt");
    elsif .NAME eq '2.txt'
        say("ok\t\t- .NAME eq 2.txt");
    else
        say("xx\t\t- unexpected .NAME: " ~ .NAME);
    end

    1
}

if +$a == 2
    say("ok\t\t- +\$a == 2");
else
    say("xx\t\t- +\$a == 2");
end
