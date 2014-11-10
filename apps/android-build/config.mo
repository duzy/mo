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

def load_xml($xml) {
    lang XML in $xml
}

def load_manifest($path) {
    load_xml("$path/AndroidManifest.xml")
}

def search_library($path, $lib) {
    if startswith($lib, '/', '~') {
        $lib
    } else {
        "$path/$lib"
    }
}

def join_target_path($sep, @_) {
    var @paths = list(); 
    for @_ { @paths.push($_.path()) }
    join($sep, @paths)
}

def notnull($v, $err) {
    if isnull($v) { die($err) }
}

class native <$path>
{
    var $.config_xml
    var $.config
    var $.module

    var $.out_lib
    var $.out_obj

    method binaries() {
        var $list = list();
        $list.push($.module.INSTALLED)
        $list
    }

    method sources() {
        var $list = list();
        for split(" ", $.module.SRC_FILES) {
            $list.push($.module.PATH~"/$_")
        }
        $list
    }

    {
        var $and_mk = any isreg "$path/Android.mk";
        var $app_mk = any isreg "$path/Application.mk";
        notnull($and_mk, "Android.mk is not underneath $path");
        notnull($app_mk, "Application.mk is not underneath $path");

        var $project_path = dirname($path);
        $.out_lib = "$project_path/libs"
        $.out_obj = "$project_path/obj"
        $.config_xml = "$.out_obj/config.xml";
    }

    $.config_xml : "$path/Android.mk" "$path/Application.mk"
    {
        var $project_path = dirname($path);
        var $name = basename($project_path);
        lang shell :escape
---------------------------
echo "$name: Generating $.config_xml.."
mkdir -p \$(dirname $.config_xml)
make -s -f $sysdir/ndk/boot.mk NDK_PROJECT_PATH=$project_path DO=xml \
    > $.config_xml || rm -f $.config_xml
------------------------end
    }

    {
        <"$.config_xml">.make(me);

        if isreg($.config_xml) {
            $.config = load_xml($.config_xml);

            var @m = $.config->module->{ .name eq $.config.top }
            if +@m < 1 {
                die("missing top module "~$.config.top)
            }

            $.module = @m[0]
        }
    }

    method make: $.module.INSTALLED : $.module.BUILT_MODULE
    {
        var $target = $_.name();
        var $built = @_[0].name();
        var $name = $.module.name;
        lang shell :escape
---------------------------
echo "$name: Generating native $target.."
mkdir -p \$(dirname $target) && cp -f $built $target
------------------------end
    }

    $.module.BUILT_MODULE : me.sources()
    {
        var $built = $_.name();
        var $project_path = dirname($path);
        var $name = $.module.name;
        lang shell :escape
---------------------------
echo "$name: Generating native $built.."
make -s -f $sysdir/ndk/boot.mk NDK_PROJECT_PATH=$project_path \
    DO=build DO_TARGET_MODULE_NAME=$name all
------------------------end
    }
}

class project <$path, $variant>
{
    var $.platform;
    var $.platform_jar;
    var $.platform_aidl;
    var $.platform_properties;

    var $.cmds = hash();

    var $.sign_cert = 'cert';
    var $.sign_storepass_filename;
    var $.sign_keypass_filename;
    var $.sign_keystore_filename;
    var $.sign_storepass;
    var $.sign_keypass;

    var $.path = $path;
    var $.name = basename($path);
    var $.manifest = load_manifest($path);

    var $.is_library = 0;

    var $.libs = list();
    var $.lib_projects = hash();

    var $.native;
    var $.native_binaries;

    var $.out = "$path/bin/$variant";
    var $.target;

