if [ "${TRACE}" = "1" ] ; then
    exit 0
fi

if [ "${DEBUG}" = "1" ] ; then
    set -x
fi

ARCH=riscv64
TARGET_VENDOR=unknown
TARGET_OS=linux
LIBC=gnu
ABI=
# riscv64-unknown-linux-gnu
GNU_TARGET_NAME=${ARCH}-${TARGET_VENDOR}-${TARGET_OS}-${LIBC}${ABI}

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_DIR=$(realpath "${SCRIPT_DIR}/../..")
OUTPUT_DIR=${PROJECT_DIR}/output
DL_DIR=${PROJECT_DIR}/dl
HOST_DIR=${OUTPUT_DIR}/host
BUILD_DIR=${OUTPUT_DIR}/build
TARGET_DIR=${OUTPUT_DIR}/target
IMAGES_DIR=${OUTPUT_DIR}/images
STAGING_DIR=${HOST_DIR}/${GNU_TARGET_NAME}/sysroot
STAGING_SUBDIR=${GNU_TARGET_NAME}/sysroot

MAXNUM_CPUS=$(nproc)

CROSS_COMPILE=${HOST_DIR}/bin/${GNU_TARGET_NAME}-

export HOST_DIR TARGET_DIR STAGING_DIR

# FIXME: 我们目前假设 DL_DIR 已经存在, 其创建不作为构建的一部分。
# 以后获取可以考虑为 download 专门写个脚本来创建 DL_DIR 并下载所需的所有的包。

# UPDATE_CONFIG_HOOK
function update_config_guess_sub() {
    echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Updating config.sub and config.guess"
    for file in config.guess config.sub; do
	for i in $(find $1 -name $file); do
	    cp ${PROJECT_DIR}/support/gnuconfig/$file $i
	done
    done
}

# LIBTOOL_PATCH_HOOK
function patch_libtool() {
	echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Patching libtool"
	for i in `find $1 -name ltmain.sh`; do
		ltmain_version=`sed -n '/^[ \t]*VERSION=/{s/^[ \t]*VERSION=//;p;q;}' $i | \
		sed -e 's/\([0-9]*\.[0-9]*\).*/\1/' -e 's/\"//'`;
		ltmain_patchlevel=`sed -n '/^[ \t]*VERSION=/{s/^[ \t]*VERSION=//;p;q;}' $i | \
		sed -e 's/\([0-9]*\.[0-9]*\.*\)\([0-9]*\).*/\2/' -e 's/\"//'`;
		if test ${ltmain_version} = '1.5'; then
			patch -i ${PROJECT_DIR}/support/libtool/buildroot-libtool-v1.5.patch ${i};
		elif test ${ltmain_version} = "2.2"; then
			patch -i ${PROJECT_DIR}/support/libtool/buildroot-libtool-v2.2.patch ${i};
		elif test ${ltmain_version} = "2.4"; then
			if test ${ltmain_patchlevel:-0} -gt 2; then
				patch -i ${PROJECT_DIR}/support/libtool/buildroot-libtool-v2.4.4.patch ${i};
			else
				patch -i ${PROJECT_DIR}/support/libtool/buildroot-libtool-v2.4.patch ${i};
			fi
		elif test ${ltmain_version} = "2.5"; then
			patch -i ${PROJECT_DIR}/support/libtool/buildroot-libtool-v2.4.4.patch ${i};
		fi
	done
}

# Fixing package configuration files when do staging installing.
# parameter: 1 - the package config file name, e.g., pkg-config, cmake
function fix_package_config_files_for_staging_install() {
	if [ -n "${1}" ] ; then
		echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Fixing package configuration files" ;\
		/usr/bin/sed -i -e  "s,${HOST_DIR},@HOST_DIR@,g" \
			-e "s,${OUTPUT_DIR},@BASE_DIR@,g" \
			-e "s,^\(exec_\)\?prefix=.*,\1prefix=@STAGING_DIR@/usr,g" \
			-e "s,-I/usr/,-I@STAGING_DIR@/usr/,g" \
			-e "s,-L/usr/,-L@STAGING_DIR@/usr/,g" \
			-e 's,@STAGING_DIR@,$(dirname $(readlink -e $0))/../..,g' \
			-e 's,@HOST_DIR@,$(dirname $(readlink -e $0))/../../../..,g' \
			-e "s,@BASE_DIR@,${OUTPUT_DIR},g" \
			${STAGING_DIR}/usr/bin/${1} ;
	fi
}

