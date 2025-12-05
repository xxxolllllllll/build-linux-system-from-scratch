#!/usr/bin/bash
source $(dirname "$0")/../common.sh

ROOTFS_EXT2_SIZE=128M

echo ">>>   Generating root filesystems common tables"
rm -rf ${BUILD_DIR}/buildroot-fs
mkdir -p ${BUILD_DIR}/buildroot-fs
printf '   \n' >> ${BUILD_DIR}/buildroot-fs/full_users_table.txt
printf '   	/bin/busybox                     f 4755 0  0 - - - - -\n\n' > ${BUILD_DIR}/buildroot-fs/full_devices_table.txt
cat ${PROJECT_DIR}/package/rootfs-ext2/device_table.txt >> ${BUILD_DIR}/buildroot-fs/full_devices_table.txt

echo ">>>   Generating filesystem image rootfs.ext2"
mkdir -p ${IMAGES_DIR}
rm -rf ${BUILD_DIR}/buildroot-fs/ext2
mkdir -p ${BUILD_DIR}/buildroot-fs/ext2
rsync -auH --exclude=/THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ${TARGET_DIR}/ ${BUILD_DIR}/buildroot-fs/ext2/target
echo '#!/bin/sh' > ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
echo "set -e" >> ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
echo "chown -h -R 0:0 ${BUILD_DIR}/buildroot-fs/ext2/target" >> ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
PATH="${HOST_DIR}/bin:${HOST_DIR}/sbin:${PATH}" ${PROJECT_DIR}/support/scripts/mkusers ${BUILD_DIR}/buildroot-fs/full_users_table.txt ${BUILD_DIR}/buildroot-fs/ext2/target >> ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
echo "${HOST_DIR}/bin/makedevs -d ${BUILD_DIR}/buildroot-fs/full_devices_table.txt ${BUILD_DIR}/buildroot-fs/ext2/target" >> ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
printf "   	rm -rf ${BUILD_DIR}/buildroot-fs/ext2/target/usr/lib/udev/hwdb.d/ ${BUILD_DIR}/buildroot-fs/ext2/target/etc/udev/hwdb.d/\n" >>${BUILD_DIR}/buildroot-fs/ext2/fakeroot
echo "find ${BUILD_DIR}/buildroot-fs/ext2/target/run/ -mindepth 1 -prune -print0 | xargs -0r rm -rf --" >> ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
echo "find ${BUILD_DIR}/buildroot-fs/ext2/target/tmp/ -mindepth 1 -prune -print0 | xargs -0r rm -rf --" >> ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
printf '   \n' >> ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
printf '   \n' >> ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
printf "   	rm -f ${IMAGES_DIR}/rootfs.ext2\n	${HOST_DIR}/sbin/mkfs.ext2 -d ${BUILD_DIR}/buildroot-fs/ext2/target -N 0 -m 5 -L \"rootfs\" -I 256 -O ^64bit ${IMAGES_DIR}/rootfs.ext2 \"${ROOTFS_EXT2_SIZE}\" || { ret=\$?; echo \"*** Maybe you need to increase the filesystem size (ROOTFS_EXT2_SIZE)\" 1>&2; exit \$ret; }\n" >> ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
chmod a+x ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
PATH="${HOST_DIR}/bin:${HOST_DIR}/sbin:${PATH}" FAKEROOTDONTTRYCHOWN=1 ${HOST_DIR}/bin/fakeroot -- ${BUILD_DIR}/buildroot-fs/ext2/fakeroot
rm -rf ${BUILD_DIR}/buildroot-fs/ext2/target

