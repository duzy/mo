say('1..8');

class test<$one, :$two, :$three>
{
    {
        if +@_ == 2 {
            say("ok - 1. +@_ == "~+@_);
            say(($one == 1 ? 'ok' : 'xx')~" - 2. \$one == "~$one);
            say((@_[0] == 2 ? 'ok' : 'xx')~" - 3. @_[0] == "~@_[0]);
            say((@_[1] == 3 ? 'ok' : 'xx')~" - 4. @_[1] == "~@_[1]);
        } else {
            say("xx - 1. +@_ == "~+@_);
        }
        if +%_ == 1 {
            say("ok - 5. +%_ == "~+%_);
            say((%_<one> == 1 ? 'ok' : 'xx')~" - 6. %_<one> == "~%_<one>);
        } else {
            say("xx - 5. +%_ == "~+%_);
        }
        say(($two == 2 ? 'ok' : 'xx')~" - 7. \$two == "~$two);
        say(($three == 3 ? 'ok' : 'xx')~" - 8. \$three == "~$three);
    }
}

var $t = new(test, 1, 2, 3, :one(1), :two(2), :three(3));
