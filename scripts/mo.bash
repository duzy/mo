#!/bin/bash
SRCDIR="$(dirname $BASH_SOURCE)"
MR="$(dirname $(dirname $BASH_SOURCE))"

function mo() {
    local d=$MR/gen/parrot
    parrot -I$d -L$d $d/mo.pbc $@
}

function mo-android-build() {
    mo $MR/apps/android-build/main.mo $@
}
