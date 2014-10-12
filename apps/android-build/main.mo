var $path = (+@ARGS < 2) ? cwd : @ARGS[1];

use config 'debug' :api(19), :path($path);

var $variant = $config::Variant;

"$path/bin/a-$variant.apk": "$path/bin/$variant/_.signed"
{
    var $apk = $_.path();
    var $dir = $_.parent_path();
    var $signed = @_[0].path();
    var $cmd = $config::Cmd_zipalign;
    lang shell :escape
------------------------
    mkdir -p $dir || exit -1
    $cmd -f 4 $signed $apk
---------------------end
}

"$path/bin/$variant/_.signed": "$path/bin/$variant/_.pack"
{
    var $storepass = isnull($config::Sign_storepass) ? '' : "-storepass '$config::Sign_storepass'";
    var $keypass = isnull($config::Sign_keypass) ? '' : "-keypass '$config::Sign_keypass'";
    var $keystore = isnull($config::Sign_keystore) ? '' : "-keystore '$config::Sign_keystore'";
    var $cmd = $config::Cmd_jarsigner;
    var $cert = $config::Sign_cert;
    var $signed = $_.path();
    var $pack = @_[0].path();
    lang shell :escape
------------------------
    echo "Signing package.."
    cp -f $pack $signed || exit -1
    $cmd -sigalg MD5withRSA -digestalg SHA1 $keystore $keypass $storepass \
        $signed $cert
---------------------end
}

"$path/bin/$variant/_.pack": "$path/AndroidManifest.xml"
{
    var $dir = $_.parent_path();
    var $pack = $_.path();
    var $am = @_[0].path();
    var $libs = "-I $config::Platform_jar";
    var $reses = "-S '$path/res'";
    var $assets = "-A '$path/assets'";
    var $debug = $variant eq 'debug' ? '--debug-mode' : '';
    var $cmd = $config::Cmd_aapt;
    unless isdir($assets) { $assets = '' }
    lang shell :escape
------------------------
    echo "Packing resources.."
    mkdir -p $dir || exit -1
    $cmd package -f -F $pack -M $am $libs $reses $assets \
        $debug --auto-add-overlay
---------------------end
}

<"$path/bin/a-$variant.apk">.make();
