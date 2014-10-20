# knowhow MO::ModuleHOW { }
class MO::PTP { # point-to-package
    has $!pkg;

    method new($pkg) {
        my $o := nqp::create(self);
        nqp::bindattr($o, MO::PTP, '$!pkg', $pkg);
        $o;
    }

    method pkg() { $!pkg }
}

class MO::ModuleLoader {
    my %modules_loaded;
    my @modules_loading;

    method get_prefixes() {
        my $file := nqp::getlexdyn('$?FILES');
        my @prefixes := nqp::clone($*SEARCHPATHS);
        my int $i := nqp::isstr($file) ?? nqp::rindex($file, '/') !! -1;
        if 0 <= $i {
            my $s := nqp::substr($file, 0, $i+1);
            $s := nqp::cwd ~ '/' ~ $s if $s[0] ne '/';
            for @prefixes {
                if $s eq $_ || $s eq "$_/" {
                    $s := ''; last;
                }
            }
            @prefixes.unshift($s) if $s ne '';
        }
        @prefixes;
    }

    sub pathconcat($base, $leaf) {
        $base ~ '/' ~ $leaf;
    }

    sub read_dir_sources($path) {
        my @sources;
        my @names := VMCall::readdir($path);
        for @names {
            if $_ ne '.' && $_ ne '..' && $_ ~~ / .*\.mo$ / {
                @sources.push(pathconcat($path, $_));
            }
        }
        @sources
    }

    method locate_module($module_name, @prefixes) {
        my @names := nqp::split('::', $module_name);
        my $base_path := nqp::join('/', @names);
        my $pbc_path := "$base_path.pbc";
        my $pir_path := "$base_path.pir";
        my $mo_path := "$base_path.mo";
        my %res;

        for @prefixes -> $prefix {
            $prefix := "$prefix/" unless $prefix[nqp::chars($prefix)-1] eq '/'; #$prefix ~~ / \/$ /;
            my $have_pir  := nqp::stat("$prefix$pir_path",  nqp::const::STAT_EXISTS);
            my $have_pbc  := nqp::stat("$prefix$pbc_path",  nqp::const::STAT_EXISTS);
            my $have_mo   := nqp::stat("$prefix$mo_path",   nqp::const::STAT_EXISTS);
            my $have_base := nqp::stat("$prefix$base_path", nqp::const::STAT_EXISTS);
            my $is_base_dir := $have_base && nqp::stat("$prefix$base_path", nqp::const::STAT_ISDIR);
            if $have_mo {
                %res<key>    := "$prefix$mo_path";
                %res<source> := "$prefix$mo_path";
                if $have_pir && nqp::stat("$prefix$pir_path", 7) >= nqp::stat("$prefix$mo_path", 7) {
                    %res<load> := "$prefix$pir_path";
                } elsif $have_pbc && nqp::stat("$prefix$pbc_path", 7) >= nqp::stat("$prefix$mo_path", 7) {
                    %res<load> := "$prefix$pbc_path";
                }
                last;
            } elsif $have_pir {
                %res<key>  := "$prefix$pir_path";
                %res<load> := "$prefix$pir_path";
            } elsif $have_pbc {
                %res<key>  := "$prefix$pbc_path";
                %res<load> := "$prefix$pbc_path";
            } elsif $is_base_dir {
                %res<key>     := "$prefix$base_path";
                %res<sources> := read_dir_sources("$prefix$base_path");
            }
        }

        %res;
    }

    method load_source($filename) {
#?if parrot
        my $fh := nqp::open("$filename", 'r');
        $fh.encoding('utf8');
        my $source := $fh.readall();
        $fh.close();
#?endif
#?if !parrot
        # my $fh := nqp::open("$filename", 'r');
        # nqp::setencoding($fh, 'utf8');
        # my $source := nqp::readallfh($fh);
        # nqp::closefh($fh);
#?endif
        $source;
    }

    my method eval_source_file($file, @params) {
        @params := nqp::clone(@params);
        @params.unshift($file);
        my $*CTX := nqp::null();
        my $*CTXSAVE := self;
        my $*MODULE_PARAMS := @params;
        my $?FILES := $file;
        my $source := self.load_source($file);
        my $eval := nqp::getcomp('mo').compile($source);
        $eval(|@params);
        $*MODULE_PARAMS := nqp::null();
        $*CTX;
    }

