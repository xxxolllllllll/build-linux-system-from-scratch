#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=ncurses
PKGVERSION=6.5-20250720
PKGSOURCE_DIR=ncurses
PKGSOURCE=ncurses-6.5-20250720.tar.gz
PKGURL=https://github.com/ThomasDickey/ncurses-snapshots/archive/v6_5_20250720/ncurses-6.5-20250720.tar.gz

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
(cd ${PKGBUILD_DIR} && rm -rf config.cache && eval "${TARGET_CONFIGURE_OPTS} CXX=no ac_cv_lbl_unaligned_fail=yes ac_cv_func_mmap_fixed_mapped=yes ac_cv_func_memcmp_working=yes ac_cv_have_decl_malloc=yes gl_cv_func_malloc_0_nonnull=yes ac_cv_func_malloc_0_nonnull=yes ac_cv_func_calloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes lt_cv_sys_lib_search_path_spec=\"\" ac_cv_c_bigendian=no   CONFIG_SITE=/dev/null ./configure --target=${GNU_TARGET_NAME} --host=${GNU_TARGET_NAME} --build=x86_64-pc-linux-gnu --prefix=/usr --exec-prefix=/usr --sysconfdir=/etc --localstatedir=/var --program-prefix=\"\" --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --with-xmlto=no --with-fop=no --disable-dependency-tracking --enable-ipv6 --disable-nls --disable-static --enable-shared  --without-cxx --without-cxx-binding --without-ada --without-tests --disable-big-core --without-profile --disable-rpath --disable-rpath-hack --enable-echo --enable-const --enable-overwrite --enable-pc-files --disable-stripping --with-pkg-config-libdir=\"/usr/lib/pkgconfig\" --without-progs --without-manpages --with-shared --without-normal --without-gpm --disable-widec --without-debug")
step_end configure

step_start build
# ncurses breaks with parallel build, but takes quite a while to
# build single threaded. Work around it similar to how Gentoo does
eval "${TARGET_MAKE_ENV} /usr/bin/make -j1  -C ${PKGBUILD_DIR} DESTDIR=${STAGING_DIR} sources"
rm -rf ${PKGBUILD_DIR}/misc/pc-files
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} -C ${PKGBUILD_DIR} DESTDIR=${STAGING_DIR}"
step_end build

step_start install-staging
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${STAGING_DIR} install -C ${PKGBUILD_DIR}"
step_end install-staging ncurses6-config

step_start install-target
eval "${TARGET_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} DESTDIR=${TARGET_DIR} install -C ${PKGBUILD_DIR}"
rm -f -rf ${TARGET_DIR}/usr/share/terminfo ${TARGET_DIR}/usr/share/tabset
NCURSES_TERMINFO_FILES=" \
	a/ansi \
	d/dumb \
	l/linux \
	p/putty \
	p/putty-256color \
	p/putty-vt100 \
	s/screen \
	s/screen-256color \
	v/vt100 \
	v/vt100-putty \
	v/vt102 \
	v/vt200 \
	v/vt220 \
	x/xterm \
	x/xterm+256color \
	x/xterm-256color \
	x/xterm-color \
	x/xterm-xfree86"
for f in ${NCURSES_TERMINFO_FILES} ; do
	/usr/bin/install -D -m 0644 ${STAGING_DIR}/usr/share/terminfo/${f} \
			${TARGET_DIR}/usr/share/terminfo/${f}
done
rm -f -f ${TARGET_DIR}/usr/bin/ncurses6-config ;
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
