.sub main :main
    get_global $P0, "top"
    capture_lex $P0
    $P0()

    .local string s
    find_lex s, "str1"
    say s
.end

.sub top
    .local string str1
    str1 = "test"

    .local string str2
    str2 = "hello"

    .lex 'str1', str1
    .lex 'str2', str2

    foo1()
    foo2()

    .local pmc s1
    .local pmc s2
    .local pmc s3
    get_global s1, "foo1"
    get_global s2, "foo2"
    get_global s3, "foo1_1"
    s1()
    s2()
    s3()

    .local pmc f
    get_global f, "foobar"
    capture_lex f
    f()
    s3()

    #.local string ss
    #find_lex ss, "foobar"
    #say ss
.end

.sub foo1 :outer(top)
    .local string str
    .local string str_foo1
    .lex "str_foo1", str_foo1
    find_lex str, 'str1'
    say str
    str_foo1 = "foo1"
.end

.sub foo2 :outer(top)
    .local string str
    #.local string str2
    find_lex str, 'str2'
    #find_lex str2, 'str_foo1'
    say str
    #say str2
.end

.sub foo1_1 :outer(foo1)
    .local string str
    .local string str2
    find_lex str, 'str1'
    find_lex str2, 'str_foo1'
    say str
    say str2

    #.local string ss
    #find_lex ss, "foobar"
    #say ss
.end

.sub foobar :outer(top)
    .local string str
    .lex "foobar", str
    str = "foobar"
.end
