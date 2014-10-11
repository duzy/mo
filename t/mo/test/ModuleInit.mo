var $Test1 = 100;
var $Test2;

if isnull($Test1) {
    say('xx - 4. init: $Test1 is null');
} elsif $Test1 == 100 {
    say('ok - 4. init: $Test1 = 100');
} else {
    say('xx - 4. init: $Test1 = '~$Test1);
}

if isnull($Test2) {
    say('xx - 5. init: $Test2 is null');
} elsif $Test2 eq 'test2' {
    say('ok - 5. init: $Test2 = test2');
} else {
    say('xx - 5. init: $Test2 = '~$Test2);
}

init {
    say('1..8');
    say('ok - 1. init called');

    if isnull($Test1) {
        say('ok - 2. init: $Test1 is null');
    } else {
        say('xx - 2. init: $Test1 is null');
    }
    if isnull($Test2) {
        say('ok - 3. init: $Test2 is null');
    } else {
        say('xx - 3. init: $Test2 is null');
    }

    $Test1 = 'test1'
    $Test2 = 'test2'
}
