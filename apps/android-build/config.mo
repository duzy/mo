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

    method init($sdk, $projectProperties) {
        var $platform = $projectProperties{'target'};
        check_notnull($platform,  'Platform target missing');

        $.platform = $platform;
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
    }

    method platform_jar()  { $.platform_jar }
    method platform_aidl() { $.platform_aidl }
    method cmd($name) { $.cmds{$name} }
}

def ParseProject($sdk, $localProperties, $projectProperties) {
    var $config = new(config);
    $config.init($sdk, $projectProperties);
    $config
}
