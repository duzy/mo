#!/bin/bash

. scripts/common.bash

SRCDIR="$(dirname $BASH_SOURCE)"

function run() {
    local PROVE="prove $2 --failures --nocolor --exec "
    local RUNNER="$(mo-cmd)"
    local NAME=$(dirname $1)/$1
    if [ -f "$1.xml" -a -f "$1.mo" ] ; then
        $PROVE "$RUNNER $1.xml" "$1.mo"
    elif [ -f "$1.mo" ] ; then
        $PROVE "$RUNNER $(dirname $1)/test.xml" "$1.mo"
    fi
    $RUNNER --target=pir $(dirname $1)/test.xml $1.mo > $1.pir
}

#run $SRCDIR/hello.xml $SRCDIR/hello.mo

if true ; then
    run $SRCDIR/00 -v
    if [[ "$TESTALL" != '1' ]]; then
        exit
    fi
fi

run $SRCDIR/00-say
run $SRCDIR/00-args
run $SRCDIR/00-expression
run $SRCDIR/00-map
run $SRCDIR/01-control-any
run $SRCDIR/01-control-any-2
run $SRCDIR/01-control-many
run $SRCDIR/01-control-cond
run $SRCDIR/01-control-cond-expr
run $SRCDIR/01-control-loop
run $SRCDIR/01-control-loop-for
run $SRCDIR/09-bare-select
run $SRCDIR/10-dot-dot
run $SRCDIR/10-dot-name
run $SRCDIR/10-dot-set
run $SRCDIR/10-arrow-name
run $SRCDIR/10-arrow-name-many
run $SRCDIR/10-arrow-many
run $SRCDIR/11-with
run $SRCDIR/11-with-var
#run $SRCDIR/12-data-namespace
run $SRCDIR/20-var-initializer
run $SRCDIR/20-var
run $SRCDIR/21-can
run $SRCDIR/30-template
run $SRCDIR/30-template-generate
run $SRCDIR/30-template-with
run $SRCDIR/30-template-if
run $SRCDIR/30-template-for
run $SRCDIR/40-filesystem
run $SRCDIR/41-io
run $SRCDIR/41-io-open
run $SRCDIR/41-io-pipe
run $SRCDIR/41-io-print
run $SRCDIR/41-io-shell
run $SRCDIR/41-io-system
#run $SRCDIR/44-filesystem-make
#run $SRCDIR/44-filesystem-make-rule
#run $SRCDIR/44-filesystem-make-rule-2
run $SRCDIR/45-rules
run $SRCDIR/50-funs
run $SRCDIR/50-fun-returns
run $SRCDIR/50-fun-lexical
run $SRCDIR/50-fun-lexical-nested
run $SRCDIR/60-module
run $SRCDIR/60-module-params
run $SRCDIR/60-module-init
run $SRCDIR/60-module-init-2
run $SRCDIR/60-module-load
run $SRCDIR/61-class
run $SRCDIR/61-class-ctor-params
run $SRCDIR/61-class-ctor-params-2
run $SRCDIR/61-class-static-variable
run $SRCDIR/70-lang-xml
run $SRCDIR/70-lang-xml-in
run $SRCDIR/70-lang-xml-escape-1
run $SRCDIR/70-lang-xml-escape-2
run $SRCDIR/70-lang-shell
run $SRCDIR/70-lang-shell-2
run $SRCDIR/70-lang-shell-escape
exit
run $SRCDIR/40-filesystem-filter -v
run $SRCDIR/40-filesystem-selectors -v
run $SRCDIR/40-filesystem-wildcard -v
run $SRCDIR/70-builtin-model-path -v
run $SRCDIR/70-builtin-model-json -v
run $SRCDIR/70-builtin-model-xml -v
