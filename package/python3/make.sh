#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=python3
PKGVERSION=3.13.7
PKGSOURCE_DIR=python3
PKGSOURCE=Python-3.13.7.tar.xz
PKGURL=https://python.org/ftp/python/3.13.7/Python-3.13.7.tar.xz

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
step_end patch autotools ignore_libtool_patch

step_start configure
echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Autoreconfiguring"
cd ${PKGBUILD_DIR} && eval "AUTOPOINT=/bin/true ${AUTORECONF_OPTS} ${HOST_DIR}/bin/autoreconf -f -i --include=${HOST_DIR}/share/autoconf-archive"
patch_libtool ${PKGBUILD_DIR}
(cd ${PKGBUILD_DIR} && rm -rf config.cache && eval "${TARGET_CONFIGURE_OPTS} CXX=no ac_cv_lbl_unaligned_fail=yes ac_cv_func_mmap_fixed_mapped=yes ac_cv_func_memcmp_working=yes ac_cv_have_decl_malloc=yes gl_cv_func_malloc_0_nonnull=yes ac_cv_func_malloc_0_nonnull=yes ac_cv_func_calloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes lt_cv_sys_lib_search_path_spec=\"\" ac_cv_c_bigendian=no  py_cv_module__dbm=n/a py_cv_module__decimal=n/a py_cv_module__hashlib=n/a py_cv_module__ssl=n/a py_cv_module__codecs_cn=n/a py_cv_module__codecs_hk=n/a py_cv_module__codecs_iso2022=n/a py_cv_module__codecs_jp=n/a py_cv_module__codecs_kr=n/a py_cv_module__codecs_tw=n/a py_cv_module__uuid=n/a py_cv_module__bz2=n/a py_cv_module__lzma=n/a py_cv_module_zlib=n/a py_cv_module_ossaudiodev=n/a ac_cv_have_long_long_format=yes ac_cv_buggy_getaddrinfo=no ac_cv_file__dev_ptmx=yes ac_cv_file__dev_ptc=yes ac_cv_working_tzset=yes py_cv_module_nis=n/a ac_cv_little_endian_double=yes CFLAGS=\"-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1\" CONFIG_SITE=/dev/null ./configure --target=${GNU_TARGET_NAME} --host=${GNU_TARGET_NAME} --build=x86_64-pc-linux-gnu --prefix=/usr --exec-prefix=/usr --sysconfdir=/etc --localstatedir=/var --program-prefix=\"\" --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --with-xmlto=no --with-fop=no --disable-dependency-tracking --enable-ipv6 --disable-nls --disable-static --enable-shared  --disable-lib2to3 --without-readline --with-expat=none --disable-sqlite3 --without-ensurepip --without-cxx-main --with-build-python=${HOST_DIR}/bin/python3 --with-system-ffi --disable-pydoc --disable-test-modules --disable-tk --disable-idle3 --disable-pyc-build")
step_end configure

step_start build
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  -C ${PKGBUILD_DIR}"
step_end build

step_start install-staging
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${STAGING_DIR} install -C ${PKGBUILD_DIR}"
step_end install-staging

step_start install-target
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${TARGET_DIR} install -C ${PKGBUILD_DIR}"
rm -f ${TARGET_DIR}/usr/bin/python3.13-config
rm -f ${TARGET_DIR}/usr/bin/python3-config
find ${TARGET_DIR}/usr/lib/python3.13/config-3.13*/ -depth -type f -not -name Makefile -exec rm -rf {} \;
find ${TARGET_DIR}/usr/lib/python3.13/ -depth -type d -name __pycache__ -exec rm -rf {} \;
chmod u+w ${TARGET_DIR}/usr/lib/libpython3.13*.so
ln -fs python3 ${TARGET_DIR}/usr/bin/python
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
