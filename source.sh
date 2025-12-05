#!/usr/bin/bash

export ONLY_DOWNLOAD=y

./package/bison/make-host.sh || exit 1
./package/gcc/make-final.sh || exit 1
./package/glibc/make.sh || exit 1
./package/m4/make-host.sh || exit 1
./package/gawk/make-host.sh || exit 1
./package/binutils/make-host.sh || exit 1
./package/gmp/make-host.sh || exit 1
./package/autoconf/make-host.sh || exit 1
./package/libtool/make-host.sh || exit 1
./package/automake/make-host.sh || exit 1
./package/mpc/make-host.sh || exit 1
./package/mpfr/make-host.sh || exit 1
./package/linux/make.sh || exit 1
./package/busybox/make.sh || exit 1
./package/e2fsprogs/make-host.sh || exit 1
./package/pkgconf/make-host.sh || exit 1
./package/util-linux/make-host.sh || exit 1
./package/libzlib/make-host.sh || exit 1
./package/kmod/make-host.sh || exit 1
./package/patchelf/make-host.sh || exit 1
./package/opensbi/make.sh || exit 1
./package/acl/make-host.sh || exit 1
./package/attr/make-host.sh || exit 1
./package/fakeroot/make-host.sh || exit 1
./package/flex/make-host.sh || exit 1
./package/gettext-tiny/make-host.sh || exit 1
./package/libxcrypt/make.sh || exit 1
./package/sysvinit/make.sh || exit 1
./package/coreutils/make.sh || exit 1
./package/ncurses/make-host.sh || exit 1
./package/readline/make.sh || exit 1
./package/bash/make.sh || exit 1
./package/vim/make.sh || exit 1
./package/libffi/make.sh || exit 1
./package/autoconf-archive/make-host.sh || exit 1
./package/expat/make-host.sh || exit 1
./package/python3/make-host.sh || exit 1
