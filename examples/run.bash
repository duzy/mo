#!/bin/bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local LIBDIR="gen"
    local RUNNER="parrot -I$LIBDIR -L$LIBDIR $LIBDIR/mo.pbc"
    $RUNNER $@
}

#run $SRCDIR/AndroidManifest.xml $SRCDIR/get-package-name.mo
#run $SRCDIR/AndroidManifest.xml $SRCDIR/get-permissions.mo
#run $SRCDIR/AndroidManifest.xml $SRCDIR/get-activities.mo
#run $SRCDIR/AndroidManifest.xml $SRCDIR/use-namespace.mo

#run $SRCDIR/proto-simple.mo
#run $SRCDIR/proto-template.mo
#run $SRCDIR/proto-run.mo
#run $SRCDIR/many-run.mo

run $SRCDIR/a.mo test

parrot -Igen -Lgen gen/mo.pbc --target=pir $SRCDIR/a.mo > $SRCDIR/a.pir
