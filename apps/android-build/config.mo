var $sysdir = dirname(@ARGS[0]);
var $Variant = 1 < +@ARGS ? @ARGS[1] : 'debug';
var $APILevel

var $LocalProperties
var $ProjectProperties

var $SDK
var $Path
var $Name
var $Manifest

var $Platform
var $PlatformProperties
var $Platform_jar
var $Platform_aidl

var $Cmd_android
var $Cmd_draw9patch
var $Cmd_lint
var $Cmd_jobb
var $Cmd_traceview
var $Cmd_screenshot2
var $Cmd_monkeyrunner
var $Cmd_hierarchyviewer
var $Cmd_uiautomatorviewer
var $Cmd_adb;
var $Cmd_dmtracedump
var $Cmd_etc1tool
var $Cmd_fastboot
var $Cmd_hprof_conv
var $Cmd_sqlite3
var $Cmd_aapt
var $Cmd_aidl
var $Cmd_dx
var $Cmd_rscc
var $Cmd_zipalign
var $Cmd_jarsigner
var $Cmd_javac

var $Sign_storepass_filename;
var $Sign_storepass;
var $Sign_keypass_filename;
var $Sign_keypass;
var $Sign_keystore;
var $Sign_cert = 'cert';

def LoadProperties($filename) {
    var $hash = hash();
    var $source = slurp($filename);
    for split("\n", $source) {
        var $i = index($_, '=');
        if 0 < $i {
            $hash{strip(substr($_, 0, $i))} = substr($_, $i+1);
        }
    }
    $hash
}

def Tool($name) {
    var $sdk = $SDK;
    any isreg "$sdk/tools/$name"
}

def PlatformTool($name) {
    var $sdk = $SDK;
    any isreg "$sdk/platform-tools/$name"
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

def check_notnull($v, $err) {
    if isnull($v) { die($err) }
}

load {
    unless isnull($SDK) { return }

    $Path = %_{'path'};

    unless isreg("$Path/AndroidManifest.xml") {
        die("AndroidManifest.xml was not found under $Path");
    }

    lang XML as $am in "$Path/AndroidManifest.xml";
    $Manifest = $am();
    $Name = basename($Path);
    if isnull($Name) {
         $Name = split('.', $Manifest.package).pop();
    }

    $LocalProperties = LoadProperties("$Path/local.properties")
    $ProjectProperties = LoadProperties("$Path/project.properties")

    check_notnull($LocalProperties,     "$Path/local.properties missing");
    check_notnull($ProjectProperties,   "$Path/project.properties missing");

    $SDK = any isdir $LocalProperties{'sdk.dir'},
        '/home/zhan/tools/android-studio/sdk',
        '/open/android/android-studio/sdk';

    check_notnull($SDK,  '$SDK missing');

    $Platform = $ProjectProperties{'target'}

    check_notnull($Platform,  '$Platform target missing');

    $PlatformProperties = LoadProperties("$SDK/platforms/$Platform/source.properties")
    $Platform_jar  = any isreg "$SDK/platforms/$Platform/android.jar"
    $Platform_aidl = any isreg "$SDK/platforms/$Platform/framework.aidl"

    check_notnull($PlatformProperties,  '$SDK/platforms/$Platform/source.properties missing');
    check_notnull($Platform_jar,        '$SDK/platforms/$Platform/android.jar missing');
    check_notnull($Platform_aidl,       '$SDK/platforms/$Platform/framework.aidl missing');

    $Cmd_android           = Tool('android')
    $Cmd_draw9patch        = Tool('draw9patch')
    $Cmd_lint              = Tool('lint')
    $Cmd_jobb              = Tool('jobb')
    $Cmd_traceview         = Tool('traceview')
    $Cmd_screenshot2       = Tool('screenshot2')
    $Cmd_monkeyrunner      = Tool('monkeyrunner')
    $Cmd_hierarchyviewer   = Tool('hierarchyviewer')
    $Cmd_uiautomatorviewer = Tool('uiautomatorviewer')
    $Cmd_adb               = PlatformTool('adb')
    $Cmd_dmtracedump       = PlatformTool('dmtracedump')
    $Cmd_etc1tool          = PlatformTool('etc1tool')
    $Cmd_fastboot          = PlatformTool('fastboot')
    $Cmd_hprof_conv        = PlatformTool('hprof-conv')
    $Cmd_sqlite3           = PlatformTool('sqlite3')
    $Cmd_aapt              = BuildTool('aapt')
    $Cmd_aidl              = BuildTool('aidl')
    $Cmd_dx                = BuildTool('dx')
    $Cmd_rscc              = BuildTool('llvm-rs-cc')
    $Cmd_zipalign          = BuildTool("zipalign")
    $Cmd_jarsigner         = "jarsigner"
    $Cmd_javac             = "javac"

    if isnull($Cmd_sqlite3)  { $Cmd_sqlite3 = Tool("sqlite3") }
    if isnull($Cmd_zipalign) { $Cmd_zipalign = Tool("zipalign") }

    check_notnull($Cmd_android,         '$SDK/tools/android missing');
    check_notnull($Cmd_lint,            '$SDK/tools/lint missing');
    check_notnull($Cmd_adb,             '$SDK/platform-tools/adb missing');
    check_notnull($Cmd_sqlite3,         '$SDK/platform-tools/sqlite3 missing');
    check_notnull($Cmd_aapt,            '$SDK/build-tools/.../aapt missing');
    check_notnull($Cmd_aidl,            '$SDK/build-tools/.../aidl missing');
    check_notnull($Cmd_dx,              '$SDK/build-tools/.../dx missing');
    check_notnull($Cmd_rscc,            '$SDK/build-tools/.../llvm-rs-cc missing');
    check_notnull($Cmd_zipalign,        '$SDK/build-tools/.../zipalign missing');
    check_notnull($Cmd_jarsigner,       'jarsigner missing');

    $Sign_cert = 'cert';
    $Sign_storepass_filename = any isreg "$Path/.android/storepass", "$sysdir/key/storepass"
    $Sign_keypass_filename = any isreg "$Path/.android/keypass", "$sysdir/key/keypass"
    $Sign_keystore = any isreg "$Path/.android/keystore", "$sysdir/key/keystore"

    unless isnull($Sign_storepass_filename) { $Sign_storepass = strip(slurp($Sign_storepass_filename)) }
    unless isnull($Sign_keypass_filename)   { $Sign_keypass = strip(slurp($Sign_keypass_filename)) }
    
    say("config.mo: Platform = $Platform");
    say("config.mo: SDK = $SDK");
}

say("config.mo: Variant = $Variant")
