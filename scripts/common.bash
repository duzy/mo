if [[ "x$vm" = "x" ]]; then
    echo 'error: $vm is empty'
    exit -1
fi

function mo-cmd-parrot() {
    echo "parrot -I$1 -L$1 $1/mo.pbc"
}

function mo-cmd-moar() {
    local P="$(dirname $(dirname $(which moar)))"
    echo "moar --libpath=$P/languages/nqp/lib --libpath=$1 $1/mo.moarvm"
}

function mo-cmd() {
    local D="gen/$vm"
    if true; then
        mo-cmd-$vm $D $@
    else
        echo '--------------------------------------------------------------'
        echo "gdb -i=mi --args $(mo-cmd-$vm $D) $@"
        echo '--------------------------------------------------------------'
        # gdb --args $(mo-cmd-$vm $D) $@
    fi
}

function run() {
    $(mo-cmd) $@
}
