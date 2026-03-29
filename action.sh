#!/system/bin/sh

script_path="/data/adb/modules/Clash/Scripts"
module_dir="/data/adb/modules/Clash"
service_script="$script_path/Clash.Service"
inotify_script="$script_path/Clash.Inotify"
core_pattern='Clash.Core -d'
log_candidates="/sdcard/Android/Clash/内核日志.txt $module_dir/Clash/内核日志.txt"
tmp_output="/data/local/tmp/clash_action.$$.$RANDOM.log"

line() {
    echo "=================================================="
}

info() {
    echo "[INFO] $1"
}

ok() {
    echo "[ OK ] $1"
}

warn() {
    echo "[WARN] $1"
}

err() {
    echo "[FAIL] $1"
}

exists_cmd() {
    command -v "$1" >/dev/null 2>&1
}

grep_pids() {
    pattern="$1"
    if exists_cmd pgrep; then
        pgrep -f "$pattern" 2>/dev/null
        return 0
    fi

    ps -ef 2>/dev/null | grep -- "$pattern" | grep -vE 'grep|inotifyd' | awk '{print $2}'
}

count_lines() {
    echo "$1" | sed '/^$/d' | wc -l | tr -d ' '
}

kernel_pids() {
    grep_pids "$core_pattern"
}

is_kernel_running() {
    [ -n "$(kernel_pids)" ]
}

show_kernel_error_output() {
    if [ -s "$tmp_output" ]; then
        echo "----- Clash.Service 输出（最近 25 行） -----"
        tail -n 25 "$tmp_output"
        echo "--------------------------------------------"
        return
    fi

    for log_path in $log_candidates; do
        if [ -f "$log_path" ]; then
            echo "----- 内核日志：$log_path（最近 25 行） -----"
            tail -n 25 "$log_path"
            echo "--------------------------------------------"
            return
        fi
    done

    warn "未找到可用日志，请手动检查 Clash.Service 与内核文件路径。"
}

start_kernel() {
    : > "$tmp_output"
    sh "$service_script" start >"$tmp_output" 2>&1
    rc=$?

    sleep 2
    if is_kernel_running; then
        ok "Clash 内核启动成功"
        return 0
    fi

    err "Clash 内核启动失败（返回码：$rc）"
    warn "以下为可用报错输出："
    show_kernel_error_output
    return 1
}

stop_kernel() {
    sh "$service_script" stop >"$tmp_output" 2>&1
    rc=$?

    sleep 1
    if is_kernel_running; then
        err "Clash 内核停止失败，仍检测到进程"
        return 1
    fi

    if [ "$rc" -eq 0 ]; then
        ok "Clash 内核已停止"
    else
        warn "停止命令返回非 0，但内核进程已退出"
    fi
    return 0
}

restart_kernel() {
    info "检测到内核正在运行，准备重启"

    if ! stop_kernel; then
        warn "停止失败，为避免重复实例与端口冲突，本次不继续启动"
        show_kernel_error_output
        return 1
    fi

    info "等待 3 秒后重新启动内核"
    sleep 3
    start_kernel
}

inotify_pids() {
    grep_pids 'inotifyd.*Clash.Inotify'
}

pid_state() {
    ps -o stat= -p "$1" 2>/dev/null | tr -d ' '
}

is_zombie_pid() {
    state="$(pid_state "$1")"
    echo "$state" | grep -q 'Z'
}

start_inotify() {
    nohup inotifyd "$inotify_script" "$module_dir" >/dev/null 2>&1 &
    sleep 1

    pids_now="$(inotify_pids)"
    count_now="$(count_lines "$pids_now")"
    if [ "$count_now" -eq 1 ]; then
        ok "inotifyd 已正常运行（PID: $pids_now）"
        return 0
    fi

    err "inotifyd 重建后状态仍异常（数量: $count_now）"
    return 1
}

repair_inotify_if_needed() {
    pids="$(inotify_pids)"
    count="$(count_lines "$pids")"

    if [ "$count" -eq 0 ]; then
        warn "inotifyd 未运行，正在重建"
        start_inotify
        return
    fi

    if [ "$count" -gt 1 ]; then
        warn "检测到 inotifyd 重复进程（数量: $count），正在清理"
        echo "$pids" | xargs kill -9 >/dev/null 2>&1
        start_inotify
        return
    fi

    only_pid="$pids"
    if is_zombie_pid "$only_pid"; then
        parent_pid="$(ps -o ppid= -p "$only_pid" 2>/dev/null | tr -d ' ')"
        warn "检测到 inotifyd 僵尸进程（PID: $only_pid, PPID: ${parent_pid:-未知}）"
        warn "僵尸进程需父进程回收，现尝试重建 inotifyd"
        kill -9 "$only_pid" >/dev/null 2>&1
        start_inotify
        return
    fi

    ok "inotifyd 当前状态正常（PID: $only_pid）"
}

main() {
    line
    info "Clash 操作按钮已触发"
    line

    if [ ! -f "$service_script" ]; then
        err "找不到服务脚本：$service_script"
        return 1
    fi

    if is_kernel_running; then
        restart_kernel
    else
        info "内核当前未运行，开始启动"
        start_kernel
    fi

    line
    repair_inotify_if_needed
    line

    rm -f "$tmp_output" >/dev/null 2>&1
}

main "$@"
