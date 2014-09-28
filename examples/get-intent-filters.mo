for ->application->activity do {
    ->:android
    with ->'intent-filter' do { say('1. '~->action.name) }
    with ->['intent-filter'] do { say('2. '~->action.name) }
    for ->*['action'] do { say('3. '~.name) }
}
