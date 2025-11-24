#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=util-linux
PKGVERSION=2.41.1
PKGSOURCE_DIR=util-linux
PKGSOURCE=util-linux-2.41.1.tar.xz
PKGURL=http://mirrors.ustc.edu.cn/kernel.org/linux/utils/util-linux/v2.41/util-linux-2.41.1.tar.xz

PKGBUILDNAME=host-${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
xzcat ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

stamp_patched autotools

step_start configure
(cd ${PKGBUILD_DIR} && rm -rf config.cache; eval "${HOST_CONFIGURE_OPTS} CONFIG_SITE=/dev/null ./configure --prefix=\"${HOST_DIR}\" --sysconfdir=\"${HOST_DIR}/etc\" --localstatedir=\"${HOST_DIR}/var\" --enable-shared --disable-static --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --disable-debug --with-xmlto=no --with-fop=no --disable-nls --disable-dependency-tracking  --without-systemd --with-systemdsystemunitdir=no --without-python --enable-libblkid --enable-libmount --enable-libuuid --without-libmagic --without-ncurses --without-ncursesw --without-tinfo --disable-raw --disable-makeinstall-chown --disable-agetty --disable-chfn-chsh --disable-chmem --disable-ipcmk --disable-liblastlog2 --disable-login --disable-lsfd --disable-lslogins --disable-mesg --disable-more --disable-newgrp --disable-nologin --disable-nsenter --disable-pg --disable-rfkill --disable-runuser --disable-schedutils --disable-setpriv --disable-setterm --disable-su --disable-sulogin --disable-tunelp --disable-ul --disable-unshare --disable-uuidd --disable-vipw --disable-wall --disable-wdctl --disable-write --disable-zramctl")
step_end configure

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  -C ${PKGBUILD_DIR}"
step_end build

step_start install-host
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} install -C ${PKGBUILD_DIR}"
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
