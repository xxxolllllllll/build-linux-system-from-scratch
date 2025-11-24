#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=gcc
PKGVERSION=14.3.0
PKGSOURCE_DIR=gcc
PKGSOURCE=gcc-14.3.0.tar.xz
PKGURL=http://mirrors.ustc.edu.cn/gnu/gcc/gcc-14.3.0/gcc-14.3.0.tar.xz

PKGBUILDNAME=${PKGNAME}-final
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

stamp_patched

stamp_configured

stamp_built

step_start install-staging
cp -dpf ${HOST_DIR}/${GNU_TARGET_NAME}/lib*/libatomic* ${STAGING_DIR}/lib/
cp -dpf ${HOST_DIR}/${GNU_TARGET_NAME}/lib*/libgcc_s* ${STAGING_DIR}/lib/
step_end install-staging

step_start install-target
mkdir -p ${TARGET_DIR}/lib ${TARGET_DIR}/usr/lib
cp -dpf ${HOST_DIR}/${GNU_TARGET_NAME}/lib*/libatomic.so* ${TARGET_DIR}/lib/
cp -dpf ${HOST_DIR}/${GNU_TARGET_NAME}/lib*/libgcc_s.so* ${TARGET_DIR}/lib/
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
