#!/bin/bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local X=/tmp/t.nqp
    local BOOT=$SRCDIR/bootstrap.nqp.tmp
    local RUNNER="nqp-p --module-path=gen $X"
    local NAME=$(dirname $1)/$(basename $1 .xml)
    (
        echo "#! nqp"
        sed -e "s|<filename>|${NAME}.xml|" $BOOT
        cat $NAME.t
    ) > $X
    prove --nocolor -v --exec "$RUNNER" $NAME.xml
}

run $SRCDIR/simple.xml
