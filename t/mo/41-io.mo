say('1..2')
with readdir('t/mo/test')->{ .NAME eq 'text.txt' }
{
    if .EXISTS
        say("ok\t\t- found "~..);
        var $h = open(.PATH, 'r');
        var $s = $h.readline();
        if $s eq "text\n"
            say("ok\t\t- text");
        else
            say("xx\t\t- wrong line: "~$s);
        end
        $h.close()
    else
        say("xx\t\t- missing text.txt");
    end
}
