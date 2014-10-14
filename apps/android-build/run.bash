#!/bin/bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local LIBDIR="gen"
    local RUNNER="parrot -I$LIBDIR -L$LIBDIR $LIBDIR/mo.pbc"
    $RUNNER $@
}

run $SRCDIR/main.mo $SRCDIR/hello $SRCDIR/hello2
