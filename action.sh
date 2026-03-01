#!/system/bin/sh
script_path=/data/adb/modules/Clash/script
watch_dir=/data/adb/modules/Clash

"$script_path/Proxy.sh" -d "$script_path" restart

inotify_pids=$(pgrep -f "inotifyd.*Clash.Inotify")

start_inotify() {
    nohup inotifyd "$script_path/Clash.Inotify" "$watch_dir" >> /dev/null &
    echo "-       已尝试重新拉起 inotifyd"
}

if [ -n "$inotify_pids" ]; then
    pid_count=$(echo "$inotify_pids" | wc -l)

    if [ "$pid_count" -gt 1 ]; then
        echo "-       检测到多个 inotifyd 进程，正在清理并重启"
        kill -9 $inotify_pids 2>/dev/null
        start_inotify
    else
        pid_state=$(ps -o stat= -p "$inotify_pids" 2>/dev/null | tr -d ' ')

        if echo "$pid_state" | grep -q "Z"; then
            echo "-       检测到僵尸 inotifyd 进程，正在重新拉起"
            kill -9 "$inotify_pids" 2>/dev/null
            start_inotify
        else
            echo "-       inotifyd 正在运行中，无需处理"
        fi
    fi
else
    echo "-       inotifyd 未运行，正在重新拉起"
    start_inotify
fi
