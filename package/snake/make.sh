#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=snake
PKGVERSION=
PKGSOURCE_DIR=
PKGSOURCE=

PKGBUILDNAME=${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

stamp_extracted

stamp_patched

stamp_configured

stamp_built

step_start install-target
# 传统上用于存放用户游戏的可执行文件（系统安装的游戏）。
mkdir -p ${TARGET_DIR}/usr/games
cp ${PROJECT_DIR}/package/${PKGNAME}/snake.py ${TARGET_DIR}/usr/games/
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
