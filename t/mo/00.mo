"foo" : "bar"
{
}

<"foo">.make();

class rules
{
    $.target = 'foobar'
    @.depends = list()

    {
        @.depends.push('foo');
        @.depends.push('bar');
    }

    $.target : @.depends
    {
        
    }
}
