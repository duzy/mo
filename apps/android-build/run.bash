#!/bin/bash

. scripts/common.bash

if true; then
    run $SRCDIR/main.mo $SRCDIR/hello $SRCDIR/hello2
else
    run $SRCDIR/m.mo $SRCDIR/hello $SRCDIR/hello2
fi
