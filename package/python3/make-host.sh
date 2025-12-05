#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=python3
PKGVERSION=3.13.7
PKGSOURCE_DIR=python3
PKGSOURCE=Python-3.13.7.tar.xz
PKGURL=https://python.org/ftp/python/3.13.7/Python-3.13.7.tar.xz

PKGBUILDNAME=host-${PKGNAME}
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
(cd ${PKGBUILD_DIR} && rm -rf config.cache; eval "${HOST_CONFIGURE_OPTS} LDFLAGS=\"-L${HOST_DIR}/lib -Wl,-rpath,${HOST_DIR}/lib -Wl,--enable-new-dtags\" py_cv_module_unicodedata=yes py_cv_module__codecs_cn=n/a py_cv_module__codecs_hk=n/a py_cv_module__codecs_iso2022=n/a py_cv_module__codecs_jp=n/a py_cv_module__codecs_kr=n/a py_cv_module__codecs_tw=n/a py_cv_module__uuid=n/a py_cv_module_nis=n/a py_cv_module_ossaudiodev=n/a py_cv_module__bz2=n/a py_cv_module__lzma=n/a py_cv_module__hashlib=n/a py_cv_module__ssl=n/a CONFIG_SITE=/dev/null ./configure --prefix=\"${HOST_DIR}\" --sysconfdir=\"${HOST_DIR}/etc\" --localstatedir=\"${HOST_DIR}/var\" --enable-shared --disable-static --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --disable-debug --with-xmlto=no --with-fop=no --disable-nls --disable-dependency-tracking  --without-ensurepip --without-cxx-main --disable-sqlite3 --disable-tk --with-expat=system --disable-test-modules --disable-idle3 --disable-curses")
step_end configure

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  -C ${PKGBUILD_DIR}"
step_end build

step_start install-host
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} install -C ${PKGBUILD_DIR}"
ln -fs python3 ${HOST_DIR}/bin/python
ln -fs python3-config ${HOST_DIR}/bin/python-config
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
