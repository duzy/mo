knowhow MO::FilesystemNodeHOW {
    my $type;

    my sub method_set($node, $name, $value) { nqp::die('filesystem nodes are readonly') }
    my sub method_children($node, $subpath = nqp::null()) {
        my $child;
        my $parent := $node;
        my $names := nqp::split('/', $subpath);
        for $names -> $name {
            my $s := pathconcat($parent.name, $name);
            # $child := nqp::getattr($parent, $type, '/'~$name);
            # unless nqp::defined($child) {
            #     $child := MO::FilesystemNodeHOW.open(:path($s));
            #     nqp::bindattr($parent, $type, '/'~$name, $child);
            # }
            $child := MO::FilesystemNodeHOW.open(:path($s));
            nqp::bindattr($child, $type, '^', $parent);
            $parent := $child;
        }
        $child;
    }
    my sub method_exists($node) { $node.get('EXISTS') }
    my sub method_depends($node) { nqp::getattr($node, $type, '@depends') }
    my sub method_depend($node, $path) {
        my @depends := method_depends($node);
        my $dep;
        if nqp::isstr($path) {
            $dep := MO::FilesystemNodeHOW.open(:path($path));
        } elsif nqp::can($node, 'make') {
            $dep := $path;
        } else {
            nqp::die("unsupported dependency $path");
        }
        @depends.push($dep);
        nqp::bindattr($node, $type, '@depends', @depends);
    }
    my sub method_updated($node) {
        
    }
    my sub method_make($node) {
        my @depends := method_depends($node);
        
    }

    method methods() {
        my %methods := MO::NodeHOW.methods();
        %methods<set>      := &method_set;
        %methods<children> := &method_children;
        %methods<exists>   := &method_exists;
        %methods<depend>   := &method_depend;
        %methods<make>     := &method_make;
        %methods;
    }

    method type() {
        unless nqp::defined($type) {
            my %methods := self.methods();
            my $metaclass := nqp::create(self);
            $type := nqp::setwho(nqp::newtype($metaclass, 'HashAttrStore'), {});
            nqp::setmethcache($type, %methods);
            nqp::setmethcacheauth($type, 1);
        }
        $type;
    }

    sub pathname($path) {
        my $i := nqp::rindex($path, '/');
        my $name := nqp::substr($path, $i+1);
        $name;
    }

    sub pathconcat($base, $leaf) {
        $base ~ '/' ~ $leaf;
    }

    sub pathabs($path) {
        if $path[0] eq '/' {
            $path;
        } else {
            pathconcat(nqp::cwd, $path);
        }
    }

    method open(:$path) {
        my $exists := nqp::stat($path, nqp::const::STAT_EXISTS);
        my $node := nqp::create(self.type);
        nqp::bindattr($node, $type, '?', 'filesystem');
        nqp::bindattr($node, $type, '', $path);
        nqp::bindattr($node, $type, '.NAME', pathname($path));
        nqp::bindattr($node, $type, '.PATH', pathabs($path));
        nqp::bindattr($node, $type, '.EXISTS', $exists);
        if ($exists) {
            nqp::bindattr($node, $type, '.FILESIZE',            nqp::stat($path, nqp::const::STAT_FILESIZE));
            nqp::bindattr($node, $type, '.ISDIR',               nqp::stat($path, nqp::const::STAT_ISDIR));
            nqp::bindattr($node, $type, '.ISREG',               nqp::stat($path, nqp::const::STAT_ISREG));
            nqp::bindattr($node, $type, '.ISDEV',               nqp::stat($path, nqp::const::STAT_ISDEV));
            nqp::bindattr($node, $type, '.CREATETIME',          nqp::stat($path, nqp::const::STAT_CREATETIME));
            nqp::bindattr($node, $type, '.ACCESSTIME',          nqp::stat($path, nqp::const::STAT_ACCESSTIME));
            nqp::bindattr($node, $type, '.MODIFYTIME',          nqp::stat($path, nqp::const::STAT_MODIFYTIME));
            nqp::bindattr($node, $type, '.CHANGETIME',          nqp::stat($path, nqp::const::STAT_CHANGETIME));
            nqp::bindattr($node, $type, '.BACKUPTIME',          nqp::stat($path, nqp::const::STAT_BACKUPTIME));
            nqp::bindattr($node, $type, '.UID',                 nqp::stat($path, nqp::const::STAT_UID));
            nqp::bindattr($node, $type, '.GID',                 nqp::stat($path, nqp::const::STAT_GID));
            nqp::bindattr($node, $type, '.ISLNK',               nqp::stat($path, nqp::const::STAT_ISLNK));
            nqp::bindattr($node, $type, '.PLATFORM_DEV',        nqp::stat($path, nqp::const::STAT_PLATFORM_DEV));
            nqp::bindattr($node, $type, '.PLATFORM_INODE',      nqp::stat($path, nqp::const::STAT_PLATFORM_INODE));
            nqp::bindattr($node, $type, '.PLATFORM_MODE',       nqp::stat($path, nqp::const::STAT_PLATFORM_MODE));
            nqp::bindattr($node, $type, '.PLATFORM_NLINKS',     nqp::stat($path, nqp::const::STAT_PLATFORM_NLINKS));
            nqp::bindattr($node, $type, '.PLATFORM_DEVTYPE',    nqp::stat($path, nqp::const::STAT_PLATFORM_DEVTYPE));
            nqp::bindattr($node, $type, '.PLATFORM_BLOCKSIZE',  nqp::stat($path, nqp::const::STAT_PLATFORM_BLOCKSIZE));
            nqp::bindattr($node, $type, '.PLATFORM_BLOCKS',     nqp::stat($path, nqp::const::STAT_PLATFORM_BLOCKS));
        }
        $node;
    }
}
