knowhow MO::ModuleLoader {
    method load_module($name) {
    }

    method load_setting($name) {
        nqp::say('MO::ModuleLoader.load_setting: '~$name);
    }
}

## We're using the same approach as NQP does.
#nqp::bindcurhllsym('ModuleLoader', ModuleLoader);
nqp::bindhllsym('mo', 'ModuleLoader', MO::ModuleLoader);
