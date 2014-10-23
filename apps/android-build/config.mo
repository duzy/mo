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

def search_library($path, $lib) {
    if startswith($lib, '/', '~') {
        $lib
    } else {
        "$path/$lib"
    }
}

def check_notnull($v, $err) {
    if isnull($v) { die($err) }
}

class project <$path, $variant>
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

    $.project_path = $path;
    $.project_name = basename($path);
    $.project_manifest = load_manifest($path);

    $.is_library = 0;

    $.libs = list();

    $.prerequisites = list();

    {
        var $name = $.project_name;
        var $manifest = $.project_manifest;
        if isnull($name) { $name = $.project_name = split('.', $manifest.package).pop() }

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

        var $lib;
        var $lib_path;
        while !isnull($lib = $projectProperties{'android.library.reference.'~(1+$.libs)}) {
            $.libs.push($lib_path = search_library($path, $lib));
            $.prerequisites.push(new(project, $lib_path, $variant));
        }

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
        $.cmds<jar>               = "jar";

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
        check_notnull($.cmds<jar>,             'jar missing');

        $.sign_storepass_filename = any isreg "$path/.android/storepass", "$sysdir/key/storepass";
        $.sign_keypass_filename   = any isreg "$path/.android/keypass",   "$sysdir/key/keypass";
        $.sign_keystore_filename  = any isreg "$path/.android/keystore",  "$sysdir/key/keystore";
        $.sign_storepass = isnull($.sign_storepass_filename) ? null : strip(slurp($.sign_storepass_filename));
        $.sign_keypass   = isnull($.sign_keypass_filename)   ? null : strip(slurp($.sign_keypass_filename));
    }

    method cmd($name) { $.cmds{$name} }

    method platform_jar()  { $.platform_jar }
    method platform_aidl() { $.platform_aidl }

    method sign_cert()               { $.sign_cert }
    method sign_storepass_filename() { $.sign_storepass_filename }
    method sign_keypass_filename()   { $.sign_keypass_filename }
    method sign_keystore_filename()  { $.sign_keystore_filename }
    method sign_storepass()          { $.sign_storepass }
    method sign_keypass()            { $.sign_keypass }

    method path() { $.project_path }
    method name() { $.project_name }
    method manifest() { $.project_manifest }

    method is_library() { $.is_library }

    method libs() { $.libs }
    method prerequisites() { $.prerequisites }

    method assets()    { <"$.project_path/assets">.findall(def($path, $name){ !endswith($name, '~') }) }
    method resources() { <"$.project_path/res">.findall(def($path, $name){ endswith($name, '.xml', '.png', '.jpg', '.xml') }) }
    method sources()   { <"$.project_path/src">.findall(def($path, $name){ endswith($name, '.java') }) }

    ######## rules ########

    $.out = "$path/bin/$variant";
    $.target = "$.out/$.project_name." ~ ($.is_library ? 'jar' : 'apk');
    {
        # say($.out);
    }

    method make: $.target : ($.is_library ? "$.out/classes.purged" : "$.out/_.signed")
    {
        say('make: '~$_.name());
    }

    "$.out/_.signed" : "$.out/_.pack"
    {
        say("build: $.out/_.signed");
    }

    "$.out/_.pack" : "$path/AndroidManifest.xml" "$.out/classes.dex"
    {
        say("build: $.out/_.pack");
    }

    "$.out/classes.dex" : "$.out/classes.list"
    {
        say("build: $.out/classes.dex");
    }

    "$.out/classes.purged" : "$.out/classes.list"
    {
        # say('build: '~$_.name());
        say("build: $.out/classes.purged");
    }

    "$.out/classes.list" : "$.out/sources.list" "$.out/classpath"
    {
        say("$.out/classes.list");
    }

    "$.out/sources.list" : "$.out/sources/R.java.d" me.sources()
    {
        say("$.out/sources.list");
    }
}

def ParseProject($path, $variant) {
    unless isreg("$path/AndroidManifest.xml") {
        die("AndroidManifest.xml is not underneath $path");
    }

    new(project, $path, $variant)
}

say('...');
