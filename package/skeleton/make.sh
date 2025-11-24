#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=skeleton
PKGVERSION=
PKGSOURCE_DIR=
PKGSOURCE=

PKGBUILDNAME=host-${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

stamp_extracted

stamp_patched

stamp_configured

stamp_built

step_start install-host
ln -snf . ${HOST_DIR}/usr
mkdir -p ${HOST_DIR}/lib
mkdir -p ${HOST_DIR}/include
ln -snf lib ${HOST_DIR}/lib64
step_end install-host

step_start install-staging
rsync -a --ignore-times --exclude .svn --exclude .git --exclude .hg --exclude .bzr --exclude CVS --chmod=u=rwX,go=rX --exclude .empty --exclude '*~' ${PROJECT_DIR}/package/${PKGNAME}/system/skeleton/ ${STAGING_DIR}
/usr/bin/install -d -m 0755 ${STAGING_DIR}/bin
/usr/bin/install -d -m 0755 ${STAGING_DIR}/sbin
/usr/bin/install -d -m 0755 ${STAGING_DIR}/lib
ln -snf lib ${STAGING_DIR}/lib64
ln -snf lib ${STAGING_DIR}/usr/lib64
/usr/bin/install -d -m 0755 ${STAGING_DIR}/usr/include
step_end install-staging

step_start install-target
rsync -a --ignore-times --exclude .svn --exclude .git --exclude .hg --exclude .bzr --exclude CVS --chmod=u=rwX,go=rX --exclude .empty --exclude '*~' ${PROJECT_DIR}/package/${PKGNAME}/system/skeleton/ ${TARGET_DIR}
/usr/bin/install -d -m 0755 ${TARGET_DIR}/bin
/usr/bin/install -d -m 0755 ${TARGET_DIR}/sbin
/usr/bin/install -d -m 0755 ${TARGET_DIR}/lib
ln -snf lib ${TARGET_DIR}/lib64
ln -snf lib ${TARGET_DIR}/usr/lib64
/usr/bin/sed -i -e 's,@PATH@,"/bin:/sbin:/usr/bin:/usr/sbin",' ${TARGET_DIR}/etc/profile
# setup sysv
rsync -a --ignore-times --exclude .svn --exclude .git --exclude .hg --exclude .bzr --exclude CVS --chmod=u=rwX,go=rX --exclude .empty --exclude '*~' ${PROJECT_DIR}/package/${PKGNAME}/skeleton/ ${TARGET_DIR}
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
