#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=libxcrypt
PKGVERSION=4.4.38
PKGSOURCE_DIR=libxcrypt
PKGSOURCE=libxcrypt-4.4.38.tar.xz
PKGURL=https://github.com/besser82/libxcrypt/releases/download/v4.4.38/libxcrypt-4.4.38.tar.xz

PKGBUILDNAME=${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
xzcat ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

stamp_patched autotools

step_start configure
(cd ${PKGBUILD_DIR} && rm -rf config.cache && eval "${TARGET_CONFIGURE_OPTS} CXX=no ac_cv_lbl_unaligned_fail=yes ac_cv_func_mmap_fixed_mapped=yes ac_cv_func_memcmp_working=yes ac_cv_have_decl_malloc=yes gl_cv_func_malloc_0_nonnull=yes ac_cv_func_malloc_0_nonnull=yes ac_cv_func_calloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes lt_cv_sys_lib_search_path_spec=\"\" ac_cv_c_bigendian=no   CONFIG_SITE=/dev/null ./configure --target=${GNU_TARGET_NAME} --host=${GNU_TARGET_NAME} --build=x86_64-pc-linux-gnu --prefix=/usr --exec-prefix=/usr --sysconfdir=/etc --localstatedir=/var --program-prefix=\"\" --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --with-xmlto=no --with-fop=no --disable-dependency-tracking --enable-ipv6 --disable-nls --disable-static --enable-shared  --disable-werror --disable-obsolete_api")
step_end configure

step_start build
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  -C ${PKGBUILD_DIR}"
step_end build

step_start install-staging
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${STAGING_DIR} install -C ${PKGBUILD_DIR}"
step_end install-staging

step_start install-target
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${TARGET_DIR} install -C ${PKGBUILD_DIR}"
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
