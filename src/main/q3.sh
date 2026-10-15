#!/bin/bash
# Q3：复制素材、备份配置、移动草稿、删除 tmp、设定权限并直接运行 hello.sh。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# TODO：删除下方提示和 exit 77，再填写你的命令。
#整理sentry
mkdir -p "$output/sentry_ws/scripts"
mkdir -p "$output/sentry_ws/config"
mkdir -p "$output/sentry_ws/backup"
mkdir -p "$output/sentry_ws/archive"
#复制脚本
cp "$input/hello.sh" "$output/sentry_ws/scripts"
cp "$input/robot.conf" "$output/sentry_ws/config"
cp "$input/draft.conf" "$output/sentry_ws/config"
#保留，移动配置
cp "$output/sentry_ws/config/robot.conf" "$output/sentry_ws/backup/robot.conf"
mv "$output/sentry_ws/config/draft.conf" "$output/sentry_ws/archive/draft.conf.old"
#删除缓存tmp
rm -rf -- "$output/sentry_ws/tmp"
#修改权限
chmod 750 "$output/sentry_ws/scripts/hello.sh"
chmod 640 "$output/sentry_ws/config/robot.conf"
#执行，输出，保存
"$output/sentry_ws/scripts/hello.sh" > "$output/hello-output.txt"
