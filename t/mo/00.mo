def load_xml($file) {
    lang XML in "$file"
}

class c
{
    $.names = hash();
    method init($xml)
    {
        $.names<a> = 'init';
        say($.names<a>);

        var $x = load_xml($xml);
        say($x.name());

        var $y = load_xml($xml);
        say($y.name());
    }
}

new(c).init('t/mo/test.xml');
