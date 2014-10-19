var $count = 0;
        
class test<$num>
{
    $.field;
    {
        var $v;
        var $s = 'test-'~$count~'-'~$num;
        $.field = $s;
        $v = $num;
        say($s~': '~$num~', '~$.field~', '~$v);
        if $count < 2 {
            $count = $count + 1;
            var $t = new(test, $num+1);
        }
        say($s~': '~$num~', '~$.field~', '~$v~'.');
    }
}

var $t = new(test, 1);
