#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=libzlib
PKGVERSION=1.3.1
PKGSOURCE_DIR=libzlib
PKGSOURCE=zlib-1.3.1.tar.xz
PKGURL=https://www.zlib.net/zlib-1.3.1.tar.xz

PKGBUILDNAME=host-${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
xzcat ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

stamp_patched

step_start configure
(cd ${PKGBUILD_DIR}; rm -rf config.cache; eval "${HOST_CONFIGURE_OPTS} ./configure --prefix=\"${HOST_DIR}\" --sysconfdir=\"${HOST_DIR}/etc\"")
step_end configure

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j1  -C ${PKGBUILD_DIR}"
step_end build

step_start install-host
eval "${HOST_MAKE_ENV} /usr/bin/make -j1  -C ${PKGBUILD_DIR} LDCONFIG=true install"
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
