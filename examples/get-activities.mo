for ->application->activity do {
    say('android:name: '~.android:name~', '~.android:label);
    with ->'intent-filter' do {
        say('action: '~->action.android:name);
    }
    with ->['intent-filter'] do {
        say('action: '~->action.android:name);
    }
    with ->{ 1 } do {
        say('activity: '~.android:name);
    }
    for ->*['action'] do {
        say('action: '~.android:name);
    }
}
