#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=linux
PKGVERSION=6.12.47
PKGSOURCE_DIR=linux
PKGSOURCE=linux-6.12.47.tar.xz
PKGURL=http://mirrors.ustc.edu.cn/kernel.org/linux/kernel/v6.x/linux-6.12.47.tar.xz

PKGBUILDNAME=${PKGNAME}
PKGBUILD_DIR=${BUILD_DIR}/${PKGBUILDNAME}-${PKGVERSION}

echo "----> Building ${PKGBUILDNAME} ..."

stamp_downloaded

step_start extract
mkdir -p ${PKGBUILD_DIR}
xzcat ${DL_DIR}/${PKGSOURCE_DIR}/${PKGSOURCE} | tar --strip-components=1 -C ${PKGBUILD_DIR} -xf -
chmod -R +rw ${PKGBUILD_DIR}
step_end extract

stamp_patched

# Before running configure, the configuration file should be present and fixed
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} -C ${PKGBUILD_DIR} ARCH=riscv KCFLAGS=\"-Wno-attribute-alias\" INSTALL_MOD_PATH=${TARGET_DIR} CROSS_COMPILE=\"${CROSS_COMPILE}\" WERROR=0 REGENERATE_PARSERS=1 DEPMOD=${HOST_DIR}/sbin/depmod INSTALL_MOD_STRIP=1 HOSTCC=\"/usr/bin/gcc\" defconfig"
touch ${PKGBUILD_DIR}/.stamp_dotconfig
echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Updating kernel config with fixups"
kconfig_enable_option CONFIG_KERNEL_GZIP
kconfig_enable_option CONFIG_CPU_LITTLE_ENDIAN
kconfig_enable_option CONFIG_DEVTMPFS
kconfig_enable_option CONFIG_DEVTMPFS_MOUNT
kconfig_disable_option CONFIG_KERNEL_LZ4
kconfig_disable_option CONFIG_KERNEL_LZMA
kconfig_disable_option CONFIG_KERNEL_LZO
kconfig_disable_option CONFIG_KERNEL_XZ
kconfig_disable_option CONFIG_KERNEL_ZSTD
kconfig_disable_option CONFIG_KERNEL_UNCOMPRESSED
kconfig_disable_option CONFIG_GCC_PLUGINS
kconfig_disable_option CONFIG_WERROR
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} -C ${PKGBUILD_DIR} ARCH=riscv KCFLAGS=\"-Wno-attribute-alias\" INSTALL_MOD_PATH=${TARGET_DIR} CROSS_COMPILE=\"${CROSS_COMPILE}\" WERROR=0 REGENERATE_PARSERS=1 DEPMOD=${HOST_DIR}/sbin/depmod INSTALL_MOD_STRIP=1 HOSTCC=\"/usr/bin/gcc\" olddefconfig"
touch ${PKGBUILD_DIR}/.stamp_kconfig_fixup_done

# 对于 linux 来说没有使用 configure 脚本
stamp_configured

step_start build
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} HOSTCC=\"/usr/bin/gcc -O2 -isystem ${HOST_DIR}/include -L${HOST_DIR}/lib -Wl,-rpath,${HOST_DIR}/lib\" ARCH=riscv KCFLAGS=\"-Wno-attribute-alias\" INSTALL_MOD_PATH=${TARGET_DIR} CROSS_COMPILE=\"${CROSS_COMPILE}\" WERROR=0 REGENERATE_PARSERS=1 DEPMOD=${HOST_DIR}/sbin/depmod INSTALL_MOD_STRIP=1 -C ${PKGBUILD_DIR} all"
eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS} HOSTCC=\"/usr/bin/gcc -O2 -isystem ${HOST_DIR}/include -L${HOST_DIR}/lib -Wl,-rpath,${HOST_DIR}/lib\" ARCH=riscv KCFLAGS=\"-Wno-attribute-alias\" INSTALL_MOD_PATH=${TARGET_DIR} CROSS_COMPILE=\"${CROSS_COMPILE}\" WERROR=0 REGENERATE_PARSERS=1 DEPMOD=${HOST_DIR}/sbin/depmod INSTALL_MOD_STRIP=1 -C ${PKGBUILD_DIR} Image"
step_end build

step_start install-target
# Install modules and remove symbolic links pointing to build
# directories, not relevant on the target
if grep -q "CONFIG_MODULES=y" ${PKGBUILD_DIR}/.config; then
	eval "${HOST_MAKE_ENV} /usr/bin/make -j${MAXNUM_CPUS}  HOSTCC=\"/usr/bin/gcc -O2 -isystem ${HOST_DIR}/include -L${HOST_DIR}/lib -Wl,-rpath,${HOST_DIR}/lib\" ARCH=riscv KCFLAGS=\"-Wno-attribute-alias\" INSTALL_MOD_PATH=${TARGET_DIR} CROSS_COMPILE=\"${CROSS_COMPILE}\" WERROR=0 REGENERATE_PARSERS=1 DEPMOD=${HOST_DIR}/sbin/depmod INSTALL_MOD_STRIP=1 -C ${PKGBUILD_DIR} modules_install" ;
	rm -f ${TARGET_DIR}/lib/modules/${PKGVERSION}/build ;
	rm -f ${TARGET_DIR}/lib/modules/${PKGVERSION}/source ;
fi
# Installing dtc (device tree compiler) as host tool, if selected
if grep -q "CONFIG_DTC=y" ${PKGBUILD_DIR}/.config; then
	/usr/bin/install -D -m 0755 ${PKGBUILD_DIR}/scripts/dtc/dtc ${HOST_DIR}/bin/linux-dtc ;
	ln -sf linux-dtc ${HOST_DIR}/bin/dtc;
fi
step_end install-target

# Image Install
step_start install-image
/usr/bin/install -m 0644 -D ${PKGBUILD_DIR}/arch/riscv/boot/Image ${IMAGES_DIR}/Image
step_end install-image

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
