#!/bin/bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local PROVE="prove $2 --failures --nocolor --exec "
    local RUNNER="parrot -Igen -Lgen gen/mo.pbc"
    local NAME=$(dirname $1)/$1
    if [ -f "$1.xml" -a -f "$1.mo" ] ; then
        $PROVE "$RUNNER $1.xml" "$1.mo"
    elif [ -f "$1.mo" ] ; then
        $PROVE "$RUNNER $(dirname $1)/test.xml" "$1.mo"
    fi
    #parrot -Igen -Lgen gen/xml.pbc --target=pir $(dirname $1)/test.xml > $1.pir
    parrot -Igen -Lgen gen/mo.pbc --target=pir $(dirname $1)/test.xml $1.mo > $1.pir
}

#run $SRCDIR/hello.xml $SRCDIR/hello.mo

if true ; then
    run $SRCDIR/00 -v
    exit
fi

run $SRCDIR/00-say
run $SRCDIR/01-control-cond
run $SRCDIR/01-control-cond-expr
run $SRCDIR/01-control-loop
run $SRCDIR/01-control-loop-for
run $SRCDIR/10-dot-dot
run $SRCDIR/10-dot-name
run $SRCDIR/10-arrow-name
run $SRCDIR/10-arrow-name-many
run $SRCDIR/10-arrow-many
run $SRCDIR/11-with
run $SRCDIR/11-with-var
run $SRCDIR/20-var
run $SRCDIR/21-can
run $SRCDIR/30-template
run $SRCDIR/40-filesystem
run $SRCDIR/41-io
run $SRCDIR/50-funs
run $SRCDIR/50-fun-returns
run $SRCDIR/50-fun-lexical
run $SRCDIR/50-fun-lexical-nested
exit
run $SRCDIR/40-filesystem-filter -v
run $SRCDIR/40-filesystem-selectors -v
run $SRCDIR/40-filesystem-wildcard -v
run $SRCDIR/70-builtin-model-path -v
run $SRCDIR/70-builtin-model-json -v
run $SRCDIR/70-builtin-model-xml -v
