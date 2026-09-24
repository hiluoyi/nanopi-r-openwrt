#!/bin/bash
#
# 在 OpenWrt 源码根目录执行，make defconfig 之前
# 这里只做"改源码模板"的事；开机后才生效的设置放在 files/etc/uci-defaults/
#
set -e

echo ">>> 应用自定义修改..."

# ---------------------------------------------------------------
# 默认 LAN IP：192.168.1.1 -> 192.168.2.1
# 改的是出厂模板，所以「恢复出厂设置」之后依然是 192.168.2.1
# ---------------------------------------------------------------
sed -i 's/192\.168\.1\.1/192.168.2.1/g' package/base-files/files/bin/config_generate
echo "    默认 LAN IP  -> 192.168.2.1"

# ---------------------------------------------------------------
# 默认主机名
# ---------------------------------------------------------------
sed -i -E "s/hostname='(ImmortalWrt|LEDE|OpenWrt)'/hostname='NanoPi'/g" package/base-files/files/bin/config_generate
echo "    默认主机名   -> NanoPi"

# ---------------------------------------------------------------
# 安全：确保不会把任何固定的 SSH 主机密钥打进固件
# 原 stupidloud/nanopi-openwrt 预置了静态 dropbear 密钥，
# 导致所有用户设备共用同一套密钥。这里显式清掉。
# ---------------------------------------------------------------
rm -rf files/etc/dropbear
echo "    已确认不预置 SSH 主机密钥"

# ---------------------------------------------------------------
# 写入构建信息，刷机后 cat /etc/nanopi-release 就知道是哪一版
# ---------------------------------------------------------------
mkdir -p files/etc
cat > files/etc/nanopi-release <<-INFO
	BUILD_DATE="${BUILD_DATE:-unknown}"
	SOURCE_REPO="${REPO_URL:-immortalwrt}"
	SOURCE_BRANCH="${REPO_BRANCH:-openwrt-25.12}"
	BUILDER="${GITHUB_REPOSITORY:-local}"
	RUN_ID="${GITHUB_RUN_ID:-local}"
INFO
echo "    已写入 /etc/nanopi-release"

echo ">>> 自定义修改完成"
