def test($v) {
    var $var = "var~$v"
    return def($a) {
        "test~$var~$a"
    }
}

var $f1 = test(1)
var $f2 = test(2)

say($f1(123))
say($f2(234))

say($f1(1234))
say($f2(2345))