echo ">>>   Generating filesystem image rootfs.tar"
mkdir -p ${IMAGES_DIR}
rm -rf ${BUILD_DIR}/buildroot-fs/tar
mkdir -p ${BUILD_DIR}/buildroot-fs/tar
rsync -auH --exclude=/THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ${TARGET_DIR}/ ${BUILD_DIR}/buildroot-fs/tar/target
echo '#!/bin/sh' > ${BUILD_DIR}/buildroot-fs/tar/fakeroot
echo "set -e" >> ${BUILD_DIR}/buildroot-fs/tar/fakeroot
echo "chown -h -R 0:0 ${BUILD_DIR}/buildroot-fs/tar/target" >> ${BUILD_DIR}/buildroot-fs/tar/fakeroot
PATH="${HOST_DIR}/bin:${HOST_DIR}/sbin:${PATH}" ${PROJECT_DIR}/support/scripts/mkusers ${BUILD_DIR}/buildroot-fs/full_users_table.txt ${BUILD_DIR}/buildroot-fs/tar/target >> ${BUILD_DIR}/buildroot-fs/tar/fakeroot
echo "${HOST_DIR}/bin/makedevs -d ${BUILD_DIR}/buildroot-fs/full_devices_table.txt ${BUILD_DIR}/buildroot-fs/tar/target" >> ${BUILD_DIR}/buildroot-fs/tar/fakeroot
printf "   	rm -rf ${BUILD_DIR}/buildroot-fs/tar/target/usr/lib/udev/hwdb.d/ ${BUILD_DIR}/buildroot-fs/tar/target/etc/udev/hwdb.d/\n" >> ${BUILD_DIR}/buildroot-fs/tar/fakeroot
echo "find ${BUILD_DIR}/buildroot-fs/tar/target/run/ -mindepth 1 -prune -print0 | xargs -0r rm -rf --" >> ${BUILD_DIR}/buildroot-fs/tar/fakeroot
echo "find ${BUILD_DIR}/buildroot-fs/tar/target/tmp/ -mindepth 1 -prune -print0 | xargs -0r rm -rf --" >> ${BUILD_DIR}/buildroot-fs/tar/fakeroot
printf '   \n' >> ${BUILD_DIR}/buildroot-fs/tar/fakeroot
printf '   \n' >> ${BUILD_DIR}/buildroot-fs/tar/fakeroot
printf "   	(cd ${BUILD_DIR}/buildroot-fs/tar/target; find -print0 | LC_ALL=C sort -z | tar  --pax-option=exthdr.name=%%d/PaxHeaders/%%f,atime:=0,ctime:=0 -cf ${IMAGES_DIR}/rootfs.tar --null --xattrs-include='*' --no-recursion -T - --numeric-owner)\n" >> ${BUILD_DIR}/buildroot-fs/tar/fakeroot
chmod a+x ${BUILD_DIR}/buildroot-fs/tar/fakeroot
PATH="${HOST_DIR}/bin:${HOST_DIR}/sbin:${PATH}" FAKEROOTDONTTRYCHOWN=1 ${HOST_DIR}/bin/fakeroot -- ${BUILD_DIR}/buildroot-fs/tar/fakeroot
rm -rf ${BUILD_DIR}/buildroot-fs/tar/target

echo ">>>   Generating Init RAM Disk initrd.img"
pushd ${TARGET_DIR}
find . | cpio --create --format='newc' > ${IMAGES_DIR}/initrd.img
popd


echo ">>>   Executing post-image";
# Ubuntu 22.04 上默认安装的 qemu 是 6.2.0
# Ubuntu 24.04 上默认安装的 qemu 是 8.2.2
QEMU_CMD="qemu-system-riscv64 -M virt -m 256M -nographic -bios fw_jump.bin -kernel Image -drive file=rootfs.ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0 -append \"nokaslr root=/dev/vda rw console=ttyS0\" -netdev user,id=net0 -device virtio-net-device,netdev=net0"
echo ${QEMU_CMD} > ${IMAGES_DIR}/start-qemu.sh
chmod +x ${IMAGES_DIR}/start-qemu.sh

# 如果是 initramfs 启动，在构建出 initrd.img 后可以采用如下
# 注意这里使用 512M 内存启动，否则可能会因为内存不足导致启动失败："Initramfs unpacking failed: write error"
QEMU_CMD_INITRAMFS="qemu-system-riscv64 -M virt -m 512M -nographic -bios fw_jump.bin -kernel Image -initrd initrd.img -append \"nokaslr rdinit=/sbin/init console=ttyS0\" -netdev user,id=net0 -device virtio-net-device,netdev=net0"
echo ${QEMU_CMD_INITRAMFS} > ${IMAGES_DIR}/start-qemu-initramfs.sh
chmod +x ${IMAGES_DIR}/start-qemu-initramfs.sh
