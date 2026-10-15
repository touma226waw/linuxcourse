#!/bin/bash
# Q4：合并日志，按级别提取，保存首尾片段并统计错误行数。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# TODO：删除下方提示和 exit 77，再填写你的命令。
#拼接boot和run
cat "$input/boot.log" "$input/run.log" > "$output/all.log"
#级别字段等于 ERROR 的完整行
grep "^ERROR" "$output/all.log" > "$output/errors.log"||true
#级别字段等于 WARN 或 ERROR 的完整行
grep -E "^(ERROR|WARN)" "$output/all.log" >"$output/attention.log"||true
#all 最后 5 行，不足则全部
tail -n 5 "$output/all.log" > "$output/recent.log"
#errors 最前 3 行，不足则全部
head -n 3 "$output/errors.log" > "$output/first-errors.log"
#错误行数，只有整数与换
grep -c "^ERROR" "$output/all.log" > "$output/error-count.txt" ||true

