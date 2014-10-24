use config;

def Add($path, $variant) {
    unless isdir($path) {
        die("$path is not a directory");
    }
    unless isreg("$path/AndroidManifest.xml") {
        die("AndroidManifest.xml is not underneath $path");
    }

    config::ParseProject($path, $variant)
}
