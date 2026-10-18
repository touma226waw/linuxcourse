#!/bin/bash
# Q7：读取 input/remote.env，生成 ssh_config，用 SSH 和 SCP 获取远程数据。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# TODO：删除下方提示和 exit 77，再填写你的命令。
#读取输入
source "$input/remote.env"
#创建config配置
cat > "$output/ssh_config" <<EOF
Host aim-sentry
    HostName "$HOST"
    Port "$PORT"
    User "$REMOTE_USER"
    IdentityFile "$KEY_PATH"
    IdentitiesOnly yes
    StrictHostKeyChecking yes
    UserKnownHostsFile "$KNOWN_HOSTS"
    BatchMode yes
EOF
#授权
chmod 600 "$output/ssh_config"
#使用该配置和别名通过 SSH 执行远端 whoami，将返回的用户名保存为 remote-user.txt
ssh -F "$output/ssh_config" aim-sentry "whoami" > "$output/remote-user.txt"
#使用 SCP 将 REMOTE_LOG 下载为输出目录的 received/errors.log
mkdir -p "$output/received"
scp -F "$output/ssh_config" "aim-sentry:$REMOTE_LOG" "$output/received/errors.log"

