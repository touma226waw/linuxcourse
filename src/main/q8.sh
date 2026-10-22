#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

# TODO：删除下方提示和 exit 77，再填写你的命令。
#采集器处理
if [ "$action" = "repair" ]; then
    #启动
    source "$input/server.conf"
    source "$input/process.env"
    #查看进程
    ps -p "$TARGET_PID" -o pid=,user=,state=,args=
   target_pid=$(ps -p "$TARGET_PID" -o pid= | tr -d '[:space:]')
    target_user=$(ps -p "$TARGET_PID" -o user=)
    target_state=$(ps -p "$TARGET_PID" -o state=)
    target_command=$(ps -p "$TARGET_PID" -o args=)
    #检查实例
    case "$target_command" in
        *"$TARGET_TOKEN"*)
            ;;
        *)
            printf '目标进程实例标识不匹配\n' >&2
            exit 1
            ;;
    esac
    case "$target_state" in
        R*|S*)
            ;;
        *)
            printf '目标进程状态不正确：%s\n' "$target_state" >&2
            exit 1
            ;;
    esac
    #保存输出
    cat > "$output/process.txt" <<EOF
pid=$target_pid
user=$target_user
state=$target_state
command=$target_command
EOF
    #保存至少两条目标采集器的 TICK 日志为 collector-sample.log，允许包含 START
    ticks=$(grep -c 'TICK' "$WORKER_LOG" || true)
    i=0
    while [ "$ticks" -lt 2 ]; do
        sleep 1
        i=$((i + 1))
        ticks=$(grep -c 'TICK' "$WORKER_LOG" || true)
        if [ "$i" -ge 3 ]
        then
        break
        fi
    done
    if [ "$ticks" -lt 2 ];
        then
        printf '等待两条 TICK 超时\n' >&2
        exit 1
        fi
    grep 'TICK' "$WORKER_LOG" > "$output/collector-sample.log"
    #向目标 PID 发送普通终止信号，等待它正常退出
    kill -TERM "$target_pid"
    #检查退出
    stopped=0
    j=0
    while [ "$j" -lt 3 ]
    do
        j=$((j + 1))
        if grep -Fqx -- "STOP $TARGET_TOKEN" "$WORKER_LOG"
        then
        sleep 1
        stopped=1
        break
    fi
    sleep 1
done
    #检查保留采集器
    if [ "$stopped" -ne 1 ]; then
        printf '目标采集器未正常停止\n' >&2
        exit 1
    fi

#修复HTTP
    source "$input/server.conf"
    source "$input/process.env"
    #正常停止 SERVICE_PID 指定的原服务，等待退出
    if kill -0 "$SERVICE_PID" 2>/dev/null; then
        kill -TERM "$SERVICE_PID"
    fi
    deadline=$((SECONDS + 3))
    while [ -n "$(ss -H -ltn "sport = :${TARGET_PORT}")" ]
    do
        if [ "$SECONDS" -ge "$deadline" ]; then
            printf '原 HTTP 服务或端口未按时释放\n' >&2
            exit 1
        fi
    sleep 1
    done
    #生成输出 server.con
    cat > "$output/server.conf" <<EOF
bind=127.0.0.1
port=${TARGET_PORT}
route=/status
EOF
    #使用教师启动工具运行修复后的服务
    bash "$START_TOOL" "$output/server.conf" "$output/service"
    #
        http_code=
        attempt=0
    while [ "$attempt" -lt 3 ]; do
        if http_code=$(
            curl --silent --show-error --fail --max-time 2 \
                --output "$output/http-body.txt" \
                --write-out '%{http_code}' \
                "http://127.0.0.1:${TARGET_PORT}/status"
        ); then
            break
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    #检验修复成功
    if [ "$http_code" != "200" ]; then
        printf 'HTTP 服务恢复失败\n' >&2
        exit 1
    fi
    printf '%s\n' "$http_code" > "$output/http-status.txt"
#cleanup
elif [ "$action" = "cleanup" ]; then
    source "$input/server.conf"
    source "$input/process.env"
    #查看监听端口
    service_port_line=$(
        ss -H -ltnp "sport = :${TARGET_PORT}"
    )
    #提取端口
    service_pid=$(
        printf '%s\n' "$service_port_line" |
        sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' |
        head -n 1
    )
    # 端口已经空闲，说明清理已经完成
    if [ -z "$service_port_line" ]; then
        exit 0
    fi
    # 端口有监听，但无法取得 PID
    if [ -z "$service_pid" ]; then
        printf '无法确定修复后 HTTP 服务的 PID\n' >&2
        exit 1
    fi
    #停止服务并退出
    kill -TERM "$service_pid"
    deadline=$((SECONDS + 3))
    while [ -n "$(ss -H -ltn "sport = :${TARGET_PORT}")" ]
    do
        if [ "$SECONDS" -ge "$deadline" ]; then
            printf '修复后 HTTP 服务未按时停止\n' >&2
            exit 1
        fi
        sleep 1
    done
#非re和clean的状态
else
    printf 'unknown action：%s\n' "$action" >&2
    exit 1
fi
