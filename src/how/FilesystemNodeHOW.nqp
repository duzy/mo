knowhow MO::FilesystemNodeHOW {
    my $type;

    method type() {
        unless nqp::defined($type) {
            my %methods;
            %methods<name> := -> $node { nqp::getattr($node, $type, ''); };
            %methods<type> := -> $node { nqp::getattr($node, $type, '?'); };
            %methods<text> := -> $node {
                nqp::join('', nqp::getattr($node, $type, '*'));
            };
            %methods<attributes> := -> $node {
                nqp::getattr($node, $type, '.*');
            };
            %methods<get> := -> $node, $name {
                nqp::getattr($node, $type, '.'~$name);
            };
            %methods<set> := -> $node, $name, $value {
                nqp::die('filesystem nodes are readonly');
            };
            %methods<count> := -> $node, $name = nqp::null() {
                +$node.children($name);
            };
            %methods<parent> := -> $node {
                nqp::getattr($node, $type, '^');
            };
            %methods<children> := -> $node, $subpath = nqp::null() {
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
            };

            my $metaclass := nqp::create(self);
            $type := nqp::setwho(nqp::newtype($metaclass, 'HashAttrStore'), {});
            nqp::setmethcache($type, %methods);
            nqp::setmethcacheauth($type, 1);

            if 0 { #######################################################
            my @repr_info;
            my @type_info;
            nqp::push(@repr_info, @type_info);
            nqp::push(@type_info, $type);

            my @attrs;
            nqp::push(@type_info, @attrs);

            my @parents;
            nqp::push(@type_info, @parents);

            #nqp::push(@parents, MO::NodeClassHOW.type);

            my $protocol := nqp::hash();
            $protocol<attribute> := @repr_info;
            nqp::composetype($type, $protocol);
            } ############################################################
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

class MO::Node { # is repr('HashAttrStore')
    method keyed($keys) { self; }
    method named($name) { self; }
    method attribute($name) { self; }
}

class MO::FilesystemNode is MO::Node {
    has $!path;
    has $!name;
    has $!entries;
    has %!entries;
    has $!exists;
    has $!filesize;
    has $!isdir;
    has $!isreg;
    has $!isdev;
    has $!createtime;
    has $!accesstime;
    has $!modifytime;
    has $!changetime;
    has $!backuptime;
    has $!uid;
    has $!gid;
    has $!islnk;
    has $!platform_dev;
    has $!platform_inode;
    has $!platform_mode;
    has $!platform_nlinks;
    has $!platform_devtype;
    has $!platform_blocksize;
    has $!platform_blocks;

    method new(:$path) {
        my $o := nqp::create(self); #(MO::FilesystemNode);
        $o.BUILD(:path($path));
    }

    method pathname($path) {
        my $i := nqp::rindex($path, '/');
        my $name := nqp::substr($path, $i+1);
        $name;
    }

    method pathconcat($base, $leaf) {
        $base ~ '/' ~ $leaf;
    }

    method BUILD(:$path, :$name = nqp::null()) {
        $!path := $path;
        $!name := nqp::isnull($name) ?? self.pathname($path) !! $name;
        $!exists                    := nqp::stat($path, nqp::const::STAT_EXISTS);
        if $!exists {
            $!filesize              := nqp::stat($path, nqp::const::STAT_FILESIZE);
            $!isdir                 := nqp::stat($path, nqp::const::STAT_ISDIR);
            $!isreg                 := nqp::stat($path, nqp::const::STAT_ISREG);
            $!isdev                 := nqp::stat($path, nqp::const::STAT_ISDEV);
            $!createtime            := nqp::stat($path, nqp::const::STAT_CREATETIME);
            $!accesstime            := nqp::stat($path, nqp::const::STAT_ACCESSTIME);
            $!modifytime            := nqp::stat($path, nqp::const::STAT_MODIFYTIME);
            $!changetime            := nqp::stat($path, nqp::const::STAT_CHANGETIME);
            $!backuptime            := nqp::stat($path, nqp::const::STAT_BACKUPTIME);
            $!uid                   := nqp::stat($path, nqp::const::STAT_UID);
            $!gid                   := nqp::stat($path, nqp::const::STAT_GID);
            $!islnk                 := nqp::stat($path, nqp::const::STAT_ISLNK);
            $!platform_dev          := nqp::stat($path, nqp::const::STAT_PLATFORM_DEV);
            $!platform_inode        := nqp::stat($path, nqp::const::STAT_PLATFORM_INODE);
            $!platform_mode         := nqp::stat($path, nqp::const::STAT_PLATFORM_MODE);
            $!platform_nlinks       := nqp::stat($path, nqp::const::STAT_PLATFORM_NLINKS);
            $!platform_devtype      := nqp::stat($path, nqp::const::STAT_PLATFORM_DEVTYPE);
            $!platform_blocksize    := nqp::stat($path, nqp::const::STAT_PLATFORM_BLOCKSIZE);
            $!platform_blocks       := nqp::stat($path, nqp::const::STAT_PLATFORM_BLOCKS);
            #nqp::say(''~$!path~'; '~$!isdir~'; '~$!name~'; '~$!filesize);
        }
        self;
    }

    method path() {
        $!path;
    }

    method name() {
        $!name;
    }

    my method read_entries() {
#?if parrot
        my $names := pir::new__PS('OS').readdir($!path);
        $!entries := nqp::list();
        %!entries := nqp::hash();
        for $names {
            if $_ ne '.' && $_ ne '..' {
                my $node := self.new(self.pathconcat($!path, $_));
                $!entries.push($node);
                %!entries{$_} := $node;
            }
        }
#?endif
# #?if !parrot
#           my $dirh := nqp::opendir($path);
#           while $dirh {
#               my $elem := nqp::nextfiledir($dirh);
#               if nqp::isnull_s($elem) || nqp::chars($elem) == 0 {
#                   nqp::closedir($dirh);
#                   $dirh := nqp::null();
#                   last;
#               }
#           }
#           nqp::closedir($dirh);
# #?endif
    }

    method iterator() is parrot_vtable('get_iter') {
        if $!isdir {
            self.read_entries unless nqp::defined($!entries);
            nqp::iterator($!entries) if nqp::defined($!entries);
        }
    }

    method keyed($keys) {
        #nqp::say('keyed: '~$!path~', '~$keys);
        self;
    }

    method named($name) {
        %!entries{$name};
    }

    method attribute($name) {
        0;
    }
}
