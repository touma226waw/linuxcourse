#!/bin/bash
# Q6：将本地 Debian 包安装到 output/sysroot，运行安装后的工具。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# TODO：删除下方提示和 exit 77，再填写你的命令。
#创建安装
mkdir -p "$output/sysroot"
dpkg --root="$output/sysroot" --force-not-root -i "$input/aim-sentry-tools.deb"
#读取包名
package=$(dpkg-deb -f "$input/aim-sentry-tools.deb" Package)
#查询包名
dpkg-query \
    --admindir="$output/sysroot/var/lib/dpkg" \
    -W \
    -f='${Package} ${Version}\n' \
    "$package"
#输出
"$output/sysroot/usr/bin/aim-sentry-info" > "$output/tool-output.txt"

