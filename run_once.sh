#!/usr/bin/env bash
#
# Run a program and remove it after it.
#
$1 ${@:2}
mv -f "$1" "$1".deleted
exit 0
