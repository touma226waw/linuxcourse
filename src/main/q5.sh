#!/bin/bash
# Q5：运行 launch.env 给定的启动前检查，保存 stdout/stderr、真实退出码和诊断报告。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# TODO：删除下方提示和 exit 77，再填写你的命令。
#启动前检查
source "$input/launch.env"
if bash "$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" 2> "$output/stderr.log" > "$output/stdout.log"
then
     exit_code=0
else
     exit_code=$?
fi
#创建exitcode.exe
printf '%s\n' "$exit_code" > "$output/exit-code.txt"
#判断错误并记录
case "$exit_code" in
    0)
        result=SUCCESS
        reason=NONE
        ;;
    10)
        result=FAILED
        reason=MODEL_MISSING
        ;;
    20)
        result=FAILED
        reason=CAMERA_DENIED
        ;;
esac
#return
cat > "$output/report.txt" <<EOF
result=$result
exit_code=$exit_code
reason=$reason
EOF
