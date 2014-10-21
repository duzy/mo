#!/bin/bash

. scripts/common.bash

SRCDIR="$(dirname $BASH_SOURCE)"

run $SRCDIR/main.mo $SRCDIR/hello $SRCDIR/hello2
