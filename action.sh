#!/system/bin/sh

script_path=/data/adb/modules/Clash/Scripts
module_path=/data/adb/modules/Clash
tproxy_script=$module_path/tproxy.sh
watch_dir=$module_path

start_inotify() {
    nohup inotifyd "$script_path/Clash.Inotify" "$watch_dir" >> /dev/null 2>&1 &
    echo "-   已尝试重新拉起 inotifyd"
}

echo "-   正在重启透明代理"
sh "$tproxy_script" restart > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "-   透明代理已重启成功"
else
    echo "-   重启透明代理失败"
fi

inotify_pids=$(pgrep -f "inotifyd.*Clash.Inotify")

if [ -z "$inotify_pids" ]; then
    echo "-   inotifyd 未运行，正在重新拉起"
    start_inotify
else
    pid_count=$(echo "$inotify_pids" | wc -l)
    if [ "$pid_count" -gt 1 ]; then
        echo "-   检测到多个异常 inotifyd 进程，正在重新拉起"
        kill -9 $inotify_pids 2>/dev/null
        start_inotify
    else
        pid_state=$(ps -o stat= -p "$inotify_pids" 2>/dev/null | tr -d ' ')
        if echo "$pid_state" | grep -q "Z"; then
            echo "-   检测到僵尸 inotifyd 进程，正在重新拉起"
            kill -9 "$inotify_pids" 2>/dev/null
            start_inotify
        else
            echo "-   inotifyd 正在运行中，无需处理"
        fi
    fi
fi