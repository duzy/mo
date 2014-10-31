#!/bin/bash

. scripts/common.bash

function run-android-examples() {
    for mo in \
        get-package-name \
        get-permissions \
        get-activities \
        get-intent-filters \
        use-namespace \
        ; do
        echo -n "test: $SRCDIR/$mo.mo.."
        ( run $SRCDIR/AndroidManifest.xml $SRCDIR/$mo.mo ) > $SRCDIR/$mo.out
        check $SRCDIR/$mo.txt $SRCDIR/$mo.out
    done
}

#        shared-lexical-for-rules

function run-normal-examples() {
    for mo in \
        proto-simple \
        proto-template \
        proto-run \
        many-run \
        class-test \
        rules \
        ; do
        echo -n "test: $SRCDIR/$mo.mo.."
        ( run $SRCDIR/$mo.mo ) > $SRCDIR/$mo.out
        check $SRCDIR/$mo.txt $SRCDIR/$mo.out
    done
}

run-android-examples
run-normal-examples
