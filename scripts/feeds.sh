#!/bin/bash
#
# 追加第三方 feed —— 在 OpenWrt 源码根目录执行，./scripts/feeds update 之前
#
# ImmortalWrt 25.12 的自带 feed 已覆盖本项目所需的全部软件包，
# 默认无需添加任何额外源。
#
# 真要加的时候按下面的格式追加，并在 README 里记一笔来源和加它的理由：
#
#   echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages' >> feeds.conf.default
#
# 注意：每加一个第三方 feed，就多一个会在上游变动时拖垮构建的点。
# 加之前先确认自带 feed 里真的没有。
#
set -e
echo ">>> 未配置额外 feed，使用 ImmortalWrt 默认源"
