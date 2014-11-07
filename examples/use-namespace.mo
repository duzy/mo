# ->:android
# say('1. '~.versionCode~', '~.versionName);
say('1. '~.android:versionCode~', '~.android:versionName);

# ->:
say('2. '~.package);

#say('3. '~->:android.versionName);
#say('4. '~->:android->.versionName);
#say('5. '~->:.package);
#say('6. '~->:->.package);
say('3. '~.android:versionName);
say('4. '~.android:versionName);
say('5. '~.package);
say('6. '~.package);
