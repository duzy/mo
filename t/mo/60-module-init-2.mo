var $n;
var $s;

if isnull($n) {
    say("xx - 5. isnull(\$n) in main");
} else {
    say("ok - 5. isnull(\$n) in main");
    $n = $n + 1;
}

init {
    say('1..7');
    say("ok - 1. init");

    if isnull($n) {
        say("ok - 2. isnull(\$n) in init");
    } else {
        say("xx - 2. isnull(\$n) in init");
    }

    if isnull($s) {
        say("ok - 3. isnull(\$s) in init");
    } else {
        say("xx - 3. isnull(\$s) in init");
    }

    $n = 1;
    $s = 'test-string';

    if $n == 1 {
        say("ok - 4. \$n == $n");
    } else {
        say("xx - 4. \$n == 1 but $n");
    }
}

if isnull($s) {
    say("xx - 6. isnull(\$s)");
} elsif $s eq 'test-string' {
    say("ok - 6. \$s = $s");
}

if $n == 2 {
    say("ok - 7. \$n == $n");
} else {
    say("xx - 7. \$n == 2");
}
