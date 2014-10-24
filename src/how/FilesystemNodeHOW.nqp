knowhow MO::FilesystemNodeHOW {
    my %cache;
    my $type;

    my sub filter_dir_names($path, $pred, $recursive) {
        my @result;
        my @names;
        try { @names := VMCall::readdir($path); }
        for @names {
            if $_ ne '.' && $_ ne '..' {
                my $pathname := "$path/$_";
                @result.push($pathname) if $pred($path, $_);
                if $recursive && nqp::stat($pathname, nqp::const::STAT_ISDIR) {
                    @result.push($_) for filter_dir_names($pathname, $pred, $recursive);
                }
            }
        }
        @result
    }

    my sub node_find($node, $pred, $recursive) {
        my $base := $node.name(); #$node.get('PATH');
        filter_dir_names($base, $pred, $recursive)
    }

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
            nqp::bindattr($child, $type, '$.^', $parent);
            $parent := $child;
        }
        $child;
    }
    my sub method_find($node, $pred)    { node_find($node, $pred, 0) }
    my sub method_findall($node, $pred) { node_find($node, $pred, 1) }
    my sub method_stat($node, $flag) { nqp::stat(method_path($node), $flag) }
    my sub method_exists($node)      { method_stat($node, nqp::const::STAT_EXISTS) }
    my sub method_isdir($node)       { method_stat($node, nqp::const::STAT_ISDIR) }
    my sub method_isreg($node)       { method_stat($node, nqp::const::STAT_ISREG) }
    my sub method_isdev($node)       { method_stat($node, nqp::const::STAT_ISDEV) }
    my sub method_islnk($node)       { method_stat($node, nqp::const::STAT_ISLNK) }
    my sub method_filesize($node)    { method_stat($node, nqp::const::STAT_FILESIZE) }
    my sub method_accesstime($node)  { method_stat($node, nqp::const::STAT_ACCESSTIME) }
    my sub method_backuptime($node)  { method_stat($node, nqp::const::STAT_BACKUPTIME) }
    my sub method_createtime($node)  { method_stat($node, nqp::const::STAT_CREATETIME) }
    my sub method_changetime($node)  { method_stat($node, nqp::const::STAT_CHANGETIME) }
    my sub method_modifytime($node)  { method_stat($node, nqp::const::STAT_MODIFYTIME) }
    my sub method_gid($node)         { method_stat($node, nqp::const::STAT_GID) }
    my sub method_uid($node)         { method_stat($node, nqp::const::STAT_UID) }
    my sub method_platform_dev($node)       { method_stat($node, nqp::const::STAT_PLATFORM_DEV) }
    my sub method_platform_inode($node)     { method_stat($node, nqp::const::STAT_PLATFORM_INODE) }
    my sub method_platform_mode($node)      { method_stat($node, nqp::const::STAT_PLATFORM_MODE) }
    my sub method_platform_nlinks($node)    { method_stat($node, nqp::const::STAT_PLATFORM_NLINKS) }
    my sub method_platform_devtype($node)   { method_stat($node, nqp::const::STAT_PLATFORM_DEVTYPE) }
    my sub method_platform_blocksize($node) { method_stat($node, nqp::const::STAT_PLATFORM_BLOCKSIZE) }
    my sub method_platform_blocks($node)    { method_stat($node, nqp::const::STAT_PLATFORM_BLOCKS) }
    my sub method_parent_path($node) { pathparent(method_path($node)) }
    my sub method_parent_name($node) { pathname(method_parent_path($node)) }
    my sub method_path($node)        { pathabs(nqp::getattr($node, $type, '')) }
    my sub method_lastname($node)    { pathname(nqp::getattr($node, $type, '')) }
    my sub method_newer_than($node1, $node2) {
        my int $t1 := method_exists($node1) ?? method_modifytime($node1) !! 0;
        my int $t2 := method_exists($node2) ?? method_modifytime($node2) !! 0;
        $t1 > $t2;
    }

    method methods() {
        my %methods := MO::NodeHOW.methods();
        %methods<set>                   := &method_set;
        %methods<children>              := &method_children;
        %methods<find>                  := &method_find;
        %methods<findall>               := &method_findall;
        %methods<exists>                := &method_exists;
        %methods<isdir>                 := &method_isdir;
        %methods<isreg>                 := &method_isreg;
        %methods<isdev>                 := &method_isdev;
        %methods<islnk>                 := &method_islnk;
        %methods<filesize>              := &method_filesize;
        %methods<accesstime>            := &method_accesstime;
        %methods<backuptime>            := &method_backuptime;
        %methods<createtime>            := &method_createtime;
        %methods<changetime>            := &method_changetime;
        %methods<modifytime>            := &method_modifytime;
        %methods<gid>                   := &method_gid;
        %methods<uid>                   := &method_uid;
        %methods<platform_dev>          := &method_platform_dev;
        %methods<platform_inode>        := &method_platform_inode;
        %methods<platform_mode>         := &method_platform_mode;
        %methods<platform_nlinks>       := &method_platform_nlinks;
        %methods<platform_devtype>      := &method_platform_devtype;
        %methods<platform_blocksize>    := &method_platform_blocksize;
        %methods<platform_blocks>       := &method_platform_blocks;
        %methods<parent_path>           := &method_parent_path;
        %methods<parent_name>           := &method_parent_name;
        %methods<path>                  := &method_path;
        %methods<lastname>              := &method_lastname;
        %methods<method_newer_than>     := &method_newer_than;
        %methods;
    }

    method type() {
        unless nqp::defined($type) {
            my %methods := self.methods();
            my $metaclass := nqp::create(self);
            $type := nqp::setwho(nqp::newtype($metaclass, 'HashAttrStore'), {});
            nqp::setboolspec($type, 0, &method_exists);
            nqp::setmethcache($type, %methods);
            nqp::setmethcacheauth($type, 1);
        }
        $type;
    }

    sub pathparent($path) {
        my $i := nqp::rindex($path, '/');
        my $name := nqp::substr($path, 0, $i);
        $name;
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
        $path[0] eq '/' ?? $path !! pathconcat(nqp::cwd, $path)
    }

    method open(:$path) {
        my $exists := nqp::stat($path, nqp::const::STAT_EXISTS);
        my $node := nqp::create(self.type);
        nqp::bindattr($node, $type, '', $path);
        nqp::bindattr($node, $type, '$.?', 'filesystem');
        nqp::bindattr($node, $type, '$.NAME', pathname($path));
        nqp::bindattr($node, $type, '$.PATH', pathabs($path));
        nqp::bindattr($node, $type, '$.EXISTS', $exists);
        if ($exists) {
            nqp::bindattr($node, $type, '$.FILESIZE',            nqp::stat($path, nqp::const::STAT_FILESIZE));
            nqp::bindattr($node, $type, '$.ISDIR',               nqp::stat($path, nqp::const::STAT_ISDIR));
            nqp::bindattr($node, $type, '$.ISREG',               nqp::stat($path, nqp::const::STAT_ISREG));
            nqp::bindattr($node, $type, '$.ISDEV',               nqp::stat($path, nqp::const::STAT_ISDEV));
            nqp::bindattr($node, $type, '$.ISLNK',               nqp::stat($path, nqp::const::STAT_ISLNK));
            nqp::bindattr($node, $type, '$.CREATETIME',          nqp::stat($path, nqp::const::STAT_CREATETIME));
            nqp::bindattr($node, $type, '$.ACCESSTIME',          nqp::stat($path, nqp::const::STAT_ACCESSTIME));
            nqp::bindattr($node, $type, '$.MODIFYTIME',          nqp::stat($path, nqp::const::STAT_MODIFYTIME));
            nqp::bindattr($node, $type, '$.CHANGETIME',          nqp::stat($path, nqp::const::STAT_CHANGETIME));
            nqp::bindattr($node, $type, '$.BACKUPTIME',          nqp::stat($path, nqp::const::STAT_BACKUPTIME));
            nqp::bindattr($node, $type, '$.UID',                 nqp::stat($path, nqp::const::STAT_UID));
            nqp::bindattr($node, $type, '$.GID',                 nqp::stat($path, nqp::const::STAT_GID));
            nqp::bindattr($node, $type, '$.PLATFORM_DEV',        nqp::stat($path, nqp::const::STAT_PLATFORM_DEV));
            nqp::bindattr($node, $type, '$.PLATFORM_INODE',      nqp::stat($path, nqp::const::STAT_PLATFORM_INODE));
            nqp::bindattr($node, $type, '$.PLATFORM_MODE',       nqp::stat($path, nqp::const::STAT_PLATFORM_MODE));
            nqp::bindattr($node, $type, '$.PLATFORM_NLINKS',     nqp::stat($path, nqp::const::STAT_PLATFORM_NLINKS));
            nqp::bindattr($node, $type, '$.PLATFORM_DEVTYPE',    nqp::stat($path, nqp::const::STAT_PLATFORM_DEVTYPE));
            nqp::bindattr($node, $type, '$.PLATFORM_BLOCKSIZE',  nqp::stat($path, nqp::const::STAT_PLATFORM_BLOCKSIZE));
            nqp::bindattr($node, $type, '$.PLATFORM_BLOCKS',     nqp::stat($path, nqp::const::STAT_PLATFORM_BLOCKS));
        }
        $node;
    }

    method add_depends($node, @targets) {
        my @depends := nqp::getattr($node, $type, '@depends');
        unless nqp::defined(@depends) {
            @depends := nqp::list();
            nqp::bindattr($node, $type, '@depends', @depends);
        }
        @depends.push($_) for @targets;
    }
}
