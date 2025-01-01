until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done

until [ -d "/sdcard/Android" ]; do
    sleep 2
done

script_path=/data/adb/modules/Clash/Scripts

$script_path/Clash.Service start
inotifyd $script_path/Clash.Inotify "/data/adb/modules/Clash" >> /dev/null &
