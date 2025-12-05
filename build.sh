#!/usr/bin/bash

make clean

make prepare-env || exit 1
make host-tools || exit 1
make toolchain  || exit 1
make opensbi  || exit 1
make linux  || exit 1
make busybox  || exit 1
make sysvinit || exit 1
make coreutils || exit 1
make bash || exit 1
make vim || exit 1
make python3 || exit 1
make before-target-image || exit 1
make rebuild-target-image || exit 1
