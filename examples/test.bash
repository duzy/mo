#!/bin/bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local LIBDIR="gen"
    local RUNNER="parrot -I$LIBDIR -L$LIBDIR $LIBDIR/mo.pbc"
    $RUNNER $@
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

    if [[ $okay == 1 ]]; then
        echo '.ok'
    fi
}

for mo in \
    get-package-name \
    get-permissions \
    get-activities \
    get-intent-filters \
    use-namespace \
    ; do
    echo -n "test: $SRCDIR/$mo.mo.."
    ( run $SRCDIR/AndroidManifest.xml $SRCDIR/$mo.mo ) > $SRCDIR/$mo.out
    check $SRCDIR/$mo.txt $SRCDIR/$mo.out
done

for mo in \
    proto \
    proto-template \
    ; do
    echo -n "test: $SRCDIR/$mo.mo.."
    ( run $SRCDIR/$mo.mo ) > $SRCDIR/$mo.out
    check $SRCDIR/$mo.txt $SRCDIR/$mo.out
done
