#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=libtool
PKGVERSION=2.4.6
PKGSOURCE_DIR=libtool
PKGSOURCE=libtool-2.4.6.tar.xz
PKGURL=http://mirrors.ustc.edu.cn/gnu/libtool/libtool-2.4.6.tar.xz

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
step_end patch autotools ignore_libtool_patch

step_start configure
# 下面四条语句的含义是在 ${PKGBUILD_DIR} 目录及其子目录中搜索 -name 
# 指定的同名文件，对每个找到的文件执行 touch 命令，'{}'：被替换为找到的文件路径
# 注意需要在最后加上 \; 或 + 来结束
# 这个命令通常在软件包构建过程中使用，通过更新文件的时间戳来防止因文件时间戳问题导致的构建错误。
find ${PKGBUILD_DIR} -name aclocal.m4 -exec touch '{}' \;
find ${PKGBUILD_DIR} -name config-h.in -exec touch '{}' \;
find ${PKGBUILD_DIR} -name configure -exec touch '{}' \;
find ${PKGBUILD_DIR} -name Makefile.in -exec touch '{}' \;
(cd ${PKGBUILD_DIR} && rm -rf config.cache; eval "${HOST_CONFIGURE_OPTS} MAKEINFO=true CONFIG_SITE=/dev/null ./configure --prefix=\"${HOST_DIR}\" --sysconfdir=\"${HOST_DIR}/etc\" --localstatedir=\"${HOST_DIR}/var\" --enable-shared --disable-static --disable-gtk-doc --disable-gtk-doc-html --disable-doc --disable-docs --disable-documentation --disable-debug --with-xmlto=no --with-fop=no --disable-nls --disable-dependency-tracking")
step_end configure

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  -C ${PKGBUILD_DIR}"
step_end build

step_start install-host
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} install -C ${PKGBUILD_DIR}"
step_end install-host

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