# Fixing libtool files when do staging installing.
function fix_libtool_files_for_staging_install() {
	echo ">>>  ${PKGBUILDNAME} ${PKGVERSION} Fixing libtool files"
	for la in $(find ${STAGING_DIR}/usr/lib* -name "*.la"); do
		cp -a "${la}" "${la}.fixed" && \
		/usr/bin/sed -i -e "s:${OUTPUT_DIR}:@BASE_DIR@:g" \
			-e "s:${STAGING_DIR}:@STAGING_DIR@:g" \
			-e "s:\(['= ]\)/usr:\\1@STAGING_DIR@/usr:g" \
			-e "s:\(['= ]\)/lib:\\1@STAGING_DIR@/lib:g" \
			-e "s:@STAGING_DIR@:${STAGING_DIR}:g" \
			-e "s:@BASE_DIR@:${OUTPUT_DIR}:g" \
			"${la}.fixed" && \
		if cmp -s "${la}" "${la}.fixed"; then \
			rm -f "${la}.fixed"; \
		else \
			mv "${la}.fixed" "${la}"; \
		fi || exit 1;
	done
}

# Check the specified kernel headers version actually matches the
# version in the toolchain.
# toolchain/helpers.mk
function check_kernel_headers_version() {
	if ! ${PROJECT_DIR}/support/scripts/check-kernel-headers.sh ${1} ${2} ${3} ${4}; then
		exit 1;
	fi
}

# Defined in toolchain/helpers.mk
function copy_toolchain_lib_root() {
	LIBPATTERN="${1}"
	LIBPATHS=`find ${STAGING_DIR} -name "${LIBPATTERN}" 2>/dev/null`
	for LIBPATH in ${LIBPATHS} ; do
		while true ; do
			LIBNAME=`basename ${LIBPATH}`
			DESTDIR=`echo ${LIBPATH} | sed "s,^${STAGING_DIR},," | xargs dirname`
			mkdir -p ${TARGET_DIR}/${DESTDIR}
			rm -fr ${TARGET_DIR}/${DESTDIR}/${LIBNAME}
			if test -h ${LIBPATH} ; then
				cp -d ${LIBPATH} ${TARGET_DIR}/${DESTDIR}/${LIBNAME}
				OLD_LIBPATH="${LIBPATH}"
				LIBPATH="`readlink -f ${LIBPATH}`"
				if [ "${LIBPATH}" = "" ]; then
					echo "LIBPATH empty after trying to resolve symlink ${OLD_LIBPATH}" 1>&2
					exit 1
				fi
			elif test -f ${LIBPATH}; then
				/usr/bin/install -D -m0755 ${LIBPATH} ${TARGET_DIR}/${DESTDIR}/${LIBNAME}
				break
			else
				exit -1
			fi
		done
	done
}

function kconfig_enable_option() {
	if ! grep -q "^${1}=[my]" ${PKGBUILD_DIR}/.config; then
		/usr/bin/sed -i -e "/^\(# \)\?${1}\>/d" ${PKGBUILD_DIR}/.config && echo "${1}=y" >> ${PKGBUILD_DIR}/.config;
	fi
}

function kconfig_disable_option() {
	/usr/bin/sed -i -e "/^\(# \)\?${1}\>/d" ${PKGBUILD_DIR}/.config && echo "# ${1} is not set" >> ${PKGBUILD_DIR}/.config
}

# ${1}: base directory to search in
# ${2}: suffix of file (optional)
# example:
# cd ${TARGET_DIR};
# LC_ALL=C find . -not -path './riscv64-unknown-linux-gnu/sysroot/*' \( -type f -o -type l \) -printf '%T@:%i:%#m:%y:%s,%p\n' \
#	| LC_ALL=C sort > ${PKGBUILD_DIR}/.files-list.before
function pkg_size_before() {
	cd ${1};
	LC_ALL=C find . -not -path "./${STAGING_SUBDIR}/*" \( -type f -o -type l \) -printf '%T@:%i:%#m:%y:%s,%p\n' \
		| LC_ALL=C sort > ${PKGBUILD_DIR}/.files-list${2}.before;
}

