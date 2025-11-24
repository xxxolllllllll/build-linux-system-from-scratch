#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=linux-headers
PKGVERSION=6.12.47
PKGSOURCE_DIR=linux
PKGSOURCE=linux-6.12.47.tar.xz
PKGURL=http://mirrors.ustc.edu.cn/kernel.org/linux/kernel/v6.x/linux-6.12.47.tar.xz

PKGBUILDNAME=${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
xzcat ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

stamp_patched

stamp_configured

stamp_built

step_start install-staging
(cd ${PKGBUILD_DIR}; eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} ARCH=riscv HOSTCC=\"/usr/bin/gcc\" HOSTCFLAGS=\"\" HOSTCXX=\"/usr/bin/g++\" INSTALL_HDR_PATH=${STAGING_DIR}/usr headers_install")
HOSTCC="/usr/bin/gcc" check_kernel_headers_version ${BUILD_DIR} ${STAGING_DIR} 6.12 strict
step_end install-staging

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
