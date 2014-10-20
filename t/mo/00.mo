#say("foo: "~!!<"foo">);
#if <"foo"> {}

def add_project_prerequisites($a) {
    if islist($a[0]) {
        say('add_project_prerequisites: '~+$a~', '~+($a[0]));
        add_project_prerequisites($a[0]);
    }
}

var $l = list(1, 2, 3);
$l.unshift(list(1, 2, 3));
$l[0].unshift(list(1, 2, 3));
$l[0][0].unshift(list(1, 2, 3));
$l[0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0][0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0][0][0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0][0][0][0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0][0][0][0][0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0][0][0][0][0][0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0][0][0][0][0][0][0][0][0][0].unshift(list(1, 2, 3));
$l[0][0][0][0][0][0][0][0][0][0][0][0][0][0][0].unshift(list(1, 2, 3));
add_project_prerequisites($l)
