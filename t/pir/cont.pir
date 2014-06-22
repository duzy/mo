.sub main :main
    .local pmc cont
    .local string str
    cont = new ['Continuation']
    set_addr cont, continued

    str = "test"
    context()

continued:
    say str
.end

.sub context
    #str = "hello"
.end
