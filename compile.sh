#!/bin/bash
set -e

build() {
    name=$1; linemode=$2; palbuild=$3
    printf "\n=== $name  (LINEMODE=$linemode PALBUILD=$palbuild) ===\n"
    wla-z80 -D LINEMODE=$linemode -D PALBUILD=$palbuild -o "$name.o" main.asm
    printf '[objects]\n%s\n' "$name.o" > "$name.link"
    wlalink -r -v -S "$name.link" "$name.sms"
    rm $name.link $name.o
}

build smb           0 0
build smbPAL        0 1
build smb224p       1 0
build smbPAL240p    2 1