    {
        if isdir("$path/jni") {
            $.native = new(native, "$path/jni");
            $.native_binaries = $.native.binaries();
        }

        var $name = $.name;
        var $manifest = $.manifest;
        if isnull($name) { $name = $.name = split('.', $manifest.package).pop() }

        var $localProperties   = LoadProperties("$path/local.properties");
        var $projectProperties = LoadProperties("$path/project.properties");
        notnull($localProperties,   "local.properties is not underneath $path");
        notnull($projectProperties, "project.properties is not underneath $path");

        var $sdk = any isdir $localProperties{'sdk.dir'}, "/open/android/android-studio/sdk";
        notnull($sdk,  'SDK missing');

        var $platform = $.platform = $projectProperties{'target'};
        notnull($platform,  'Platform target missing');

        var $library = $projectProperties{'android.library'}; # android.library=true
        $.is_library = isnull($library) ? 0 : $library eq 'true';
        $.target = "$.out/$.name." ~ ($.is_library ? 'jar' : 'apk');

        var $pre;
        var $lib;
        var $lib_path;
        while !isnull($lib = $projectProperties{'android.library.reference.'~(1+$.libs)}) {
            $lib_path = search_library($path, $lib);
            $pre = new(project, $lib_path, $variant);
            $.libs.push($lib = "$lib_path/bin/$variant/"~$pre.name()~'.jar');
            $.lib_projects{$lib} = $pre;
        }

        $.platform_jar  = any isreg "$sdk/platforms/$platform/android.jar";
        $.platform_aidl = any isreg "$sdk/platforms/$platform/framework.aidl";
        notnull($.platform_jar,  '$sdk/platforms/$platform/android.jar missing');
        notnull($.platform_aidl, '$sdk/platforms/$platform/framework.aidl missing');

        $.platform_properties = LoadProperties("$sdk/platforms/$platform/source.properties");
        notnull($.platform_properties,  '$sdk/platforms/$platform/source.properties missing');

        var $platformVersion = $.platform_properties{'Platform.Version'};
        notnull($platformVersion,  'Platform.Version missing');

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

        notnull($.cmds<android>,         '$sdk/tools/android missing');
        notnull($.cmds<lint>,            '$sdk/tools/lint missing');
        notnull($.cmds<adb>,             '$sdk/platform-tools/adb missing');
        notnull($.cmds<sqlite3>,         '$sdk/platform-tools/sqlite3 missing');
        notnull($.cmds<aapt>,            '$sdk/build-tools/.../aapt missing');
        notnull($.cmds<aidl>,            '$sdk/build-tools/.../aidl missing');
        notnull($.cmds<dx>,              '$sdk/build-tools/.../dx missing');
        notnull($.cmds<rscc>,            '$sdk/build-tools/.../llvm-rs-cc missing');
        notnull($.cmds<zipalign>,        '$sdk/build-tools/.../zipalign missing');
        notnull($.cmds<jarsigner>,       'jarsigner missing');
        notnull($.cmds<jar>,             'jar missing');

        $.sign_storepass_filename = any isreg "$path/.android/storepass", "$sysdir/key/storepass";
        $.sign_keypass_filename   = any isreg "$path/.android/keypass",   "$sysdir/key/keypass";
        $.sign_keystore_filename  = any isreg "$path/.android/keystore",  "$sysdir/key/keystore";
        $.sign_storepass = isnull($.sign_storepass_filename) ? null : strip(slurp($.sign_storepass_filename));
        $.sign_keypass   = isnull($.sign_keypass_filename)   ? null : strip(slurp($.sign_keypass_filename));
    }

    method path()      { $.path }
    method name()      { $.name }

    method assets()    { <"$.path/assets">.findall(def($path, $name){ !endswith($name, '~') }) }
    method resources() { <"$.path/res">.findall(def($path, $name){ endswith($name, '.xml', '.png', '.jpg', '.xml') }) }
    method sources()   { <"$.path/src">.findall(def($path, $name){ endswith($name, '.java') }) }

    ############################## rules ##############################

