.PHONY: all
all:
	@./build.sh

.PHONY: source
source:
	@./package/prepare-env/make.sh || exit 1
	@./source.sh || exit 1

.PHONY: prepare-env
prepare-env:
	@./package/prepare-env/make.sh || exit 1
	@./package/skeleton/make.sh || exit 1

.PHONY: host-tools
host-tools:
	@./package/pkgconf/make-host.sh || exit 1
	@./package/libzlib/make-host.sh || exit 1
	@./package/m4/make-host.sh || exit 1
	@./package/libtool/make-host.sh || exit 1
	@./package/autoconf/make-host.sh || exit 1
	@./package/automake/make-host.sh || exit 1

.PHONY: toolchain
toolchain:
	@./package/bison/make-host.sh || exit 1
	@./package/gawk/make-host.sh || exit 1
	@./package/gmp/make-host.sh || exit 1
	@./package/mpfr/make-host.sh || exit 1
	@./package/mpc/make-host.sh || exit 1
	@./package/binutils/make-host.sh || exit 1
	@./package/gcc/make-host-initial.sh || exit 1
	@./package/linux-headers/make.sh || exit 1
	@./package/glibc/make.sh || exit 1
	@./package/gcc/make-host-final.sh || exit 1
	@./package/gcc/make-final.sh || exit 1
	@./package/toolchain/make.sh || exit 1

.PHONY: opensbi
opensbi:
	@./package/opensbi/make.sh || exit 1

.PHONY: linux
linux:
	@./package/kmod/make-host.sh || exit 1
	@./package/gettext-tiny/make-host.sh || exit 1
	@./package/flex/make-host.sh || exit 1
	@./package/linux/make.sh || exit 1

.PHONY: busybox
busybox:
	@./package/busybox/make.sh || exit 1

.PHONY: before-target-image
before-target-image:
	@./package/util-linux/make-host.sh || exit 1
	@./package/e2fsprogs/make-host.sh || exit 1
	@./package/attr/make-host.sh || exit 1
	@./package/acl/make-host.sh || exit 1
	@./package/fakeroot/make-host.sh || exit 1
	@./package/makedevs/make-host.sh || exit 1
	@./package/patchelf/make-host.sh || exit 1

.PHONY: rebuild-target-image
rebuild-target-image:
	@echo "----> Building $@ ..."
	@./package/host-finalize/make.sh || exit 1
	@./package/target-finalize/make.sh || exit 1
	@./package/rootfs-ext2/make.sh || exit 1
	@echo "<---- $@ build complete."

.PHONY: sysvinit
sysvinit:
	@./package/libxcrypt/make.sh || exit 1
	@./package/sysvinit/make.sh || exit 1

clean:
	rm -rf output/
