# 45-rules.mo
say('1..40');

"foo" : "bar"
{
    say('ok - 7. build foo');
    say((($_.name() eq 'foo') ? 'ok' : 'xx')~' - 8. $_.name() is '~$_.name());
    say((($_.path() eq cwd()~'/foo') ? 'ok' : 'xx')~' - 9. $_.path() is '~$_.path());
    say(((system('test -f foo') != 0) ? 'ok' : 'xx')~' - 10. (test -f foo) != 0');
    say(((system('touch foo || exit 1') == 0) ? 'ok' : 'xx')~' - 11. (touch foo) == 0');
    say(((system('test -f foo') == 0) ? 'ok' : 'xx')~' - 12. (test -f foo) == 0');
    say(((+@_ == 1) ? 'ok' : 'xx')~' - 13. +@_ == 1 ');
    say(((@_[0].name() eq 'bar') ? 'ok' : 'xx')~' - 14. @_[0].name() is '~@_[0].name());
    say(((@_[0].path() eq cwd()~'/bar') ? 'ok' : 'xx')~' - 15. @_[0].path() is '~@_[0].path());
}

"bar" :
{
    say('ok - 1. build bar');
    say((($_.name() eq 'bar') ? 'ok' : 'xx')~' - 2. $_.name() is '~$_.name());
    say((($_.path() eq cwd()~'/bar') ? 'ok' : 'xx')~' - 3. $_.path() is '~$_.path());
    say(((system('test -f bar') != 0) ? 'ok' : 'xx')~' - 4. (test -f bar) != 0');
    say(((system('touch bar || exit 1') == 0) ? 'ok' : 'xx')~' - 5. (touch bar) == 0');
    say(((system('test -f bar') == 0) ? 'ok' : 'xx')~' - 6. (test -f bar) == 0');
}

system('rm -f foo bar');

<"foo">.make();

class foobar
{
    var $.target = 'foobar';
    var @.depends = list();

    {
        @.depends.push('foo');
        @.depends.push('bar');
    }

    method normal($v) {
        say("ok - $v. normal");
    }

    method make: $.target : @.depends
    {
        say('ok - 30. build foobar');
        say((($_.name() eq 'foobar') ? 'ok' : 'xx')~' - 31. $_.name() is '~$_.name());
        say((($_.path() eq cwd()~'/foobar') ? 'ok' : 'xx')~' - 32. $_.path() is '~$_.path());
        say(((system('test -f foobar') != 0) ? 'ok' : 'xx')~' - 33. (test -f foobar) != 0');
        say(((system('touch foobar || exit 1') == 0) ? 'ok' : 'xx')~' - 34. (touch foobar) == 0');
        say(((system('test -f foobar') == 0) ? 'ok' : 'xx')~' - 35. (test -f foobar) == 0');
        say(((+@_ == 2) ? 'ok' : 'xx')~' - 36. +@_ == 2');
        say(((@_[0].name() eq 'foo') ? 'ok' : 'xx')~' - 37. @_[0].name() is '~@_[0].name());
        say(((@_[1].name() eq 'bar') ? 'ok' : 'xx')~' - 38. @_[1].name() is '~@_[1].name());
        say(((system('test -f foo') == 0) ? 'ok' : 'xx')~' - 39. (test -f foo) == 0');
        say(((system('test -f bar') == 0) ? 'ok' : 'xx')~' - 40. (test -f bar) == 0');
    }

    'foo' :
    {
        say('ok - 16. build foo');
        say((($_.name() eq 'foo') ? 'ok' : 'xx')~' - 17. $_.name() is '~$_.name());
        say((($_.path() eq cwd()~'/foo') ? 'ok' : 'xx')~' - 18. $_.path() is '~$_.path());
        say(((system('test -f foo') != 0) ? 'ok' : 'xx')~' - 19. (test -f foo) != 0');
        say(((system('touch foo || exit 1') == 0) ? 'ok' : 'xx')~' - 20. (touch foo) == 0');
        say(((system('test -f foo') == 0) ? 'ok' : 'xx')~' - 21. (test -f foo) == 0');
        say((<'foo'>.exists() ? 'ok' : 'xx')~' - 22. <\'foo\'>.exists()');
    }

    'bar' :
    {
        say('ok - 23. build bar');
        say((($_.name() eq 'bar') ? 'ok' : 'xx')~' - 24. $_.name() is '~$_.name());
        say((($_.path() eq cwd()~'/bar') ? 'ok' : 'xx')~' - 25. $_.path() is '~$_.path());
        say(((system('test -f bar') != 0) ? 'ok' : 'xx')~' - 26. (test -f bar) != 0');
        say(((system('touch bar || exit 1') == 0) ? 'ok' : 'xx')~' - 27. (touch bar) == 0');
        say(((system('test -f bar') == 0) ? 'ok' : 'xx')~' - 28. (test -f bar) == 0');
        me.normal(29);
    }
}

var $t = new(foobar);
system('rm -f foo bar foobar');
$t.make();

system('rm -f foo bar foobar');