# ${1}: base directory to search in
# ${2}: suffix of file (optional)
function pkg_size_after() {
	cd ${1}; \
	LC_ALL=C find . -not -path "./${STAGING_SUBDIR}/*" \( -type f -o -type l \) -printf '%T@:%i:%#m:%y:%s,%p\n' \
		| LC_ALL=C sort > ${PKGBUILD_DIR}/.files-list${2}.after
	LC_ALL=C comm -13 \
		${PKGBUILD_DIR}/.files-list${2}.before \
		${PKGBUILD_DIR}/.files-list${2}.after \
		| sed -r -e "s/^[^,]+/${PKGBUILDNAME}/" \
		> ${PKGBUILD_DIR}/.files-list${2}.txt
	rm -f ${PKGBUILD_DIR}/.files-list${2}.before
	rm -f ${PKGBUILD_DIR}/.files-list${2}.after
}

# ${1} step name
function step_start() {
	printf "%s:%-5.5s:%-20.20s: %s\n" "$(date +%s.%N)" "start" "${1}" "${PKGBUILDNAME}" >>"${BUILD_DIR}/build-time.log"
	if [ "${1}" == "download" ]; then
		echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Downloading"
	elif [ "${1}" == "extract" ]; then
		echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Extracting"
	elif [ "${1}" == "patch" ]; then
		echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Patching"
	elif [ "${1}" == "configure" ]; then
		echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Configuring"
	elif [ "${1}" == "build" ]; then
		echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Building"
	elif [ "${1}" == "install-host" ]; then
		echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Installing to host directory"
	elif [ "${1}" == "install-staging" ]; then
		echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Installing to staging directory"
	elif [ "${1}" == "install-target" ]; then
		echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Installing to target"
	elif [ "${1}" == "install-image" ]; then
		echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Installing to images directory"
	fi

	if [ "${1}" == "configure" ]; then
		mkdir -p ${HOST_DIR} ${TARGET_DIR} ${STAGING_DIR} ${IMAGES_DIR}
		pkg_size_before ${TARGET_DIR}
		pkg_size_before ${STAGING_DIR} -staging
		pkg_size_before ${IMAGES_DIR} -images
		pkg_size_before ${HOST_DIR} -host
	fi
}

# ${1} step name
# ${2} 如果 ${1} 为 "patch", 则可能存在 ${2}，用于标识构建类型；目前支持的有效值为
#      "autotool", 其他情况不给出则默认为不适用 autotools，譬如采用 kconfig 的，
#      如 linux，busybox 等。
#      对于该分支，如果 ${2} 为空则 ${3} 也必须为空
#      如果 ${1} 为 "install-staging", 则可能存在 ${2}
# ${3} 如果 ${1} 为 "patch" 并且 ${2} 为 "autotools"，则可以继续指定 ${3} 用于指
#      定是否需要忽略给 libtool 打补丁，"ignore_libtool_patch" 表示忽略。默认如果
#      不指明则缺省要给 libtool 打补丁
function step_end() {
	if [ "${1}" == "patch" ]; then
		# 如果是采用 autotools 方式构建才有可能需要更新 config.guess
		# 以及对 libtool 打补丁。
		# 但也有几种情况是不需要在 patch 阶段对 libtool 打补丁的
		# 一种是 configure 阶段会运行 autoreconf，对该种情况我们会在
		# 运行完 autoreconf 后再对 libtool 打补丁
		# 还有一种情况是明确不需要对 libtool 打补丁的，譬如本身就是在
		# 构建 libtool。
		if [ "${2}" == "autotools" ]; then
			update_config_guess_sub ${PKGBUILD_DIR}
			if [ "${3}" != "ignore_libtool_patch" ]; then
				patch_libtool ${PKGBUILD_DIR}
			fi
		fi
	elif [ "${1}" == "install-host" ]; then
		rm -f -rf  ${HOST_DIR}/share/info/dir
	elif [ "${1}" == "install-staging" ]; then
		rm -f -rf  ${STAGING_DIR}/share/info/dir
		fix_package_config_files_for_staging_install ${2}
		fix_libtool_files_for_staging_install
	elif [ "${1}" == "install-target" ]; then
		rm -f -rf  ${TARGET_DIR}/share/info/dir
	fi
	printf "%s:%-5.5s:%-20.20s: %s\n" "$(date +%s.%N)" "end" "${1}" "${PKGBUILDNAME}" >>"${BUILD_DIR}/build-time.log"
	if [ "${1}" == "install-host" ]; then
		${PROJECT_DIR}/support/scripts/check-host-rpath ${PKGBUILDNAME} ${HOST_DIR} ${OUTPUT_DIR}/per-package
	fi
	# 这里应该有一步 step_check_build_dir，但从 make 的 log 看感觉这里传入的 $(STAGING_DIR)/$(O) 会有问题
	# FIXME，先不加这个 check
	mkdir -p ${PKGBUILD_DIR}
	if [ "${1}" == "download" ]; then
		touch ${PKGBUILD_DIR}/.stamp_downloaded
	elif [ "${1}" == "extract" ]; then
		touch ${PKGBUILD_DIR}/.stamp_extracted
	elif [ "${1}" == "patch" ]; then
		touch ${PKGBUILD_DIR}/.stamp_patched
	elif [ "${1}" == "configure" ]; then
		touch ${PKGBUILD_DIR}/.stamp_configured
	elif [ "${1}" == "build" ]; then
		touch ${PKGBUILD_DIR}/.stamp_built
	elif [ "${1}" == "install-host" ]; then
		touch ${PKGBUILD_DIR}/.stamp_host_installed
	elif [ "${1}" == "install-staging" ]; then
		touch ${PKGBUILD_DIR}/.stamp_staging_installed
	elif [ "${1}" == "install-target" ]; then
		touch ${PKGBUILD_DIR}/.stamp_target_installed
	elif [ "${1}" == "install-image" ]; then
		touch ${PKGBUILD_DIR}/.stamp_images_installed
	fi
}

