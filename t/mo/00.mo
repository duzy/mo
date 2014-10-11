use test::ModuleInit 'abc', 123;

if isnull($ModuleInit::Test1) {
    say('xx - 7. $ModuleInit::Test1 is null');
} elsif $ModuleInit::Test1 == 100 {
    say('ok - 7. $ModuleInit::Test1 = 100');
} else {
    say('xx - 7. $ModuleInit::Test1 = '~$ModuleInit::Test1);
}

if isnull($ModuleInit::Test2) {
    say('xx - 8. $ModuleInit::Test2 is null');
} elsif $ModuleInit::Test2 eq 'test2' {
    say('ok - 8. $ModuleInit::Test2 = test2');
} else {
    say('xx - 8. $ModuleInit::Test2 = '~$ModuleInit::Test2);
}

init {
    say('ok - 6. main.init called');
}
