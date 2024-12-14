# 等待设备启动完成
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done

# 启动 Clash 服务
/data/adb/modules/Clash/Scripts/Clash.Service start

# 监听 disable 文件的创建和删除事件
inotifyd /data/adb/modules/Clash/Scripts/Clash.Inotify "/data/adb/modules/Clash" >> /dev/null &

