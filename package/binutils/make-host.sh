#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=binutils
PKGVERSION=2.43.1
PKGSOURCE_DIR=binutils
PKGSOURCE=binutils-2.43.1.tar.xz
PKGURL=http://mirrors.ustc.edu.cn/gnu/binutils/binutils-2.43.1.tar.xz

PKGBUILDNAME=host-${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
xzcat ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

step_start patch
TAR="tar" PATH=${HOST_DIR}/bin:$PATH ${PROJECT_DIR}/support/scripts/apply-patches.sh ${PKGBUILD_DIR} ${PROJECT_DIR}/package/${PKGNAME}/${PKGVERSION} \*.patch
step_end patch autotools

step_start configure
(cd ${PKGBUILD_DIR} && rm -rf config.cache; eval "${HOST_CONFIGURE_OPTS} MAKEINFO=true CONFIG_SITE=/dev/null ./configure --prefix=\"${HOST_DIR}\" --sysconfdir=\"${HOST_DIR}/etc\" --localstatedir=\"${HOST_DIR}/var\" --enable-shared --disable-static --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --disable-debug --with-xmlto=no --with-fop=no --disable-nls --disable-dependency-tracking  --disable-multilib --disable-werror --target=${GNU_TARGET_NAME} --disable-shared --enable-static --with-sysroot=${STAGING_DIR} --enable-poison-system-directories --without-debuginfod --enable-plugins --enable-lto --disable-sim --disable-gdb  --without-zstd --with-system-readline --disable-gprofng")
step_end configure

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} MAKEINFO=true -C ${PKGBUILD_DIR}"
step_end build

step_start install-host
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} MAKEINFO=true install -C ${PKGBUILD_DIR}"
# Hardlinks between binaries in different directories cause a problem
# with rpath fixup, so we de-hardlink those binaries, and replace them
# with copies instead.
BINUTILS_TOOLS="ar as ld ld.bfd nm objcopy objdump ranlib readelf strip"
for tool in ${BINUTILS_TOOLS}; do
	rm -f ${HOST_DIR}/${GNU_TARGET_NAME}/bin/${tool} && \
	cp -a ${HOST_DIR}/bin/${GNU_TARGET_NAME}-${tool} ${HOST_DIR}/${GNU_TARGET_NAME}/bin/${tool}
done
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
