#!/bin/bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local X=/tmp/t.nqp
    local BOOT=$SRCDIR/bootstrap.nqp.in
    local RUNNER="nqp-p --module-path=gen $X"
    local NAME=$(dirname $1)/$(basename $1 .t)
    (
        echo "#! nqp"
        cat $BOOT \
            | sed -e "s|<engine>|gen/xml.pbc|" \
            | sed -e "s|<filename>|${NAME}.xml|"
        cat $NAME.t
    ) > $X
    prove --nocolor -v --exec "$RUNNER" $1
    parrot gen/xml.pbc --target=pir $NAME.xml > $NAME.pir
}

run $SRCDIR/simple.t
