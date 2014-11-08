for ->application->activity {
    #->:android
    #with ->'intent-filter' { say('1. '~->action.name) }
    #with ->{ .name() eq 'intent-filter' } { say('2. '~->action.name) }
    #for ->*->'action' { say('3. '~.name) }

    with ->'intent-filter' { say('1. '~->action.android:name) }
    #with ->{ .name() eq 'intent-filter' } { say('2. '~->action.android:name) }
    with ->*->{ !isstr($_) && .name() eq 'intent-filter' } { say('2. '~->action.android:name) }
    for ->*->action { say('3. '~.android:name) }
}
