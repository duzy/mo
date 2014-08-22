# my native NodeList is repr('QRPA') { }
class MO::Model {
    my $instance;
    method get() { $instance; }

    has $!root;
    has $!current;

    method init($data) {
        my $one := nqp::create(self);
        $one.BUILD( :data($data) );
        $instance := $one;
    }

    method BUILD(:$data){
        $!root := $data;
        $!current := $data;
    }

    method root() {
        $!root;
    }

    method current() {
        $!current;
    }

    my sub pathname($path) {
        my $i := nqp::rindex($path, '/');
        my $name := nqp::substr($path, $i+1);
        $name;
    }

    my sub pathconcat($base, $leaf) {
        $base ~ '/' ~ $leaf;
    }

    method dot($name, $node) { # .name, node.attribute
        $node := nqp::atpos($node, 0) if nqp::islist($node);
        # if nqp::istype($node, MO::Node) {
        #     $node.attribute($name);
        # } else {
            $name := '.'~$name unless $name eq '';
            nqp::getattr($node, $node, $name);
        # }
    }

    method arrow($name, $node) { # ->child, ->child[pos], parent->child
        $node := nqp::atpos($node, 0) if nqp::islist($node);
        # if nqp::istype($node, MO::Node) {
        #     $node.named($name);
        # } else {
            nqp::getattr($node, $node, $name); # if !nqp::isnull($node);
        # }
    }

    method path($path, $parent) {
        #my $node := MO::FilesystemNode.new(:path($path));
        my $node := nqp::create(MO::NodeClassHOW.type);
        # TODO: .. 
        $node;
    }

    method keyed($keys, $nodes) { # [0], [1, 2, 3], ['key1', 'key2']
        # if nqp::istype($nodes, MO::Node) {
        #     $nodes.keyed($keys);
        # } elsif nqp::islist($keys) {
        if nqp::islist($keys) {
            my $list := nqp::list();
            $list.push(nqp::atpos($nodes, $_)) for $keys;
            $list;
        } else {
            nqp::atpos($nodes, $keys);
        }
    }

    method filter($selector, $nodes) { # ->child{ ... }
        my $list := nqp::list();
        if nqp::islist($nodes) {
            $list.push($_) if !nqp::isnull($_) && $selector($_) for $nodes;
        } else {
            $list.push($nodes) if !nqp::isnull($nodes) && $selector($nodes);
        }
        $list;
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
