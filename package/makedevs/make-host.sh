#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=makedevs
PKGVERSION=
PKGSOURCE_DIR=makedevs
PKGSOURCE=

PKGBUILDNAME=host-${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
cp ${PROJECT_DIR}/package/${PKGNAME}/makedevs.c ${PKGBUILD_DIR}
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

stamp_patched

stamp_configured

step_start build
/usr/bin/gcc -O2 -I${HOST_DIR}/include ${PKGBUILD_DIR}/makedevs.c -o ${PKGBUILD_DIR}/makedevs -L${HOST_DIR}/lib -Wl,-rpath,${HOST_DIR}/lib
step_end build

step_start install-host
/usr/bin/install -D -m 755 ${PKGBUILD_DIR}/makedevs ${HOST_DIR}/bin/makedevs
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
