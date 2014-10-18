var $sysdir = dirname(@ARGS[0]);

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

def Tool($sdk, $name) {
    any isreg "$sdk/tools/$name"
}

def PlatformTool($sdk, $name) {
    any isreg "$sdk/platform-tools/$name"
}

def BuildTool($sdk, $version, $name) {
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

def load_manifest($path) {
    lang XML in "$path/AndroidManifest.xml"
}

def check_notnull($v, $err) {
    if isnull($v) { die($err) }
}

class config
{
    $.platform;
    $.platform_jar;
    $.platform_aidl;
    $.platform_properties;

    $.cmds = hash();

    $.sign_cert = 'cert';
    $.sign_storepass_filename;
    $.sign_keypass_filename;
    $.sign_keystore_filename;
    $.sign_storepass;
    $.sign_keypass;

    $.project_name;
    $.project_manifest;

    $.is_library = 0;

    $.libs = list();

    method parse($path) {
        var $name = $.project_name = basename($path);
        var $manifest = $.project_manifest = load_manifest($path);
        if isnull($name) { $name = split('.', $manifest.package).pop() }

        var $localProperties   = LoadProperties("$path/local.properties");
        var $projectProperties = LoadProperties("$path/project.properties");
        check_notnull($localProperties,   "local.properties is not underneath $path");
        check_notnull($projectProperties, "project.properties is not underneath $path");

        var $sdk = any isdir $localProperties{'sdk.dir'}, "/open/android/android-studio/sdk";
        check_notnull($sdk,  'SDK missing');

        var $platform = $.platform = $projectProperties{'target'};
        check_notnull($platform,  'Platform target missing');

        var $library = $projectProperties{'android.library'}; # android.library=true
        $.is_library = isnull($library) ? 0 : $library eq 'true';

say(+$.libs)
say('android.library.reference.1: '~isnull($projectProperties{'android.library.reference.1'}))
say('android.library.reference.2: '~isnull($projectProperties{'android.library.reference.2'}))

        var $lib;
        while !isnull($lib = $projectProperties{'android.library.reference.'~(1+$.libs)}) {
say($lib);
            $.libs.push($lib);
        }

        say($path~' '~join(' ', $.libs));

        $.platform_jar  = any isreg "$sdk/platforms/$platform/android.jar";
        $.platform_aidl = any isreg "$sdk/platforms/$platform/framework.aidl";
        check_notnull($.platform_jar,  '$sdk/platforms/$platform/android.jar missing');
        check_notnull($.platform_aidl, '$sdk/platforms/$platform/framework.aidl missing');

        $.platform_properties = LoadProperties("$sdk/platforms/$platform/source.properties");
        check_notnull($.platform_properties,  '$sdk/platforms/$platform/source.properties missing');

        var $platformVersion = $.platform_properties{'Platform.Version'};
        check_notnull($platformVersion,  'Platform.Version missing');

        $.cmds<android>           = Tool($sdk, 'android');
        $.cmds<draw9patch>        = Tool($sdk, 'draw9patch');
        $.cmds<lint>              = Tool($sdk, 'lint');
        $.cmds<jobb>              = Tool($sdk, 'jobb');
        $.cmds<traceview>         = Tool($sdk, 'traceview');
        $.cmds<screenshot2>       = Tool($sdk, 'screenshot2');
        $.cmds<monkeyrunner>      = Tool($sdk, 'monkeyrunner');
        $.cmds<hierarchyviewer>   = Tool($sdk, 'hierarchyviewer');
        $.cmds<uiautomatorviewer> = Tool($sdk, 'uiautomatorviewer');
        $.cmds<adb>               = PlatformTool($sdk, 'adb');
        $.cmds<dmtracedump>       = PlatformTool($sdk, 'dmtracedump');
        $.cmds<etc1tool>          = PlatformTool($sdk, 'etc1tool');
        $.cmds<fastboot>          = PlatformTool($sdk, 'fastboot');
        $.cmds<hprof_conv>        = PlatformTool($sdk, 'hprof-conv');
        $.cmds<sqlite3>           = PlatformTool($sdk, 'sqlite3');
        $.cmds<aapt>              = BuildTool($sdk, $platformVersion, 'aapt');
        $.cmds<aidl>              = BuildTool($sdk, $platformVersion, 'aidl');
        $.cmds<dx>                = BuildTool($sdk, $platformVersion, 'dx');
        $.cmds<rscc>              = BuildTool($sdk, $platformVersion, 'llvm-rs-cc');
        $.cmds<zipalign>          = BuildTool($sdk, $platformVersion, "zipalign");
        $.cmds<jarsigner>         = "jarsigner";
        $.cmds<javac>             = "javac";

        if isnull($.cmds<sqlite3>)  { $.cmds<sqlite3>  = Tool($sdk, "sqlite3") }
        if isnull($.cmds<zipalign>) { $.cmds<zipalign> = Tool($sdk, "zipalign") }

        check_notnull($.cmds<android>,         '$sdk/tools/android missing');
        check_notnull($.cmds<lint>,            '$sdk/tools/lint missing');
        check_notnull($.cmds<adb>,             '$sdk/platform-tools/adb missing');
        check_notnull($.cmds<sqlite3>,         '$sdk/platform-tools/sqlite3 missing');
        check_notnull($.cmds<aapt>,            '$sdk/build-tools/.../aapt missing');
        check_notnull($.cmds<aidl>,            '$sdk/build-tools/.../aidl missing');
        check_notnull($.cmds<dx>,              '$sdk/build-tools/.../dx missing');
        check_notnull($.cmds<rscc>,            '$sdk/build-tools/.../llvm-rs-cc missing');
        check_notnull($.cmds<zipalign>,        '$sdk/build-tools/.../zipalign missing');
        check_notnull($.cmds<jarsigner>,       'jarsigner missing');

        $.sign_storepass_filename = any isreg "$path/.android/storepass", "$sysdir/key/storepass";
        $.sign_keypass_filename   = any isreg "$path/.android/keypass",   "$sysdir/key/keypass";
        $.sign_keystore_filename  = any isreg "$path/.android/keystore",  "$sysdir/key/keystore";
        $.sign_storepass = isnull($.sign_storepass_filename) ? null : strip(slurp($.sign_storepass_filename));
        $.sign_keypass   = isnull($.sign_keypass_filename)   ? null : strip(slurp($.sign_keypass_filename));
    }

    method platform_jar()  { $.platform_jar }
    method platform_aidl() { $.platform_aidl }

    method cmd($name) { $.cmds{$name} }

    method project_name() { $.project_name }
    method project_manifest() { $.project_manifest }

    method sign_cert()               { $.sign_cert }
    method sign_storepass_filename() { $.sign_storepass_filename }
    method sign_keypass_filename()   { $.sign_keypass_filename }
    method sign_keystore_filename()  { $.sign_keystore_filename }
    method sign_storepass()          { $.sign_storepass }
    method sign_keypass()            { $.sign_keypass }

    method is_library() { $.is_library }
}

def ParseProject($path) {
    unless isreg("$path/AndroidManifest.xml") {
        die("AndroidManifest.xml is not underneath $path");
    }

    var $config = new(config);
    $config.parse($path);
    $config
}
