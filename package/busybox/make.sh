#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=busybox
PKGVERSION=1.37.0
PKGSOURCE_DIR=busybox
PKGSOURCE=busybox-1.37.0.tar.bz2
PKGURL=https://www.busybox.net/downloads/busybox-1.37.0.tar.bz2

PKGBUILDNAME=${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
bzcat ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

step_start patch
TAR="tar" PATH=${HOST_DIR}/bin:$PATH ${PROJECT_DIR}/support/scripts/apply-patches.sh ${PKGBUILD_DIR} ${PROJECT_DIR}/package/${PKGNAME} \*.patch
step_end patch

# Before running configure, the configuration file should be present and fixed
# busybox 这里的动作分以下几步：
# 先用 busybox.config 替换 .config 文件，busybox.config 基于 1.36.1，这里直接参考了 buildroot (2025.08.1) 维护的一套针对 busybox 的默认配置
# 然后执行 yes = "" | make oldconfig，目的是基于我们当前的 busybox 版本（1.37.0）升级 .config 文件
# 然后执行 fix，即手动调整一些配置
# 最后再执行一遍 yes = "" | make oldconfig，确保配置正确
/usr/bin/install -m 0644 -D ${PROJECT_DIR}/package/busybox/busybox.config ${PKGBUILD_DIR}/.config
yes "" | eval "${TARGET_MAKE_ENV} CFLAGS=\"-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1\" CFLAGS_busybox=\"\" /usr/bin/make -j${MAXNUM_CPUS} -C ${PKGBUILD_DIR} HOSTCC=\"/usr/bin/gcc\" AR=\"${CROSS_COMPILE}gcc-ar\" NM=\"${CROSS_COMPILE}gcc-nm\" RANLIB=\"${CROSS_COMPILE}gcc-ranlib\" CC=\"${CROSS_COMPILE}gcc\" ARCH=riscv PREFIX=\"${TARGET_DIR}\" EXTRA_LDFLAGS=\"\" CROSS_COMPILE=\"${CROSS_COMPILE}\" CONFIG_PREFIX=\"${TARGET_DIR}\" SKIP_STRIP=y oldconfig"
touch ${PKGBUILD_DIR}/.stamp_dotconfig
# fixup
kconfig_disable_option CONFIG_NOMMU
kconfig_enable_option CONFIG_USE_BB_CRYPT_SHA
kconfig_disable_option CONFIG_PAM
kconfig_enable_option CONFIG_INIT
yes "" | eval "${TARGET_MAKE_ENV} CFLAGS=\"-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1\" CFLAGS_busybox=\"\" /usr/bin/make -j${MAXNUM_CPUS} -C ${PKGBUILD_DIR} HOSTCC=\"/usr/bin/gcc\" AR=\"${CROSS_COMPILE}gcc-ar\" NM=\"${CROSS_COMPILE}gcc-nm\" RANLIB=\"${CROSS_COMPILE}gcc-ranlib\" CC=\"${CROSS_COMPILE}gcc\" ARCH=riscv PREFIX=\"${TARGET_DIR}\" EXTRA_LDFLAGS=\"\" CROSS_COMPILE=\"${CROSS_COMPILE}\" CONFIG_PREFIX=\"${TARGET_DIR}\" SKIP_STRIP=y oldconfig"
touch ${PKGBUILD_DIR}/.stamp_kconfig_fixup_done

# 对于 busybox 来说没有使用 configure 脚本
stamp_configured

step_start build
eval "${TARGET_MAKE_ENV} CFLAGS=\"-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1\" CFLAGS_busybox=\"\" /usr/bin/make -j${MAXNUM_CPUS} AR=\"${CROSS_COMPILE}gcc-ar\" NM=\"${CROSS_COMPILE}${CROSS_COMPILE}gcc-nm\" RANLIB=\"${CROSS_COMPILE}gcc-ranlib\" CC=\"${CROSS_COMPILE}gcc\" ARCH=riscv PREFIX=\"${TARGET_DIR}\" EXTRA_LDFLAGS=\"\" CROSS_COMPILE=\"${CROSS_COMPILE}\" CONFIG_PREFIX=\"${TARGET_DIR}\" SKIP_STRIP=y -C ${PKGBUILD_DIR}"
step_end build

step_start install-target
eval "${TARGET_MAKE_ENV} CFLAGS=\"-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1\" CFLAGS_busybox=\"\" /usr/bin/make -j${MAXNUM_CPUS} AR=\"${CROSS_COMPILE}gcc-ar\" NM=\"${CROSS_COMPILE}gcc-nm\" RANLIB=\"${CROSS_COMPILE}gcc-ranlib\" CC=\"${CROSS_COMPILE}gcc\" ARCH=riscv PREFIX=\"${TARGET_DIR}\" EXTRA_LDFLAGS=\"\" CROSS_COMPILE=\"${CROSS_COMPILE}\" CONFIG_PREFIX=\"${TARGET_DIR}\" SKIP_STRIP=y -C ${PKGBUILD_DIR} install-noclobber"
if test ! -e ${TARGET_DIR}/etc/inittab; then
	/usr/bin/install -D -m 0644 ${PROJECT_DIR}/package/busybox/inittab ${TARGET_DIR}/etc/inittab;
fi
if grep -q CONFIG_UDHCPC=y ${PKGBUILD_DIR}/.config; then
	/usr/bin/install -m 0755 -D ${PROJECT_DIR}/package/busybox/udhcpc.script ${TARGET_DIR}/usr/share/udhcpc/default.script;
	/usr/bin/install -m 0755 -d ${TARGET_DIR}/usr/share/udhcpc/default.script.d;
fi
if grep -q CONFIG_ZCIP=y ${PKGBUILD_DIR}/.config; then
	/usr/bin/install -m 0755 -D ${PKGBUILD_DIR}/examples/zcip.script ${TARGET_DIR}/usr/share/zcip/default.script;
fi
if grep -q CONFIG_SYSLOGD=y ${PKGBUILD_DIR}/.config; then
	/usr/bin/install -m 0755 -D ${PROJECT_DIR}/package/busybox/S01syslogd ${TARGET_DIR}/etc/init.d/S01syslogd;
fi;
if grep -q CONFIG_KLOGD=y ${PKGBUILD_DIR}/.config; then
	/usr/bin/install -m 0755 -D ${PROJECT_DIR}/package/busybox/S02klogd ${TARGET_DIR}/etc/init.d/S02klogd;
fi
if grep -q CONFIG_BB_SYSCTL=y ${PKGBUILD_DIR}/.config; then
	/usr/bin/install -m 0755 -D ${PROJECT_DIR}/package/busybox/S02sysctl ${TARGET_DIR}/etc/init.d/S02sysctl ;
fi
if grep -q CONFIG_IFPLUGD=y ${PKGBUILD_DIR}/.config; then
	/usr/bin/install -m 0755 -D ${PROJECT_DIR}/package/busybox/S41ifplugd ${TARGET_DIR}/etc/init.d/S41ifplugd;
fi;
if grep -q CONFIG_CROND=y ${PKGBUILD_DIR}/.config; then
	mkdir -p ${TARGET_DIR}/etc/cron/crontabs
	/usr/bin/install -m 0755 -D ${PROJECT_DIR}/package/busybox/S50crond ${TARGET_DIR}/etc/init.d/S50crond
fi;
if grep -q CONFIG_FEATURE_TELNETD_STANDALONE=y ${PKGBUILD_DIR}/.config; then
	/usr/bin/install -m 0755 -D ${PROJECT_DIR}/package/busybox/S50telnet ${TARGET_DIR}/etc/init.d/S50telnet ;
fi
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
