#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=gettext-tiny
PKGVERSION=0.3.2
PKGSOURCE_DIR=gettext-tiny
PKGSOURCE=gettext-tiny-0.3.2.tar.gz
PKGSOURCE2=gettext-0.22.4.tar.xz
PKGURL="https://github.com/sabotage-linux/gettext-tiny/archive/v0.3.2/gettext-tiny-0.3.2.tar.gz http://mirrors.ustc.edu.cn/gnu/gettext/gettext-0.22.4.tar.xz"

PKGBUILDNAME=host-${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
gzip -d -c ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
mkdir -p ${PKGBUILD_DIR}/gettext-gnu
xzcat ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE2} | tar --strip-components=1 -C ${PKGBUILD_DIR}/gettext-gnu  -xf -
step_end extract

step_start patch
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/gettext-tools/misc/gettextize.in ${PKGBUILD_DIR}/extra/gettextize.in
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/gettext-tools/po/Makevars.template ${PKGBUILD_DIR}/extra/Makevars.template
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/gettext-runtime/po/boldquot.sed ${PKGBUILD_DIR}/extra/boldquot.sed
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/gettext-runtime/po/en@boldquot.header ${PKGBUILD_DIR}/extra/en@boldquot.header
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/gettext-runtime/po/en@quot.header ${PKGBUILD_DIR}/extra/en@quot.header
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/gettext-runtime/po/insert-header.sin ${PKGBUILD_DIR}/extra/insert-header.sin
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/gettext-runtime/po/quot.sed ${PKGBUILD_DIR}/extra/quot.sed
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/gettext-runtime/po/remove-potcdate.sin ${PKGBUILD_DIR}/extra/remove-potcdate.sin
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/gettext-runtime/po/Rules-quot ${PKGBUILD_DIR}/extra/Rules-quot
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/gettext-runtime/po/Makefile.in.in ${PKGBUILD_DIR}/extra/Makefile.in.in
/usr/bin/install -D -m 0644 ${PKGBUILD_DIR}/gettext-gnu/COPYING ${PKGBUILD_DIR}/extra/COPYING
/usr/bin/install -D -m 0755 ${PKGBUILD_DIR}/gettext-gnu/build-aux/config.rpath ${PKGBUILD_DIR}/build-aux/config.rpath
step_end patch

stamp_configured

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} -C ${PKGBUILD_DIR} ${HOST_CONFIGURE_OPTS} prefix=${HOST_DIR} CFLAGS=\"-O2 -I${HOST_DIR}/include -fPIC\" LIBINTL=NONE"
cp ${PKGBUILD_DIR}/extra/gettextize.in ${PKGBUILD_DIR}/gettextize
/usr/bin/sed -i -e 's,@PACKAGE@,gettext-tools,g;' ${PKGBUILD_DIR}/gettextize
/usr/bin/sed -i -e 's,@VERSION@,0.22.4,g;' ${PKGBUILD_DIR}/gettextize
/usr/bin/sed -i -e 's,@ARCHIVE_VERSION@,0.22.4,' ${PKGBUILD_DIR}/gettextize
/usr/bin/sed -i -e "s,@prefix@,${HOST_DIR},g;" ${PKGBUILD_DIR}/gettextize
/usr/bin/sed -i -e 's,@datarootdir@,${prefix}/share,g;' ${PKGBUILD_DIR}/gettextize
/usr/bin/sed -i -e 's,@datadir@,${prefix}/share,g;' ${PKGBUILD_DIR}/gettextize
/usr/bin/sed -i -e 's,@PATH_SEPARATOR@,:,g;' ${PKGBUILD_DIR}/gettextize
/usr/bin/sed -i -e 's,@RELOCATABLE@,no,g;' ${PKGBUILD_DIR}/gettextize
/usr/bin/sed -i -e 's,@exec_prefix@,${prefix},g;' ${PKGBUILD_DIR}/gettextize
/usr/bin/sed -i -e 's,@bindir@,${exec_prefix}/bin,g;' ${PKGBUILD_DIR}/gettextize
step_end build

step_start install-host
mkdir -p ${HOST_DIR}/share/gettext-tiny/po
mkdir -p ${HOST_DIR}/share/gettext-tiny/m4
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} -C ${PKGBUILD_DIR} ${HOST_CONFIGURE_OPTS} prefix=${HOST_DIR} LIBINTL=NONE install"
/usr/bin/sed -i -e '/read dummy/d' ${PKGBUILD_DIR}/gettextize
/usr/bin/install -m 0755 -D ${PKGBUILD_DIR}/gettextize ${HOST_DIR}/bin/gettextize
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/build-aux/config.rpath ${HOST_DIR}/share/gettext-tiny/config.rpath
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/extra/Makefile.in.in ${HOST_DIR}/share/gettext-tiny/po/Makefile.in.in
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/extra/boldquot.sed ${HOST_DIR}/share/gettext-tiny/po/boldquot.sed
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/extra/en@boldquot.header ${HOST_DIR}/share/gettext-tiny/po/en@boldquot.header
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/extra/en@quot.header ${HOST_DIR}/share/gettext-tiny/po/en@quot.header
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/extra/insert-header.sin ${HOST_DIR}/share/gettext-tiny/po/insert-header.sin
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/extra/quot.sed ${HOST_DIR}/share/gettext-tiny/po/quot.sed
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/extra/remove-potcdate.sin ${HOST_DIR}/share/gettext-tiny/po/remove-potcdate.sin
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/extra/Rules-quot ${HOST_DIR}/share/gettext-tiny/po/Rules-quot
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/extra/Makevars.template ${HOST_DIR}/share/gettext-tiny/po/Makevars.template
touch ${HOST_DIR}/share/gettext-tiny/ABOUT-NLS
# for gettextize
ln -sf ${HOST_DIR}/share/gettext-tiny ${HOST_DIR}/share/gettext
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
