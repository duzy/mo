for ->application->activity do {
    with ->{ 1 } do { say('1. '~.android:name~', '~.android:label) }

    say('2. '~.android:name~', '~.android:label~', '~.android:theme);

    # ->:android
    # say('3. '~.name~', '~.label~', '~.theme);
    say('3. '~.android:name~', '~.android:label~', '~.android:theme);
}
