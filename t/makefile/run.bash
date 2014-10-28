#!/bin/bash

. scripts/common.bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local L="gen/parrot"
    local PROVE="prove --failures --nocolor --exec"
    local RUNNER="parrot -I$L -L$L $L/makefile.pbc"
    local NAME=$(dirname $1)/$1
    $PROVE "$RUNNER" "$SRCDIR/$1.mk"
}

run 00
