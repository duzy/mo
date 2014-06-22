#!/bin/bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local RUNNER="parrot -Igen -Lgen gen/mo.pbc"
    local NAME=$(dirname $1)/$(basename $1 .xml)
    prove --nocolor -v --exec "$RUNNER $1" $2
    parrot gen/xml.pbc --target=pir $NAME.xml > $NAME.pir
    #parrot gen/mo.pbc --target=pir $NAME.xml > $NAME.pir
}

run $SRCDIR/hello.xml $SRCDIR/hello.mo
