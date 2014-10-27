knowhow MO::Builtin {
    sub glob(*@patterns) {
        my @result;
        # TODO: glob...
        @result
    }

    sub readdir(*@dirs) {
        my @result;
        # TODO: ...
        @result
    }

    method init() {
        MO::World.add_builtin_code('glob', &glob);
        MO::World.add_builtin_code('readdir', &readdir);
    }
}
