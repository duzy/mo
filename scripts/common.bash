SRCDIR="$(dirname ${BASH_SOURCE[1]})"

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

function check() {
    local txt="$1"
    local out="$2"

    # IFS=$'\n' local txt_lines=($(cat $txt))
    # IFS=$'\n' local out_lines=($(cat $out))
    mapfile -t txt_lines < $txt
    mapfile -t out_lines < $out

    local okay=1
    for i in $(seq ${#out_lines[*]}); do
        [[ "${out_lines[$i-1]}" == "${txt_lines[$i-1]}" ]] || {
            echo '.wrong line #'$i':'
            echo "--output: ${out_lines[$i-1]}"
            echo "--expect: ${txt_lines[$i-1]}"
            okay=0
            break
        }
    done

    if [[ $okay == 1 && "${#out_lines[*]}" == "${#txt_lines[*]}" ]]; then
        echo '.ok'
    elif [[ "${#out_lines[*]}" != "${#txt_lines[*]}" ]]; then
        echo ".xx (want ${#txt_lines[*]} lines, but ${#out_lines[*]})"
    else
        echo '.xx'
    fi
}
