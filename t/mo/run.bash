#!/bin/bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local PROVE="prove --nocolor -v --exec"
    local RUNNER="parrot -Igen -Lgen gen/mo.pbc"
    local NAME=$(dirname $1)/$1
    if [ -f "$1.xml" -a -f "$1.mo" ] ; then
        $PROVE "$RUNNER $1.xml" "$1.mo"
    elif [ -f "$1.mo" ] ; then
        $PROVE "$RUNNER $(dirname $1)/test.xml" "$1.mo"
    fi
    #parrot -Igen -Lgen gen/xml.pbc --target=pir $NAME.xml > $NAME.pir
    #parrot -Igen -Lgen gen/mo.pbc --target=pir $NAME.xml > $NAME.pir
    #parrot -Igen -Lgen gen/mo.pbc $NAME.xml $NAME.mo
    #parrot -Igen -Lgen gen/mo.pbc --target=pir $NAME.xml $NAME.mo > $NAME.pir
}

#run $SRCDIR/hello.xml $SRCDIR/hello.mo

run $SRCDIR/00-say
run $SRCDIR/01-control-cond
run $SRCDIR/01-control-loop
run $SRCDIR/10-dot-name
