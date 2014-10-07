var $sdk = '/home/zhan/tools/android-studio/sdk';

var $path = (+@ARGS < 2) ? cwd : @ARGS[1];
var $variant = 0 ? 'release' : 'debug';
var $manifest = <"$path/AndroidManifest.xml">;

say($manifest.name()~' '~$manifest.PATH);

"$path/bin/a.apk": "$path/AndroidManifest.xml" {
lang bash
-----------
try something
--------end
}
