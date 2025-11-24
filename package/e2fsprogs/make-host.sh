#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=e2fsprogs
PKGVERSION=1.47.2
PKGSOURCE_DIR=e2fsprogs
PKGSOURCE=e2fsprogs-1.47.2.tar.xz
PKGURL=http://mirrors.ustc.edu.cn/kernel.org/linux/kernel/people/tytso/e2fsprogs/v1.47.2/e2fsprogs-1.47.2.tar.xz

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
(cd ${PKGBUILD_DIR} && rm -rf config.cache; eval "${HOST_CONFIGURE_OPTS} ac_cv_path_LDCONFIG=true CONFIG_SITE=/dev/null ./configure --prefix=\"${HOST_DIR}\" --sysconfdir=\"${HOST_DIR}/etc\" --localstatedir=\"${HOST_DIR}/var\" --enable-shared --disable-static --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --disable-debug --with-xmlto=no --with-fop=no --disable-nls --disable-dependency-tracking  --disable-defrag --disable-e2initrd-helper --disable-fuse2fs --disable-fsck --disable-libblkid --disable-libuuid --disable-testio-debug --enable-symlink-install --enable-elf-shlibs --with-crond-dir=no --with-udev-rules-dir=no --with-systemd-unit-dir=no")
step_end configure

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  -C ${PKGBUILD_DIR}"
step_end build

step_start install-host
eval "${HOST_MAKE_ENV} /usr/bin/make -j1  -C ${PKGBUILD_DIR} install install-libs"
# Remove compile_et which raises a build failure with samba4
rm -f ${HOST_DIR}/bin/compile_et
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
