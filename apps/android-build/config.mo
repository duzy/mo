var $Variant = 0 < +@ARGS ? @ARGS[1] : 'debug';
var $APILevel

var $LocalProperties
var $ProjectProperties

var $SDK

var $Platform = "android-$APILevel"
var $PlatformProperties
var $Platform_jar
var $Platform_aidl

var $Path

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

def Tool($name) {
    var $sdk = $SDK;
    any isreg "$sdk/tools/$name"
}

def BuildTool($name) {
    var $sdk = $SDK;
    var $version = $PlatformProperties{'Platform.Version'};
    any isreg
    "$sdk/build-tools/android-$version/$name",
    "$sdk/build-tools/android-4.4W/$name",
    "$sdk/build-tools/android-4.4.2/$name",
    "$sdk/build-tools/19.1.0/$name",
    "$sdk/build-tools/19.0.3/$name",
    "$sdk/build-tools/19.0.2/$name",
    "$sdk/build-tools/19.0.1/$name",
    "$sdk/build-tools/19.0.0/$name",
    "$sdk/build-tools/18.1.1/$name",
    "$sdk/build-tools/18.1.0/$name",
    "$sdk/build-tools/18.0.1/$name",
    "$sdk/build-tools/17.0.0/$name"
}

load {
    $APILevel = $_{'api'};
    $Path = $_{'path'};

    $LocalProperties = LoadProperties("$Path/local.properties")
    $ProjectProperties = LoadProperties("$Path/project.properties")

    $SDK = any isdir $LocalProperties{'sdk.dir'},
        '/home/zhan/tools/android-studio/sdk',
        '/open/android/android-studio/sdk';

    $Platform = "android-$APILevel"
    $PlatformProperties = LoadProperties("$SDK/platforms/$Platform/source.properties")
    $Platform_jar = "$SDK/platforms/$Platform/android.jar"
    $Platform_aidl = "$SDK/platforms/$Platform/framework.aidl"

    say("config.mo: init: Platform = $Platform");
    say("config.mo: init: SDK = $SDK");
}

say("config.mo: Platform = $Platform")
