# knowhow MO::ModuleHOW { }
class MO::ModuleLoader {
    my %modules_loaded;
    my @modules_loading;

    sub pathconcat($base, $leaf) {
        $base ~ '/' ~ $leaf;
    }

    sub read_dir_sources($path) {
        my @sources;
        my @names := pir::new__PS('OS').readdir($path);
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
            $prefix := "$prefix/" unless $prefix ~~ / \/$ /;
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

    my method compile_source_file($file) {
        my $*CTX := nqp::null();
        my $*CTXSAVE := self;
        my $?FILES := $file;
        my $source := self.load_source($file);
        my $eval := nqp::getcomp('mo').compile($source);
        $eval();
        $*CTX;
    }

    method create_module() {
        # MO::ModuleHOW.new_type(:name<Module>);
        nqp::knowhow().new_type(:name<Module>);
    }

    method load_module($module_name, *@GLOBALish, :$line, :$file, :%chosen) {
        unless %chosen {
            %chosen := self.locate_module($module_name, ['t/mo/', 'examples/']);
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
                nqp::loadbytecode(%chosen<load>);
                @module_ctx.push( $*CTX );
            } elsif %chosen<source> {
                @module_ctx.push( self.compile_source_file(%chosen<source>) );
            } elsif %chosen<sources> {
                for %chosen<sources> {
                    if nqp::defined(%modules_loaded{$_}) {
                        @module_ctx.push( $_ ) for %modules_loaded{$_};
                    } else {
                        @modules_loading.push($_);
                        my $ctx := self.compile_source_file($_);
                        @module_ctx.push( $ctx );
                        %modules_loaded{$_} := nqp::list($ctx);
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
            my $module := self.create_module; # create a new container for symbols
            my int $i := 0;
            while $i < $mn {
                my $unit := nqp::ctxlexpad(@module_ctx[$i]);
                for $unit<EXPORT>.WHO {
                    $module.WHO{$_.key} := $_.value;
                }
                $i := $i + 1;
            }
            @GLOBALish[0].WHO{$final} := $module;
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
