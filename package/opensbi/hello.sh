#!/usr/bin/bash
source $(dirname "$0")/../common.sh

rm -f hello.o hello.elf hello.bin

# 编译
${CROSS_COMPILE}as hello.s -o hello.o
${CROSS_COMPILE}ld hello.o -Ttext=0x80200000 -o hello.elf
${CROSS_COMPILE}objcopy -O binary hello.elf hello.bin

# 运行
echo "Running in QEMU..."
echo "Press Ctrl+A then X to exit"
qemu-system-riscv64 \
    -M virt \
    -m 256M \
    -nographic \
    -bios ${IMAGES_DIR}/fw_jump.bin \
    -kernel hello.bin