    sub compute_module_name($filename) {
        my int $dot := nqp::rindex($filename, '.');
        my int $beg := nqp::rindex($filename, '/') + 1;
        nqp::substr($filename, $beg, $dot)
    }

    method create_module($name) {
        # MO::ModuleHOW.new_type(:name<Module>);
        nqp::knowhow().new_type(:$name);
    }

    method load_module($module_name, @params, *@GLOBALish, :$line, :$file, :%chosen) {
        unless %chosen {
            %chosen := self.locate_module($module_name, self.get_prefixes);
        }

        for @modules_loading {
            if %chosen<key> eq $_ {
                $file := nqp::getlexdyn('$?FILES') unless nqp::defined($file);
                $file := '?' unless nqp::defined($file);
                nqp::die('recursive loading modules: '~$file~', '~%chosen<key>);
            }
        }

        my @module_ctx;
        if nqp::defined(%modules_loaded{%chosen<key>}) {
            @module_ctx := %modules_loaded{%chosen<key>};
        } else {
            @modules_loading.push(%chosen<key>);
            if %chosen<load> {
                my $*CTX := nqp::null();
                my $*CTXSAVE := self;
                my $*MODULE_PARAMS := nqp::clone(@params);
                $*MODULE_PARAMS.unshift(%chosen<load>);
                nqp::loadbytecode(%chosen<load>);
                $*MODULE_PARAMS := nqp::null();

                my $module_name := compute_module_name(%chosen<load>);
                @module_ctx.push( [$module_name, $*CTX] );
            } elsif %chosen<source> {
                my $module_name := compute_module_name(%chosen<source>);
                my $module_ctx := self.eval_source_file(%chosen<source>, @params);
                @module_ctx.push( [$module_name, $module_ctx] );
            } elsif %chosen<sources> {
                for %chosen<sources> {
                    if nqp::defined(%modules_loaded{$_}) {
                        @module_ctx.push( $_ ) for %modules_loaded{$_};
                    } else {
                        @modules_loading.push($_);
                        my $module_name := compute_module_name($_);
                        my $module_ctx := self.eval_source_file($_, @params);
                        @module_ctx.push( [$module_name, $module_ctx] );
                        %modules_loaded{$_} := nqp::list([$module_name, $module_ctx]);
                        @modules_loading.pop;
                    }
                }
            } else {
                nqp::die("missing module $module_name");
            }
            %modules_loaded{%chosen<key>} := @module_ctx;
            @modules_loading.pop;
        }

        my int $mn := +@module_ctx;
        if $mn && +@GLOBALish {
            # Make a symbole for the loaded module.
            my @name := nqp::split('::', $module_name);
            my $final := @name[+@name - 1];
            if 0 {
                my $unit := nqp::ctxlexpad(@module_ctx[0][1]);
                @GLOBALish[0].WHO{$final} := $unit<EXPORT>;
            } else {
                my $module := self.create_module($final); # create a new container for symbols
                my int $i := 0;
                while $i < $mn {
                    my @m := @module_ctx[$i];
                    my $unit := nqp::ctxlexpad(@m[1]);
                    for $unit<EXPORT>.WHO {
                        if nqp::existskey($module.WHO, $_.key) {
                            my $s := $module.WHO{$_.key};
                            # TODO: report line number where it's defined
                            nqp::die($_.key ~ " already defined in "~nqp::substr($s, 1));
                        }

                        # alias -- point-to-package(PTP)
                        $module.WHO{$_.key} := MO::PTP.new($unit<EXPORT>);
                    }
                    $i := $i + 1;
                }
                @GLOBALish[0].WHO{$final} := $module;
            }
        }

        @module_ctx;
    }

    method ctxsave() {
        $*CTX := nqp::ctxcaller(nqp::ctx());
        $*CTXSAVE := nqp::null();
    }
}

# We stash this in the MO HLL namespace, just so it's easy to
# locate. Note this makes it invisible inside Perl 6 itself.
nqp::bindhllsym('mo', 'ModuleLoader', MO::ModuleLoader);
