var $Variant = 0 < +@ARGS ? @ARGS[1] : 'debug';
var $APILevel

var $LocalProperties
var $ProjectProperties

var $SDK
var $Path

var $Platform
var $PlatformProperties
var $Platform_jar
var $Platform_aidl

var $Cmd_aapt
var $Cmd_zipalign
var $Cmd_jarsigner

var $Sign_storepass_filename;
var $Sign_storepass;
var $Sign_keystore_filename;
var $Sign_keystore;
var $Sign_keypass_filename;
var $Sign_keypass;
var $Sign_cert = 'cert';

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
    $APILevel = %_{'api'};
    $Path = %_{'path'};

    $LocalProperties = LoadProperties("$Path/local.properties")
    $ProjectProperties = LoadProperties("$Path/project.properties")

    $SDK = any isdir $LocalProperties{'sdk.dir'},
        '/home/zhan/tools/android-studio/sdk',
        '/open/android/android-studio/sdk';

    $Platform = "android-$APILevel"
    $PlatformProperties = LoadProperties("$SDK/platforms/$Platform/source.properties")
    $Platform_jar = "$SDK/platforms/$Platform/android.jar"
    $Platform_aidl = "$SDK/platforms/$Platform/framework.aidl"

    $Cmd_aapt = BuildTool('aapt')
    $Cmd_zipalign = Tool("zipalign")
    $Cmd_jarsigner = "jarsigner"

    $Sign_storepass_filename = any isreg "$Path/.android/storepass"
    $Sign_keystore_filename = any isreg "$Path/.android/keystore"
    $Sign_keypass_filename = any isreg "$Path/.android/keypass"

    unless isnull($Sign_storepass_filename) { $Sign_storepass = slurp($Sign_storepass_filename) }
    unless isnull($Sign_keystore_filename)  { $Sign_keystore = slurp($Sign_keystore_filename) }
    unless isnull($Sign_keypass_filename)   { $Sign_keypass = slurp($Sign_keypass_filename) }
    
    $Sign_cert = 'cert';

    say("config.mo: Platform = $Platform");
    say("config.mo: SDK = $SDK");
}

say("config.mo: Variant = $Variant")
