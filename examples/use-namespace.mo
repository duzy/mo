->:android
say('version: '~.versionCode~', '~.versionName);

->:
say('package: '~.package);


say('version: '~->:android.versionName);
say('version: '~->:android->.versionName);
say('package: '~->:.package);
say('package: '~->:->.package);
