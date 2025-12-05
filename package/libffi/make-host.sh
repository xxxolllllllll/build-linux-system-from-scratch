#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=libffi
PKGVERSION=3.4.8
PKGSOURCE_DIR=libffi
PKGSOURCE=libffi-3.4.8.tar.gz
PKGURL=https://github.com/libffi/libffi/releases/download/v3.4.8/libffi-3.4.8.tar.gz

PKGBUILDNAME=host-${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
gzip -d -c ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

step_start patch
TAR="tar" PATH=${HOST_DIR}/bin:$PATH ${PROJECT_DIR}/support/scripts/apply-patches.sh ${PKGBUILD_DIR} ${PROJECT_DIR}/package/${PKGNAME} \*.patch
step_end patch autotools ignore_libtool_patch

step_start configure
echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Autoreconfiguring"
cd ${PKGBUILD_DIR} && eval "AUTOPOINT=/bin/true ${AUTORECONF_OPTS} ${HOST_DIR}/bin/autoreconf -f -i" 
patch_libtool ${PKGBUILD_DIR}
(cd ${PKGBUILD_DIR} && rm -rf config.cache; eval "${HOST_CONFIGURE_OPTS} CONFIG_SITE=/dev/null ./configure --prefix=\"${HOST_DIR}\" --sysconfdir=\"${HOST_DIR}/etc\" --localstatedir=\"${HOST_DIR}/var\" --enable-shared --disable-static --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --disable-debug --with-xmlto=no --with-fop=no --disable-nls --disable-dependency-tracking")
step_end configure

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  -C ${PKGBUILD_DIR}"
step_end build

step_start install-host
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} install -C ${PKGBUILD_DIR}"
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
