#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=glibc
PKGVERSION=2.41-70-g1502c248d58cb99a203731707987a4342926e830
PKGSOURCE_DIR=glibc
PKGSOURCE=glibc-2.41-70-g1502c248d58cb99a203731707987a4342926e830.tar.gz
PKGURL=https://github.com/bminor/glibc/archive/2.41-70-g1502c248d58cb99a203731707987a4342926e830/glibc-2.41-70-g1502c248d58cb99a203731707987a4342926e830.tar.gz

PKGBUILDNAME=${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
gzip -d -c ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

step_start patch
/usr/bin/sed -i -e 's/$"/"/g' ${PKGBUILD_DIR}/elf/ldd.bash.in
step_end patch autotools

tep_start configure
mkdir -p ${PKGBUILD_DIR}/build
(cd ${PKGBUILD_DIR}/build; eval "${TARGET_CONFIGURE_OPTS} CXX=no CFLAGS=\"-O2 -fno-lto\" CPPFLAGS=\"\" CXXFLAGS=\"-O2 -fno-lto\" ac_cv_path_BASH_SHELL=/bin/sh libc_cv_forced_unwind=yes libc_cv_ssp=no libc_cv_slibdir=/lib64 libc_cv_rtlddir=/lib ac_cv_prog_MAKE=\"/usr/bin/make -j9\" /bin/bash ${PKGBUILD_DIR}/configure --target=${GNU_TARGET_NAME} --host=${GNU_TARGET_NAME} --build=x86_64-pc-linux-gnu --prefix=/usr --enable-shared --disable-profile --disable-werror --without-gd --with-headers=${STAGING_DIR}/usr/include  --enable-kernel=6.12")
mkdir -p ${STAGING_DIR}/usr/include/gnu
touch ${STAGING_DIR}/usr/include/gnu/stubs.h
step_end configure

step_start build
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} -C ${PKGBUILD_DIR}/build"
step_end build

step_start install-staging
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} install_root=${STAGING_DIR} install -C ${PKGBUILD_DIR}/build"
step_end install-staging

step_start install-target
for libpattern in ld*.so.* libanl.so.* libc.so.* libdl.so.* libgcc_s.so.* libm.so.* libpthread.so.* libresolv.so.* librt.so.* libutil.so.* libnss_files.so.* libnss_dns.so.* libmvec.so.*; do
	copy_toolchain_lib_root ${libpattern}
done
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
