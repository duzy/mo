for ->message do {
    say(.name);
    for ->field do {
        say("    "~.name~', '~.type~(isnull(.size) ? '' : ', '~.size));
    }
}
