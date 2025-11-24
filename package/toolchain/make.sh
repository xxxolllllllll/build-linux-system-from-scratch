#!/usr/bin/bash
source $(dirname "$0")/../common.sh

PKGNAME=toolchain
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
# /etc/nsswitch.conf 的全称是 Name Service Switch configuration file（名称服务切换配置文件）。
# 它的主要作用是告诉操作系统，当需要查询某类信息（比如用户名、主机名、组信息等）时，
# 应该按照什么顺序、从哪些数据源去查找。可以把它看作是一个 “查询路由表” 或 “信息查找指南”
# 至于为何会存在这个需求，是因为在现代操作系统中，同一种信息可能存在于多个地方。
# 例如，用户名和用户ID（UID）可能存在于：本地文件：如 /etc/passwd, /etc/group；或者
# 网络服务：如 LDAP（轻型目录访问协议）、NIS（网络信息服务）、Active Directory（AD）；
# 或者 DNS（域名系统）：用于主机名解析
# 当系统运行一个命令（如 ls -l，它会显示文件所有者用户名）或一个程序调用一个函数
# （如 getpwuid() 来通过UID查找用户名）时，系统需要知道：先查哪里？ 是先查本地文件还是先查网络服务？
# 如果第一个源查不到或出错了，怎么办？ 是继续查下一个源，还是直接报错？nsswitch.conf 就是为
# 了解决这些问题而生的。
# 这个文件的内容通常由很多行组成，每行对应一种信息的查询配置。其基本格式是：
# <数据库类型>:    <查找顺序>
# 例子：passwd:      files systemd
# 当需要查询用户信息时，首先，查询本地文件 /etc/passwd (files)，如果没找到，再去 systemd 的动态用户库中查找。
# 更多例子不再赘述。
# 注意这个 Name Service Switch 服务（NSS）是由 glibc 提供的，由一系列系统数据库查询函数组成，譬如：
# getpwnam(), getpwuid() - 获取用户信息（/etc/passwd）
# getgrnam(), getgrgid() - 获取用户组信息（/etc/group）
# gethostbyname(), getaddrinfo() - 获取主机名和IP地址信息（/etc/hosts, DNS）
# getservbyname() - 获取网络服务信息（/etc/services）
# 该服务的核心组件包括：
# - 配置文件：/etc/nsswitch.conf
# - 一系列共享库模块：位于/lib或/lib64目录下，名称通常为libnss_*.so.2（例如 libnss_files.so.2,
#  libnss_dns.so.2, libnss_ldap.so.2）。
# 由以上分析，我们可以得知，由于 nsswitch.conf 主要被 glibc 使用，所以我们将其视为工具链的一部分
# 如果我们工具链使用的是其他 C 库（如 uClibc、musl），这个文件通常不是必需的
# 构建 glibc 后会生成 nsswitch.conf 文件，但我们没有直接用，而是提供了一个自己定义的版本。
# 这里的 nsswitch.conf 是一个 默认的安全配置。这个默认配置通常比较简单，例如对于 hosts 数据库，
# 配置可能是 files dns，意味着先查找 /etc/hosts 文件，再使用 DNS 查询
# 同时它只在 目标系统 /etc/ 目录下尚不存在 nsswitch.conf 时 才拷贝默认文件，
if [ ! -f "${TARGET_DIR}/etc/nsswitch.conf" ]; then
    /usr/bin/install -D -m 0644 ${PROJECT_DIR}/package/glibc/nsswitch.conf ${TARGET_DIR}/etc/nsswitch.conf
fi
step_end install-target

stamp_installed

echo "<---- ${PKGBUILDNAME} build complete."
