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
        say('foobar.~ctor');
    }

    method normal($v) {
        say("normal: $v");
    }

    method make: $.target : @.depends
    {
        say('build: me:'~isnull(me)~', '~$_.name());
    }

    'foo' :
    {
        say('build: '~$_.name()~', '~+@.depends);
        me.normal(1);
    }

    'bar' :
    {
        say('build: '~$_.name()~', '~+@.depends);
        me.normal(2);
    }
}

var $t = new(foobar);
$t.make();
