# 等待设备启动完成
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done
script_path=/data/adb/modules/Clash/Scripts
# 启动 Clash 服务
$script_path/Clash.Service start

# 监听 disable 文件的创建和删除事件
inotifyd $script_path/Clash.Inotify "/data/adb/modules/Clash" >> /dev/null &

