def test($num) {
    var $n = $num;
    say("pre: $num, $n");
    if $num < 3 {
        test($num + 1);
    }
    say("post: $num, $n");
}

test(0);
