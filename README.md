# NanoPi R2S / R4S / R5S OpenWrt 固件

基于 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) `openwrt-25.12` 分支，
用 GitHub Actions 自动编译 NanoPi R2S、R4S、R5S 三款软路由的固件：R2S、R5S 基于 ImmortalWrt，R4S 基于 LEDE 单独构建（原因见下文）。

R2S 和 R5S 同属 `rockchip/armv8`（aarch64_generic）架构，**一次编译同时产出两个机型的固件**。

## 下载

去 [Releases](../../releases) 拿最新的包，认准文件名里的机型：

| 文件 | 适用 |
|---|---|
| `*friendlyarm_nanopi-r2s*` | NanoPi R2S (RK3328) |
| `*friendlyarm_nanopi-r4s*`（在 `r4s-lede-` 开头的发布里） | NanoPi R4S (RK3399) |
| `*friendlyarm_nanopi-r5s*` | NanoPi R5S (RK3568) |

每个机型有两种根文件系统：

- **`-ext4-sysupgrade.img.gz`** — 可以用 `resize2fs` 扩容根分区，要装 Docker 或大插件选它
- **`-squashfs-sysupgrade.img.gz`** — 带 overlay，支持一键恢复出厂设置，日常用选它

## R4S 单独构建（LEDE）

部分 NanoPi R4S 在 ImmortalWrt 25.12 的开源引导链下无法启动（只亮 Power 灯），
同一块板用 LEDE 固件可以正常运行。因此 R4S 另有一条基于
[coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) 的构建：

- 工作流：`.github/workflows/build-r4s-lede.yml`（Actions → Build R4S (LEDE)，手动触发）
- 配置：`config-lede/r4s.config`
- 发布标签：`r4s-lede-日期`
- **默认密码是 `password`**（LEDE 默认），与 ImmortalWrt 版的空密码不同

## 默认设置

| 项 | 值 |
|---|---|
| 管理地址 | **http://192.168.2.1** |
| 用户名 | `root` |
| 密码 | **空，首次登录后请立刻设置** |
| 主机名 | `NanoPi` |
| 时区 | `Asia/Shanghai` |
| 主题 | Argon |
| 包管理器 | apk（OpenWrt 25.12 起取代 opkg） |

默认网段用 `192.168.2.x` 而不是 `192.168.1.x`，是为了避开国内光猫默认的 `192.168.1.1`，
免得网段冲突导致上不了网或进不去后台。这个改动写在出厂模板里，**恢复出厂设置后依然生效**。

## 刷机

```bash
gzip -d immortalwrt-*-friendlyarm_nanopi-r5s-squashfs-sysupgrade.img.gz
sudo dd if=immortalwrt-*.img of=/dev/sdX bs=4M status=progress conv=fsync
```

Windows 下用 [balenaEtcher](https://etcher.balena.io/) 或 Rufus 写卡即可。

刷完插卡开机，**把电脑网线拔掉重插一次**（强制重新 DHCP），然后访问 http://192.168.2.1。

## 自己改配置

| 想改什么 | 改哪个文件 |
|---|---|
| 加/减插件 | `config/10-packages.config` |
| 换机型、改分区大小、改镜像格式 | `config/00-target.config` |
| 默认 IP、主机名等出厂模板 | `scripts/customize.sh` |
| 首次开机执行的设置 | `files/etc/uci-defaults/99-custom-settings` |
| 塞任意文件进固件 | 直接放进 `files/` 下对应路径 |
| 加第三方软件源 | `scripts/feeds.sh` |

改完 push，到 Actions 页面手动触发 **Build OpenWrt** 即可。
构建日志里有一段 **"被 defconfig 丢弃的包"**，如果插件名写错或上游已删除，会在那里列出来。

## 构建

- **手动**：Actions → Build OpenWrt → Run workflow
- **自动**：每月 1 号北京时间 04:00 跑一次
- **耗时**：首次约 2.5~3.5 小时；`dl` 和 `ccache` 命中后约 1 小时
- **调试**：触发时勾选 `ssh_debug`，会开一个 tmate SSH 会话进去看

仓库必须是 **public**，这样 GitHub Actions 标准 runner 免费无限分钟。
私有仓库每月只有 2000 分钟，编译两次就没了。

## 设计说明

这个项目在思路上参考了已停止维护的
[stupidloud/nanopi-openwrt](https://github.com/stupidloud/nanopi-openwrt)（最后更新 2024-04），
但在几个关键处做了不同的选择：

| | 原项目 | 本项目 |
|---|---|---|
| 源码 | coolsnowwolf/lede | ImmortalWrt 稳定分支 |
| 构建方式 | 全量编译所有 luci-app → 生成 ImageBuilder → 二次打包 | 只编实际需要的包，一步出固件 |
| 增量缓存 | 依赖作者私人仓库的 30GB btrfs 镜像 | `actions/cache` 缓存 `dl` 和 `ccache` |
| 打补丁 | `grep -n` 取行号后 `sed Nd` 删行 | `uci-defaults` + 标准 patch |
| 机型 | 每个机型单独全量编译 | R2S/R5S 一次编译，R4S 单独编译 |
| SSH 主机密钥 | 固件内预置静态密钥（所有用户共用） | 不预置，设备首次开机随机生成 |

原项目那套两阶段流水线是为"一次编译供给所有机型的全量离线软件源"设计的，
代价是必须维护 30GB 的私人增量缓存，且大量 `sed` 补丁绑死在第三方 Makefile 的具体行号上。
本项目放弃了离线软件源这个特性，换来的是**任何人 fork 过去都能直接跑通**。

## 许可

构建脚本以 MIT 许可发布。固件本身遵循 OpenWrt / ImmortalWrt 及各软件包各自的许可。
