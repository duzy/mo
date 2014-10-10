var $path = (+@ARGS < 2) ? cwd : @ARGS[1];

use config 'release' :api(19), :path($path);
use config 'debug' :api(19), :path($path);

init {
  say("main.mo: init");
}

say('main.mo: isnull($config::SDK): '~isnull($config::SDK))

var $sdk = $config::SDK;
var $variant = $config::Variant;
var $api_level = $config::APILevel;

var $platform = $config::Platform;
var $platform_jar = $config::Platform_jar;
var $platform_aidl = $config::Platform_aidl;
var $platform_properties = $config::PlatformProperties;

var $cmd_zipalign = config::Tool("zipalign");
var $cmd_aapt = config::BuildTool('aapt');
var $cmd_jarsigner = "jarsigner";

var $sign_storepass;
var $sign_storepass_opt = '';
var $sign_keystore;
var $sign_keystore_opt = '';
var $sign_keypass;
var $sign_keypass_opt = '';
var $sign_cert = 'cert';

if isreg("$path/.android/storepass") { $sign_storepass = "$path/.android/storepass" }
if isreg("$path/.android/keystore") { $sign_keystore = "$path/.android/keystore" }
if isreg("$path/.android/keypass") { $sign_keypass = "$path/.android/keypass" }

unless isnull($sign_storepass) { $sign_storepass_opt = "-storepass " ~ slurp($sign_storepass) }
unless isnull($sign_keystore)  { $sign_keystore_opt = "-keystore " ~ slurp($sign_keystore) }
unless isnull($sign_keypass)   { $sign_keypass_opt = "-keypass " ~ slurp($sign_keypass) }

"$path/bin/a-$variant.apk": "$path/bin/$variant/_.signed" 
{
    var $apk = $_.PATH;
    var $dir = $_.parent_path();
    var $signed = @_[0].PATH;
    lang shell :escape
----------------------
    mkdir -p $dir
    $cmd_zipalign -f 4 $signed $apk
-------------------end
}

"$path/bin/$variant/_.signed": "$path/bin/$variant/_.pack"
{
    var $storepass = $sign_storepass_opt;
    var $keystore = $sign_keystore_opt;
    var $keypass = $sign_keypass_opt;
    var $signed = $_.path();
    var $cert = $sign_cert;
    lang shell :escape
----------------------
    $cmd_jarsigner -sigalg MD5withRSA -digestalg SHA1 \
        $keystore $keypass $storepass $signed $cert
-------------------end
}

"$path/bin/$variant/_.pack": "$path/AndroidManifest.xml"
{
    var $dir = $_.parent_path();
    var $pack = $_.path();
    var $am = @_[0].path();
    var $libs = "-I $platform_jar";
    var $reses = "-S '$path/res'";
    var $assets = "-A '$path/assets'";
    var $debug = $variant eq 'debug' ? '--debug-mode' : '';
    unless isdir($assets) { $assets = '' }
    lang shell :escape
------------------------
    echo "Packing resources.."
    mkdir -p $dir
    $cmd_aapt package -f -F $pack -M $am $libs $reses $assets \
        $debug --auto-add-overlay
---------------------end
}

<"$path/bin/a-$variant.apk">.make();
