#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=vim
PKGVERSION=9.1.1684
PKGSOURCE_DIR=vim
PKGSOURCE=vim-9.1.1684.tar.gz
PKGURL=https://github.com/vim/vim/archive/v9.1.1684/vim-9.1.1684.tar.gz

PKGBUILDNAME=${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
gzip -d -c ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

stamp_patched autotools

step_start configure
(cd ${PKGBUILD_DIR}/src && rm -rf config.cache && eval "${TARGET_CONFIGURE_OPTS} CXX=no ac_cv_lbl_unaligned_fail=yes ac_cv_func_mmap_fixed_mapped=yes ac_cv_func_memcmp_working=yes ac_cv_have_decl_malloc=yes gl_cv_func_malloc_0_nonnull=yes ac_cv_func_malloc_0_nonnull=yes ac_cv_func_calloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes lt_cv_sys_lib_search_path_spec=\"\" ac_cv_c_bigendian=no  vim_cv_toupper_broken=no vim_cv_terminfo=yes vim_cv_tgetent=zero vim_cv_tty_group=world vim_cv_tty_mode=0620 vim_cv_getcwd_broken=no vim_cv_stat_ignores_slash=yes vim_cv_memmove_handles_overlap=yes ac_cv_sizeof_int=4 ac_cv_small_wchar_t=no CONFIG_SITE=/dev/null ./configure --target=${GNU_TARGET_NAME} --host=${GNU_TARGET_NAME} --build=x86_64-pc-linux-gnu --prefix=/usr --exec-prefix=/usr --sysconfdir=/etc --localstatedir=/var --program-prefix=\"\" --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --with-xmlto=no --with-fop=no --disable-dependency-tracking --enable-ipv6 --disable-nls --disable-static --enable-shared  --with-tlib=ncurses --enable-gui=no --without-x --disable-acl --disable-gpm --disable-selinux")
step_end configure

step_start build
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  -C ${PKGBUILD_DIR}/src"
step_end build

step_start install-target
cd ${PKGBUILD_DIR}/src;
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${TARGET_DIR} installvimbin"
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${TARGET_DIR} installpack"
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${TARGET_DIR} installtools"
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${TARGET_DIR} installlinks"
ln -sf ../usr/bin/vim ${TARGET_DIR}/bin/vi
cd ${PKGBUILD_DIR}/src;
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${TARGET_DIR} installrtbase"
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${TARGET_DIR} installmacros"
rm -f -rf ${TARGET_DIR}/usr/share/vim/vim*/doc/
# QEMU使用 -nographic 时，其模拟的是 vt220 类型的串口终端，
# 这种终端无法自动适应宿主终端（如Xshell）的尺寸变化
# 这导致系统启动后，如果我们输入 stty size 查看终端尺寸时，
# 会发现行数和列数都是0，从而影响一些程序的显示效果，譬如 vim
# 因此，我们在 /etc/profile 末尾添加一些代码，
# 获取当前 host 的终端尺寸并在 guest 用户登录时动态设置终端的行数和列数
if [ -f "${TARGET_DIR}/etc/profile" ]; then
	read -r TERM_ROWS TERM_COLS < <(stty size 2>/dev/null)
	if [ -n "${TERM_ROWS}" ] && [ -n "${TERM_COLS}" ]; then
		echo "" >> ${TARGET_DIR}/etc/profile
		echo "# Force setting terminal size." >> ${TARGET_DIR}/etc/profile
		echo "stty rows ${TERM_ROWS} cols ${TERM_COLS} 2>/dev/null" >> ${TARGET_DIR}/etc/profile
		echo "# Re-initialize terminal." >> ${TARGET_DIR}/etc/profile
		echo "tput init 2>/dev/null" >> ${TARGET_DIR}/etc/profile
	else
		echo "Warning: unable to get host terminal size!"
	fi
else
	echo "Warning: ${TARGET_DIR}/etc/profile not found!"
fi
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
