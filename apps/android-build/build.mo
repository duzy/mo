use config;

var $sysdir = dirname(@ARGS[0]);

def check_notnull($v, $err) {
    if isnull($v) { die($err) }
}

def join_target_path($sep, @_) {
    var @paths = list(); 
    for @_ { @paths.push($_.path()) }
    join($sep, @paths)
}

def Add($path, $variant) {
    unless isdir($path) {
        die("$path is not a directory");
    }
    unless isreg("$path/AndroidManifest.xml") {
        die("AndroidManifest.xml is not underneath $path");
    }

    var $project = config::ParseProject($path);
    var $name = $project.name();

    var $platform_jar  = $project.platform_jar();
    var $platform_aidl = $project.platform_aidl();

    var $sign_keystore  = $project.sign_keystore_filename();
    var $sign_storepass = $project.sign_storepass();
    var $sign_keypass   = $project.sign_keypass();

    var $out = "$path/bin/$variant";
    var $target = "$out/$name.apk";

    if $project.libs() {
        say("TODO: libs: "~join(', ', $project.libs()));
    }

    for $project.prerequisites() {
        say("TODO: prerequisite: "~$_.name()~", "~$_.path());
    }

    if $project.is_library() {
        say("TODO: $name is library");
    }

$target: "$out/_.signed"
{
    var $apk    = $_.path();
    var $dir    = $_.parent_path();
    var $signed = @_[0].path();
    var $cmd    = $project.cmd('zipalign');
    lang shell :escape
-------------------------------
echo "Generating APK.."
mkdir -p $dir || exit -1
$cmd -f 4 $signed $apk
----------------------------end
}

"$out/_.signed": "$out/_.pack"
{
    var $storepass = isnull($sign_storepass) ? '' : "-storepass '$sign_storepass'";
    var $keypass   = isnull($sign_keypass)   ? '' : "-keypass '$sign_keypass'";
    var $keystore  = isnull($sign_keystore)  ? '' : "-keystore '$sign_keystore'";
    var $cmd    = $project.cmd('jarsigner');
    var $cert   = $project.sign_cert();
    var $signed = $_.path();
    var $pack   = @_[0].path();
    var $tsa = 1 ? "-tsacert $cert" : '-tsa'
    lang shell :escape
-------------------------------
echo "Signing package.."
cp -f $pack $signed || exit -1
$cmd -sigalg MD5withRSA -digestalg SHA1 $keystore $keypass $storepass \
    $signed $cert
----------------------------end
}

"$out/_.pack": "$path/AndroidManifest.xml" "$out/classes.dex"
{
    var $dir  = $_.parent_path();
    var $pack = $_.path();
    var $am   = @_[0].path();
    var $dex  = @_[1].path();
    var $libs   = "-I $platform_jar";
    var $reses  = "-S '$path/res'";
    var $assets = "-A '$path/assets'";
    var $debug  = $variant eq 'debug' ? '--debug-mode' : '';
    var $cmd = $project.cmd('aapt');
    unless isdir($assets) { $assets = '' }
    lang shell :escape
--------------------------------
echo "Packing resources.."
mkdir -p $dir || exit -1
$cmd package -f -F $pack -M $am $libs $reses $assets \
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
    var $cmd = $project.cmd('dx');
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
    var $cmd = $project.cmd('javac');
    lang shell :escape
--------------------------------
echo "Generating classes.."
rm -f $out/classes.{dex,jar}
[[ -d $out/classes ]] || mkdir -p $out/classes || exit -1
$cmd -d $out/classes $debug -Xlint:unchecked -encoding "UTF-8" \
    -Xlint:-options -source 1.5 -target 1.5 \
    -sourcepath "$out/sources" "\@$out/classpath" "\@$out/sources.list"
find $out/classes -type f -name '*.class' > $out/classes.list
----------------------------end
}

"$out/classpath":
{
    var $classpath = $_.path();
    lang shell :escape
-------------------------------
echo "Generating classpath.."
( echo '-bootclasspath "$platform_jar"' ) > $classpath
----------------------------end
}

"$out/sources.list": "$out/sources/R.java.d" $project.sources()
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

"$out/sources/R.java.d": "$path/AndroidManifest.xml" "$path/res" $project.resources()
{
    var $libs   = "-I $platform_jar";
    var $reses  = isdir("$path/res") ? "-S '$path/res'" : '';
    var $assets = isdir("$path/assets") ? "-A '$path/assets'" : '';
    var $am  = @_[0].path();
    var $cmd = $project.cmd('aapt');
    lang shell :escape
--------------------------------
echo "Generating R.java.."
mkdir -p "$out/sources" || exit -1
$cmd package -f -m -M $am \
    -J "$out/sources" \
    -P "$out/sources/R.public" \
    -G "$out/sources/R.proguard" \
	--output-text-symbols "$out/sources" \
    --generate-dependencies --auto-add-overlay \
    $libs $reses $assets
----------------------------end
}

<"$target">
}
