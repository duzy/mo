def LoadProperties($filename) {
    var $hash = hash();
    var $source = slurp($filename);
    for split("\n", $source) {
        var $i = index($_, '=');
        if 0 < $i {
            $hash{substr($_, 0, $i)} = substr($_, $i+1);
        }
    }
    $hash
}

var $Variant = 0 ? 'release' : 'debug';
var $APILevel = 0 < +@ARGS ? @ARGS[0] : 19;

var $LocalProperties
var $ProjectProperties

var $SDK

var $Platform = "android-$APILevel";
var $PlatformProperties
var $Platform_jar
var $Platform_aidl

var $Path

init {
    $Path = +@_ < 1 ? cwd : @_[0];
    $LocalProperties = LoadProperties("$Path/local.properties")
    $ProjectProperties = LoadProperties("$Path/project.properties")

    $SDK = any isdir $LocalProperties{'sdk.dir'},
        '/home/zhan/tools/android-studio/sdk',
        '/open/android/android-studio/sdk';

    $PlatformProperties = LoadProperties("$SDK/platforms/$Platform/source.properties")
    $Platform_jar = "$SDK/platforms/$Platform/android.jar"
    $Platform_aidl = "$SDK/platforms/$Platform/framework.aidl"

say($SDK)
}