function stamp_downloaded() {
	local STARTED=n
	# PKGSOURCE is MUST to have; PKGSOURCE2 is OPTIONAL
	if [ ! -z "${PKGSOURCE}" ]; then
		for p in ${PKGURL}; do
			f=`basename ${p}`
		        if [ ! -e "${DL_DIR}/${PKGSOURCE_DIR}/${f}" ] ; then
				if [ ${STARTED} = "n" ]; then
					step_start download
					STARTED=y
				fi
				mkdir -p ${DL_DIR}/${PKGSOURCE_DIR}
				(cd ${DL_DIR}/${PKGSOURCE_DIR}; wget ${PKGURL})
				if [ $? -ne 0 ]; then
					echo ">>> ${PKGBUILDNAME} ${PKGVERSION} Downloading FAILED!!!"
					exit 1
				fi
			fi
		done
		if [ ${STARTED} = "y" ]; then
			step_end download
		fi
	fi
	if [ "${ONLY_DOWNLOAD}" = "y" ] ; then
		exit 0
	fi
}

function stamp_extracted() {
	step_start extract
	step_end extract
}

# ${1}: see comments for ${2} of step_end
function stamp_patched() {
	step_start patch
	step_end patch ${1}
}

function stamp_configured() {
	step_start configure
	step_end configure
}

function stamp_built() {
	step_start build
	step_end build
}

function stamp_installed() {
	pkg_size_after ${TARGET_DIR}
	pkg_size_after ${STAGING_DIR} -staging
	pkg_size_after ${IMAGES_DIR} -images
	pkg_size_after ${HOST_DIR} -host
	${PROJECT_DIR}/support/scripts/check-bin-arch -p ${PKGBUILDNAME} -l ${PKGBUILD_DIR}/.files-list.txt  -r ${CROSS_COMPILE}readelf -a "RISC-V"
	touch ${PKGBUILD_DIR}/.stamp_installed
}

HOST_MAKE_ENV='GIT_DIR=. PATH="${HOST_DIR}/bin:${HOST_DIR}/sbin:${PATH}" PKG_CONFIG="${HOST_DIR}/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="${HOST_DIR}/lib/pkgconfig:${HOST_DIR}/share/pkgconfig"'

HOST_CONFIGURE_OPTS='GIT_DIR=. PATH="${HOST_DIR}/bin:${HOST_DIR}/sbin:${PATH}" PKG_CONFIG="${HOST_DIR}/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="${HOST_DIR}/lib/pkgconfig:${HOST_DIR}/share/pkgconfig" AR="/usr/bin/ar" AS="/usr/bin/as" LD="/usr/bin/ld" NM="/usr/bin/nm" CC="/usr/bin/gcc" GCC="/usr/bin/gcc" CXX="/usr/bin/g++" CPP="/usr/bin/cpp" OBJCOPY="/usr/bin/objcopy" RANLIB="/usr/bin/ranlib" CPPFLAGS="-I${HOST_DIR}/include" CFLAGS="-O2 -I${HOST_DIR}/include" CXXFLAGS="-O2 -I${HOST_DIR}/include" LDFLAGS="-L${HOST_DIR}/lib -Wl,-rpath,${HOST_DIR}/lib" INTLTOOL_PERL=/usr/bin/perl'

