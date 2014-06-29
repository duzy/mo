#!/bin/bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local RUNNER="parrot -Igen -Lgen gen/mo.pbc"
    local NAME=$(dirname $1)/$(basename $1 .xml)
    prove --nocolor -v --exec "$RUNNER $1" $2
    #parrot -Igen -Lgen gen/xml.pbc --target=pir $NAME.xml > $NAME.pir
    #parrot -Igen -Lgen gen/mo.pbc --target=pir $NAME.xml > $NAME.pir
    #parrot -Igen -Lgen gen/mo.pbc $NAME.xml $NAME.mo
    #parrot -Igen -Lgen gen/mo.pbc --target=pir $NAME.xml $NAME.mo > $NAME.pir
}

run $SRCDIR/00-say.xml $SRCDIR/00-say.mo

#run $SRCDIR/hello.xml $SRCDIR/hello.mo
