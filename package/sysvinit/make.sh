#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=sysvinit
PKGVERSION=3.14
PKGSOURCE_DIR=sysvinit
PKGSOURCE=sysvinit-3.14.tar.xz
PKGURL=https://github.com/slicer69/sysvinit/releases/download/3.14/sysvinit-3.14.tar.xz

PKGBUILDNAME=${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
xzcat ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

step_start patch
TAR="tar" PATH=${HOST_DIR}/bin:$PATH ${PROJECT_DIR}/support/scripts/apply-patches.sh ${PKGBUILD_DIR} ${PROJECT_DIR}/package/${PKGNAME} \*.patch
step_end patch

stamp_configured

step_start build
eval "${TARGET_CONFIGURE_OPTS} CXX=no /usr/bin/make -j${MAXNUM_CPUS} SYSROOT=${STAGING_DIR} VERSION=3.14 -C ${PKGBUILD_DIR}/src"
step_end build

step_start install-target
for x in halt init shutdown killall5; do
	/usr/bin/install -D -m 0755 ${PKGBUILD_DIR}/src/$x ${TARGET_DIR}/sbin/$x || exit 1;
done
/usr/bin/install -D -m 0644 ${PROJECT_DIR}/package/sysvinit/inittab ${TARGET_DIR}/etc/inittab
ln -sf /sbin/halt ${TARGET_DIR}/sbin/reboot
ln -sf /sbin/halt ${TARGET_DIR}/sbin/poweroff
ln -sf killall5 ${TARGET_DIR}/sbin/pidof
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