    #method make: $.target : ($.is_library ? "$.out/classes.purged" : "$.out/_.signed")
    method make: $.target : ($.is_library ? "$.out/classes.list" : "$.out/_.signed")
    {
        var $dir    = $_.parent_path();
        var $target = $_.name();
        var $depend = @_[0].path();
        var $cmd    = $.cmds{$.is_library ? 'jar' : 'zipalign'};
        if $.is_library lang shell :escape
-------------------------------
echo "$.name: Generating library ($target).."
mkdir -p $dir || exit -1
$cmd cf $target -C "$.out/classes" .
#$cmd cvfm $target manifest -C "$.out/classes" .
----------------------------end
        else lang shell :escape
-------------------------------
echo "$.name: Generating APK ($target).."
mkdir -p "$dir" || exit -1
$cmd -f 4 "$depend" "$target"
----------------------------end
        end
    }

    "$.out/_.signed" : "$.out/_.pack"
    {
        var $storepass = isnull($.sign_storepass)          ? '' : "-storepass '$.sign_storepass'";
        var $keypass   = isnull($.sign_keypass)            ? '' : "-keypass '$.sign_keypass'";
        var $keystore  = isnull($.sign_keystore_filename)  ? '' : "-keystore '$.sign_keystore_filename'";
        var $cmd       = $.cmds<jarsigner>;
        var $cert      = $.sign_cert;
        var $signed    = $_.path();
        var $pack      = @_[0].path();
        var $tsa       = 1 ? "-tsacert $cert" : '-tsa';
        lang shell :escape
-------------------------------
echo "$.name: Signing package.."
cp -f $pack $signed || exit -1
$cmd -sigalg MD5withRSA -digestalg SHA1 $keystore $keypass $storepass \
    $signed $cert
----------------------------end
    }

    "$.out/_.pack" : "$.path/AndroidManifest.xml" "$.out/classes.dex" $.native_binaries
    {
        var $dir    = $_.parent_path();
        var $pack   = $_.path();
        var $am     = @_[0].path();
        var $dex    = @_[1].path();
        var $libs   = "-I $.platform_jar";
        var $reses  = "-S '$.path/res'";
        var $assets = "-A '$.path/assets'";
        var $debug  = $variant eq 'debug' ? '--debug-mode' : '';
        var $cmd    = $.cmds<aapt>;
        var $natives = isnull($.native_binaries) ? '' : join(' ', $.native_binaries);
        unless isdir($assets) { $assets = '' }
        lang shell :escape
--------------------------------
echo "$.name: Packing resources.."
mkdir -p $dir || exit -1
$cmd package -f -F $pack -M $am $libs $reses $assets \
    $debug --auto-add-overlay

echo "$.name: Packing natives.. (TODO)"
# for l in $natives ; do
#     $cmd add -k $pack \$l
# done
$cmd add -k $pack $natives

jar tf $pack

echo "$.name: Packing classes.."
$cmd add -k $pack $dex > /dev/null
----------------------------end
    }

    "$.out/classes.dex" : "$.out/classes.list"
    {
        var $is_windows = 0;
        var $os_options = $is_windows ? '' : '-JXms16M -JXmx1536M';
        var $apk        = $.target;
        var $dex        = $_.path();
        var $libs       = '';
        var $input      = "$.out/classes";
        var $debug      = $variant eq 'debug' ? '--debug' : '';
        var $cmd        = $.cmds<dx>;
        lang shell :escape
-------------------------------
echo "$.name: Generating dex file.."
rm -f $apk "$.out/_.signed" "$.out/_.unsigned" "$.out/_.pack"
$cmd $os_options --dex $debug --output $dex $libs $input
----------------------------end
    }

    "$.out/classes.purged" : "$.out/classes.list"
    {
        var $purged = $_.path();
        lang shell :escape
-------------------------------
echo "$.name: Purging duplicated classes.."
# find "$.out/classes" -type f \\( -name 'R.class' -or -name 'R\$*.class' \\) -delete
find "$.out/classes" -type f \\( -name 'R.class' -or -name 'R\$*.class' \\) -print > $purged
for f in \$(cat $purged) ; do rm -f \$f ; done
----------------------------end
    }

