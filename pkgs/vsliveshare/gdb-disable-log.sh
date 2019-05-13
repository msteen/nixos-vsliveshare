#!/usr/bin/env bash
fd=$(lsof -p "$1" | grep 'type=DGRAM' | sed -n 's/.*[^0-9]\([0-9]*\)u *unix.*/\1/p')
whoami > /dev/pts/4
if [[ -n $fd ]]; then
  gdb --batch -p "$1" \
    -ex 'call (int)open("/dev/null", 1)' \
    -ex 'call (int)dup2($1, '$fd')' \
    -ex 'call (int)close($1)' \
    > /dev/pts/4 2>&1
fi
