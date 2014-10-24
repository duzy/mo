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

    $.path = $path;
    $.name = basename($path);
    $.manifest = load_manifest($path);

    $.is_library = 0;

    $.libs = list();
    $.lib_projects = hash();

    $.out = "$path/bin/$variant";
    $.target;

    {
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

    "$.out/_.pack" : "$.path/AndroidManifest.xml" "$.out/classes.dex"
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
        unless isdir($assets) { $assets = '' }
        lang shell :escape
--------------------------------
echo "$.name: Packing resources.."
mkdir -p $dir || exit -1
$cmd package -f -F $pack -M $am $libs $reses $assets \
    $debug --auto-add-overlay

echo "$.name: Packing natives.. (TODO)"

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
cat $.out/classpath
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
        for @_ { $libs = $libs ~ ' ' ~ $_.path() }
        lang shell :escape
-------------------------------
echo "$.name: Generating classpath.."
mkdir -p $dir || exit -1
(
    echo '-bootclasspath "$.platform_jar"'
    for lib in $libs ; do echo "-cp \\"\$lib\\""; done
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
