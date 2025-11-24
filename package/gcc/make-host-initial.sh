#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=gcc
PKGVERSION=14.3.0
PKGSOURCE_DIR=gcc
PKGSOURCE=gcc-14.3.0.tar.xz
PKGURL=http://mirrors.ustc.edu.cn/gnu/gcc/gcc-14.3.0/gcc-14.3.0.tar.xz

PKGBUILDNAME=host-${PKGNAME}-initial
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
xzcat ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} --exclude='libjava/*'  --exclude='libgo/*' -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

step_start patch
TAR="tar" PATH=${HOST_DIR}/bin:$PATH ${PROJECT_DIR}/support/scripts/apply-patches.sh ${PKGBUILD_DIR} ${PROJECT_DIR}/package/${PKGNAME}/14.3.0 \*.patch || exit 1
step_end patch autotools

step_start configure
mkdir -p ${PKGBUILD_DIR}/build
ln -sf ../configure ${PKGBUILD_DIR}/build/configure
(cd  ${PKGBUILD_DIR}/build && rm -rf config.cache; eval "${HOST_CONFIGURE_OPTS} MAKEINFO=missing CFLAGS_FOR_TARGET=\"-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1 \" CXXFLAGS_FOR_TARGET=\"-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1 \" LDFLAGS_FOR_TARGET=\" \" AR_FOR_TARGET=gcc-ar NM_FOR_TARGET=gcc-nm RANLIB_FOR_TARGET=gcc-ranlib CONFIG_SITE=/dev/null ./configure --prefix=\"${HOST_DIR}\" --sysconfdir=\"${HOST_DIR}/etc\" --localstatedir=\"${HOST_DIR}/var\" --enable-shared --disable-static --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --disable-debug --with-xmlto=no --with-fop=no --disable-nls --disable-dependency-tracking  --target=${GNU_TARGET_NAME} --with-sysroot=${STAGING_DIR} --enable-__cxa_atexit --with-gnu-ld --disable-libssp --disable-multilib --disable-decimal-float --enable-plugins --enable-lto --with-gmp=${HOST_DIR} --with-mpc=${HOST_DIR} --with-mpfr=${HOST_DIR} --without-zstd --disable-libquadmath --disable-libquadmath-support --enable-tls --enable-threads --without-isl --without-cloog --with-arch=\"rv64imafd_zicsr_zifencei\" --with-abi=\"lp64d\" --enable-languages=c --disable-shared --without-headers --disable-threads --with-newlib --disable-largefile")
step_end configure

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} gcc_cv_prog_makeinfo_modern=no gcc_cv_libc_provides_ssp=yes all-gcc all-target-libgcc -C ${PKGBUILD_DIR}/build"
/usr/bin/gcc -O2 -I${HOST_DIR}/include -DBR_CROSS_PATH_SUFFIX='".br_real"' -DBR_SYSROOT="\"${STAGING_SUBDIR}\"" -DBR_ADDITIONAL_CFLAGS='"-fstack-protector-strong",' -DBR2_PIC_PIE -DBR2_RELRO_FULL -s -Wl,--hash-style=both ${PROJECT_DIR}/package/${PKGNAME}/toolchain-wrapper.c -o ${PKGBUILD_DIR}/toolchain-wrapper
step_end build

step_start install-host
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} install-gcc install-target-libgcc -C ${PKGBUILD_DIR}/build"
/usr/bin/install -D -m 0755 ${PKGBUILD_DIR}/toolchain-wrapper ${HOST_DIR}/bin/toolchain-wrapper
cd ${HOST_DIR}/bin;
for i in ${GNU_TARGET_NAME}-*; do
	case "$i" in
	*.br_real)
		;;
	*-ar|*-ranlib|*-nm)
		ln -snf $i ${ARCH}-linux${i##${GNU_TARGET_NAME}};
		;;
	*cc|*cc-*|*++|*++-*|*cpp|*-gfortran|*-gdc)
		rm -f $i.br_real;
		mv $i $i.br_real;
		ln -sf toolchain-wrapper $i;
		ln -sf toolchain-wrapper ${ARCH}-linux${i##${GNU_TARGET_NAME}};
		ln -snf $i.br_real ${ARCH}-linux${i##${GNU_TARGET_NAME}}.br_real;
		;;
	*)
		ln -snf $i ${ARCH}-linux${i##${GNU_TARGET_NAME}};
		;;
	esac;
done
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
