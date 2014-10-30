#!/bin/bash

. scripts/common.bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local L="gen/parrot"
    local PROVE="prove --failures --nocolor --exec"
    local RUNNER="parrot -I$L -L$L $L/makefile.pbc"
    $PROVE "$RUNNER" "$SRCDIR/$1.mk" -v
    $RUNNER --target=pir $SRCDIR/$1.mk 1>$SRCDIR/$1.pir 2>/dev/null
}

run 00
