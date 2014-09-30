for $_.children('uses-permission') {
    say($_.name()~': '~$_.get('android:name'));
}
