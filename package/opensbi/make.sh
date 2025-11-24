#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=opensbi
PKGVERSION=1.6
PKGSOURCE_DIR=opensbi
PKGSOURCE=opensbi-1.6.tar.gz
PKGURL=https://github.com/riscv-software-src/opensbi/archive/v1.6/opensbi-1.6.tar.gz

PKGBUILDNAME=${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
gzip -d -c ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

stamp_patched

stamp_configured

step_start build
eval "${TARGET_MAKE_ENV} CROSS_COMPILE=${CROSS_COMPILE}  PLATFORM=generic /usr/bin/make -j${MAXNUM_CPUS} -C ${PKGBUILD_DIR}"
step_end build

step_start install-image
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/build/platform/generic/firmware/fw_jump.bin ${IMAGES_DIR}/fw_jump.bin
step_end install-image

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