AUTORECONF_OPTS='GIT_DIR=. PATH="${HOST_DIR}/bin:${HOST_DIR}/sbin:${PATH}" PKG_CONFIG="${HOST_DIR}/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="${HOST_DIR}/lib/pkgconfig:${HOST_DIR}/share/pkgconfig" AR="/usr/bin/ar" AS="/usr/bin/as" LD="/usr/bin/ld" NM="/usr/bin/nm" CC="/usr/bin/gcc" GCC="/usr/bin/gcc" CXX="/usr/bin/g++" CPP="/usr/bin/cpp" OBJCOPY="/usr/bin/objcopy" RANLIB="/usr/bin/ranlib" CPPFLAGS="-I${HOST_DIR}/include" CFLAGS="-O2 -I${HOST_DIR}/include" CXXFLAGS="-O2 -I${HOST_DIR}/include" LDFLAGS="-L${HOST_DIR}/lib -Wl,-rpath,${HOST_DIR}/lib" INTLTOOL_PERL=/usr/bin/perl ACLOCAL="${HOST_DIR}/bin/aclocal" AUTOCONF="${HOST_DIR}/bin/autoconf -I "${STAGING_DIR}/usr/share/aclocal" -I "${HOST_DIR}/share/aclocal"" AUTOHEADER="${HOST_DIR}/bin/autoheader -I "${STAGING_DIR}/usr/share/aclocal" -I "${HOST_DIR}/share/aclocal"" AUTOMAKE="${HOST_DIR}/bin/automake" GTKDOCIZE=/bin/true'

TARGET_MAKE_ENV='GIT_DIR=. PATH="${HOST_DIR}/bin:${HOST_DIR}/sbin:${PATH}"'

TARGET_CONFIGURE_OPTS='GIT_DIR=. PATH="${HOST_DIR}/bin:${HOST_DIR}/sbin:${PATH}" AR="${CROSS_COMPILE}gcc-ar" AS="${CROSS_COMPILE}as" LD="${CROSS_COMPILE}ld" NM="${CROSS_COMPILE}gcc-nm" CC="${CROSS_COMPILE}gcc" GCC="${CROSS_COMPILE}gcc" CPP="${CROSS_COMPILE}cpp" CXX="${CROSS_COMPILE}g++" FC="${CROSS_COMPILE}gfortran" F77="${CROSS_COMPILE}gfortran" RANLIB="${CROSS_COMPILE}gcc-ranlib" READELF="${CROSS_COMPILE}readelf" STRIP="${CROSS_COMPILE}strip" OBJCOPY="${CROSS_COMPILE}objcopy" OBJDUMP="${CROSS_COMPILE}objdump" AR_FOR_BUILD="/usr/bin/ar" AS_FOR_BUILD="/usr/bin/as" CC_FOR_BUILD="/usr/bin/gcc" GCC_FOR_BUILD="/usr/bin/gcc" CXX_FOR_BUILD="/usr/bin/g++" LD_FOR_BUILD="/usr/bin/ld" CPPFLAGS_FOR_BUILD="-I${HOST_DIR}/include" CFLAGS_FOR_BUILD="-O2 -I${HOST_DIR}/include" CXXFLAGS_FOR_BUILD="-O2 -I${HOST_DIR}/include" LDFLAGS_FOR_BUILD="-L${HOST_DIR}/lib -Wl,-rpath,${HOST_DIR}/lib" FCFLAGS_FOR_BUILD="" DEFAULT_ASSEMBLER="${CROSS_COMPILE}as" DEFAULT_LINKER="${CROSS_COMPILE}ld" CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1" CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1" LDFLAGS="" FCFLAGS=" -O2 -g0" FFLAGS=" -O2 -g0" PKG_CONFIG="${HOST_DIR}/bin/pkg-config" STAGING_DIR="${STAGING_DIR}" INTLTOOL_PERL=/usr/bin/perl'