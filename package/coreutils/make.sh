#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=coreutils
PKGVERSION=9.5
PKGSOURCE_DIR=coreutils
PKGSOURCE=coreutils-9.5.tar.xz
PKGURL=http://mirrors.ustc.edu.cn/gnu/coreutils/coreutils-9.5.tar.xz

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
step_end patch autotools

step_start configure
(cd ${PKGBUILD_DIR} && rm -rf config.cache && eval "${TARGET_CONFIGURE_OPTS} CXX=no ac_cv_lbl_unaligned_fail=yes ac_cv_func_mmap_fixed_mapped=yes ac_cv_func_memcmp_working=yes ac_cv_have_decl_malloc=yes gl_cv_func_malloc_0_nonnull=yes ac_cv_func_malloc_0_nonnull=yes ac_cv_func_calloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes lt_cv_sys_lib_search_path_spec=\"\" ac_cv_c_bigendian=no  ac_cv_c_restrict=no ac_cv_func_chown_works=yes ac_cv_func_fstatat=yes ac_cv_func_getdelim=yes ac_cv_func_getgroups=yes ac_cv_func_getgroups_works=yes ac_cv_func_getloadavg=no ac_cv_func_strnlen_working=yes ac_cv_have_decl_strerror_r=yes ac_cv_have_decl_strnlen=yes ac_cv_lib_getloadavg_getloadavg=no ac_cv_lib_util_getloadavg=no ac_fsusage_space=yes ac_use_included_regex=no am_cv_func_working_getline=yes fu_cv_sys_stat_statfs2_bsize=yes gl_cv_func_getcwd_null=yes gl_cv_func_getcwd_path_max=yes gl_cv_func_link_follows_symlink=no gl_cv_func_lstat_dereferences_slashed_symlink=yes gl_cv_func_re_compile_pattern_working=yes gl_cv_func_svid_putenv=yes gl_cv_func_working_mkstemp=yes gl_cv_func_working_utimes=yes gl_cv_macro_MB_CUR_MAX_good=yes gl_cv_have_proc_uptime=yes utils_cv_localtime_cache=no PERL=missing MAKEINFO=true INSTALL_PROGRAM=/usr/bin/install CONFIG_SITE=/dev/null ./configure --target=${GNU_TARGET_NAME} --host=${GNU_TARGET_NAME} --build=x86_64-pc-linux-gnu --prefix=/usr --exec-prefix=/usr --sysconfdir=/etc --localstatedir=/var --program-prefix=\"\" --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --with-xmlto=no --with-fop=no --disable-dependency-tracking --enable-ipv6 --disable-nls --disable-static --enable-shared  --disable-rpath  --disable-single-binary --disable-acl --disable-xattr --disable-libcap --without-selinux")
step_end configure

step_start build
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  -C ${PKGBUILD_DIR}"
step_end build

step_start install-target
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${TARGET_DIR} install -C ${PKGBUILD_DIR}"
COREUTILS_BIN_PROGS="base64 cat chgrp chmod chown cp date dd df dir echo false \
	kill link ln ls mkdir mknod mktemp mv nice printenv pwd rm rmdir \
	vdir sleep stty sync touch true uname join"
for f in ${COREUTILS_BIN_PROGS} ; do
	mv ${TARGET_DIR}/usr/bin/${f} ${TARGET_DIR}/bin
done
ln -fs test ${TARGET_DIR}/usr/bin/[
mv ${TARGET_DIR}/usr/bin/chroot ${TARGET_DIR}/usr/sbin
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
