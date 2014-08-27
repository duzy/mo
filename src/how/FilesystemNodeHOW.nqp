knowhow MO::FilesystemNodeHOW {
    my $type;

    method type() {
        unless $type {
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
            };
            %methods<children> := -> $node, $name = nqp::null() {
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
