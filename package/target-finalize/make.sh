#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=target-finalize

PYTHON3_BUILD_DIR=${BUILD_DIR}/python3-3.13.7

mkdir -p ${TARGET_DIR}/etc

echo ">>>   Installing ifupdown-scripts"
/usr/bin/install -m 0755 -D ${PROJECT_DIR}/package/${PKGNAME}/ifupdown-scripts/nfs_check ${TARGET_DIR}/etc/network/nfs_check
rsync -a --ignore-times --exclude .svn --exclude .git --exclude .hg --exclude .bzr --exclude CVS --chmod=u=rwX,go=rX --exclude .empty --exclude '*~' ${PROJECT_DIR}/package/${PKGNAME}/ifupdown-scripts/network/ ${TARGET_DIR}/etc/network/
/usr/bin/install -D -m 0755 ${PROJECT_DIR}/package/${PKGNAME}/ifupdown-scripts/S40network ${TARGET_DIR}/etc/init.d/S40network
echo "# interface file" > ${TARGET_DIR}/etc/network/interfaces
( echo ; echo "auto lo"; echo "iface lo inet loopback"; ) >> ${TARGET_DIR}/etc/network/interfaces
( echo ; echo "auto eth0"; echo "iface eth0 inet dhcp"; echo "  pre-up /etc/network/nfs_check"; echo "  wait-delay 15"; echo "  hostname \$(hostname)"; ) >> ${TARGET_DIR}/etc/network/interfaces

echo ">>>   Installing initscripts"
mkdir -p ${TARGET_DIR}/etc/init.d
/usr/bin/install -D -m 0755 ${PROJECT_DIR}/package/${PKGNAME}/initscripts/init.d/* ${TARGET_DIR}/etc/init.d/

echo ">>>   Installing urandom-scripts"
/usr/bin/install -D -m 0755 ${PROJECT_DIR}/package/${PKGNAME}/urandom-scripts/S01seedrng ${TARGET_DIR}/etc/init.d/S01seedrng

echo ">>>   Finalizing target directory"
/usr/bin/sed -i -e '/# GENERIC_SERIAL$/s~^.*#~sole::respawn:/sbin/getty -L  console 0 vt100 #~' ${TARGET_DIR}/etc/inittab
/usr/bin/sed -i -e '/^#.*-o remount,rw \/$/s~^#\+~~' ${TARGET_DIR}/etc/inittab
if grep -q CONFIG_ASH=y ${BUILD_DIR}/busybox-1.37.0/.config; then grep -qsE '^/bin/ash$' ${TARGET_DIR}/etc/shells || echo "/bin/ash" >> ${TARGET_DIR}/etc/shells; fi
if grep -q CONFIG_HUSH=y ${BUILD_DIR}/busybox-1.37.0/.config; then grep -qsE '^/bin/hush$' ${TARGET_DIR}/etc/shells || echo "/bin/hush" >> ${TARGET_DIR}/etc/shells; fi
grep -qsE '^/bin/sh$' ${TARGET_DIR}/etc/shells || echo "/bin/sh" >> ${TARGET_DIR}/etc/shells
grep -qsE '^/bin/bash$' ${TARGET_DIR}/etc/shells || echo "/bin/bash" >> ${TARGET_DIR}/etc/shells
ln -sf bash ${TARGET_DIR}/bin/sh
PYTHONPATH="${STAGING_DIR}/usr/lib/python3.13/" ${HOST_DIR}/bin/python3.13 ${PYTHON3_BUILD_DIR}/Lib/compileall.py  -b -s ${TARGET_DIR} -p / ${TARGET_DIR}/usr/lib/python3.13
find ${TARGET_DIR}/usr/lib/python3.13 -name '*.py'  -print0 | xargs -0 --no-run-if-empty rm -f
find ${TARGET_DIR}/usr/lib/python3.13 -name '*.opt-1.pyc' -print0 -o -name '*.opt-2.pyc' -print0 | xargs -0 --no-run-if-empty rm -f
echo "buildlinux" > ${TARGET_DIR}/etc/hostname
/usr/bin/sed -i -e '$a \127.0.1.1\tbuildlinux' -e '/^127.0.1.1/d' ${TARGET_DIR}/etc/hosts
echo "Welcome to Build Linux System From Scratch" > ${TARGET_DIR}/etc/issue
/usr/bin/sed -i -e s,^root:[^:]*:,root::, ${TARGET_DIR}/etc/shadow
/usr/bin/sed -i -e '/^root:/s,[^/]*$,bash,' ${TARGET_DIR}/etc/passwd
if [ -x ${TARGET_DIR}/sbin/swapon -a -x ${TARGET_DIR}/sbin/swapoff ]; then
	/usr/bin/sed -i -e '/^#.*\/sbin\/swap/s/^#\+[[:blank:]]*//' ${TARGET_DIR}/etc/inittab;
