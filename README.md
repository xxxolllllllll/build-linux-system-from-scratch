**从零开始为 RISC-V 构建一个 Linux 系统**

<!-- TOC -->

- [1. 课程简介](#1-课程简介)
- [2. 本仓库介绍](#2-本仓库介绍)
- [3. 运行环境](#3-运行环境)
- [4. 下载本仓库](#4-下载本仓库)
- [5. 构建和使用说明](#5-构建和使用说明)
	- [5.1. 批量下载软件包源码压缩包](#51-批量下载软件包源码压缩包)
	- [5.2. 构建](#52-构建)
	- [5.3. 运行](#53-运行)
- [6. 致谢](#6-致谢)

<!-- /TOC -->

# 1. 课程简介

随着 RISC-V 生态的不断发展，越来越多的开发者开始在实际项目中接触 RISC-V 架构下的 Linux 系统。然而在学习与实践过程中，开发者往往会遇到以下困惑：

- 使用现成镜像可以快速启动，但对系统的构成与启动流程缺乏整体认知。
- 能够编译内核或应用程序，却不清楚各组件之间的依赖关系。
- 对工具链、OpenSBI、内核、文件系统等概念有所了解，但理解碎片化，尚未形成完整体系。

针对这些常见困惑，中国科学院软件研究所智能软件研究中心特此推出由汪辰老师主讲的在线慕课课程：《从零开始为 RISC-V 构建一个 Linux 系统》。本课程内容涵盖交叉编译工具链的制作、SBI 固件的构建、Linux 内核的编译与加载、根文件系统的组织与实现，并最终在 QEMU 模拟器中运行自制的 Linux 系统。通过本课程的学习，希望能够帮助大家更加系统地了解和掌握构建一个完整的 Linux 操作系统所需的关键知识与方法。

本课程也是 openRuyi 课程系列的重要组成部分。

在线慕课 B 站地址：<https://www.bilibili.com/video/BV1C5f1B2EwH>

欢迎加入本课程的 QQ 学习群 (群号：1090841283)，边学习边讨论：

![](./qq-group.png)

# 2. 本仓库介绍

本仓库包含课程《从零开始为 RISC-V 构建一个 Linux 系统》的配套课件和构建脚本代码。该课程用于教学演示如何从零开始为 RISC-V 平台构建一个 Linux 系统。采用 GPL v2 许可证发布（具体请阅读本仓库根目录下的 [LICENSE 文件](./LICENSE)）。

本仓库目录文件介绍：

- `package`: 目录，用于存放每个软件包的构建素材（譬如补丁文件）和构建脚本。
- `slides`: 目录，用于存放本课程对应的课件（pdf）。
- `support`：目录，用于存放构建中会用到的一些辅助脚本和素材文件。
- `.gitignore`: Git 配置文件，用于指定哪些文件或目录应该被 Git 忽略，不纳入版本控制。
- `build.sh`: 执行 `make` 时会执行的脚本文件。
- `LICENSE`: 本仓库的发布许可证文件。
- `Makefile`: make 文件。
- `README.md`: 本文件。
- `source.sh`: 执行 `make source` 时会执行的脚本文件。

执行构建过程中还会创建以下目录，但不作为本仓库的一部分。

- `dl`: 目录，用于存放网络下载的软件包源码压缩包。
- `output`: 目录，用于存放构建的输出，即本课程定义的 `${OUTPUT_DIR}`。

# 3. 运行环境

本仓库提供了对应课程内容的参考构建脚本，构建脚本在 Ubuntu 22.04 LTS 和 Ubuntu 24.04 LTS 上验证通过。有关运行环境的具体要求可以参考课件 “第 3 章 构建 Linux 系统之前的准备工作” 的 02 部分：“构建环境准备” 的介绍。

也欢迎大家在其他 Linux 发行版上尝试，原理上本仓库的参考构建脚本并不局限于 Ubuntu 系统。

# 4. 下载本仓库

```shell
$ git clone https://git.openruyi.cn/openRuyi-tutorials/build-linux-system-from-scratch.git
```

下载后进入课程仓库目录：

```shell
$ cd build-linux-system-from-scratch
```

下文假设下载后的课程仓库目录为 `${PROJECT_DIR}`，不再赘述。

**注意：由于本仓库代码出于演示 Step by Step 的修改过程的目的，main 分支的 commit 仅用于演示步骤而不反应实际 git 提交历史，所以在同步本地仓库时不支持简单的 pull。建议每次同步本地时直接采用完整的 clone 方式**。

# 5. 构建和使用说明

本节运行命令时假设都在 `${PROJECT_DIR}`，即本仓库所在路径下运行，不再赘述。

本仓库的构建命令无需 root 权限。

## 5.1. 批量下载软件包源码压缩包

强烈建议在开始构建之前先完整下载所需的软件包源码压缩包。

批量下载软件包源码压缩包的命令如下。注意：中途可能失败，多半是因为网络超时所致，可以多试几次以下命令，直到全部成功。

```shell
$ make source
```

如果仍然无法完整下载软件包，也可以去 openRuyi 仓库克隆一份。确保在 `${PROJECT_DIR}` 下执行如下命令：

```shell
$ git clone --depth 1 --branch main https://git.openruyi.cn/openRuyi-tutorials/packages-for-build-linux-system-from-scratch.git dl
```

## 5.2. 构建

本仓库的主分支 main 上有 6 个 commit，从下到上分别对应以下步骤：

```
Step6: add python and snake.
Step5: add vim.
Step4: enhanced shell with bash.
Step3: enhanced with coreutiles.
Step2: enhanced with sysvinit
Step1: build with busybox.
```

学习者可以 checkout 到任意一个 commit 并运行以下命令进行构建。注意：本仓库的构建脚本不支持增量构建，只支持从零开始一次性构建（实际上执行 `make` 内部也会默认先执行 `make clean`）。

```shell
$ make clean
$ make
```

## 5.3. 运行

构建成功后可以进入 `${IMAGES_DIR}` 执行脚本，运行 QEMU 模拟器并加载我们制作的 Linux 系统。

```shell
$ cd output/images/
$ ./start-qemu.sh
```

登录系统的用户名是 root，无密码。

关机可以在登录系统后在控制台中输入 poweroff 命令，或者直接 "Ctrl+A X" 强制退出 QEMU（所谓 "Ctrl+A X" 是指同时按下 Ctrl 和 A，同时松开后再按 X）。

# 6. 致谢

本仓库的构建脚本参考了 [Buildroot (2025.08.1)](https://buildroot.org/)。在此表示衷心感谢！