    "$.out/classes.list" : "$.out/sources.list" "$.out/classpath"
    {
        var $debug = $variant eq 'debug' ? '-g' : '';
        var $cmd   = $.cmds<javac>;
        lang shell :escape
--------------------------------
echo "$.name: Generating classes.."
rm -f $.out/classes.{dex,jar,list}
[[ -d $.out/classes ]] || mkdir -p "$.out/classes" || exit -1
find "$.out/classes" -type f -name '*.class' -delete
$cmd -d "$.out/classes" $debug -Xlint:unchecked -encoding "UTF-8" \
    -Xlint:-options -source 1.5 -target 1.5 \
    -sourcepath "$.out/sources" "\@$.out/classpath" "\@$.out/sources.list" || exit -1
find "$.out/classes" -type f -name '*.class' > "$.out/classes.list"
----------------------------end
    }

    "$.out/sources.list" : "$.out/sources/R.java.d" me.sources()
    {
        var $d = @_.shift(); # remove R.java.d
        var $sources = join_target_path(' ', @_);
        var $outfile = $_.path();
        lang shell :escape
-------------------------------
echo "$.name: Generating source list.."
mkdir -p \$(dirname $outfile) || exit -1
(
    for s in $sources ; do echo \$s ; done
    find "$.out/sources" -type f -name '*.java'
) > $outfile
----------------------------end
    }

    "$.out/sources/R.java.d" : "$.path/AndroidManifest.xml" "$.path/res" me.resources() $.libs
    {
        var $libs   = "-I $.platform_jar";
        var $reses  = isdir("$.path/res") ? "-S '$.path/res'" : '';
        var $assets = isdir("$.path/assets") ? "-A '$.path/assets'" : '';
        var $am  = @_[0].path();
        var $cmd = $.cmds<aapt>;
        if $.is_library lang shell :escape
--------------------------------
echo "$.name: Generating R.java.."
mkdir -p "$.out/sources" || exit -1
$cmd package -f -m -M $am \
    -J "$.out/sources" \
    -P "$.out/sources/R.public" \
    -G "$.out/sources/R.proguard" \
    --output-text-symbols "$.out/sources" \
    --generate-dependencies --auto-add-overlay \
    $libs $reses $assets
----------------------------end
        else lang shell :escape
--------------------------------
echo "$.name: Generating R.java.."
mkdir -p "$.out/sources" || exit -1
$cmd package -f -m -x -M $am \
    -J "$.out/sources" \
    -P "$.out/sources/R.public" \
    -G "$.out/sources/R.proguard" \
    --output-text-symbols "$.out/sources" \
    --generate-dependencies --non-constant-id --auto-add-overlay \
    $libs $reses $assets
----------------------------end
        end
    }

    "$.out/classpath": $.libs
    {
        var $dir = $_.parent_path();
        var $classpath = $_.path();
        var $libs = '';
        for @_ {
            if $libs ne '' { $libs = $libs ~ ':' }
            # $libs = $libs ~ dirname($_.path()) ~ '/classes'
            $libs = $libs ~ $_.path()
        }
        lang shell :escape
-------------------------------
echo "$.name: Generating classpath.."
mkdir -p $dir || exit -1
(
    echo '-bootclasspath "$.platform_jar"'
    echo "-cp \\"$libs\\""
) > $classpath
----------------------------end
    }

    $.libs:
    {
        var $lib = $_.name();
        var $project = $.lib_projects{$lib};
        if defined($project) {
            say("$.name: Building "~$project.name()~" ($lib)");
            $project.make();
        }
    }

    $.native_binaries :
    {
        say("$.name: make "~$_.path()~"..");
        $.native.make();
    }
}

def ParseProject($path, $variant) {
    unless isdir($path) {
        die("$path is not a directory");
    }
    unless isreg("$path/AndroidManifest.xml") {
        die("AndroidManifest.xml is not underneath $path");
    }

    new(project, $path, $variant)
}