else
	/usr/bin/sed -i -e '/^[^#].*\/sbin\/swap/s/^/#/' ${TARGET_DIR}/etc/inittab;
fi
if test -d ${TARGET_DIR}/lib/modules/6.12.47 && grep -q "CONFIG_MODULES=y" ${BUILD_DIR}/linux-6.12.47/.config; then
	${HOST_DIR}/sbin/depmod -a -b ${TARGET_DIR} 6.12.47;
fi
printf '%s\n' C en_US locale-archive > ${BUILD_DIR}/locales.nopurge
for dir in ${TARGET_DIR}/usr/share/locale ${TARGET_DIR}/usr/share/X11/locale ${TARGET_DIR}/usr/lib/locale; do
	if [ ! -d $dir ]; then continue; fi; 
	for langdir in $dir/*; do 
		if [ -e "${langdir}" ]; then 
			grep -qx "${langdir##*/}" ${BUILD_DIR}/locales.nopurge || rm -rf $langdir;
		fi
	done;
done
if [ -d ${TARGET_DIR}/usr/share/X11/locale ]; then
	for lang in C en_US; do
		if [ -f ${TARGET_DIR}/usr/share/X11/locale/$lang/XLC_LOCALE ]; then
			echo "$lang/XLC_LOCALE: $lang";
		fi
	done > ${TARGET_DIR}/usr/share/X11/locale/locale.dir;
fi
rm -rf ${TARGET_DIR}/usr/include ${TARGET_DIR}/usr/share/aclocal \
	${TARGET_DIR}/usr/lib/pkgconfig ${TARGET_DIR}/usr/share/pkgconfig \
	${TARGET_DIR}/usr/lib/cmake ${TARGET_DIR}/usr/share/cmake \
	${TARGET_DIR}/usr/lib/rpm ${TARGET_DIR}/usr/doc
find ${TARGET_DIR}/usr/{lib,share}/ -name '*.cmake' -print0 | xargs -0 rm -f
find ${TARGET_DIR}/lib/ ${TARGET_DIR}/usr/lib/ ${TARGET_DIR}/usr/libexec/ \
	\( -name '*.a' -o -name '*.la' -o -name '*.prl' \) -print0 | xargs -0 rm -f
rm -rf ${TARGET_DIR}/usr/share/gdb
rm -rf ${TARGET_DIR}/usr/share/zsh
rm -rf ${TARGET_DIR}/usr/man ${TARGET_DIR}/usr/share/man
rm -rf ${TARGET_DIR}/usr/info ${TARGET_DIR}/usr/share/info
rm -rf ${TARGET_DIR}/usr/doc ${TARGET_DIR}/usr/share/doc
rm -rf ${TARGET_DIR}/usr/share/gtk-doc
rmdir ${TARGET_DIR}/usr/share 2>/dev/null || true
rm -rf ${TARGET_DIR}/lib/debug ${TARGET_DIR}/usr/lib/debug
find ${TARGET_DIR}   -type f \( -perm /111 -o -name '*.so*' \) -not \( -name 'libpthread*.so*' -o -name 'ld-*.so*' -o -name '*.ko' \) -print0 | xargs -0 ${CROSS_COMPILE}strip --remove-section=.comment --remove-section=.note 2>/dev/null || true
find ${TARGET_DIR}   \( -name 'ld-*.so*' -o -name 'libpthread*.so*' \) -print0 | xargs -0 -r ${CROSS_COMPILE}strip --remove-section=.comment --remove-section=.note --strip-debug 2>/dev/null || true
test -f ${TARGET_DIR}/etc/ld.so.conf && \
	{ echo "ERROR: we shouldn't have a /etc/ld.so.conf file"; exit 1; } || true
test -d ${TARGET_DIR}/etc/ld.so.conf.d && \
	{ echo "ERROR: we shouldn't have a /etc/ld.so.conf.d directory"; exit 1; } || true
( \
	echo "NAME=BuildLinux"; \
	echo "VERSION=1"; \
	echo "ID=buildlinux"; \
	echo "VERSION_ID=2025.08.1"; \
	echo "PRETTY_NAME=\"Build Linux System From Scratch\"" \
) >  ${TARGET_DIR}/usr/lib/os-release
ln -sf ../usr/lib/os-release ${TARGET_DIR}/etc

echo ">>>   Sanitizing RPATH in target tree"
PATCHELF=${HOST_DIR}/bin/patchelf \
PARALLEL_JOBS=${MAXNUM_CPUS} \
PER_PACKAGE_DIR=${OUTPUT_DIR}/per-package \
${PROJECT_DIR}/support/scripts/fix-rpath target

touch ${TARGET_DIR}/usr