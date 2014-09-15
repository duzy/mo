class MO::ModuleLoader {
    my %modules_loaded;

    method locate_module($module_name, @prefixes) {
        my @names := nqp::split('::', $module_name);
        my $base_path := nqp::join('/', @names);
        my $pbc_path := "$base_path.pbc";
        my $pir_path := "$base_path.pir";
        my $mo_path := "$base_path.mo";
        my %res;

        for @prefixes -> $prefix {
            my $have_pir := nqp::stat("$prefix/$pir_path", 0);
            my $have_pbc := nqp::stat("$prefix/$pbc_path", 0);
            my $have_mo := nqp::stat("$prefix/$mo_path", 0);
            if $have_mo {
                %res<key>    := "$prefix/$mo_path";
                %res<source> := "$prefix/$mo_path";
                if $have_pir && nqp::stat("$prefix/$pir_path", 7) >= nqp::stat("$prefix/$mo_path", 7) {
                    %res<load> := "$prefix/$pir_path";
                } elsif $have_pbc && nqp::stat("$prefix/$pbc_path", 7) >= nqp::stat("$prefix/$mo_path", 7) {
                    %res<load> := "$prefix/$pbc_path";
                }
                last;
            } elsif $have_pir {
                %res<key>  := "$prefix/$pir_path";
                %res<load> := "$prefix/$pir_path";
            } elsif $have_pbc {
                %res<key>  := "$prefix/$pbc_path";
                %res<load> := "$prefix/$pbc_path";
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

    method load_module($module_name, %opts, *@GLOBALish, :$line, :$file, :%chosen) {
        unless %chosen {
            %chosen := self.locate_module($module_name, ['t/mo/']);
        }

        if %chosen<load> {
            my $*CTX := nqp::null();
            my $*CTXSAVE := self;
            nqp::loadbytecode(%chosen<load>);
        } elsif %chosen<source> {
            my $*CTX := nqp::null();
            my $*CTXSAVE := self;
            my $source := self.load_source(%chosen<source>);
            my $code := nqp::getcomp('mo').compile($source);
            $code();
        } else {
            nqp::die("missing module $module_name");
        }
    }

    method ctxsave() {
        $*CTX := nqp::ctxcaller(nqp::ctx());
        $*CTXSAVE := nqp::null();
    }
}

# We stash this in the MO HLL namespace, just so it's easy to
# locate. Note this makes it invisible inside Perl 6 itself.
nqp::bindhllsym('mo', 'ModuleLoader', MO::ModuleLoader);
