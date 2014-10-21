"foo" : "bar"
{
}

<"foo">.make();

class foobar
{
    $.target = 'foobar';
    @.depends = list();

    {
        @.depends.push('foo');
        @.depends.push('bar');
        say('foobar');
    }

    $.target : @.depends
    {
        say('build: '~$_.name());
    }

    'foo' :
    {
        say('build: '~+@.depends)
    }

    'bar' :
    {
        say('build: '~+@.depends)
    }
}

var $t = new(foobar);
<'foobar'>.make();
