#!/bin/bash

. scripts/common.bash

function run() {
    local L="gen/parrot"
    local PROVE="prove --failures --nocolor --exec"
    local RUNNER="parrot -I$L -L$L $L/makefile.pbc"
    #$PROVE "$RUNNER" "$SRCDIR/$1.mk" -v

    echo -n "test: $SRCDIR/$1.."
    ( make -s -f "$SRCDIR/$1.mk" ) 1>$SRCDIR/$1.txt 2>$SRCDIR/$1.err
    ( $RUNNER "$SRCDIR/$1.mk"    ) 1>$SRCDIR/$1.out 2>$SRCDIR/$1.oer
    check $SRCDIR/$1.txt $SRCDIR/$1.out

    echo -n "errr: $SRCDIR/$1.."
    check $SRCDIR/$1.err $SRCDIR/$1.oer

    test -f $SRCDIR/$1.bash && bash $SRCDIR/$1.bash

    $RUNNER --target=pir $SRCDIR/$1.mk 1>$SRCDIR/$1.pir 2>/dev/null
}

run 00
