#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=ncurses
PKGVERSION=6.5-20250720
PKGSOURCE_DIR=ncurses
PKGSOURCE=ncurses-6.5-20250720.tar.gz
PKGURL=https://github.com/ThomasDickey/ncurses-snapshots/archive/v6_5_20250720/ncurses-6.5-20250720.tar.gz

PKGBUILDNAME=host-${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
gzip -d -c ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

stamp_patched autotools

step_start configure
(cd ${PKGBUILD_DIR} && rm -rf config.cache; eval "${HOST_CONFIGURE_OPTS} ac_cv_path_LDCONFIG=\"\" CONFIG_SITE=/dev/null ./configure --prefix=\"${HOST_DIR}\" --sysconfdir=\"${HOST_DIR}/etc\" --localstatedir=\"${HOST_DIR}/var\" --enable-shared --disable-static --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --disable-debug --with-xmlto=no --with-fop=no --disable-nls --disable-dependency-tracking  --with-shared --without-gpm --without-manpages --without-cxx --without-cxx-binding --without-ada --with-default-terminfo-dir=/usr/share/terminfo --disable-db-install --without-normal")
step_end configure

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  -C ${PKGBUILD_DIR}"
step_end build

step_start install-host
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} install -C ${PKGBUILD_DIR}"
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
