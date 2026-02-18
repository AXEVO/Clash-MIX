script_path=/data/adb/modules/Clash/Scripts
watch_dir=/data/adb/modules/Clash

start_kernel() {
    $script_path/Clash.Service start > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "-   内核启动成功"
    else
        echo "-   启动内核失败"
    fi
}

stop_kernel() {
    $script_path/Clash.Service stop > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "-       内核已关闭"
    else
        echo "-       停止内核失败"
    fi
}

start_inotify() {
    nohup inotifyd $script_path/Clash.Inotify "$watch_dir" >> /dev/null &
    echo "-       已尝试重新拉起 inotifyd"
}

if (pgrep -f 'Clash.Core -d') > /dev/null ; then
    echo "-       检测到内核正在运行，准备重启"
    stop_kernel

    echo "-       3秒钟后重启内核"
    sleep 1
    echo "-       2"
    sleep 1
    echo "-       1"
    sleep 1
    echo "-       正在重启内核"

    start_kernel
else
    echo "-       内核未在运行，正在启动"
    start_kernel
fi

inotify_pids=$(pgrep -f "inotifyd.*Clash.Inotify")

if [ -n "$inotify_pids" ]; then
    pid_count=$(echo "$inotify_pids" | wc -l)

    if [ "$pid_count" -gt 1 ]; then
        echo "-       检测到多个僵尸 inotifyd 进程，正在重新拉起"
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