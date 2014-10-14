var $path = (+@ARGS < 2) ? cwd : @ARGS[1];

use config 'debug' :path($path);

var $variant = $config::Variant;
var $name = $config::Name;
var $out = "$path/bin/$variant";
var @java_sources = <"$path/src">.findall(def($path, $name){ endswith($name, '.java') });
var @res_files = <"$path/res">.findall(def($path, $name){ endswith($name, '.xml', '.png', '.jpg', '.xml') });

def join_target_path($sep, @_) {
    var @paths = list(); 
    for @_ { @paths.push($_.path()) }
    join($sep, @paths)
}

"$out/$name.apk": "$out/_.signed"
{
    var $apk = $_.path();
    var $dir = $_.parent_path();
    var $signed = @_[0].path();
    var $cmd = $config::Cmd_zipalign;
    lang shell :escape
-------------------------------
    echo "Generating APK.."
    mkdir -p $dir || exit -1
    $cmd -f 4 $signed $apk
----------------------------end
}

"$out/_.signed": "$out/_.pack"
{
    var $storepass = isnull($config::Sign_storepass) ? '' : "-storepass '$config::Sign_storepass'";
    var $keypass   = isnull($config::Sign_keypass)   ? '' : "-keypass '$config::Sign_keypass'";
    var $keystore  = isnull($config::Sign_keystore)  ? '' : "-keystore '$config::Sign_keystore'";
    var $cmd  = $config::Cmd_jarsigner;
    var $cert = $config::Sign_cert;
    var $signed = $_.path();
    var $pack   = @_[0].path();
    var $tsa = 1 ? "-tsacert $cert" : '-tsa'
    lang shell :escape
-------------------------------
    echo "Signing package.."
    cp -f $pack $signed || exit -1
    $cmd -sigalg MD5withRSA -digestalg SHA1 $keystore $keypass $storepass \\
        $signed $cert
----------------------------end
}

"$out/_.pack": "$path/AndroidManifest.xml" "$out/classes.dex"
{
    var $dir  = $_.parent_path();
    var $pack = $_.path();
    var $am   = @_[0].path();
    var $dex  = @_[1].path();
    var $libs   = "-I $config::Platform_jar";
    var $reses  = "-S '$path/res'";
    var $assets = "-A '$path/assets'";
    var $debug  = $variant eq 'debug' ? '--debug-mode' : '';
    var $cmd = $config::Cmd_aapt;
    unless isdir($assets) { $assets = '' }
    lang shell :escape
-------------------------------
    echo "Packing resources.."
    mkdir -p $dir || exit -1
    $cmd package -f -F $pack -M $am $libs $reses $assets \\
        $debug --auto-add-overlay

    echo "Packing natives.. (TODO)"

    echo "Packing classes.."
    $cmd add -k $pack $dex > /dev/null
----------------------------end
}

"$out/classes.dex": "$out/classes.list"
{
    var $is_windows = 0;
    var $os_options = $is_windows ? '' : '-JXms16M -JXmx1536M';
    var $apk = "$out/$name.apk";
    var $dex = $_.path();
    var $libs = ''
    var $input = "$out/classes"
    var $debug  = $variant eq 'debug' ? '--debug' : '';
    var $cmd = $config::Cmd_dx;
    lang shell :escape
-------------------------------
    echo "Generating dex file.."
    rm -f $apk $out/_.signed $out/_.unsigned $out/_.pack
    $cmd $os_options --dex $debug --output $dex $libs $input
----------------------------end
}

"$out/classes.list": "$out/sources.list" "$out/classpath"
{
    var $debug  = $variant eq 'debug' ? '-g' : '';
    var $cmd = $config::Cmd_javac;
    lang shell :escape
-------------------------------
    echo "Generating classes.."
    rm -f $out/classes.{dex,jar}
    [[ -d $out/classes ]] || mkdir -p $out/classes || exit -1
    $cmd -d $out/classes $debug -Xlint:unchecked -encoding "UTF-8" -source 1.5 -target 1.5 \\
        -sourcepath "$out/sources" "\@$out/classpath" "\@$out/sources.list"
    find $out/classes -type f -name '*.class' > $out/classes.list
----------------------------end
}

"$out/classpath":
{
    var $platform_jar =  "$config::Platform_jar";
    var $classpath = $_.path();
    lang shell :escape
-------------------------------
    echo "Generating classpath.."
    (
        echo '-bootclasspath "$platform_jar"'
    ) > $classpath
----------------------------end
}

"$out/sources.list": "$out/sources/R.java.d" @java_sources
{
    var $d = @_.shift(); # remove R.java.d
    var $sources = join_target_path(' ', @_);
    var $outfile = $_.path();
    lang shell :escape
-------------------------------
    echo "Generating source list.."
    echo '# AUTOMACTICLY GENERATED, DONNOT EDDIT' > $outfile
    (for s in $sources ; do echo \$s ; done) >> $outfile
    find $out/sources -type f -name '*.java' >> $outfile
----------------------------end
}

"$out/sources/R.java.d": "$path/AndroidManifest.xml" "$path/res" @res_files
{
    var $libs   = "-I $config::Platform_jar";
    var $reses  = isdir("$path/res") ? "-S '$path/res'" : '';
    var $assets = isdir("$path/assets") ? "-A '$path/assets'" : '';
    var $am  = @_[0].path();
    var $cmd = $config::Cmd_aapt;
    lang shell :escape
-------------------------------
    echo "Generating R.java.."
    mkdir -p "$out/sources" || exit -1
    $cmd package -f -m -M $am \\
        -J "$out/sources" \\
        -P "$out/sources/R.public" \\
        -G "$out/sources/R.proguard" \\
	--output-text-symbols "$out/sources" \\
        --generate-dependencies --auto-add-overlay \\
        $libs $reses $assets
----------------------------end
}

<"$out/$name.apk">.make();
